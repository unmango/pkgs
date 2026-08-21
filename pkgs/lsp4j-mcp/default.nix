{
  lib,
  maven,
  jdk,
  makeWrapper,
  fetchFromGitHub,
  nix-update-script,
}:
let
  version = "1.0.0";
  # Upstream's pom.xml declares <version>1.0.0-SNAPSHOT</version>, so the
  # shaded jar keeps that literal suffix regardless of the release tag.
  jarName = "lsp4j-mcp-1.0.0-SNAPSHOT.jar";
in
maven.buildMavenPackage {
  pname = "lsp4j-mcp";
  inherit version;

  src = fetchFromGitHub {
    owner = "stephanj";
    repo = "LSP4J-MCP";
    rev = "v${version}";
    hash = "sha256-At+RWftJErCx3Tga6QfAh3XtCCzCnMvdKV7GlKDBc0E=";
  };

  mvnHash = "sha256-CPS8RfEJ7+xMJRB2mtnjH7t+eYdNTFyXgAqkWfyDi5c=";

  nativeBuildInputs = [ makeWrapper ];

  # Tests spawn a live JDTLS process, which isn't available in the sandbox.
  doCheck = false;

  installPhase = ''
    runHook preInstall

    install -Dm644 target/${jarName} $out/share/java/lsp4j-mcp.jar
    makeWrapper ${jdk}/bin/java $out/bin/lsp4j-mcp \
      --add-flags "-jar $out/share/java/lsp4j-mcp.jar"

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Model Context Protocol (MCP) server exposing Java IDE features via JDTLS";
    homepage = "https://github.com/stephanj/LSP4J-MCP";
    # Upstream's README claims MIT but ships no LICENSE file.
    license = licenses.mit;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "lsp4j-mcp";
  };
}
