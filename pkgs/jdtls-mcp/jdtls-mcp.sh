#!/bin/sh
# Mirrors upstream's scripts/start-mcp-server.sh, adapted for the release
# archive's fixed layout inside the nix store (plugins/ and configuration/
# live directly under the product dir).
set -eu

PROD_DIR="@out@/opt/jdtls-mcp"
if [ ! -d "$PROD_DIR/plugins" ]; then
  # The macOS release archive nests the product inside an app bundle.
  PROD_DIR="$PROD_DIR/Eclipse.app/Contents/Eclipse"
fi

LAUNCHER=$(ls "$PROD_DIR"/plugins/org.eclipse.equinox.launcher_*.jar | head -1)

WORKSPACE="${1:-$PWD}"
WORKSPACE=$(cd "$WORKSPACE" && pwd)

# Equinox takes an exclusive lock on the `-data` area, so two servers started
# against different workspaces must not land on the same default. Key the
# default on the canonical workspace path; an explicit second argument still
# wins.
if [ "$#" -ge 2 ]; then
  DATA_DIR="$2"
else
  workspace_id=$(printf '%s' "$WORKSPACE" | cksum | cut -d' ' -f1)
  DATA_DIR="${TMPDIR:-/tmp}/jdtls-mcp-data-$workspace_id"
fi

mkdir -p "$DATA_DIR"

# Equinox needs a writable configuration area (it drops lock files/logs
# there), but the one shipped in the product dir lives in the read-only nix
# store, so mirror it into DATA_DIR on first run.
CONFIG_DIR="$DATA_DIR/configuration"
if [ ! -d "$CONFIG_DIR" ]; then
  cp -r "$PROD_DIR/configuration" "$CONFIG_DIR"
  chmod -R u+w "$CONFIG_DIR"
fi

exec @jdk@/bin/java \
  -Declipse.application=org.eclipse.jdt.ls.mcp.app \
  -Dosgi.bundles.defaultStartLevel=4 \
  -Djdtls.workspace.root="$WORKSPACE" \
  -jar "$LAUNCHER" \
  -configuration "$CONFIG_DIR" \
  -data "$DATA_DIR"
