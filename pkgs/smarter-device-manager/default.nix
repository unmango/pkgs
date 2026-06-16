{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  makeWrapper,
  mkUpdateDeps,
  nix-update-script,
}:
let
  pname = "smarter-device-manager";
  # TODO: pin to commit once fork is set up with go.mod fix
  version = "1.20.12";
  src = fetchFromGitHub {
    owner = "UnstoppableMango";
    repo = pname;
    rev = "main";
    hash = lib.fakeHash;
  };
in
buildGoApplication {
  inherit pname version src;

  modules = ./gomod2nix.toml;
  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    install -Dm644 conf.yaml $out/share/${pname}/conf.yaml
    wrapProgram $out/bin/smarter-device-management \
      --add-flags "-config $out/share/${pname}/conf.yaml"
  '';

  passthru.update-deps = mkUpdateDeps src;
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Kubernetes device plugin for exposing host devices to containers";
    homepage = "https://github.com/smarter-project/smarter-device-manager";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "smarter-device-management";
    platforms = platforms.linux;
    # Fork not yet tagged; remove once UnstoppableMango/smarter-device-manager has go.mod fix
    broken = true;
  };
}
