# What an editor or a devShell needs from likec4, pinned to one likec4:
#
#   bin/likec4                     the CLI, which also serves `likec4 mcp`
#   bin/likec4-lsp                 `likec4 lsp`, under the name editor configs expect
#   share/likec4/schema.json       the likec4.config.json schema
#   share/likec4/skills/likec4-dsl the agent skill likec4 ships
#
# likec4-lsp wraps the CLI's own server rather than the standalone @likec4/lsp
# package, so the two can never be on different versions. It takes the same
# --stdio, --node-ipc, --socket and --pipe transports.
{
  coreutils,
  jq,
  likec4,
  makeWrapper,
  runCommand,
}:
let
  pkg = "${likec4}/lib/node_modules/likec4";
in
runCommand "likec4-env-${likec4.version}"
  {
    nativeBuildInputs = [
      coreutils
      jq
      makeWrapper
    ];

    meta = likec4.meta // {
      description = "LikeC4 CLI, language server, config schema and agent skill";
    };
  }
  ''
    mkdir -p $out/bin $out/share/likec4/skills
    ln -s ${likec4}/bin/likec4 $out/bin/likec4
    makeWrapper ${likec4}/bin/likec4 $out/bin/likec4-lsp --add-flags lsp

    # Checked right after linking, so a release that moves either one fails
    # here rather than leaving a dangling link.
    ln -s ${pkg}/config/schema.json $out/share/likec4/schema.json
    ln -s ${pkg}/skills/likec4-dsl $out/share/likec4/skills/likec4-dsl
    jq -e '."$defs".LikeC4ProjectConfig' $out/share/likec4/schema.json >/dev/null
    test -f $out/share/likec4/skills/likec4-dsl/SKILL.md

    # Same check as likec4-lsp's install check: a real initialize over stdio.
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"

    body='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":null,"rootUri":null,"capabilities":{}}}'

    coproc lsp { exec timeout 60 $out/bin/likec4-lsp --stdio >"$TMPDIR/reply" 2>"$TMPDIR/stderr"; }
    server=$lsp_PID
    printf 'Content-Length: %d\r\n\r\n%s' "''${#body}" "$body" >&"''${lsp[1]}"

    # The reply's body follows the header's blank line.
    initialized() {
      sed -n 's/^.*\r$//; /^{/p' "$TMPDIR/reply" | head -n1 \
        | jq -e '.id == 1 and (.result.capabilities | has("completionProvider"))' >/dev/null 2>&1
    }

    ok=
    for _ in $(seq 1 30); do
      if initialized; then
        ok=1
        break
      fi
      sleep 1
    done

    kill "$server" 2>/dev/null || true
    wait "$server" 2>/dev/null || true

    if [ -z "$ok" ]; then
      echo "likec4-env: no valid initialize reply from likec4-lsp" >&2
      cat "$TMPDIR/reply" "$TMPDIR/stderr" >&2
      exit 1
    fi
  ''
