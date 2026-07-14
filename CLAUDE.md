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

After changing `go.mod` in any Go package, run `gomod2nix` inside the dev shell to regenerate `gomod2nix.toml`.

## Architecture

`flake-parts`-based flake. All packages are `perSystem` outputs, exposed via `packages.<system>.<name>` and re-exported in `overlayAttrs` for `overlays.default`.

**`pkgs/default.nix`** — central wiring: builds a custom `callPackage` that injects `buildGoApplication` (from gomod2nix) and `nix2container`, then calls each package derivation. This is the file to edit when adding a new package.

**`pkgs/<name>/default.nix`** — individual derivation. All packages set `passthru.updateScript = nix-update-script { }` for `nix-update` support.

**`pkgs/images/`** — container images built with `nix2container.buildImage`. Images are not standalone packages; they attach to an existing nixpkgs package via `overrideAttrs` + `passthru.image` (see `hercules-ci-agent` and `github-runner` in `pkgs/default.nix`).

**`lib/maintainers.nix`** — extends `pkgs.lib.maintainers` with the local `UnstoppableMango` entry. Referenced in every `meta.maintainers` block.

**`lib/packages.nix`** — pure Nix function that generates the README table from `config.packages`. Called via `legacyPackages.packagesTable`; the actual README markers are updated by `scripts/gen-packages-table.sh`.

## Package patterns

| Language        | Builder                                  | Extra files                            |
| --------------- | ---------------------------------------- | -------------------------------------- |
| Go              | `buildGoApplication` (gomod2nix)         | `gomod2nix.toml` per package           |
| .NET            | `buildDotnetModule`                      | `deps.json` per package                |
| Python          | `python3Packages.buildPythonApplication` | —                                      |
| Container image | `nix2container.buildImage`               | `manifest.json` for pulled base images |

## Adding a package

1. Create `pkgs/<name>/default.nix` following an existing derivation of the same language.
2. Add the package to `pkgs/default.nix` — both the `packages` attrset and `overlayAttrs`.
3. Run `make generate` to update the README table and badge.
4. For Go packages: run `gomod2nix` to produce `gomod2nix.toml`.

## CI

`.github/workflows/ci.yml` has four jobs:

- **`matrix`** — enumerates all package/image targets via `scripts/list-build-targets.sh` (`nix eval` over `packages.<system>`, source of truth is `pkgs/default.nix`), then diffs the push/PR against its base to filter down to only the changed targets. Any change outside `pkgs/**` (e.g. `flake.nix`, `pkgs/default.nix`, `lib/**`) falls back to building everything.
- **`build`** — matrix job, one `nix build .#<target>` per changed package/image, each on its own runner (fixes prior disk exhaustion from building everything in one job).
- **`check`** — `nix flake check` (lint + eval), runs unconditionally.
- **`codegen`** — runs `make generate` and fails if the README diff is non-empty — keep the generated table committed.

`scripts/list-build-targets.sh` is also used by `make build` locally, so the local and CI target lists can't drift.
