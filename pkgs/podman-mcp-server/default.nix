{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  mkUpdateDeps,
  nix-update-script,
}:
let
  version = "0.0.15";
  src = fetchFromGitHub {
    owner = "manusa";
    repo = "podman-mcp-server";
    rev = "v${version}";
    hash = "sha256-6637MP4WA2XfIyfMQhM9shvqGkj+GZjaHXU+zf+EGN4=";
  };
  versionPkg = "github.com/manusa/podman-mcp-server/pkg/version";
in
buildGoApplication {
  pname = "podman-mcp-server";
  inherit version src;

  modules = ./gomod2nix.toml;
  subPackages = [ "cmd/podman-mcp-server" ];

  # CGO_ENABLED=0 selects the pure-Go btrfs/devicemapper/openpgp stubs, and
  # "remote" avoids needing a local libpod/CGO storage backend, mirroring
  # upstream's own Makefile BUILD_TAGS.
  CGO_ENABLED = 0;
  tags = "remote,containers_image_openpgp,exclude_graphdriver_btrfs,btrfs_noversion,exclude_graphdriver_devicemapper";

  ldflags = [
    "-s"
    "-w"
    "-X ${versionPkg}.Version=v${version}"
    "-X ${versionPkg}.BinaryName=podman-mcp-server"
  ];

  # Upstream's test suite expects a podman CLI on PATH (CI installs it
  # explicitly before `make test`), which isn't available in the sandbox.
  doCheck = false;

  passthru.update-deps = mkUpdateDeps src;
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Model Context Protocol (MCP) server for container runtimes (Podman and Docker)";
    homepage = "https://github.com/manusa/podman-mcp-server";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "podman-mcp-server";
  };
}
