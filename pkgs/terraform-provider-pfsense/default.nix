{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  mkUpdateDeps,
  nix-update-script,
}:
let
  version = "0.22.0";
  src = fetchFromGitHub {
    owner = "marshallford";
    repo = "terraform-provider-pfsense";
    rev = "v${version}";
    hash = "sha256-hGPq3m41DmfvpZgHSYVVH/vqhyU5WrgK3P4d6NBlU6k=";
  };
in
buildGoApplication {
  pname = "terraform-provider-pfsense";
  inherit version src;

  modules = ./gomod2nix.toml;
  disableGoCache = true;

  ldflags = [
    "-w"
    "-s"
  ];

  doCheck = false;

  passthru.update-deps = mkUpdateDeps src;
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Used to configure pfSense firewall/router devices with Terraform";
    homepage = "https://github.com/marshallford/terraform-provider-pfsense";
    license = licenses.mit;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "terraform-provider-pfsense";
  };
}
