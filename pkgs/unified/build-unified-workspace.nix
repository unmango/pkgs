# Builds every member of an npm workspace from one fetch and one lockfile.
# A scoped member is keyed without its `@` and slash, so `@mdx-js/mdx` is
# `mdx-js-mdx`.
#
# buildNpmPackage's install hook assumes the root package.json names the
# package and copies node_modules with its workspace symlinks dangling, so
# each member gets its own installPhase. Links to sibling members are pointed
# at the siblings' own store paths, taken from `packages`, so overrideScope
# reaches them.
{
  lib,
  buildNpmPackage,
  fetchNpmDeps,
  jq,
}:
{
  pname,
  src,
  # Upstream unified repos set package-lock=false, so the lock is vendored.
  lockfile,
  # A root package.json to use instead of upstream's, to build only some
  # members against a smaller lockfile.
  manifest ? null,
  # Written by workspaces.sh:
  # { <name> = { path, version, description, entry, dependencies }; }
  workspaces,
  npmDepsHash,
  # The scope the sibling members are looked up in.
  packages,
  meta ? { },
}:
let
  attrName = name: lib.replaceStrings [ "@" "/" ] [ "" "-" ] name;

  postPatch = ''
    cp ${lockfile} package-lock.json
  ''
  + lib.optionalString (manifest != null) ''
    cp ${manifest} package.json
  '';

  npmDeps = fetchNpmDeps {
    name = "${pname}-npm-deps";
    inherit src postPatch;
    hash = npmDepsHash;
    # Packuments too: npm reads them to resolve workspace members offline.
    fetcherVersion = 2;
  };

  member =
    name:
    {
      path,
      version,
      description,
      entry,
      dependencies,
    }:
    buildNpmPackage (finalAttrs: {
      pname = attrName name;
      inherit
        version
        src
        postPatch
        npmDeps
        ;

      meta = meta // {
        inherit description;
      };

      npmWorkspace = path;
      npmDepsFetcherVersion = 2;
      dontNpmBuild = true;

      nativeBuildInputs = [ jq ];

      installPhase = ''
        runHook preInstall

        npm prune --omit=dev --no-save $npmFlags "''${npmFlagsArray[@]}"
        find node_modules -maxdepth 1 -type d -empty -delete

        packageOut="$out/lib/node_modules/${name}"
        mkdir -p "$packageOut"

        # Run from inside the member so the hooks read its package.json.
        pushd ${lib.escapeShellArg path}
        npm pack --json --dry-run --loglevel=warn --no-foreground-scripts \
          | jq --raw-output '.[0].files[].path' \
          | while IFS= read -r file; do
              mkdir -p "$packageOut/$(dirname "$file")"
              cp "$file" "$packageOut/$file"
            done
        nodejsInstallExecutables ./package.json
        nodejsInstallManuals ./package.json
        popd

        cp -r node_modules "$packageOut/node_modules"

        # A dependency whose version clashes with the hoisted one is nested
        # under the member instead, and wins.
        pushd ${lib.escapeShellArg path}
        for dep in node_modules/* node_modules/@*/*; do
          case "$dep" in
            node_modules/@*/*) ;;
            node_modules/@*) continue ;;
          esac
          [ -e "$dep" ] || continue
          rm -rf "$packageOut/$dep"
          mkdir -p "$(dirname "$packageOut/$dep")"
          cp -r "$dep" "$packageOut/$dep"
        done
        popd

        # Workspace links point at ../packages/*, which is not in $out.
        find "$packageOut/node_modules" -maxdepth 2 -type l -lname '../*' -delete
        ${lib.concatMapStrings (dep: ''
          mkdir -p "$(dirname "$packageOut/node_modules/${dep}")"
          ln -s ${packages.${attrName dep}}/lib/node_modules/${dep} "$packageOut/node_modules/${dep}"
        '') dependencies}

        runHook postInstall
      '';

      passthru = {
        inherit npmDeps;
      }
      // lib.optionalAttrs (entry != null) {
        # The file a unified rc names to load this package as a plugin.
        unifiedPlugin = "${finalAttrs.finalPackage}/lib/node_modules/${name}/${entry}";
      };
    });
in
lib.mapAttrs' (
  name: workspace: lib.nameValuePair (attrName name) (member name workspace)
) workspaces
