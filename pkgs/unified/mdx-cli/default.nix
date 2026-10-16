# @mdx-js/mdx has no upstream CLI, so this is a local one around its
# `compile`; see cli.js for its flags. @mdx-js/mdx is the scope's own
# derivation, linked in by store path, so it needs no lockfile.
{
  lib,
  stdenvNoCC,
  makeWrapper,
  nodejs,
  runCommand,
  testers,
  mdx-js-mdx,
  remark-gfm,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mdx-cli";
  inherit (mdx-js-mdx) version;

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    packageOut="$out/lib/node_modules/mdx-cli"
    mkdir -p "$packageOut/node_modules/@mdx-js"
    cp cli.js package.json "$packageOut"
    substituteInPlace "$packageOut/cli.js" --replace-fail @version@ ${finalAttrs.version}
    ln -s ${mdx-js-mdx}/lib/node_modules/@mdx-js/mdx "$packageOut/node_modules/@mdx-js/mdx"

    makeWrapper ${lib.getExe nodejs} "$out/bin/mdx" --add-flags "$packageOut/cli.js"

    runHook postInstall
  '';

  passthru.tests = {
    version = testers.testVersion { package = finalAttrs.finalPackage; };

    # A remark plugin loads from its store path: without remark-gfm the
    # strikethrough stays literal text.
    compile =
      runCommand "mdx-cli-compile-test"
        {
          options = builtins.toJSON { remarkPlugins = [ remark-gfm.unifiedPlugin ]; };
          passAsFile = [ "options" ];
        }
        ''
          mkdir -p docs
          printf '# Hi\n\n~~old~~ <Note>new</Note>\n' > docs/a.mdx
          ${lib.getExe finalAttrs.finalPackage} --options "$optionsPath" --out-dir out docs/a.mdx

          for want in 'export default function MDXContent' '_components.del' 'Note'; do
            grep -qF -- "$want" out/docs/a.js || {
              echo "expected '$want', got:" >&2
              cat out/docs/a.js >&2
              exit 1
            }
          done
          touch "$out"
        '';
  };

  meta = {
    description = "Compile MDX to JavaScript with @mdx-js/mdx";
    homepage = "https://mdxjs.com";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ UnstoppableMango ];
    mainProgram = "mdx";
  };
})
