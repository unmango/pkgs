{
  lib,
  fetchFromGitHub,
  nix-update-script,
  ocamlPackages,
  pkg-config,
  protobuf,
}:
ocamlPackages.buildDunePackage rec {
  pname = "ocaml-protoc-plugin";
  version = "4.5.0";

  src = fetchFromGitHub {
    owner = "issuu";
    repo = "ocaml-protoc-plugin";
    rev = version;
    hash = "sha256-ZHeOi3y2X11MmkRuthmYFSjPLoGlGTO1pnRfk/XmgPU=";
  };

  nativeBuildInputs = [
    pkg-config
    protobuf
  ];

  buildInputs = with ocamlPackages; [
    zarith
    ppx_deriving
    ppx_deriving_yojson
    re
    dune-site
    ppx_expect
    protobuf
  ];

  doCheck = true;
  nativeCheckInputs = [ protobuf ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Maps google protobuf compiler to Ocaml types";
    homepage = "https://github.com/issuu/ocaml-protoc-plugin";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ UnstoppableMango ];
  };
}
