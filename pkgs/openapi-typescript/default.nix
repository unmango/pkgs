{
  lib,
  buildNpmPackage,
  fetchzip,
  jq,
  nix-update-script,
}:
let
  version = "7.13.0";
in
buildNpmPackage {
  pname = "openapi-typescript";
  inherit version;

  # The published dist/ is prebuilt, so devDependencies are dead weight.
  # Stripping them at fetch time lets `nix-update --generate-lockfile`
  # regenerate package-lock.json from the unpacked source.
  src = fetchzip {
    url = "https://registry.npmjs.org/openapi-typescript/-/openapi-typescript-${version}.tgz";
    hash = "sha256-kkCis5j3cekBmuNSE8YodyCUgFDqVOhBNji/FrekPlc=";
    nativeBuildInputs = [ jq ];
    postFetch = ''
      jq 'del(.devDependencies)' "$out/package.json" > "$out/package.json.tmp"
      mv "$out/package.json.tmp" "$out/package.json"
    '';
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-GdMEYLSRZmg806lb8O44/mnX5VqOsjgzmmS/pK3idGo=";

  dontNpmBuild = true;

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--generate-lockfile" ];
  };

  meta = with lib; {
    description = "Generate TypeScript types from OpenAPI 3 schemas";
    homepage = "https://openapi-ts.dev";
    license = licenses.mit;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "openapi-typescript";
  };
}
