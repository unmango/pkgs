{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  mkUpdateDeps,
  nix-update-script,
}:
let
  version = "3.107.3";
  src = fetchFromGitHub {
    owner = "pulumi";
    repo = "pulumi-dotnet";
    tag = "v${version}";
    hash = "sha256-HzdQVmIafCn3n2Ia5k89CRz2SYMItOfGlKNPQsizLxg=";
  };
in
buildGoApplication {
  pname = "pulumi-dotnet";
  inherit version src;
  # go.mod lives in a nested module, not at the repo root: pwd drives vendoring/dep
  # resolution, modRoot tells the build hook where to cd for the actual go build.
  pwd = src + "/pulumi-language-dotnet";
  modules = ./gomod2nix.toml;
  modRoot = "pulumi-language-dotnet";
  subPackages = [ "." ];

  # Matches nixpkgs' pulumi-go, which skips TestLanguage as sandbox-incompatible.
  doCheck = false;

  passthru.update-deps = mkUpdateDeps "${src}/pulumi-language-dotnet";
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Pulumi language host for .NET programs";
    homepage = "https://github.com/pulumi/pulumi-dotnet";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "pulumi-language-dotnet";
  };
}
