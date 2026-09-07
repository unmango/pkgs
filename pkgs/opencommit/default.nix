{
  lib,
  stdenvNoCC,
  fetchzip,
  makeWrapper,
  nodejs,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencommit";
  version = "3.3.10";

  # The published out/cli.cjs is an esbuild bundle that requires only Node
  # builtins, so the tarball's dependencies are never loaded. Wrapping the
  # bundle directly avoids installing ~115M of unreferenced node_modules.
  src = fetchzip {
    url = "https://registry.npmjs.org/opencommit/-/opencommit-${finalAttrs.version}.tgz";
    hash = "sha256-RRLsakHJ7tOs0fwOHt/j4Vu7U+2wWiQjC0HIxa+Xk84=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/opencommit
    cp -r out/. $out/lib/opencommit

    makeWrapper ${lib.getExe nodejs} $out/bin/opencommit \
      --add-flags $out/lib/opencommit/cli.cjs
    ln -s opencommit $out/bin/oco

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Auto-generate impressive commits in 1 second, killing lame commits with AI";
    homepage = "https://github.com/di-sukharev/opencommit";
    license = licenses.mit;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "opencommit";
  };
})
