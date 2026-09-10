{
  lib,
  buildPythonPackage,
  click,
  faker,
  faker-edu,
  faker-nonprofit,
  fetchFromGitHub,
  gvgen,
  hatchling,
  jinja2,
  nix-update-script,
  packaging,
  pydantic,
  python-baseconv,
  python-dateutil,
  pyyaml,
  requests,
  setuptools,
  sqlalchemy_1_4,
}:
buildPythonPackage rec {
  pname = "snowfakery";
  version = "4.2.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "SFDO-Tooling";
    repo = "Snowfakery";
    tag = "v${version}";
    hash = "sha256-XSFbWhAVa3rxhyROu17x/hnaSEYqsJZRHqBnKFNQkYk=";
  };

  postPatch = ''
    # pkg_resources was removed in setuptools 81; parse_version has always been
    # a re-export of packaging's.
    substituteInPlace snowfakery/utils/versions.py \
      --replace-fail \
        'import pkg_resources' \
        'from packaging.version import parse as _parse_version' \
      --replace-fail \
        'pkg_resources.parse_version' \
        '_parse_version'
  '';

  build-system = [ hatchling ];

  dependencies = [
    click
    faker
    faker-edu
    faker-nonprofit
    gvgen
    jinja2
    packaging
    pydantic
    python-baseconv
    python-dateutil
    pyyaml
    requests
    setuptools
    # Upstream allows sqlalchemy<3, but CumulusCI pins <2 and the two majors
    # cannot coexist on one PYTHONPATH.
    sqlalchemy_1_4
  ];

  # The suite is snapshot-based and expects a checkout-relative cwd.
  doCheck = false;

  pythonImportsCheck = [ "snowfakery" ];

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Tool for generating fake data that has relations between tables";
    homepage = "https://github.com/SFDO-Tooling/Snowfakery";
    license = licenses.bsd3;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "snowfakery";
  };
}
