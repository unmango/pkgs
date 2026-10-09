# Wraps a unified CLI so it always loads `plugins`, the way
# python3.withPackages does. Backs `remark-cli.withPlugins`.
#
# Each plugin is passed as `--use <entry file>`, the absolute store path in
# its `passthru.unifiedPlugin`, so nothing is resolved by package name and
# each plugin finds its own dependencies from its own store path. ESM refuses
# directory imports, which is why the entry file and not the package
# directory is named. Flags rather than `--rc-path` keep the CLI's discovery
# of a project's own .remarkrc or package.json config, which `--rc-path`
# turns off. A list entry carries plugin options, as in an rc file:
#
#   [ remark-gfm [ remark-toc { heading = "Contents"; } ] ]
{
  lib,
  makeWrapper,
  runCommand,
}:
{
  cli,
  plugins ? [ ],
  settings ? { },
}:
let
  exe = cli.meta.mainProgram;

  entry = plugin: plugin.unifiedPlugin or (toString plugin);

  # unified-args parses option values as JSON5 wrapped in braces, so the
  # object's own braces come off.
  fields = value: lib.removePrefix "{" (lib.removeSuffix "}" (builtins.toJSON value));

  use =
    plugin:
    let
      file = entry (if lib.isList plugin then lib.head plugin else plugin);
      options = if lib.isList plugin then lib.elemAt plugin 1 else { };
    in
    [
      "--use"
      (if options == { } then file else "${file}=${fields options}")
    ];

  flags =
    lib.concatMap use plugins
    ++ lib.optionals (settings != { }) [
      "--setting"
      (fields settings)
    ];
in
runCommand "${cli.pname}-with-plugins-${cli.version}"
  {
    nativeBuildInputs = [ makeWrapper ];

    passthru = {
      unifiedFlags = flags;
      unwrapped = cli;
    };

    meta = cli.meta // {
      mainProgram = exe;
    };
  }
  ''
    makeWrapper ${lib.getExe cli} "$out/bin/${exe}" ${
      lib.concatMapStringsSep " " (flag: "--add-flag ${lib.escapeShellArg flag}") flags
    }
  ''
