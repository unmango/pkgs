{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  autoPatchelfHook,
}:
let
  version = "0.7.6";

  # Closed-source Bun single-file executable, published as a per-platform zip
  # rather than to a git host, so there is nothing to build from source. Bump
  # `version` and all four hashes together; the current version is at
  # https://cli.coderabbit.ai/releases/latest/VERSION.
  hashes = {
    "x86_64-linux" = {
      platform = "linux-x64";
      hash = "sha256-hToXJ2CasP8fVoY/pt56zz3lk6bcG9f5GjLxHFck/8k=";
    };
    "aarch64-linux" = {
      platform = "linux-arm64";
      hash = "sha256-InBkGmMUvvDaMuWQPdxt5iZTVJYvfPZR/FgaSpHyJEc=";
    };
    "x86_64-darwin" = {
      platform = "darwin-x64";
      hash = "sha256-HGJC3sigmD/3CEK8HQ6MiI0akrGtgK+5acAMlMSCpwQ=";
    };
    "aarch64-darwin" = {
      platform = "darwin-arm64";
      hash = "sha256-+XDmCOODEU4e3yFO6nGpnWYE6h3QnAHnVO5rjUuFLLE=";
    };
  };

  inherit (stdenvNoCC.hostPlatform) system;

  release =
    hashes.${system}
      or (throw "coderabbit: no upstream release for ${system} (linux and darwin, x64 and arm64 only)");
in
stdenvNoCC.mkDerivation {
  pname = "coderabbit";
  inherit version;

  src = fetchurl {
    url = "https://cli.coderabbit.ai/releases/${version}/coderabbit-${release.platform}.zip";
    inherit (release) hash;
  };

  nativeBuildInputs = [
    unzip
  ]
  ++ lib.optional stdenvNoCC.hostPlatform.isLinux autoPatchelfHook;

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 coderabbit $out/bin/coderabbit
    # Upstream's installer drops the same alias next to the binary, and the
    # docs and the CLI's own help text both use it.
    ln -s coderabbit $out/bin/cr
    runHook postInstall
  '';

  # The binary phones home on `--version`, so there is no offline invocation
  # to check against.
  dontStrip = true;

  meta = {
    description = "CodeRabbit AI code review, in the terminal";
    homepage = "https://www.coderabbit.ai/cli";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ UnstoppableMango ];
    mainProgram = "coderabbit";
    platforms = lib.attrNames hashes;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
