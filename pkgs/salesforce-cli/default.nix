{
  lib,
  buildNpmPackage,
  fetchurl,
  jq,
  makeWrapper,
  nix-update-script,
  runCommand,
  writeText,
}:
let
  version = "2.149.9";

  tarball = fetchurl {
    url = "https://registry.npmjs.org/@salesforce/cli/-/cli-${version}.tgz";
    hash = "sha256-875QsNywNzWiqZZKSyJMtJQTUbtE/dUFoaCdB1W70og=";
  };

  otelPeerDependencies."@opentelemetry/api" = ">=1.0.0 <1.10.0";
  otelEngines.node = ">=14";

  otelCore = {
    version = "1.30.1";
    resolved = "https://registry.npmjs.org/@opentelemetry/core/-/core-1.30.1.tgz";
    integrity = "sha512-OOCM2C/QIURhJMuKaekP3TRBxBKxG/TWWA0TL2J6nXUtDnuCtccy49LUJF8xPFXMX+0LMcxFpCo8M9cGY1W6rQ==";
    license = "Apache-2.0";
    dependencies."@opentelemetry/semantic-conventions" = "1.28.0";
    peerDependencies = otelPeerDependencies;
    engines = otelEngines;
  };

  otelResources = {
    version = "1.30.1";
    resolved = "https://registry.npmjs.org/@opentelemetry/resources/-/resources-1.30.1.tgz";
    integrity = "sha512-5UxZqiAgLYGFjS4s9qm5mBVo433u+dSPUFWVWXmLAD4wB65oMCoXaJP1KJa9DIYYMeHu3z4BZcStG3LC593cWA==";
    license = "Apache-2.0";
    dependencies = {
      "@opentelemetry/core" = "1.30.1";
      "@opentelemetry/semantic-conventions" = "1.28.0";
    };
    peerDependencies = otelPeerDependencies;
    engines = otelEngines;
  };

  otelSemanticConventions = {
    version = "1.28.0";
    resolved = "https://registry.npmjs.org/@opentelemetry/semantic-conventions/-/semantic-conventions-1.28.0.tgz";
    integrity = "sha512-lp4qAiMTD4sNWW4DbKLBkfiMZ4jbAboJIGOQr5DvciMRI494OapieI9qiODpOt0XBr1LjIDy1xAGAnVs5supTA==";
    license = "Apache-2.0";
    engines = otelEngines;
  };

  # The published npm-shrinkwrap.json hoists the OpenTelemetry 2.x line to the
  # top level but leaves the 1.x pins of applicationinsights and
  # @opentelemetry/sdk-trace-base without nested entries. npm ci then falls back
  # to the registry for them, which fails in the sandbox. Supply the nested
  # entries so the lockfile describes a complete tree.
  lockAdditions = writeText "npm-shrinkwrap-additions.json" (
    builtins.toJSON {
      "node_modules/@opentelemetry/sdk-trace-base/node_modules/@opentelemetry/core" = otelCore;
      "node_modules/@opentelemetry/sdk-trace-base/node_modules/@opentelemetry/resources" = otelResources;
      "node_modules/@opentelemetry/sdk-trace-base/node_modules/@opentelemetry/semantic-conventions" =
        otelSemanticConventions;
      "node_modules/applicationinsights/node_modules/@opentelemetry/core" = otelCore;
      "node_modules/applicationinsights/node_modules/@opentelemetry/semantic-conventions" =
        otelSemanticConventions;
    }
  );

  # devDependencies go too: dist/ ships prebuilt, and their subtree in the
  # lockfile is incomplete (chokidar's optional fsevents has no entry), which
  # npm ci also rejects.
  src = runCommand "salesforce-cli-source-${version}" { nativeBuildInputs = [ jq ]; } ''
    mkdir -p $out
    tar xf ${tarball} --strip-components=1 -C $out
    jq 'del(.devDependencies)' $out/package.json >package.json
    mv package.json $out/package.json

    jq --slurpfile add ${lockAdditions} '
      (.packages |= with_entries(select(.value.dev != true)))
      | del(.packages[""].devDependencies)
      | .packages += $add[0]
    ' $out/npm-shrinkwrap.json >shrinkwrap.json
    mv shrinkwrap.json $out/npm-shrinkwrap.json
  '';
in
buildNpmPackage {
  pname = "salesforce-cli";
  inherit version src;

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-YiebUV18yxWX+mF02QMFVvpEi0pnLajzmGcYULvMHts=";

  nativeBuildInputs = [ makeWrapper ];

  # dist/ ships prebuilt, and the preinstall script shells out to
  # `sfdx --version` to detect a conflicting v1 install.
  npmFlags = [
    "--ignore-scripts"
    "--legacy-peer-deps"
  ];
  dontNpmBuild = true;

  # The environment below pins the CLI to this store path. Updating happens by
  # bumping `version` and the hashes above.
  #
  # SF_REDIRECTED short-circuits the launcher's first branch, which otherwise
  # hands execution to $XDG_DATA_HOME/sf/client/bin/sf whenever a self-updated
  # copy is sitting there.
  #
  # SF_INSTALLER marks this as a managed install, so the "update available"
  # notice points at the environment instead of telling the user to run
  # `npm update --global`. The CLI accepts either spelling of the autoupdate
  # flag, so both are set.
  postInstall = ''
    for bin in sf sfdx; do
      wrapProgram $out/bin/$bin \
        --set SF_REDIRECTED 1 \
        --set SF_INSTALLER true \
        --set SF_AUTOUPDATE_DISABLE true \
        --set SF_DISABLE_AUTOUPDATE true
    done
  '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "CLI for developing against the Salesforce Platform";
    homepage = "https://developer.salesforce.com/tools/salesforcecli";
    downloadPage = "https://github.com/salesforcecli/cli/releases";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "sf";
  };
}
