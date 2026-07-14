#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

system=$(nix config show system)

nix eval --json ".#packages.$system" --apply \
  'pkgs: builtins.concatMap (n: let p = pkgs.${n}; in [ n ] ++ (if p ? image then [ "${n}.image" ] else [ ])) (builtins.attrNames pkgs)' |
  jq -r '.[]'
