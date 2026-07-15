{
  buildGoApplication,
  fetchFromGitHub,
  lib,
  mkUpdateDeps,
  nix-update-script,
}:
let
  version = "3.252.0";
  src = fetchFromGitHub {
    owner = "pulumi";
    repo = "pulumi";
    tag = "v${version}";
    hash = "sha256-jJC317Nnc0vF1bSlPx1GXNBid6fmXHY2lzfUqvMlRq4=";
  };
in
buildGoApplication {
  pname = "pulumi-bun";
  inherit version src;
  # go.mod lives in a nested module, not at the repo root: pwd drives vendoring/dep
  # resolution, modRoot tells the build hook where to cd for the actual go build.
  pwd = src + "/sdk/nodejs/cmd/pulumi-language-bun";
  modules = ./gomod2nix.toml;
  modRoot = "sdk/nodejs/cmd/pulumi-language-bun";
  subPackages = [ "." ];

  # Matches nixpkgs' pulumi-go, which skips TestLanguage as sandbox-incompatible.
  doCheck = false;

  passthru.update-deps = mkUpdateDeps "${src}/sdk/nodejs/cmd/pulumi-language-bun";
  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Pulumi language host for Bun programs";
    homepage = "https://github.com/pulumi/pulumi";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "pulumi-language-bun";
  };
}
