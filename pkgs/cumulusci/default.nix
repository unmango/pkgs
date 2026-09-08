{
  lib,
  fetchFromGitHub,
  fetchPypi,
  nix-update-script,
  python313Packages,
}:
let
  version = "4.10.1";

  # rst2ansi (last released 2018) imports docutils.utils.error_reporting,
  # which was removed in docutils 0.21. Pin a standalone docutils to the last
  # release that still carries it, scoped to just this package's closure
  # (rather than overriding the whole python313Packages set, which forces a
  # rebuild-from-source of everything that transitively depends on docutils,
  # e.g. sphinx, and its flaky sandboxed test suite).
  docutilsOld = python313Packages.docutils.overridePythonAttrs (old: rec {
    version = "0.20.1";
    src = fetchPypi {
      pname = "docutils";
      inherit version;
      hash = "sha256-8IpOJ2w6FYOobc4+NKuj/gTQK7ot1R7RYQYkToqSPjs=";
    };
    # 0.20.1 predates the flit-core packaging used since 0.21.
    build-system = [ python313Packages.setuptools ];
  });

  rst2ansiOld = python313Packages.rst2ansi.override { docutils = docutilsOld; };
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
    hash = "sha256-uaf/UG2LKXubRa7J+HcRHgPiPDdNTLCtm3tsNiZigMM=";
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
  #
  # docutils and rst2ansi come from docutilsOld/rst2ansiOld above, not
  # python313Packages, so only one docutils version ends up in the closure.
  dependencies = with python313Packages; [
    annoy
    click
    cryptography
    defusedxml
    docutilsOld
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
    rst2ansiOld
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
