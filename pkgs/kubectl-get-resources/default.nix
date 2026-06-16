{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  mkUpdateDeps,
  nix-update-script,
}:
let
  version = "0.1.1";
  src = fetchFromGitHub {
    owner = "Sandeep-Prajapati";
    repo = "kubectl-get-resources";
    rev = "v${version}";
    hash = "sha256-XDd3B95dnhpuG4redqFOysIYEQm3G6+hiE7uqdksok4=";
  };
in
buildGoApplication {
  pname = "kubectl-get-resources";
  inherit version src;

  modules = ./gomod2nix.toml;

  passthru.update-deps = mkUpdateDeps src;
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Get Kubernetes resources (cluster or namespace scope) in CSV or YAML with support for multiple filtering flags.";
    homepage = "https://github.com/Sandeep-Prajapati/kubectl-get-resources";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "kubectl-get-resources";
  };
}
