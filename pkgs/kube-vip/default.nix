{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  mkUpdateDeps,
  nix-update-script,
}:
let
  version = "1.1.2";
  src = fetchFromGitHub {
    owner = "kube-vip";
    repo = "kube-vip";
    rev = "v${version}";
    hash = "sha256-vH9fiFInTu2NnC2jLrZUpjaxUxcQuwgvCyl9jlU+UqU=";
  };
in
buildGoApplication {
  pname = "kube-vip";
  inherit version src;

  modules = ./gomod2nix.toml;
  subPackages = [ "." ];

  ldflags = [
    "-w"
    "-s"
    "-X github.com/kube-vip/kube-vip/main.Version=${version}"
    "-X github.com/kube-vip/kube-vip/main.Build=${src.rev}"
    "-extldflags -static"
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
