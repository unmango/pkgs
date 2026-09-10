{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  mkUpdateDeps,
  nix-update-script,
}:
let
  version = "1.38.4";
  src = fetchFromGitHub {
    owner = "pulumi";
    repo = "pulumi-yaml";
    tag = "v${version}";
    hash = "sha256-Sdq2LRf+NQTM02RjNTW7nIb1fpCRxsZmFMSsOqK1O1s=";
  };
in
buildGoApplication {
  pname = "pulumi-yaml";
  inherit version src;
  modules = ./gomod2nix.toml;
  subPackages = [ "cmd/pulumi-language-yaml" ];

  # Matches nixpkgs' pulumi-go, which skips TestLanguage as sandbox-incompatible.
  doCheck = false;

  passthru.update-deps = mkUpdateDeps src;
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Pulumi language host for YAML programs";
    homepage = "https://github.com/pulumi/pulumi-yaml";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "pulumi-language-yaml";
  };
}
