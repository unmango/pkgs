{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  mkUpdateDeps,
  nix-update-script,
}:
let
  version = "1.4.22-ec5";
  src = fetchFromGitHub {
    owner = "openshift";
    repo = "installer";
    rev = "v${version}";
    hash = "sha256-a6jTIaRzUjSfvCiKlr2d0nvm9cvDK8713McFwts9ZfE=";
  };
in
buildGoApplication {
  pname = "openshift-installer";
  inherit version src;

  modules = ./gomod2nix.toml;
  subPackages = [ "cmd/openshift-install" ];

  ldflags = [
    "-w"
    "-s"
    "-X github.com/openshift/installer/pkg/version.Raw=${version}"
    "-X github.com/openshift/installer/pkg/version.Commit=${src.rev}"
    "-X github.com/openshift/installer/pkg/version.defaultArch=amd64"
  ];

  # TODO
  doCheck = false;

  passthru.update-deps = mkUpdateDeps src;
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Install an OpenShift Cluster";
    homepage = "https://github.com/openshift/installer";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "openshift-install";
  };
}
