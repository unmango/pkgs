{
  lib,
  jq,
  makeWrapper,
  nodejs,
  runCommand,
  sfWithPlugins,
}:

# Rebuilds the Salesforce CLI with `plugins` linked in as core plugins, so they
# resolve from the store instead of from `sf plugins install`'s mutable copy
# under $XDG_DATA_HOME/sf.
{ salesforce-cli, plugins }:
let
  runtimeInputs = lib.concatMap (plugin: plugin.runtimeInputs or [ ]) plugins;

  wrapperArgs =
    lib.mapAttrsToList (
      name: value: "--set ${name} ${lib.escapeShellArg value}"
    ) salesforce-cli.runtimeEnv
    ++ lib.optional (runtimeInputs != [ ]) "--prefix PATH : ${lib.makeBinPath runtimeInputs}";
in
runCommand "salesforce-cli-${salesforce-cli.version}"
  {
    nativeBuildInputs = [
      jq
      makeWrapper
    ];

    inherit plugins;
    pluginNames = builtins.toJSON (map (plugin: plugin.npmName) plugins);
    pluginDeps = builtins.toJSON (
      lib.listToAttrs (lib.map (plugin: lib.nameValuePair plugin.npmName plugin.version) plugins)
    );

    inherit (salesforce-cli) meta;
    passthru = salesforce-cli.passthru // {
      inherit plugins;
      # Stack onto what is already linked in rather than starting from the
      # bare CLI again.
      withPlugins =
        extra:
        sfWithPlugins {
          inherit salesforce-cli;
          plugins = plugins ++ extra;
        };
    };
  }
  ''
    upstream=${salesforce-cli}/lib/node_modules/@salesforce/cli
    root=$out/lib/node_modules/@salesforce/cli
    mkdir -p "$root/node_modules"

    # The CLI's own ~2M of files are copied rather than symlinked: node resolves
    # a module's dependencies from its realpath, so a symlinked entry point
    # would look for node_modules beside the upstream copy and never see the
    # plugins linked in below.
    for entry in $(ls -A "$upstream"); do
      if [ "$entry" != node_modules ]; then
        cp -r --no-preserve=mode,ownership "$upstream/$entry" "$root/$entry"
      fi
    done

    # Its 270M of dependencies stay symlinks. Scope directories are recreated as
    # real directories so a scoped plugin can be linked in beside them.
    link_into() {
      local from="$1"
      for entry in $(ls -A "$from"); do
        case "$entry" in
          @*)
            mkdir -p "$root/node_modules/$entry"
            for scoped in $(ls -A "$from/$entry"); do
              ln -sfn "$from/$entry/$scoped" "$root/node_modules/$entry/$scoped"
            done
            ;;
          *)
            ln -sfn "$from/$entry" "$root/node_modules/$entry"
            ;;
        esac
      done
    }

    link_into "$upstream/node_modules"
    for plugin in $plugins; do
      link_into "$plugin/lib/node_modules"
    done

    # oclif loads a core plugin only when it appears in both oclif.plugins and
    # dependencies (see loadCorePlugins in @oclif/core), and a plugin that is
    # also declared under oclif.jitPlugins would otherwise still be reported as
    # not installed.
    jq --argjson names "$pluginNames" --argjson deps "$pluginDeps" '
      .oclif.plugins += $names
      | .dependencies += $deps
      | if .oclif.jitPlugins
        then .oclif.jitPlugins |= with_entries(select(.key as $k | $names | index($k) | not))
        else . end
    ' "$root/package.json" >package.json
    mv package.json "$root/package.json"

    mkdir -p $out/bin
    for bin in sf sfdx; do
      makeWrapper ${lib.getExe nodejs} "$out/bin/$bin" \
        --add-flags "--no-deprecation $root/bin/run.js" \
        ${lib.concatStringsSep " " wrapperArgs}
    done
  ''
