{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  nix-update-script,
}:
let
  version = "1.4.22-ec5";
  src = fetchFromGitHub {
    owner = "openshift";
    repo = "installer";
    rev = "release-${version}";
    hash = "sha256-2jWuUPuIirN5HUBVnoNy5hZoYt29P/qUF3NX2okxGgI=";
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

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Install an OpenShift Cluster";
    homepage = "https://github.com/openshift/installer";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "openshift-install";
  };
}
