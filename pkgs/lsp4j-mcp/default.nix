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

    # maven-shade-plugin replaces the main artifact in place and keeps the
    # unshaded one as `original-*.jar`. The artifact's name tracks the pom's
    # `<version>` (a literal `1.0.0-SNAPSHOT`), not the release tag, so match
    # it by glob rather than pinning a name that a version bump would miss.
    jar=$(find target -maxdepth 1 -name 'lsp4j-mcp-*.jar' ! -name 'original-*')
    test -f "$jar" || { echo "expected exactly one shaded jar, got: $jar" >&2; exit 1; }

    install -Dm644 "$jar" $out/share/java/lsp4j-mcp.jar
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
