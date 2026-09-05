#!/usr/bin/env bash
# Update automation: bump every wired-up package to its latest upstream
# release with nix-update, regenerate whatever vendored dependency manifest
# the package carries, and open one pull request per package that builds.
set -uo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root" || exit 1

# Packages nix-update can't drive end to end. Reported as needing a manual
# bump instead of being attempted.
# Quoted keys: shfmt reads a bare hyphenated index as arithmetic and would
# rewrite [aspire-cli] to [aspire - cli].
declare -A manual_only=(
  ["aspire-cli"]="nix-update's fetch-deps run fails to load the dotnet command"
  ["coderabbit"]="four per-platform zip hashes that move together, and no git host to read a version from"
  ["lsmcp"]="npm tarball src plus a hand-vendored package-lock.json"
  ["opencommit"]="npm tarball src plus a hand-vendored package-lock.json"
  ["salesforce-cli"]="npm tarball src rewritten by a runCommand nix-update cannot see through"
)

# createCommitOnBranch needs the repository's name-with-owner in its input.
repo_slug=$(gh repo view --json nameWithOwner --jq .nameWithOwner) || exit 1

failures=()
updates=()
manual=()
skipped=()

# Extracts the first `<attr> = "<value>";` assignment from a nix file.
pin() { sed -n 's/^[[:space:]]*'"$1"' = "\(.*\)";/\1/p' "$2" | head -n1; }

# Records a failed bump and restores the work tree; uses the caller's locals.
fail() {
  echo "  $1"
  failures+=("$name: $1 ($old_version -> $new_version)")
  git checkout -- "$dir"
}

# Refreshes the vendored dependency manifest a package pins alongside its
# derivation. Only gomod2nix is handled here: nix-update recognizes the
# fetchers it knows (nugetDeps, cargoHash, npmDepsHash) and refreshes those
# itself, but a gomod2nix.toml is opaque to it.
regen_deps() {
  if [[ -f "$dir/gomod2nix.toml" ]]; then
    echo "  regenerating gomod2nix.toml"
    nix run ".#$name.update-deps" "$repo_root/$dir/gomod2nix.toml"
  fi
}

# Commits the package's changed files on a new branch and opens a pull
# request for them. Commits go through createCommitOnBranch rather than
# git push because main's ruleset requires GitHub-signed commits, and the
# API signs what it commits; the mutation needs an existing branch, so the
# ref is created first.
open_pr() {
  local branch="$1" head_sha files=()
  mapfile -t files < <(git diff --name-only -- "$dir")

  # DRY_RUN exercises everything up to the point of touching the remote,
  # which is what a local run wants.
  if [[ -n ${DRY_RUN:-} ]]; then
    echo "  dry run, would open $branch with: ${files[*]}"
    git checkout -- "$dir"
    return
  fi

  head_sha=$(git rev-parse HEAD)
  gh api "repos/{owner}/{repo}/git/refs" \
    -f ref="refs/heads/$branch" -f sha="$head_sha" >/dev/null ||
    {
      fail "branch create failed"
      return 1
    }

  delete_branch() { gh api -X DELETE "repos/{owner}/{repo}/git/refs/heads/$branch" >/dev/null; }

  # shellcheck disable=SC2016 # $input is a GraphQL variable, not a shell one
  local mutation='mutation($input: CreateCommitOnBranchInput!) { createCommitOnBranch(input: $input) { commit { oid } } }'
  local payload
  payload=$(
    for f in "${files[@]}"; do
      jq -n --arg path "$f" --arg contents "$(base64 -w0 "$f")" \
        '{path: $path, contents: $contents}'
    done | jq -s \
      --arg query "$mutation" \
      --arg repo "$repo_slug" \
      --arg branch "$branch" \
      --arg oid "$head_sha" \
      --arg message "$name: $old_version -> $new_version" \
      '{query: $query, variables: {input: {
          branch: {repositoryNameWithOwner: $repo, branchName: $branch},
          expectedHeadOid: $oid,
          message: {headline: $message},
          fileChanges: {additions: .}
        }}}'
  )

  gh api graphql --input - <<<"$payload" >/dev/null ||
    {
      delete_branch
      fail "commit create failed"
      return 1
    }

  # The change now lives only on the remote branch; reset the work tree so
  # the next package starts from a clean checkout.
  git checkout -- "$dir"

  gh pr create --title "$name: $old_version -> $new_version" --head "$branch" \
    --body "Automated update to the latest upstream release." ||
    {
      delete_branch
      fail "gh pr create failed"
      return 1
    }

  # Queued behind main's required build check rather than merged outright.
  # A bump whose build breaks in CI stays open for a person to look at.
  gh pr merge --auto --squash "$branch" ||
    echo "  auto-merge could not be enabled, leaving the PR open"
}

