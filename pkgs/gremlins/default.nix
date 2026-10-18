{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  mkUpdateDeps,
  nix-update-script,
}:
let
  version = "0.6.0";
  src = fetchFromGitHub {
    owner = "go-gremlins";
    repo = "gremlins";
    rev = "v${version}";
    hash = "sha256-QwMj7aA4eafMT25gBLAomZMliCbueoEsDHD/nxtnmk4=";
  };
in
buildGoApplication {
  pname = "gremlins";
  inherit version src;

  modules = ./gomod2nix.toml;
  subPackages = [ "cmd/gremlins" ];

  ldflags = [
    "-w"
    "-s"
    "-X main.version=${version}"
  ];

  passthru.update-deps = mkUpdateDeps src;
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Mutation testing for Go";
    homepage = "https://gremlins.dev";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "gremlins";
  };
}
