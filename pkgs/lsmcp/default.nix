{
  lib,
  buildNpmPackage,
  fetchurl,
  nix-update-script,
}:
let
  version = "0.10.0";
in
buildNpmPackage {
  pname = "lsmcp";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@mizchi/lsmcp/-/lsmcp-${version}.tgz";
    hash = "sha256-NdnhTN9HyPlTuy3E0dw6r2jh1WRJXavJQ5WZM3LDmKY=";
  };

  # The published package.json's devDependencies pull in internal pnpm
  # workspace packages (@internal/types, @internal/lsp-client,
  # @internal/code-indexer) not published to the public registry, so
  # npm ci can't resolve them. They're also unneeded since dist/ ships
  # prebuilt. Replace it with a minimal stub (no external tools available
  # here: this postPatch also runs inside the fetchNpmDeps FOD, which has
  # no jq/node on PATH, only coreutils) and vendor a matching lockfile.
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
    cat > package.json <<EOF
    {
      "name": "lsmcp",
      "version": "${version}",
      "license": "MIT",
      "dependencies": {
        "gitaware-glob": "^0.2.0",
        "glob": "^10.4.5",
        "minimatch": "^9.0.5",
        "uuid": "^11.1.0",
        "zod": "^3.25.56"
      },
      "bin": {
        "lsmcp": "./dist/lsmcp.js"
      }
    }
    EOF
  '';

  npmDepsHash = "sha256-9kVqalzZrvG5DicydrzSpbsHn4gJPUkhdGvpUAlmgME=";

  dontNpmBuild = true;

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Unified MCP server for language-service/LSP-based code analysis across multiple languages";
    homepage = "https://github.com/mizchi/lsmcp";
    license = licenses.mit;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "lsmcp";
  };
}
