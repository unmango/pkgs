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
  /\[!\[packages\]\(https:\/\/img\.shields\.io\/badge\/packages-/ { print ENVIRON["badge"]; next }
  { print }
' "$README" >"$README.tmp" && mv "$README.tmp" "$README"
