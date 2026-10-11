# rehypejs/rehype: rehype, rehype-cli, rehype-parse and rehype-stringify.
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
    pname = "rehype";

    src = fetchFromGitHub {
      owner = "rehypejs";
      repo = "rehype";
      tag = "13.0.2";
      hash = "sha256-CwRc169rWS5JeJ7DQhS8DjOrNHpZRNbo8RBevKOgmwI=";
    };

    lockfile = ./package-lock.json;
    workspaces = lib.importJSON ./workspaces.json;
    npmDepsHash = "sha256-ypiiZmXu/XS/6U0l+S/Hq6Nm5a2OI/+21DR5eJxWix8=";
    packages = unifiedPackages;

    meta = {
      homepage = "https://github.com/rehypejs/rehype";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [ UnstoppableMango ];
    };
  };
in
packages
// {
  rehype-cli = packages.rehype-cli.overrideAttrs (
    finalAttrs: prev: {
      passthru = prev.passthru // {
        # rehype-cli.withPlugins (ps: [ ps.rehype-format ])
        withPlugins =
          f:
          wrapUnifiedCli {
            cli = finalAttrs.finalPackage;
            plugins = f unifiedPackages;
          };

        tests = {
          version = testers.testVersion { package = finalAttrs.finalPackage; };

          # A settings flag reaches rehype-stringify through the wrapper.
          withPlugins =
            let
              rehype = wrapUnifiedCli {
                cli = finalAttrs.finalPackage;
                settings.quote = "'";
              };
            in
            runCommand "rehype-cli-with-plugins-test" { } ''
              echo '<p class="a">b</p>' > in.html
              ${lib.getExe rehype} --no-color in.html > out.html

              grep -qF "<p class='a'>b</p>" out.html || {
                echo "expected single quotes, got:" >&2
                cat out.html >&2
                exit 1
              }
              touch "$out"
            '';
        };
      };

      meta = prev.meta // {
        mainProgram = "rehype";
      };
    }
  );
}
