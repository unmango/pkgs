{
  lib,
  buildNpmPackage,
  fetchzip,
  jq,
  nix-update-script,
}:
let
  version = "0.10.0";
in
buildNpmPackage {
  pname = "lsmcp";
  inherit version;

  # The published package.json's devDependencies pull in internal pnpm
  # workspace packages (@internal/types, @internal/lsp-client,
  # @internal/code-indexer) not published to the public registry, so npm
  # can't resolve them. They're also unneeded since dist/ ships prebuilt.
  # Stripping them at fetch time keeps upstream's dependency list
  # authoritative and lets `nix-update --generate-lockfile` regenerate
  # package-lock.json from the unpacked source.
  src = fetchzip {
    url = "https://registry.npmjs.org/@mizchi/lsmcp/-/lsmcp-${version}.tgz";
    hash = "sha256-GJPAeP32Fpm/F8Z8HL+1IvJads+RjiKuNTLe0Nrb5K0=";
    nativeBuildInputs = [ jq ];
    postFetch = ''
      jq 'del(.devDependencies)' "$out/package.json" > "$out/package.json.tmp"
      mv "$out/package.json.tmp" "$out/package.json"
    '';
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-GEYTKhgzDu6KncBI/0FqkKZcE8djlzoXT9ci0i4jisA=";

  dontNpmBuild = true;

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--generate-lockfile" ];
  };

  meta = with lib; {
    description = "Unified MCP server for language-service/LSP-based code analysis across multiple languages";
    homepage = "https://github.com/mizchi/lsmcp";
    license = licenses.mit;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "lsmcp";
  };
}
