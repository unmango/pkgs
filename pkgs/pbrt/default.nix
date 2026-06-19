{
  lib,
  fetchFromGitHub,
  nix-update-script,
  ocamlPackages,
}:
let
  version = "4.1";
in
ocamlPackages.buildDunePackage {
  pname = "pbrt";
  inherit version;

  src = fetchFromGitHub {
    owner = "mransan";
    repo = "ocaml-protoc";
    rev = "v${version}";
    hash = "sha256-UrgrzI5Pgi79C/OhqYxwSNfqsoBULUZ13XVaB71fGes=";
  };

  propagatedBuildInputs = [ ocamlPackages.stdlib-shims ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Runtime library for Protobuf tooling";
    homepage = "https://github.com/mransan/ocaml-protoc";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ UnstoppableMango ];
  };
}
