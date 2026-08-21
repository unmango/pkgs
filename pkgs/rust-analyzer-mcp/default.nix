{
  lib,
  fetchFromGitHub,
  rustPlatform,
  nix-update-script,
}:
let
  version = "0.3.1";
in
rustPlatform.buildRustPackage {
  pname = "rust-analyzer-mcp";
  inherit version;

  src = fetchFromGitHub {
    owner = "zeenix";
    repo = "rust-analyzer-mcp";
    rev = "v${version}";
    hash = "sha256-PWEl5Ik4F6u8wXi+oPSL3+C3z9dOSVMNAJvEcYf3Q4s=";
  };

  cargoHash = "sha256-NUOqAUsFyALfnDVLZIQeUWR9wPLF9Tr3BFDBN9zZAwk=";

  # Integration tests spawn a live rust-analyzer process, which isn't
  # available in the build sandbox.
  doCheck = false;

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Model Context Protocol (MCP) server that provides integration with rust-analyzer";
    homepage = "https://github.com/zeenix/rust-analyzer-mcp";
    license = licenses.mit;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "rust-analyzer-mcp";
  };
}
