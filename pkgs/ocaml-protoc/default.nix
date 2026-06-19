{
  lib,
  nix-update-script,
  ocamlPackages,
  pbrt,
}:
ocamlPackages.buildDunePackage {
  pname = "ocaml-protoc";
  inherit (pbrt) version src;

  buildInputs = [ ocamlPackages.stdlib-shims ];
  propagatedBuildInputs = [ pbrt ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Pure OCaml compiler for .proto files";
    homepage = "https://github.com/mransan/ocaml-protoc";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ UnstoppableMango ];
    mainProgram = "ocaml-protoc";
  };
}
