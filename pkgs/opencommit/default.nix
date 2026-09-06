{
  lib,
  buildNpmPackage,
  fetchzip,
  jq,
  nix-update-script,
}:
let
  version = "3.3.10";
in
buildNpmPackage {
  pname = "opencommit";
  inherit version;

  # The published package.json's devDependencies pull in build/test/lint
  # tooling (esbuild, jest, ts-node, biome, ...) that's unneeded since
  # out/cli.cjs ships prebuilt. Stripping them at fetch time keeps
  # upstream's dependency list authoritative and lets
  # `nix-update --generate-lockfile` regenerate package-lock.json from the
  # unpacked source.
  src = fetchzip {
    url = "https://registry.npmjs.org/opencommit/-/opencommit-${version}.tgz";
    hash = "sha256-flWO0AKHZsi2Sa9eiJo40u9K/a6NSo1qD3MKkNCIBd0=";
    nativeBuildInputs = [ jq ];
    postFetch = ''
      jq 'del(.devDependencies)' "$out/package.json" > "$out/package.json.tmp"
      mv "$out/package.json.tmp" "$out/package.json"
    '';
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-g2UwWjGLOksvyj/qXLF21WttnT8aVSMS7rzoYAgzSGI=";

  dontNpmBuild = true;

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--generate-lockfile" ];
  };

  meta = with lib; {
    description = "Auto-generate impressive commits in 1 second, killing lame commits with AI";
    homepage = "https://github.com/di-sukharev/opencommit";
    license = licenses.mit;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "opencommit";
  };
}
