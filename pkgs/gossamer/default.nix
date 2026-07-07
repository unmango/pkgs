{
  fetchFromGitHub,
  lib,
  nix-update-script,
  rustPlatform,
}:
let
  version = "0.24.1";

  src = fetchFromGitHub {
    owner = "danpozmanter";
    repo = "gossamer";
    rev = "v${version}";
    hash = "sha256-z82aKkd3SRsxndyyHyuB2K1dCAqF5N9oq2q8qBEr7vI=";
  };

  cargoHash = "sha256-33jSqzJLib7Irh8dXFZcYMr269YwDdwc6Ykhc7K9N0s=";

  # gossamer-cli's build.rs spawns a nested `cargo build -p gossamer-runtime`
  # to produce libgossamer_runtime.a, but the nested invocation succeeds with
  # no output in Nix's sandbox (vendor/env mismatch in subprocess). Build the
  # staticlib as a separate derivation so it can be pre-placed at the path
  # build.rs expects before the copy step runs.
  gossamer-runtime = rustPlatform.buildRustPackage {
    pname = "gossamer-runtime";
    inherit version src cargoHash;

    cargoBuildFlags = [
      "-p"
      "gossamer-runtime"
    ];

    installPhase = ''
      runHook preInstall
      install -Dm644 target/release/libgossamer_runtime.a $out/lib/libgossamer_runtime.a
      runHook postInstall
    '';

    doCheck = false;
  };
in
rustPlatform.buildRustPackage {
  pname = "gossamer";
  inherit version src cargoHash;

  # Tests invoke `gos build` which requires LLVM opt at runtime.
  doCheck = false;

  # build.rs copies from target/runtime-staticlib/release/ into target/release/.
  # Place the pre-built staticlib there so the copy succeeds when the nested
  # cargo invocation produces no output.
  preBuild = ''
    mkdir -p target/runtime-staticlib/release
    cp ${gossamer-runtime}/lib/libgossamer_runtime.a target/runtime-staticlib/release/
  '';

  passthru = {
    updateScript = nix-update-script { };
    runtime = gossamer-runtime;
  };

  meta = with lib; {
    description = "The Gossamer programming language compiler";
    homepage = "https://github.com/danpozmanter/gossamer";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "gos";
  };
}
