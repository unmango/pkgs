#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash git gawk
# shellcheck shell=bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
README="$root/README.md"

system=$(nix config show system)
table=$(nix eval --raw ".#legacyPackages.$system.packagesTable")
count=$(echo "$table" | grep -c '| `')
badge="[![packages](https://img.shields.io/badge/packages-${count}-blue)](#packages)"

badge="$badge" awk '
  /<!-- PACKAGE_COUNT:START -->/ { print; print ENVIRON["badge"]; skip=1; next }
  /<!-- PACKAGE_COUNT:END -->/ { skip=0 }
  !skip
' "$README" >"$README.tmp" && mv "$README.tmp" "$README"
