{
  buildGoApplication,
  fetchFromGitLab,
  lib,
  mkUpdateDeps,
  nix-update-script,
}:
let
  version = "0.2.2";
  src = fetchFromGitLab {
    group = "gitlab-org";
    owner = "cloud-native";
    repo = "operator";
    rev = "v${version}";
    hash = "sha256-uEXDT/ZZH2uodi6NkAhLlCEwaFQzhX9eXHnsPOHnOKw=";
  };
in
buildGoApplication {
  pname = "gitlab-operator-v2";
  inherit version src;

  modules = ./gomod2nix.toml;
  subPackages = [ "cmd/manager" ];

  # The test suite requires KUBEBUILDER_ASSETS from setup-envtest, which
  # downloads Kubernetes control-plane binaries at test time.
  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=v${version}"
  ];

  postInstall = ''
    mkdir -p $out/share/gitlab-operator-v2/crds
    cp ${src}/config/crd/bases/*.yaml $out/share/gitlab-operator-v2/crds/
  '';

  passthru.update-deps = mkUpdateDeps src;
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Kubernetes Operator for managing the lifecycle of GitLab instances (experimental V2 rewrite)";
    homepage = "https://gitlab.com/gitlab-org/cloud-native/operator";
    license = licenses.mit;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "manager";
  };
}
