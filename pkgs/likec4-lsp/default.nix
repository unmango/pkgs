{
  lib,
  buildNpmPackage,
  coreutils,
  fetchzip,
  jq,
  nix-update-script,
}:
let
  version = "1.60.0";
in
buildNpmPackage {
  pname = "likec4-lsp";
  inherit version;

  # Same shape as likec4: devDependencies name pnpm workspace packages that
  # aren't on the public registry, and dist/ ships prebuilt. Stripping them at
  # fetch time lets `nix-update --generate-lockfile` regenerate
  # package-lock.json from the unpacked source.
  src = fetchzip {
    url = "https://registry.npmjs.org/@likec4/lsp/-/lsp-${version}.tgz";
    hash = "sha256-LzM912o5Ppsywbm6/Sc2eZcfASmw1LlI8Rde6A2UsH8=";
    nativeBuildInputs = [ jq ];
    postFetch = ''
      jq 'del(.devDependencies)' "$out/package.json" > "$out/package.json.tmp"
      mv "$out/package.json.tmp" "$out/package.json"
    '';
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-LYXqrdMP9uWiBiBemfhFJWccu7ef49zlaA7eAqejdSA=";

  dontNpmBuild = true;

  nativeInstallCheckInputs = [
    coreutils
    jq
  ];

  doInstallCheck = true;

  # A server that loads but can't speak the protocol would pass a --help check,
  # so this sends a real initialize request over stdio and expects capabilities
  # back. The sleep holds stdin open so the server never sees EOF before it
  # replies; timeout ends both once the reply has been read or the wait is up.
  installCheckPhase = ''
    runHook preInstallCheck

    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"

    body='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":null,"rootUri":null,"capabilities":{}}}'

    { printf 'Content-Length: %d\r\n\r\n%s' "''${#body}" "$body"; sleep 30; } \
      | timeout 30 "$out/bin/likec4-lsp" --stdio >"$TMPDIR/reply" 2>"$TMPDIR/stderr" &

    for _ in $(seq 1 30); do
      grep -q '"capabilities"' "$TMPDIR/reply" 2>/dev/null && break
      sleep 1
    done

    if ! grep -q '"capabilities"' "$TMPDIR/reply"; then
      echo "likec4-lsp: no initialize reply" >&2
      cat "$TMPDIR/stderr" >&2
      exit 1
    fi

    # The reply's body follows the header's blank line.
    sed -n 's/^.*\r$//; /^{/p' "$TMPDIR/reply" | head -n1 \
      | jq -e '.id == 1 and (.result.capabilities | has("completionProvider"))' >/dev/null

    runHook postInstallCheck
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--generate-lockfile" ];
  };

  meta = with lib; {
    description = "Standalone LikeC4 language server for editor integrations";
    homepage = "https://likec4.dev/tooling/editors/";
    license = licenses.mit;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "likec4-lsp";
  };
}
