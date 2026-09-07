---
name: code-review
description: Review checklist for pull requests in this nix flake-parts packages repo, covering derivation conventions, pkgs/default.nix wiring, generated artifacts, and per-language vendored manifests. Use when reviewing a pull request or diff in this repository.
---

# Reviewing a pull request in this repo

This repo is a `flake-parts` flake whose only content is Nix package derivations under `pkgs/`.
Most defects here are wiring and generated-artifact mistakes that evaluate fine locally and fail in CI, or fail silently.
Check the items below against the diff.
Skip a section if the diff does not touch it.

## 1. Derivation shape

Applies to `pkgs/<name>/default.nix`.

- Follows the house shape: a `let` block binding `version` and `src` (usually `fetchFromGitHub`), then the builder call with `pname` and `inherit version src`.
- `passthru.updateScript = nix-update-script { };` is present, unless the package is listed in the `manual_only` map in `scripts/update.sh`.
- `meta` has `description`, `homepage`, `license`, `maintainers = with maintainers; [ UnstoppableMango ]`, and `mainProgram` for anything that ships an executable.
- `UnstoppableMango` comes from `lib/maintainers.nix`. A new maintainer entry is a mistake.
- No placeholder, zeroed, or otherwise unfetchable hash. CI runs `make build`, which builds every attr of `packages.<system>`, so a fake hash fails the required check.

## 2. Wiring in `pkgs/default.nix`

- A new package is registered alphabetically in **both** the `packages` attrset and the `overlayAttrs` inherit list.
  Only one of the two means `overlays.default` and the flake's `packages` output disagree.
- An unfree vendor binary belongs in the `unfreePackages` attrset instead, which already flows into `overlayAttrs` and `legacyPackages.<system>`. Putting it in `packages` makes CI build it and push it to the public cachix caches, redistributing the vendor's binary.
- Every unfree package name must also appear in `allowUnfreePredicate` in `flake.nix`.
  Without it, `meta.available` is false and the package is filtered out of the flake outputs with no error at all.
- A package that depends on another local package takes it via `inherit (config.packages) <dep>;`.
- A `pkgs/<name>/default.nix` that exists but is deliberately not registered is not necessarily a bug. See the `smarter-device-manager` comment in `pkgs/default.nix`.

## 3. Generated artifacts

- The `<!-- PACKAGES:START -->` / `<!-- PACKAGES:END -->` block in `README.md` is generated from `config.packages` by `lib/packages.nix` via `scripts/gen-packages-table.sh`.
  Hand edits inside that block are a defect. So is a package-count badge that disagrees with the table.
- Any PR that adds or removes a package must include the regenerated table and badge from `make generate`.
  The `codegen` CI job runs `make generate` and fails on a non-empty diff.

## 4. Per-language manifests

| Language | Builder                                  | What must accompany the change                                                                                                                                |
| -------- | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Go       | `buildGoApplication`                     | `gomod2nix.toml` committed and regenerated after any `go.mod` change, `passthru.update-deps = mkUpdateDeps src;`, and the name in `GO_PKGS` in the `Makefile` |
| .NET     | `buildDotnetModule`                      | `deps.json` committed, `dotnet-sdk` pinned through `dotnetCorePackages`                                                                                       |
| Python   | `python3Packages.buildPythonApplication` | `pyproject = true;` with `build-system` and `dependencies`                                                                                                    |
| Rust     | `rustPlatform.buildRustPackage`          | a real `cargoHash`                                                                                                                                            |

`nix-update` maintains `nugetDeps`, `cargoHash`, and `npmDepsHash` on its own, but gomod2nix is opaque to it.
A Go version bump that leaves `gomod2nix.toml` untouched is suspect.

Container images under `pkgs/images/<name>/` attach to an existing nixpkgs package through `overrideAttrs` plus `passthru.image`.
An image registered as its own `packages` entry is wrong.

## 5. Nix idioms

- Prefer `inherit (foo) bar;` over `bar = foo.bar;`.
- `inputs` and `self` are referenced only in `flake.nix` and in flake modules where they are module arguments by design.
  Package derivations take what they need as explicit function arguments so they stay usable outside this flake.

## 6. Leave these alone

Comments on the following are noise:

- Individual rows inside the generated README package table.
- Version strings and source hashes in automated update pull requests, which `scripts/update.sh` and `nix-update` produce mechanically.
- Formatting that `make fmt` owns (nixfmt, prettier, shfmt, statix, deadnix, actionlint).
