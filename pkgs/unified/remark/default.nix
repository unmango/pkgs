# remarkjs/remark: remark, remark-cli, remark-parse and remark-stringify.
{
  lib,
  buildUnifiedWorkspace,
  fetchFromGitHub,
  runCommand,
  testers,
  unifiedPackages,
  wrapUnifiedCli,
}:
let
  packages = buildUnifiedWorkspace {
    pname = "remark";

    src = fetchFromGitHub {
      owner = "remarkjs";
      repo = "remark";
      tag = "remark-cli@12.0.1";
      hash = "sha256-kiaMI42smtTNiGxM1quGCpQx/YnRfYpAmDhtuPzV6fA=";
    };

    lockfile = ./package-lock.json;
    workspaces = lib.importJSON ./workspaces.json;
    npmDepsHash = "sha256-f4axPvlv37i9k2Y4GKtLHLIgN3+K2tK7RbK7ohJdKr4=";
    packages = unifiedPackages;

    meta = {
      homepage = "https://remark.js.org";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [ UnstoppableMango ];
    };
  };
in
packages
// {
  remark-cli = packages.remark-cli.overrideAttrs (
    finalAttrs: prev: {
      passthru = prev.passthru // {
        # remark-cli.withPlugins (ps: [ ps.remark-gfm ])
        withPlugins =
          f:
          wrapUnifiedCli {
            cli = finalAttrs.finalPackage;
            plugins = f unifiedPackages;
          };

        tests = {
          version = testers.testVersion { package = finalAttrs.finalPackage; };

          # remark-gfm loads from its store path: without it remark leaves
          # the bare URL as plain text.
          withPlugins =
            let
              remark = finalAttrs.finalPackage.withPlugins (ps: [ ps.remark-gfm ]);
            in
            runCommand "remark-cli-with-plugins-test" { } ''
              echo 'www.example.com' | ${lib.getExe remark} --no-color > out.md
              grep -qF '[www.example.com](http://www.example.com)' out.md || {
                cat out.md >&2
                exit 1
              }
              touch "$out"
            '';
        };
      };

      meta = prev.meta // {
        mainProgram = "remark";
      };
    }
  );
}
