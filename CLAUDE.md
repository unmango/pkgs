# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
nix develop          # enter dev shell (or use direnv)
make                 # build all packages
make check           # nix flake check (lint + eval)
make fmt             # format (nixfmt, prettier, shfmt, statix, deadnix)
make generate        # regenerate README package table and badge
nix build .#<name>   # build a single package
```

After changing `go.mod` in any Go package, run `make deps` (or `nix run .#<name>.update-deps pkgs/<name>/gomod2nix.toml` for a single package) to regenerate `gomod2nix.toml`.

## Architecture

`flake-parts`-based flake. All packages are `perSystem` outputs, exposed via `packages.<system>.<name>` and re-exported in `overlayAttrs` for `overlays.default`.

**`pkgs/default.nix`** — central wiring: builds a custom `callPackage` that injects `buildGoApplication` (from gomod2nix) and `nix2container`, then calls each package derivation. This is the file to edit when adding a new package.

**`pkgs/<name>/default.nix`** — individual derivation. Packages set `passthru.updateScript = nix-update-script { }` for `nix-update` support, except the ones `scripts/update.sh` lists as `manual_only`.

**`pkgs/images/`** — container images built with `nix2container.buildImage`. Images are not standalone packages; they attach to an existing nixpkgs package via `overrideAttrs` + `passthru.image` (see `hercules-ci-agent` and `github-runner` in `pkgs/default.nix`).

**`lib/maintainers.nix`** — extends `pkgs.lib.maintainers` with the local `UnstoppableMango` entry. Referenced in every `meta.maintainers` block.

**`lib/packages.nix`** — pure Nix function that generates the README table from `config.packages`. Called via `legacyPackages.packagesTable`; the actual README markers are updated by `scripts/gen-packages-table.sh`.

## Package patterns

| Language        | Builder                                  | Extra files                            |
| --------------- | ---------------------------------------- | -------------------------------------- |
| Go              | `buildGoApplication` (gomod2nix)         | `gomod2nix.toml` per package           |
| .NET            | `buildDotnetModule`                      | `deps.json` per package                |
| Python          | `python3Packages.buildPythonApplication` | —                                      |
| Rust            | `rustPlatform.buildRustPackage`          | `cargoHash` in derivation              |
| OCaml           | `ocamlPackages.buildDunePackage`         | —                                      |
| Container image | `nix2container.buildImage`               | `manifest.json` for pulled base images |

## Adding a package

1. Create `pkgs/<name>/default.nix` following an existing derivation of the same language.
2. Add the package to `pkgs/default.nix` — both the `packages` attrset and `overlayAttrs`.
3. Run `make generate` to update the README table and badge.
4. For Go packages: run `make deps` to produce `gomod2nix.toml`.

## Update automation

`scripts/update.sh`, run daily by `.github/workflows/update.yml`, bumps every wired-up package to its latest upstream release:

1. Skip packages listed in the script's `manual_only` map, packages absent from `pkgs/default.nix`, and `unstable-` pins.
1. `nix-update --flake <name> --override-filename pkgs/<name>/default.nix` rewrites `version` and the source hashes. `--flake` is required (there's no top-level `default.nix` to import) and `--override-filename` names the file to rewrite directly.
1. Regenerate `gomod2nix.toml` via the package's `update-deps` if it has one. Other vendored manifests (`nugetDeps`, `cargoHash`, `npmDepsHash`) are nix-update's own job; gomod2nix is opaque to it.
1. `nix build .#<name>`, then commit the package directory's changed files on `update-<name>-<version>` and open a pull request with auto-merge enabled.

Commits go through the GraphQL `createCommitOnBranch` mutation rather than `git push`, because main's ruleset requires GitHub-signed commits and the API signs what it commits. The workflow authenticates with the `UPDATE_TOKEN` PAT: `GITHUB_TOKEN`'s commits are unattributed (which the ruleset requires an extra approval for) and its pull requests don't trigger the required `build` check.

Each package is independent — a failure is recorded and the run continues, and the script exits non-zero only if something failed. Run it locally with `DRY_RUN=1 ./scripts/update.sh` to stop short of touching the remote.

## CI

`make check build` runs on every push/PR across a 3-system matrix (x86_64-linux, aarch64-linux, aarch64-darwin), pulling from the `unstoppablemango` and `mangopkgs` cachix caches. A separate `codegen` job runs `make generate` and fails if the README diff is non-empty — keep the generated table committed.

## Gotchas

- CI runs `make check build`: `nix flake check` does lint + eval, and `make build` (via `nix build`) builds the packages listed in the Makefile. A placeholder/unfetchable hash will fail the build step. Keep in-progress packages out of `pkgs/default.nix`/`overlayAttrs` (and the Makefile build list) until real hashes exist.
- `packages` filters on `meta.available`, which is false for an unfree package unless `flake.nix`'s `config.allowUnfreePredicate` names it. An unfree package missing from that list disappears from the flake outputs with no error.
- A `pkgs/<name>/default.nix` existing doesn't mean it's wired up — packages blocked on an upstream fix are deliberately left out of `pkgs/default.nix`'s `packages` attrset (see the `smarter-device-manager` comment there).
