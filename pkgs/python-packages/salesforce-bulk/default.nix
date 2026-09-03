{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  nix-update-script,
  requests,
  setuptools,
  simple-salesforce,
  six,
  unicodecsv,
}:
buildPythonPackage rec {
  pname = "salesforce-bulk";
  version = "2.2.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "heroku";
    repo = "salesforce-bulk";
    tag = "v${version}";
    hash = "sha256-WDSzWmqHvBCf5DNrDn3hiag38dhgKRlkgYfadG3Mzl8=";
  };

  build-system = [ setuptools ];

  dependencies = [
    requests
    simple-salesforce
    six
    unicodecsv
  ];

  # The suite talks to a live Salesforce org.
  doCheck = false;

  pythonImportsCheck = [ "salesforce_bulk" ];

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Python interface to the Salesforce.com Bulk API";
    homepage = "https://github.com/heroku/salesforce-bulk";
    license = licenses.mit;
    maintainers = with maintainers; [ UnstoppableMango ];
  };
}
