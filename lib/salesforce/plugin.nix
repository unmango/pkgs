{
  lib,
  buildNpmPackage,
  fetchurl,
  jq,
}:

# Builds an oclif plugin published to the npm registry into
# $out/lib/node_modules/<npmName>, ready for `salesforce-cli.withPlugins`.
{
  pname,
  version,
  # Registry name, e.g. "@salesforce/plugin-code-analyzer".
  npmName,
  # Hash of the registry tarball.
  hash,
  npmDepsHash,
  # Packages a command of this plugin shells out to. `withPlugins` puts them on
  # the PATH of the CLI it builds; a plugin derivation on its own has no bin to
  # wrap, so this is the only place they can be attached.
  runtimeInputs ? [ ],
  passthru ? { },
  ...
}@args:
let
  # Scoped names live under the scope on the registry but drop it from the
  # tarball filename: @salesforce/plugin-x/-/plugin-x-1.0.0.tgz.
  tarballName = lib.last (lib.splitString "/" npmName);
in
buildNpmPackage (
  removeAttrs args [
    "npmName"
    "hash"
    "runtimeInputs"
    "passthru"
  ]
  // {
    inherit pname version npmDepsHash;

    src = fetchurl {
      url = "https://registry.npmjs.org/${npmName}/-/${tarballName}-${version}.tgz";
      inherit hash;
    };

    npmDepsFetcherVersion = 2;

    # Salesforce publishes plugins with an npm-shrinkwrap.json (plugin-trust
    # signs it) whose dev subtree is incomplete, so `npm ci` falls back to the
    # registry for the missing entries and fails in the sandbox. dist/ ships
    # prebuilt, so drop the dev half of the lockfile and of package.json with
    # it. jq is called by store path because buildNpmPackage replays postPatch
    # inside fetchNpmDeps, whose build environment it does not control.
    postPatch = ''
      if [ -f npm-shrinkwrap.json ]; then
        lockfile=npm-shrinkwrap.json
      elif [ -f package-lock.json ]; then
        lockfile=package-lock.json
      else
        echo "mkSfPlugin: ${npmName} ships no npm-shrinkwrap.json or package-lock.json" >&2
        exit 1
      fi

      ${lib.getExe jq} 'del(.devDependencies)' package.json >patched.json
      mv patched.json package.json

      ${lib.getExe jq} '
        (.packages |= with_entries(select(.value.dev != true)))
        | del(.packages[""].devDependencies)
      ' "$lockfile" >patched.json
      mv patched.json "$lockfile"
    '';

    # dist/ ships prebuilt, and the install scripts are husky and telemetry.
    npmFlags = [
      "--ignore-scripts"
      "--legacy-peer-deps"
    ];
    dontNpmBuild = true;

    passthru = passthru // {
      inherit npmName runtimeInputs;
    };
  }
)
