{
  lib,
  mkSfPlugin,
  nix-update-script,
}:
mkSfPlugin {
  pname = "sfdx-git-delta";
  version = "6.45.1";
  npmName = "sfdx-git-delta";

  hash = "sha256-XKtzSp/j5Oqu8gkFvh1y+IAhel3vzuMCEoTYYPD3pUg=";
  npmDepsHash = "sha256-8scoP6imZJAt3qB3O+Mb5DykYNjC6FY/1dNdUXJY/OE=";

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Salesforce CLI plugin that generates a delta package from a git diff";
    homepage = "https://github.com/scolladon/sfdx-git-delta";
    license = licenses.mit;
    maintainers = with maintainers; [ UnstoppableMango ];
  };
}
