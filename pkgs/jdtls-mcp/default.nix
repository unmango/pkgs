{
  lib,
  stdenv,
  fetchurl,
  jdk,
  nix-update-script,
}:
let
  version = "1.0.1";

  sources = {
    x86_64-linux = {
      url = "https://github.com/sunix/jdtls-mcp/releases/download/v${version}/jdtls-mcp-v${version}-linux-x86_64.tar.gz";
      hash = lib.fakeHash;
    };
    aarch64-linux = {
      url = "https://github.com/sunix/jdtls-mcp/releases/download/v${version}/jdtls-mcp-v${version}-linux-aarch64.tar.gz";
      hash = lib.fakeHash;
    };
    aarch64-darwin = {
      url = "https://github.com/sunix/jdtls-mcp/releases/download/v${version}/jdtls-mcp-v${version}-macos-aarch64.tar.gz";
      hash = "sha256-ZoHFvdQxE8JYSdEyMHTEP9MD7Q+WcdhU3qfhmFCzxtE=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "jdtls-mcp: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "jdtls-mcp";
  inherit version;

  src = fetchurl { inherit (source) url hash; };

  sourceRoot = "jdtls-mcp";

  dontBuild = true;

  # The archive's native `eclipse`/`Eclipse.app` launcher is just a
  # convenience wrapper around `java -jar <equinox-launcher>.jar`; upstream's
  # own scripts/start-mcp-server.sh (bundled in the archive) launches it that
  # way to avoid needing a display. Doing the same here sidesteps native
  # linking (autoPatchelf/GTK) entirely and works identically on every
  # platform.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt
    cp -r . $out/opt/jdtls-mcp

    install -Dm755 ${./jdtls-mcp.sh} $out/bin/jdtls-mcp
    substituteInPlace $out/bin/jdtls-mcp \
      --replace-fail '@out@' "$out" \
      --replace-fail '@jdk@' "${jdk}"

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Model Context Protocol (MCP) server embedding Eclipse JDT Language Server via OSGi";
    homepage = "https://github.com/sunix/jdtls-mcp";
    license = licenses.epl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "jdtls-mcp";
    platforms = builtins.attrNames sources;
  };
}
