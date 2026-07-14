---
name: add-package
description: Guide for adding a new package (or container image) to this nix flake-parts repo under pkgs/. Use when the user asks to add/create/package a new tool, add a derivation, add a Go/Python/.NET/OCaml package, or add a container image to this repo.
---

# Adding a package to this repo

Walks through adding `pkgs/<name>/default.nix`, wiring it into `pkgs/default.nix`, and regenerating generated artifacts (README table, badge).

## 1. Decide the shape

- **Standalone package** (most common) — new derivation under `pkgs/<name>/`. Go to §2.
- **Container image** — an OCI image attached to an _existing_ nixpkgs package (e.g. `hercules-ci-agent`, `github-runner`). Not a new `packages` entry. Skip to §5.

For standalone packages, identify the language/build system: Go, .NET, Python, or other (e.g. OCaml). Pick the matching checklist in §3.

## 2. Common steps (every standalone package)

1. Create `pkgs/<name>/default.nix` following the shared skeleton:

   ```nix
   { <builder-and-inputs>, lib, fetchFromGitHub, nix-update-script }:
   let
     version = "X.Y.Z";
     src = fetchFromGitHub {
       owner = "...";
       repo = "...";
       rev = "v${version}"; # or tag = version;
       hash = "sha256-...";
     };
   in
   <builder> {
     pname = "<name>";
     inherit version src;
     # build-specific attrs (§3)

     passthru.updateScript = nix-update-script { };

     meta = with lib; {
       description = "...";
       homepage = "https://...";
       license = licenses.<id>;
       maintainers = with maintainers; [ UnstoppableMango ];
       mainProgram = "<name>"; # omit for libraries
     };
   }
   ```

2. Register in `pkgs/default.nix`, alphabetically, inside `packages = { ... };`:
   ```nix
   <name> = callPackage ./<name> { };
   ```
   If it needs another local package as an input, use `inherit (config.packages) <dep>;` (see `ocaml-protoc` → `pbrt`).
3. Add the same name, alphabetically, to the `overlayAttrs` inherit list in `pkgs/default.nix`. Do this unless there's a clear reason not to — one existing package (`awxkit`) is missing from `overlayAttrs`, but that's an inconsistency, not a pattern to follow.
4. Do **not** hand-edit the README package table — `lib/packages.nix` generates it from `config.packages` automatically (`make generate` refreshes it, §6).
5. Do **not** add a new maintainer entry — `UnstoppableMango` already exists in `lib/maintainers.nix`.

## 3. Per-language checklist

**Go** — `buildGoApplication` (gomod2nix). Reference: `pkgs/kubectl-slice/default.nix`.

- Function args include `buildGoApplication, mkUpdateDeps`.
- Derivation attrs: `modules = ./gomod2nix.toml;`, optional `ldflags`.
- Passthru: also add `passthru.update-deps = mkUpdateDeps src;` (alongside `updateScript`).
- Add `<name>` to `GO_PKGS` in the root `Makefile`.
- Run `make deps` (or `nix run .#<name>.update-deps pkgs/<name>/gomod2nix.toml`) to generate `gomod2nix.toml` — the build fails without it.

**.NET** — `buildDotnetModule`. Reference: `pkgs/aspire-cli/default.nix`.

- Function args include `buildDotnetModule, dotnetCorePackages`.
- Derivation attrs: `dotnet-sdk = dotnetCorePackages.sdk_10_0_1xx;` (or current pin), `projectFile`, `nugetDeps = ./deps.json;`, `selfContainedBuild = true;`.
- `deps.json` must exist before the build succeeds — generate/update it per the nixpkgs `buildDotnetModule` deps workflow if missing.

**Python** — `python3Packages.buildPythonApplication`. Reference: `pkgs/awxkit/default.nix`.

- Function args include `python3Packages`.
- Derivation attrs: `pyproject = true;`, `build-system = with python3Packages; [ ... ];`, `dependencies = with python3Packages; [ ... ];`, optional `postPatch` for source patches.

**Other/minimal** (e.g. OCaml via `ocamlPackages.buildDunePackage`). References: `pkgs/pbrt/default.nix`, `pkgs/ocaml-protoc-plugin/default.nix`.

- Function args are builder-specific (e.g. `ocamlPackages`).
- Minimal shape: `src`, builder call, optional `propagatedBuildInputs`, `meta` (may omit `mainProgram` for libraries).

## 4. Skip to §6 for verification once the standalone package is wired.

## 5. Special case: container images

Applies when packaging an image for an _existing_ nixpkgs derivation, not creating a new one.

1. Create `pkgs/images/<name>/default.nix`:
   ```nix
   { nix2container, ... }:
   nix2container.buildImage {
     name = "<name>";
     fromImage = nix2container.pullImageFromManifest {
       registryUrl = "...";
       imageName = "...";
       imageTag = "...";
       imageManifest = ./manifest.json; # sibling file, if pulling a base image
     };
     config = { ... };
   }
   ```
2. Do **not** add this as a new `packages`/`overlayAttrs` entry. Instead, attach it via `.overrideAttrs` + `passthru.image` on the existing package in `pkgs/default.nix`:
   ```nix
   <name> = pkgs.<name>.overrideAttrs (old: {
     passthru = (old.passthru or { }) // {
       image = callPackage ./images/<name> { };
     };
   });
   ```
   Reference: `pkgs/images/github-runner/default.nix` and its `pkgs/default.nix` entry.

## 6. Verification (always run, in order)

1. `nix build .#<name>` — confirms the derivation builds.
2. Go only: confirm `gomod2nix.toml` was generated first (§3), otherwise the build fails.
3. `make generate` (or `make gen`) — regenerates the README package table (`scripts/gen-packages-table.sh`) and package-count badge (`scripts/gen-package-count-badge.sh`), then runs `nix fmt`.
4. `git status` / `git diff` — confirm the README diff looks correct (new row, incremented badge count) and nothing unrelated changed.
5. Optional: `make check` (runs `nix flake check`) for broader validation.

## Quick reference

| Language        | Builder                                  | Extra passthru               | Example                     |
| --------------- | ---------------------------------------- | ---------------------------- | --------------------------- |
| Go              | `buildGoApplication`                     | `update-deps`                | `pkgs/kubectl-slice`        |
| .NET            | `buildDotnetModule`                      | —                            | `pkgs/aspire-cli`           |
| Python          | `python3Packages.buildPythonApplication` | —                            | `pkgs/awxkit`               |
| Other/OCaml     | `ocamlPackages.buildDunePackage`         | —                            | `pkgs/pbrt`                 |
| Container image | `nix2container.buildImage`               | `passthru.image` on base pkg | `pkgs/images/github-runner` |
