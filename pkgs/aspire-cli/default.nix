{
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
  gcc,
  lib,
  nix-update-script,
}:
let
  dotnet = dotnetCorePackages.sdk_10_0_1xx;
in
# TODO: System.Resources.MissingManifestResourceException: Could not find the resource "Aspire.Cli.Resources.NewCommandStrings.resources" among the resources "Aspire.Cli.Resources.dotnet-install.sh", "Aspire.Cli.Resources.dotnet-install.ps1" embedded in the assembly "aspire", nor among the resources in any satellite assemblies for the specified culture. Perhaps the resources were embedded with an incorrect name.
buildDotnetModule {
  pname = "aspire-cli";
  version = "13.0.2";

  nativeBuildInputs = [ gcc ];

  src = fetchFromGitHub {
    owner = "dotnet";
    repo = "aspire";
    rev = "v13.0.2";
    hash = "sha256-mCDAwg2+yq3D108lHLxXXYCEWs3yMUitKRImjOfTrDU=";
  };

  dotnet-sdk = dotnet;
  projectFile = "./src/Aspire.Cli/Aspire.Cli.csproj";
  nugetDeps = ./deps.json;
  selfContainedBuild = true;

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "A CLI tool for managing Aspire projects";
    homepage = "https://github.com/dotnet/aspire";
    maintainers = with maintainers; [ UnstoppableMango ];
    license = licenses.mit;
    mainProgram = "aspire";
  };
}
