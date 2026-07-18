{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  mkUpdateDeps,
  nix-update-script,
}:
let
  version = "0.4.1";
  src = fetchFromGitHub {
    owner = "hashicorp";
    repo = "terraform-plugin-codegen-framework";
    tag = "v${version}";
    hash = "sha256-a5eWS2pcr7tbAd9xrGJKRZ3DzHoBwM0FMLV5RGQhGa4=";
  };
in
buildGoApplication {
  pname = "terraform-plugin-codegen-framework";
  inherit version src;

  modules = ./gomod2nix.toml;
  disableGoCache = true;
  subPackages = [ "cmd/tfplugingen-framework" ];

  passthru.update-deps = mkUpdateDeps src;
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Terraform Plugin Framework Code Generation";
    homepage = "https://github.com/hashicorp/terraform-plugin-codegen-framework";
    license = licenses.mpl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "tfplugingen-framework";
  };
}
