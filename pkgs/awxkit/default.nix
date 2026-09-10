{
  lib,
  fetchFromGitHub,
  nix-update-script,
  python3Packages,
}:
let
  version = "24.6.1";
in
python3Packages.buildPythonApplication {
  pname = "awxkit";
  inherit version;
  pyproject = true;

  src = fetchFromGitHub {
    owner = "ansible";
    repo = "awx";
    tag = version;
    hash = "sha256-ByDB3OhUvGPyRQUtMfkQUbSiAeGAli3zyaBtNlNILt4=";
  };

  sourceRoot = "source/awxkit";

  postPatch = ''
    # No VERSION file in the repo; setup.py falls back to setuptools_scm which requires git
    echo "${version}" > VERSION

    # pkg_resources is deprecated since setuptools 67 and emits a noisy warning on import
    substituteInPlace awxkit/cli/client.py \
      --replace-fail \
        'import pkg_resources' \
        'import importlib.metadata' \
      --replace-fail \
        "pkg_resources.get_distribution('awxkit').version" \
        "importlib.metadata.version('awxkit')"

    # HelpfulArgumentParser._parse_known_args overrides a private argparse method that
    # gained an `intermixed` parameter in Python 3.12 (bpo-9694), breaking the old 2-arg signature
    substituteInPlace awxkit/cli/utils.py \
      --replace-fail \
        'def _parse_known_args(self, args, ns):' \
        'def _parse_known_args(self, args, ns, intermixed=False):' \
      --replace-fail \
        'return super(HelpfulArgumentParser, self)._parse_known_args(args, ns)' \
        'return super(HelpfulArgumentParser, self)._parse_known_args(args, ns, intermixed)'
  '';

  build-system = with python3Packages; [
    setuptools
  ];

  dependencies = with python3Packages; [
    cryptography
    jq
    pyyaml
    requests
    setuptools
    websocket-client
  ];

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Official command line interface for Ansible AWX";
    homepage = "https://github.com/ansible/awx";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "awx";
  };
}
