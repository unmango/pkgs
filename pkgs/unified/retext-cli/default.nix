# retext has no upstream CLI, so this is a local one on unified-args, the
# same ten lines remark-cli is. Its dependencies are the scope's own
# derivations, linked in by store path, so it needs no lockfile.
{
  lib,
  stdenvNoCC,
  makeWrapper,
  nodejs,
  runCommand,
  testers,
  retext,
  unified-args,
  unifiedPackages,
  wrapUnifiedCli,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "retext-cli";
  inherit (retext) version;

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    packageOut="$out/lib/node_modules/retext-cli"
    mkdir -p "$packageOut/node_modules"
    cp cli.js package.json "$packageOut"
    substituteInPlace "$packageOut/cli.js" --replace-fail @version@ ${finalAttrs.version}
    ln -s ${retext}/lib/node_modules/retext "$packageOut/node_modules/retext"
    ln -s ${unified-args}/lib/node_modules/unified-args "$packageOut/node_modules/unified-args"

    makeWrapper ${lib.getExe nodejs} "$out/bin/retext" --add-flags "$packageOut/cli.js"

    runHook postInstall
  '';

  passthru = {
    # retext-cli.withPlugins (ps: [ ps.retext-english ps.retext-repeated-words ])
    withPlugins =
      f:
      wrapUnifiedCli {
        cli = finalAttrs.finalPackage;
        plugins = f unifiedPackages;
      };

    tests = {
      version = testers.testVersion { package = finalAttrs.finalPackage; };

      # retext-repeated-words loads from its store path and warns.
      withPlugins =
        let
          retext = finalAttrs.finalPackage.withPlugins (ps: [
            ps.retext-english
            ps.retext-repeated-words
          ]);
        in
        runCommand "retext-cli-with-plugins-test" { } ''
          echo 'It is a a test.' > in.txt
          ${lib.getExe retext} --no-color in.txt > /dev/null 2> report

          grep -qF 'Unexpected repeated `a`' report || {
            echo "expected a repeated-words warning, got:" >&2
            cat report >&2
            exit 1
          }
          touch "$out"
        '';
    };
  };

  meta = {
    description = "Command line interface to inspect and change prose with retext";
    homepage = "https://github.com/retextjs/retext";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ UnstoppableMango ];
    mainProgram = "retext";
  };
})
