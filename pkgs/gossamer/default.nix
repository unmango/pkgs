{
  fetchFromGitHub,
  lib,
  nix-update-script,
  rustPlatform,
}:
let
  version = "0.24.1";
in
rustPlatform.buildRustPackage {
  pname = "gossamer";
  inherit version;

  src = fetchFromGitHub {
    owner = "danpozmanter";
    repo = "gossamer";
    rev = "v${version}";
    hash = "sha256-z82aKkd3SRsxndyyHyuB2K1dCAqF5N9oq2q8qBEr7vI=";
  };

  cargoHash = "sha256-33jSqzJLib7Irh8dXFZcYMr269YwDdwc6Ykhc7K9N0s=";

  # build.rs for gossamer-cli spawns a nested `cargo build -p gossamer-runtime`
  # to produce the staticlib. In Nix's sandbox the nested invocation succeeds
  # but produces no file (vendor/env mismatch in subprocess). Pre-building here
  # so the file exists at the expected path when build.rs tries to copy it.
  preBuild = ''
    cargo build -p gossamer-runtime \
      --target-dir target/runtime-staticlib \
      --release \
      --offline
  '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "The Gossamer programming language compiler";
    homepage = "https://github.com/danpozmanter/gossamer";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "gos";
  };
}
