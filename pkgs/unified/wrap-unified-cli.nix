# Wraps a unified CLI so it always loads `plugins`, the way
# python3.withPackages does. Backs `remark-cli.withPlugins`.
#
# The generated rc names each plugin by the absolute store path of its entry
# file (`passthru.unifiedPlugin`), so nothing is resolved by package name and
# each plugin finds its own dependencies from its own store path. ESM refuses
# directory imports, which is why the entry file and not the package directory
# is named. A list entry carries plugin options, as in an rc file:
#
#   [ remark-gfm [ remark-toc { heading = "Contents"; } ] ]
{
  lib,
  formats,
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
  toRc =
    plugin:
    if lib.isList plugin then [ (entry (lib.head plugin)) ] ++ lib.tail plugin else entry plugin;

  rc = (formats.json { }).generate "${cli.pname}-rc.json" (
    { plugins = map toRc plugins; } // lib.optionalAttrs (settings != { }) { inherit settings; }
  );
in
runCommand "${cli.pname}-with-plugins-${cli.version}"
  {
    nativeBuildInputs = [ makeWrapper ];

    passthru = {
      inherit rc;
      unwrapped = cli;
    };

    meta = cli.meta // {
      mainProgram = exe;
    };
  }
  ''
    makeWrapper ${lib.getExe cli} "$out/bin/${exe}" --add-flags "--rc-path ${rc}"
  ''
