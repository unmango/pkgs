{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  nix-update-script,
}:
let
  version = "1.4.2";
  src = fetchFromGitHub {
    owner = "patrickdappollonio";
    repo = "kubectl-slice";
    rev = "v${version}";
    hash = "sha256-C9YxMP9MCKJXh3wQ1JoilpzI3nIH3LnsTeVPMzri5h8=";
  };
in
buildGoApplication {
  pname = "kubectl-slice";
  inherit version src;

  modules = ./gomod2nix.toml;

  ldflags = [
    "-w"
    "-s"
    "-X github.com/patrickdappollonio/kubectl-slice/main.Version=${version}"
    "-extldflags -static"
  ];

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Split multiple Kubernetes files into smaller files with ease. Split multi-YAML files into individual files.";
    homepage = "https://github.com/patrickdappollonio/kubectl-slice";
    license = licenses.mit;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "kubectl-slice";
  };
}
