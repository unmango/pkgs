{
  callPackage,
  fetchFromGitHub,
  lib,
  llvmPackages_18,
  makeWrapper,
  nix-update-script,
  rustPlatform,
}:
let
  version = "0.58.3";
in
rustPlatform.buildRustPackage {
  pname = "gossamer";
  inherit version;

  src = fetchFromGitHub {
    owner = "danpozmanter";
    repo = "gossamer";
    rev = "v${version}";
    hash = "sha256-YaL85rTDOUpa57xX2gHe6XGViYPuoqYb+rndY6MM/kk=";
  };

  cargoHash = "sha256-Q7uqtQiuN4jE15KzpF5DjerAkHYbjERI2VjsCNGOW1M=";

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

  nativeBuildInputs = [ makeWrapper ];

  # Tests invoke `gos build` which requires LLVM opt at runtime.
  doCheck = false;

  # `gos build` shells out to `opt`/`llc` at runtime, not just build time.
  postInstall = ''
    wrapProgram $out/bin/gos --prefix PATH : ${lib.makeBinPath [ llvmPackages_18.llvm ]}
  '';

  passthru.updateScript = nix-update-script { };
  passthru.editorSupport = callPackage ./editor-support.nix { };

  meta = with lib; {
    description = "The Gossamer programming language compiler";
    homepage = "https://github.com/danpozmanter/gossamer";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "gos";
  };
}
