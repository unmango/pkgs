{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  mkUpdateDeps,
  nix-update-script,
}:
let
  version = "1.4.2";
  src = fetchFromGitHub {
    owner = "stackitcloud";
    repo = "kubectl-get-all";
    rev = "v${version}";
    hash = "sha256-7KYnWeml3vVxklmw26S44U92Hpvgw9yIQ9wgQGrUb3U=";
  };
in
buildGoApplication {
  pname = "kubectl-get-all";
  inherit version src;

  modules = ./gomod2nix.toml;
  disableGoCache = true;

  ldflags = [
    "-w"
    "-s"
    "-X github.com/stackitcloud/kubectl-get-all/internal/version.Version=${version}"
  ];

  passthru.update-deps = mkUpdateDeps src;
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Like `kubectl get all`, but get really all resources";
    homepage = "https://github.com/stackitcloud/kubectl-get-all";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "kubectl-get-all";
  };
}
