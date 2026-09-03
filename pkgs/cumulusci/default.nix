{
  lib,
  fetchFromGitHub,
  nix-update-script,
  python313Packages,
}:
let
  version = "4.10.0";
in
# CumulusCI declares requires-python >=3.11,<3.14, so it can't use the default
# interpreter. pkgs/default.nix passes a 3.13 set extended with the libraries
# under pkgs/python-packages.
python313Packages.buildPythonApplication {
  pname = "cumulusci";
  inherit version;
  pyproject = true;

  src = fetchFromGitHub {
    owner = "SFDO-Tooling";
    repo = "CumulusCI";
    tag = "v${version}";
    hash = "sha256-h55nZpXvu3QvTZSJTx5Or/7x8OcDivUc5h9If3jFABU=";
  };

  build-system = with python313Packages; [
    hatch-fancy-pypi-readme
    hatchling
  ];

  # nixpkgs carries newer majors than these upper bounds. The APIs CumulusCI
  # uses are unchanged in the versions available here.
  pythonRelaxDeps = [
    "docutils"
    "keyring"
    "robotframework-seleniumlibrary"
    "selenium"
  ];

  # Includes the `select` extra (annoy, numpy, pandas, scikit-learn), which
  # keeps cumulusci.tasks.bulkdata.select_utils on its optimized path; without
  # it the task warns and falls back to a slow one.
  dependencies = with python313Packages; [
    annoy
    click
    cryptography
    defusedxml
    docutils
    faker
    github3-py
    jinja2
    keyring
    lxml
    markupsafe
    numpy
    packaging
    pandas
    psutil
    pydantic
    pyjwt
    python-dateutil
    pytz
    pyyaml
    requests
    requests-futures
    rich
    robotframework
    robotframework-pabot
    robotframework-requests
    robotframework-seleniumlibrary
    rst2ansi
    salesforce-bulk
    sarge
    scikit-learn
    selenium
    simple-salesforce
    snowfakery
    # Upstream pins sqlalchemy<2 and still uses the 1.4 API.
    sqlalchemy_1_4
    xmltodict
  ];

  # The suite needs network access and a scratch Salesforce org.
  doCheck = false;

  pythonImportsCheck = [ "cumulusci" ];

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Build and release tools for Salesforce developers";
    homepage = "https://github.com/SFDO-Tooling/CumulusCI";
    license = licenses.bsd3;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "cci";
  };
}
