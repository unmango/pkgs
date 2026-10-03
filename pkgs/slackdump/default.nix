{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  mkUpdateDeps,
  nix-update-script,
}:
let
  version = "4.5.0";
  src = fetchFromGitHub {
    owner = "rusq";
    repo = "slackdump";
    rev = "v${version}";
    hash = "sha256-yRxaBbqVFZbDN6H8v8OPh/alE3+L8d6r4rO6ZHLxroM=";
  };
in
buildGoApplication {
  pname = "slackdump";
  inherit version src;

  modules = ./gomod2nix.toml;
  subPackages = [ "cmd/slackdump" ];

  ldflags = [
    "-w"
    "-s"
    "-X main.version=v${version}"
  ];

  passthru.update-deps = mkUpdateDeps src;
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Save or export your private and public Slack messages, threads, files, and users locally without admin privileges";
    homepage = "https://github.com/rusq/slackdump";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "slackdump";
  };
}