# Runs nix-update, refreshes vendored dependencies, builds, and opens a PR.
attempt_bump() {
  local new_version="" branch

  nix-update --flake "$name" --override-filename "$dir/default.nix" ||
    {
      new_version="?"
      fail "nix-update failed"
      return
    }

  if git diff --quiet -- "$dir"; then
    echo "  up to date ($old_version)"
    return
  fi

  new_version=$(pin version "$dir/default.nix")
  [[ -n $new_version && $new_version != "$old_version" ]] ||
    {
      new_version="?"
      fail "nix-update changed files without changing the version"
      return
    }

  echo "  $old_version -> $new_version"

  # A bump stays pending until a human merges it; don't push over its branch.
  branch="update-$name-$new_version"
  if [[ $(gh pr list --head "$branch" --state open --json number --jq 'length') != "0" ]]; then
    echo "  PR already open for $branch, skipping"
    git checkout -- "$dir"
    skipped+=("$name: PR already open for $new_version")
    return
  fi

  regen_deps || {
    fail "dependency regeneration failed"
    return
  }

  nix build ".#$name" || {
    fail "build failed, discarding change"
    return
  }

  open_pr "$branch" || return
  updates+=("$name: $old_version -> $new_version")
}

for dir in pkgs/*/; do
  dir=${dir%/}
  name=$(basename "$dir")
  [[ -f "$dir/default.nix" ]] || continue

  # A directory under pkgs/ isn't necessarily a package: ones blocked on an
  # upstream fix are deliberately left out of pkgs/default.nix.
  grep -q "callPackage \./$name " pkgs/default.nix || continue

  echo "== $name =="

  if [[ -n ${manual_only[$name]:-} ]]; then
    echo "  needs manual bump: ${manual_only[$name]}"
    manual+=("$name: ${manual_only[$name]}")
    continue
  fi

  old_version=$(pin version "$dir/default.nix")
  if [[ -z $old_version ]]; then
    echo "  skip: no version pin in $dir/default.nix"
    skipped+=("$name: no version pin")
    continue
  fi

  # An unstable pin tracks a commit on a source with no usable releases;
  # picking a new commit is a person's call.
  if [[ $old_version == *unstable-* ]]; then
    echo "  skip: unstable pin, upstream has no releases ($old_version)"
    skipped+=("$name: unstable pin ($old_version)")
    continue
  fi

  attempt_bump
done

# Prints "<label>: <count>" followed by one indented line per entry.
report() {
  local label="$1"
  shift
  echo "$label: $#"
  (($# == 0)) || printf '  %s\n' "$@"
}

# Same, as a markdown section for the workflow run's summary page.
report_md() {
  local label="$1"
  shift
  printf '### %s (%s)\n\n' "$label" "$#"
  if (($# > 0)); then
    printf -- '- %s\n' "$@"
  else
    echo "_none_"
  fi
  echo
}

echo
echo "== summary =="
report updated "${updates[@]}"
report "manual bumps needed" "${manual[@]}"
report skipped "${skipped[@]}"
report failed "${failures[@]}"

if [[ -n ${GITHUB_STEP_SUMMARY:-} ]]; then
  {
    echo "## Update automation"
    echo
    report_md "Updated" "${updates[@]}"
    report_md "Manual bumps needed" "${manual[@]}"
    report_md "Skipped" "${skipped[@]}"
    report_md "Failed" "${failures[@]}"
  } >>"$GITHUB_STEP_SUMMARY"
fi

if ((${#failures[@]} > 0)); then
  exit 1
fi
