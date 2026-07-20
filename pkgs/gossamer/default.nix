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

  # Teach build.rs to use a pre-built libgossamer_runtime.a when GOS_RUNTIME_LIB
  # is set, instead of spawning a nested cargo build. This is needed for the JIT
  # tests: they create a runner project in a tmpdir whose build.rs otherwise
  # cannot produce the staticlib (sandbox prevents the nested cargo invocation
  # from finding the vendor directory).
  patches = [ ./gos-runtime-lib-env.patch ];

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

  # JIT tests spawn a runner (a cargo project in a tmpdir) whose build.rs also
  # tries to build gossamer-runtime. Point it at the release staticlib already
  # built in preBuild; the patched build.rs copies it into place without
  # invoking cargo again.
  preCheck = ''
    export GOS_RUNTIME_LIB="$PWD/target/runtime-staticlib/release/libgossamer_runtime.a"
  '';

  nativeBuildInputs = [ makeWrapper ];

  # Tests invoke `gos build` which shells out to `opt`/`llc` at runtime.
  nativeCheckInputs = [ llvmPackages_18.llvm ];

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
