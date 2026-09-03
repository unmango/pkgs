{
  lib,
  buildPythonPackage,
  faker,
  fetchFromGitHub,
  nix-update-script,
  setuptools,
}:
buildPythonPackage rec {
  pname = "faker-nonprofit";
  version = "1.0.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "SFDO-Community-Sprints";
    repo = "Snowfakery-Nonprofit";
    tag = "v${version}";
    hash = "sha256-oORbq5FQCz40IB1wCQ0R8hSfWxhVkVUIAjNQimb3BGU=";
  };

  build-system = [ setuptools ];

  dependencies = [ faker ];

  pythonImportsCheck = [ "faker_nonprofit" ];

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Faker provider for nonprofit-related fake data";
    homepage = "https://github.com/SFDO-Community-Sprints/Snowfakery-Nonprofit";
    license = licenses.bsd3;
    maintainers = with maintainers; [ UnstoppableMango ];
  };
}
