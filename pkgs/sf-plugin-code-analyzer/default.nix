{
  lib,
  jdk21,
  mkSfPlugin,
  nix-update-script,
  python3,
}:
mkSfPlugin {
  pname = "sf-plugin-code-analyzer";
  version = "5.16.0";
  npmName = "@salesforce/plugin-code-analyzer";

  hash = "sha256-1rKVldKQ0mEJm/8V+t3EYKTKwXMMSiOPM6/TVAN1npE=";
  npmDepsHash = "sha256-6qZ2LGYEJ95CgWq+vrUla0NnJHJCbAE0ShQBVkpe+wM=";

  # The PMD, SFGE and ApexGuru engines run bundled jars, and the Flow engine
  # runs a bundled Python module. Both are looked up on PATH.
  runtimeInputs = [
    jdk21
    python3
  ];

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Salesforce Code Analyzer, a Salesforce CLI plugin for static analysis";
    homepage = "https://developer.salesforce.com/docs/platform/salesforce-code-analyzer/overview";
    license = licenses.bsd3;
    maintainers = with maintainers; [ UnstoppableMango ];
  };
}
