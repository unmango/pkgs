{
  buildGoApplication,
  coreutils,
  fetchFromGitHub,
  git,
  installShellFiles,
  kubectl,
  kubernetes-helm,
  lib,
  makeWrapper,
  mkUpdateDeps,
  nix-update-script,
  yamale,
  yamllint,
}:
let
  version = "1.8.1";
  src = fetchFromGitHub {
    owner = "helm";
    repo = "chart-releaser";
    rev = "v${version}";
    hash = "sha256-h1czHb/xK+kOEK4TJhMnwnLeVmQm52C8dTUy+fahJ90=";
  };
in
buildGoApplication {
  pname = "chart-releaser";
  inherit version src;

  modules = ./gomod2nix.toml;
  disableGoCache = true;

  postPatch = ''
    substituteInPlace pkg/config/config.go \
      --replace "\"/etc/cr\"," "\"$out/etc/cr\","
  '';

  ldflags = [
    "-w"
    "-s"
    "-X github.com/helm/chart-releaser/cr/cmd.Version=${version}"
    "-X github.com/helm/chart-releaser/cr/cmd.GitCommit=${src.rev}"
    "-X github.com/helm/chart-releaser/cr/cmd.BuildDate=19700101-00:00:00"
  ];

  nativeBuildInputs = [
    git
    installShellFiles
    makeWrapper
  ];

  postInstall = ''
    installShellCompletion --cmd cr \
      --bash <($out/bin/cr completion bash) \
      --zsh <($out/bin/cr completion zsh) \
      --fish <($out/bin/cr completion fish)

    wrapProgram $out/bin/cr --prefix PATH : ${
      lib.makeBinPath [
        coreutils
        git
        kubectl
        kubernetes-helm
        yamale
        yamllint
      ]
    }
  '';

  passthru.update-deps = mkUpdateDeps src;
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Hosting Helm Charts via GitHub Pages and Releases";
    homepage = "https://github.com/helm/chart-releaser";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "cr";
  };
}
