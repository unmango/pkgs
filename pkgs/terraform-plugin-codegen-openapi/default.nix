{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  mkUpdateDeps,
  nix-update-script,
}:
let
  version = "0.3.0";
  src = fetchFromGitHub {
    owner = "hashicorp";
    repo = "terraform-plugin-codegen-openapi";
    tag = "v${version}";
    hash = "sha256-6xI6PVlvYHwOnWjE0pKYDF/FvdomE5KydS7gBokJ2EM=";
  };
in
buildGoApplication {
  pname = "terraform-plugin-codegen-openapi";
  inherit version src;

  modules = ./gomod2nix.toml;
  disableGoCache = true;
  subPackages = [ "cmd/tfplugingen-openapi" ];

  passthru.update-deps = mkUpdateDeps src;
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "OpenAPI to Terraform Provider Code Generation Specification";
    homepage = "https://github.com/hashicorp/terraform-plugin-codegen-openapi";
    license = licenses.mpl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "tfplugingen-openapi";
  };
}
