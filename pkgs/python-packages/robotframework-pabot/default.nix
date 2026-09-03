{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  nix-update-script,
  robotframework,
  setuptools,
}:
buildPythonPackage rec {
  pname = "robotframework-pabot";
  version = "5.2.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "mkorpela";
    repo = "pabot";
    tag = version;
    hash = "sha256-wVr0eOUvzw+nBRp1EUlXcy3pob8CbwYHSDhwjwwVD74=";
  };

  build-system = [ setuptools ];

  dependencies = [ robotframework ];

  # The suite drives real Robot Framework runs against fixture projects.
  doCheck = false;

  pythonImportsCheck = [ "pabot" ];

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Parallel test runner for Robot Framework";
    homepage = "https://pabot.org";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "pabot";
  };
}
