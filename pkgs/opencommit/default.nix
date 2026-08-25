{
  lib,
  buildNpmPackage,
  fetchurl,
  nix-update-script,
}:
let
  version = "3.3.10";
in
buildNpmPackage {
  pname = "opencommit";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/opencommit/-/opencommit-${version}.tgz";
    hash = "sha256-YmdpPflI+JC48AhBqdS1XTlv8zxr4o69PC92OFUTs/4=";
  };

  # The published package.json's devDependencies pull in build/test/lint
  # tooling (esbuild, jest, ts-node, biome, ...) that's unneeded since
  # out/cli.cjs ships prebuilt. Replace it with a minimal stub (no external
  # tools available here: this postPatch also runs inside the fetchNpmDeps
  # FOD, which has no jq/node on PATH, only coreutils) and vendor a matching
  # lockfile.
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
    cat > package.json <<EOF
    {
      "name": "opencommit",
      "version": "${version}",
      "license": "MIT",
      "dependencies": {
        "@actions/core": "^1.10.0",
        "@actions/exec": "^1.1.1",
        "@actions/github": "^6.0.1",
        "@anthropic-ai/sdk": "^0.19.2",
        "@azure/openai": "^1.0.0-beta.12",
        "@clack/prompts": "^0.6.1",
        "@dqbd/tiktoken": "^1.0.2",
        "@google/generative-ai": "^0.24.1",
        "@mistralai/mistralai": "^1.3.5",
        "@octokit/webhooks-schemas": "^6.11.0",
        "@octokit/webhooks-types": "^6.11.0",
        "axios": "1.9.0",
        "chalk": "^5.2.0",
        "cleye": "^1.3.2",
        "crypto": "^1.0.1",
        "execa": "^7.0.0",
        "https-proxy-agent": "^8.0.0",
        "ignore": "^5.2.4",
        "ini": "^3.0.1",
        "inquirer": "^9.1.4",
        "openai": "^4.57.0",
        "punycode": "^2.3.1",
        "zod": "^3.23.8"
      },
      "overrides": {
        "ajv": "^8.17.1",
        "whatwg-url": "^14.0.0"
      },
      "bin": {
        "opencommit": "out/cli.cjs",
        "oco": "out/cli.cjs"
      }
    }
    EOF
  '';

  npmDepsHash = "sha256-EQfyczVNsmFgkTegDoW1T+E9ZpBjM73fGwxqPhdPGTc=";

  dontNpmBuild = true;

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Auto-generate impressive commits in 1 second, killing lame commits with AI";
    homepage = "https://github.com/di-sukharev/opencommit";
    license = licenses.mit;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "opencommit";
  };
}
