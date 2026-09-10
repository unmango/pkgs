{
  lib,
  fetchFromGitHub,
  rustPlatform,
  nix-update-script,
}:
let
  version = "0.4.0";
in
rustPlatform.buildRustPackage {
  pname = "rust-analyzer-mcp";
  inherit version;

  src = fetchFromGitHub {
    owner = "zeenix";
    repo = "rust-analyzer-mcp";
    rev = "v${version}";
    hash = "sha256-W9LFTQ4KxUHDFuENRhDsv+jUjzgHdCEn7xXWzVKF6y0=";
  };

  cargoHash = "sha256-LcX9VO1ArCdiq5j57JB/Tkfw6pAl6QvckhzMRv5C5dA=";

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
