# remarkjs/remark-lint: remark-lint, unified-lint-rule, every remark-lint-*
# rule and the remark-preset-lint-* presets.
{
  lib,
  buildUnifiedWorkspace,
  fetchFromGitHub,
  runCommand,
  unifiedPackages,
}:
let
  packages = buildUnifiedWorkspace {
    pname = "remark-lint";

    src = fetchFromGitHub {
      owner = "remarkjs";
      repo = "remark-lint";
      # Packages are tagged one by one; this is the newest, and every member
      # is at its latest release here.
      tag = "remark-lint-no-unused-definitions@4.0.2";
      hash = "sha256-EHYZfx11UwMkvFGux6bH5Oz/sWoVkc2R68S8vQTPFQU=";
    };

    lockfile = ./package-lock.json;
    workspaces = lib.importJSON ./workspaces.json;
    npmDepsHash = "sha256-E7AdEGJoxuCEbcWqHDceR+IkN2Chi0OEwbSqzyYRlTY=";
    packages = unifiedPackages;

    meta = {
      homepage = "https://github.com/remarkjs/remark-lint";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [ UnstoppableMango ];
    };
  };
in
packages
// {
  remark-preset-lint-recommended = packages.remark-preset-lint-recommended.overrideAttrs (
    finalAttrs: prev: {
      # The preset loads its rules from their own store paths and fails a bad
      # file under --frail.
      passthru = prev.passthru // {
        tests.lint =
          let
            remark = unifiedPackages.remark-cli.withPlugins (_: [ finalAttrs.finalPackage ]);
          in
          runCommand "remark-preset-lint-recommended-test" { } ''
            printf '# a\n\n[b]: https://example.com\n' > bad.md
            if ${lib.getExe remark} --no-color --frail bad.md 2> report; then
              echo "expected bad.md to fail lint" >&2
              exit 1
            fi
            grep -qF 'no-unused-definitions' report || {
              echo "expected no-unused-definitions, got:" >&2
              cat report >&2
              exit 1
            }

            printf '# a\n' > good.md
            ${lib.getExe remark} --no-color --frail good.md
            touch "$out"
          '';
      };
    }
  );
}
