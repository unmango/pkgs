{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  nix-update-script,
  setuptools,
  six,
}:
buildPythonPackage rec {
  pname = "gvgen";
  version = "1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "stricaud";
    repo = "gvgen";
    tag = "v${version}";
    hash = "sha256-7/lOOryZEJ1W+7hQWGqPRuTdalIbviVz2lEABjywrlg=";
  };

  build-system = [ setuptools ];

  # Undeclared in setup.py; gvgen.py imports six at module level.
  dependencies = [ six ];

  pythonImportsCheck = [ "gvgen" ];

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Python class to generate dot files for graphviz";
    homepage = "https://github.com/stricaud/gvgen";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ UnstoppableMango ];
  };
}
