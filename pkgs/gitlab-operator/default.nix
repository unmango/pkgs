{
  buildGoModule,
  fetchFromGitLab,
  lib,
  nix-update-script,
}:
let
  version = "3.3.1";
  src = fetchFromGitLab {
    group = "gitlab-org";
    owner = "cloud-native";
    repo = "gitlab-operator";
    rev = version;
    hash = "sha256-2RsbONhdnU7uJfoLnHt0pLZLMTuGvaufHRPncHQNf/I=";
  };
in
# buildGoModule rather than buildGoApplication: helm v4 resolves the Kubernetes
# version from `debug.ReadBuildInfo().Deps` at package init, and the gomod2nix
# vendor tree has no `vendor/modules.txt`, so the dependency list is empty and
# the manager panics on start.
buildGoModule {
  pname = "gitlab-operator";
  inherit version src;

  vendorHash = "sha256-7tHv9+7GRWnhDwSR+yl3bRihfwBOUqWyrzc5IHWbUYw=";
  subPackages = [ "cmd/manager" ];

  # Upstream builds the manager statically for the ubi-micro runtime image.
  env.CGO_ENABLED = 0;

  # The test suite requires KUBEBUILDER_ASSETS from setup-envtest, which
  # downloads Kubernetes control-plane binaries at test time.
  doCheck = false;

  ldflags = [
    "-s"
    "-w"
  ];

  postInstall = ''
    mkdir -p $out/share/gitlab-operator/crds
    cp ${src}/config/crd/bases/*.yaml $out/share/gitlab-operator/crds/
  '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Kubernetes Operator for managing the lifecycle of GitLab instances";
    homepage = "https://gitlab.com/gitlab-org/cloud-native/gitlab-operator";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "manager";
  };
}
