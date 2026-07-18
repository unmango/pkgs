{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  mkUpdateDeps,
  nix-update-script,
}:
let
  version = "0.0.0-unstable-2026-06-29";
  src = fetchFromGitHub {
    owner = "openshift";
    repo = "oc-mirror";
    rev = "c3552e2d3df5dcc4eb939b6bcbb6541e5f26eed6";
    hash = "sha256-Bo2YjApjG9OcQfI6jFgTM8/fmh2jpiyIP9cmXIMqjQo=";
  };
  versionPkg = "github.com/openshift/oc-mirror/v2/internal/pkg/version";
in
buildGoApplication {
  pname = "oc-mirror";
  inherit version src;

  modules = ./gomod2nix.toml;
  disableGoCache = true;
  subPackages = [ "cmd/oc-mirror" ];

  # CGO_ENABLED=0 selects the pure-Go btrfs/devicemapper/openpgp stubs
  CGO_ENABLED = 0;
  # gomod2nix hook: space-joined list → word-split per tag; comma-sep string → single -tags=... flag
  tags = "json1,exclude_graphdriver_devicemapper,exclude_graphdriver_btrfs,containers_image_openpgp";

  ldflags = [
    "-w"
    "-s"
    "-X ${versionPkg}.versionFromGit=${version}"
    "-X ${versionPkg}.commitFromGit=${src.rev}"
    "-X ${versionPkg}.gitTreeState=clean"
    "-X ${versionPkg}.buildDate=1970-01-01T00:00:00Z"
    "-X ${versionPkg}.majorFromGit=0"
  ];

  doCheck = false;

  passthru.update-deps = mkUpdateDeps src;
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Lifecycle manager for internet-disconnected OpenShift environments";
    homepage = "https://github.com/openshift/oc-mirror";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "oc-mirror";
  };
}
