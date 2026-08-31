{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  mkUpdateDeps,
  nix-update-script,
}:
let
  version = "1.36.2";
  src = fetchFromGitHub {
    owner = "pulumi";
    repo = "pulumi-java";
    tag = "v${version}";
    hash = "sha256-VHk2dGNAU9SxNDoiqD3NESmjKuDKYyHRJYGLGf4YxQw=";
  };
in
buildGoApplication {
  pname = "pulumi-java";
  inherit version src;
  modules = ./gomod2nix.toml;
  subPackages = [ "pkg/cmd/pulumi-language-java" ];

  # TestLanguage needs sibling dirs outside the fetched module (../../../pulumi/proto), unavailable in the sandbox.
  doCheck = false;

  passthru.update-deps = mkUpdateDeps src;
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Pulumi language host for Java programs";
    homepage = "https://github.com/pulumi/pulumi-java";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "pulumi-language-java";
  };
}
