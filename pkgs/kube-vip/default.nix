{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  mkUpdateDeps,
  nix-update-script,
}:
let
  version = "1.2.4";
  src = fetchFromGitHub {
    owner = "kube-vip";
    repo = "kube-vip";
    rev = "v${version}";
    hash = "sha256-8jrf2U/TiO9vVUv+55IadzxcrO+Kzj3RKSngfaCaWbc=";
  };
in
buildGoApplication {
  pname = "kube-vip";
  inherit version src;

  modules = ./gomod2nix.toml;
  subPackages = [ "." ];

  # No cgo is required, and linking it statically fails for lack of a static libc.
  CGO_ENABLED = 0;

  ldflags = [
    "-w"
    "-s"
    "-X main.Version=${version}"
    "-X main.Build=${src.rev}"
  ];

  passthru.update-deps = mkUpdateDeps src;
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Kube-VIP: Virtual IP for Kubernetes clusters";
    homepage = "https://github.com/kube-vip/kube-vip";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "kube-vip";
    badPlatforms = [ "aarch64-darwin" ];
  };
}
