#!/usr/bin/env bash
# Prints the workspaces.json for an npm workspace checkout: each member's path,
# version, description, entry file, and which other members it depends on at runtime.
# Committed beside the lockfile because reading package.json out of the
# fetched source would be import-from-derivation.
#
#   ./workspaces.sh path/to/checkout > remark/workspaces.json
set -euo pipefail

root="${1:-.}"

jq -r '.workspaces[]' "$root/package.json" | while read -r path; do
  jq --arg path "${path%/}" '{
    (.name): {
      path: $path,
      version,
      description,
      entry: (.exports | if type == "object" then .["."] else . end | if type == "string" then ltrimstr("./") else null end),
      dependencies: (.dependencies // {} | keys)
    }
  }' "$root/$path/package.json"
done | jq -s 'add as $all | $all | map_values(.dependencies |= map(select($all[.])))'
