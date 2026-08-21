{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,
}:
let
  version = "1.0.4";
in
buildNpmPackage {
  pname = "java-jdtls-mcp-server";
  inherit version;

  src = fetchFromGitHub {
    owner = "SachieWang";
    repo = "java-jdtls-mcp-server";
    rev = "v${version}";
    hash = "sha256-Qyjni3OMZjALX93cv26+b1TCVBy6QP4IfNpaNcTbyVU=";
  };

  npmDepsHash = "sha256-sj28T0+30pcInEV405qPuAEuyGu2KALlQkQrpliiyDU=";

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Model Context Protocol (MCP) server for Java using Eclipse JDT.LS";
    homepage = "https://github.com/SachieWang/java-jdtls-mcp-server";
    license = licenses.isc;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "java-mcp-server";
  };
}
