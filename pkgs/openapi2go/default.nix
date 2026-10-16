{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  mkUpdateDeps,
  nix-update-script,
}:
let
  version = "0.0.1";
  src = fetchFromGitHub {
    owner = "UnstoppableMango";
    repo = "openapi2go";
    rev = "v${version}";
    hash = "sha256-GMv9/mCCw40heEZ5seJ+NtYdzxUoEAR2ARxJLrlHEMk=";
  };
in
buildGoApplication {
  pname = "openapi2go";
  inherit version src;

  modules = ./gomod2nix.toml;

  subPackages = [ "." ];

  # The e2e suite reads the Petstore spec from the network.
  doCheck = false;

  passthru.update-deps = mkUpdateDeps src;
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Generate Go types from OpenAPI specifications";
    homepage = "https://github.com/UnstoppableMango/openapi2go";
    license = licenses.mit;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "openapi2go";
  };
}
