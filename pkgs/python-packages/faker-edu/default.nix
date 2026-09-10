{
  lib,
  buildPythonPackage,
  faker,
  fetchFromGitHub,
  nix-update-script,
  setuptools,
}:
buildPythonPackage rec {
  pname = "faker-edu";
  version = "1.1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "SFDO-Community-Sprints";
    repo = "Snowfakery-Edu";
    tag = "v${version}";
    hash = "sha256-kLTIycnEHNikPU/zc7P+iKUJs7x9h7WvhPfIWBblwzE=";
  };

  build-system = [ setuptools ];

  dependencies = [ faker ];

  pythonImportsCheck = [ "faker_edu" ];

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Faker provider for education-related fake data";
    homepage = "https://github.com/SFDO-Community-Sprints/Snowfakery-Edu";
    license = licenses.bsd3;
    maintainers = with maintainers; [ UnstoppableMango ];
  };
}
