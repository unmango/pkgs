{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  mkUpdateDeps,
  nix-update-script,
}:
let
  version = "0.0.66";
  src = fetchFromGitHub {
    owner = "containers";
    repo = "kubernetes-mcp-server";
    rev = "v${version}";
    hash = "sha256-vnJxSCfnpvOZJXQpKrCAW4QKt5R2PJDYQevA7O1uXZg=";
  };
in
buildGoApplication {
  pname = "kubernetes-mcp-server";
  inherit version src;

  modules = ./gomod2nix.toml;
  subPackages = [ "cmd/kubernetes-mcp-server" ];

  # Example_version asserts the ldflags-injected version is unset ("0.0.0"),
  # which conflicts with the version we inject below.
  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/containers/kubernetes-mcp-server/pkg/version.Version=v${version}"
    "-X github.com/containers/kubernetes-mcp-server/pkg/version.BinaryName=kubernetes-mcp-server"
    "-X github.com/containers/kubernetes-mcp-server/pkg/version.WebsiteURL=https://github.com/containers/kubernetes-mcp-server"
  ];

  passthru.update-deps = mkUpdateDeps src;
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Model Context Protocol (MCP) server for Kubernetes and OpenShift";
    homepage = "https://github.com/containers/kubernetes-mcp-server";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "kubernetes-mcp-server";
  };
}
