{
  lib,
  buildNpmPackage,
  fetchzip,
  jq,
  nix-update-script,
}:
let
  version = "1.59.3";
in
buildNpmPackage {
  pname = "likec4";
  inherit version;

  # The published package.json's devDependencies pull in pnpm workspace
  # packages (@likec4/devops, @likec4/tsconfig, ...) that aren't on the
  # public registry, so npm can't resolve them. They're also unneeded since
  # dist/ ships prebuilt. Stripping them at fetch time keeps upstream's
  # dependency list authoritative and lets `nix-update --generate-lockfile`
  # regenerate package-lock.json from the unpacked source.
  src = fetchzip {
    url = "https://registry.npmjs.org/likec4/-/likec4-${version}.tgz";
    hash = "sha256-1K6CBH0whoxtFj8+n2TUvb6ILeawmkg0CHytZHx4aRs=";
    nativeBuildInputs = [ jq ];
    postFetch = ''
      jq 'del(.devDependencies)' "$out/package.json" > "$out/package.json.tmp"
      mv "$out/package.json.tmp" "$out/package.json"
    '';
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-rVbzJwycyU98uMbIhPZsdCcaleT1rruwvMHkIhnETpM=";

  # playwright's install script downloads browsers, which the sandbox
  # can't do. Browsers for `likec4 export png` come from a separate
  # `playwright install` (or PLAYWRIGHT_BROWSERS_PATH) at run time.
  npmFlags = [ "--ignore-scripts" ];

  dontNpmBuild = true;

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--generate-lockfile" ];
  };

  meta = with lib; {
    description = "Toolchain for your architecture diagrams";
    homepage = "https://likec4.dev";
    license = licenses.mit;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "likec4";
  };
}
