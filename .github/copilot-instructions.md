# Copilot Instructions

## Commands

```bash
nix develop              # enter dev shell (or use direnv / .envrc)
make                     # build all packages
make check               # nix flake check (lint + eval)
make fmt                 # format (nixfmt, prettier, shfmt, statix, deadnix, actionlint)
make generate            # regenerate README package table and badge — must be committed

nix build .#<name>       # build a single package
nix build .#<name>.image # build a container image
```

After changing `go.mod` in any Go package, run `gomod2nix` inside the dev shell to regenerate `gomod2nix.toml`.

## Architecture

This is a `flake-parts`-based Nix flake. All packages are `perSystem` outputs exposed as `packages.<system>.<name>` and re-exported in `overlayAttrs` for `overlays.default`.

**`pkgs/default.nix`** — central wiring. Builds a custom `callPackage` that injects `buildGoApplication` (from gomod2nix) and `nix2container`, then calls each package derivation. **Edit here when adding or removing a package** — both in `packages` and `overlayAttrs`.

**`pkgs/<name>/default.nix`** — individual derivation. Each package is a plain Nix function; no module system.

**`pkgs/images/`** — container images built with `nix2container.buildImage`. Images are not standalone packages; they attach to an existing nixpkgs package via `overrideAttrs` + `passthru.image` (see `hercules-ci-agent` and `github-runner` in `pkgs/default.nix`).

**`lib/maintainers.nix`** — extends `pkgs.lib.maintainers` with the local `UnstoppableMango` entry. Referenced in every `meta.maintainers` block.

**`lib/packages.nix`** — pure Nix function that generates the README table from `config.packages`. The README markers are updated by `scripts/gen-packages-table.sh` (run via `make generate`). **Never edit the `<!-- PACKAGES:START/END -->` block in `README.md` manually.**

## Package conventions

All packages follow these patterns:

```nix
let
  version = "x.y.z";
  src = fetchFromGitHub { ... rev = "v${version}"; };
in
<builder> {
  pname = "<name>";
  inherit version src;

  passthru.updateScript = nix-update-script { };  # always present

  meta = with lib; {
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "<binary-name>";
    # ...
  };
}
```

| Language | Builder | Extra files |
|----------|---------|-------------|
| Go | `buildGoApplication` (gomod2nix) | `gomod2nix.toml` |
| .NET | `buildDotnetModule` | `deps.json` |
| Python | `python3Packages.buildPythonApplication` | — |
| Container image | `nix2container.buildImage` | `manifest.json` (for pulled base images) |

Go packages pass `modules = ./gomod2nix.toml;` and typically inject version info via `ldflags`.

## Adding a package

1. Create `pkgs/<name>/default.nix` modelled on an existing derivation of the same language.
2. Register it in `pkgs/default.nix` — add to both the `packages` attrset and `overlayAttrs`.
3. Run `make generate` to update the README table and badge, and commit the result.
4. For Go packages: run `gomod2nix` inside the dev shell to generate `gomod2nix.toml`.

## CI

- `nix flake check` — lint (statix, deadnix, actionlint) + eval
- `nix build .#` — builds all packages listed in the Makefile
- `codegen` job — runs `make generate` and fails if `README.md` diff is non-empty; keep the generated table committed
