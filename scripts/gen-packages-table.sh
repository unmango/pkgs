#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash git gawk
# shellcheck shell=bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
README="$root/README.md"

system=$(nix config show system)
table=$(nix eval --raw ".#legacyPackages.$system.packagesTable")

table="$table" awk '
  /<!-- PACKAGES:START -->/ { print; print ENVIRON["table"]; skip=1; next }
  /<!-- PACKAGES:END -->/ { skip=0 }
  !skip
' "$README" >"$README.tmp" && mv "$README.tmp" "$README"
