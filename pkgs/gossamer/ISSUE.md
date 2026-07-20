# `gossamer` package missing LLVM runtime dependency

## Symptom

`gos build` fails inside the Nix sandbox (and in any environment without
`opt`/`llc` on `$PATH`):

```
error: build: native codegen cannot yet lower this program: opt (LLVM toolchain) not found. Install LLVM 18+ and retry:
  Linux:   apt install llvm-18-dev               (or the distro equivalent)
  macOS:   brew install llvm@18
  Windows: pacman -S mingw-w64-x86_64-llvm       (from MSYS2; the upstream LLVM
           Windows installer ships clang
           but not `opt`/`llc`)
Or set `GOS_LLVM_OPT` to the absolute path of `opt`.
```

## Root cause

`pkgs/gossamer/default.nix` builds the `gos` CLI (`rustPlatform.buildRustPackage`)
but declares no `nativeBuildInputs`/`propagatedBuildInputs` for LLVM:

```
$ nix eval --impure --expr '(builtins.getFlake "/home/erik/src/github.com/unmango/pkgs").legacyPackages.x86_64-linux.gossamer' \
    --apply 'p: { nativeBuildInputs = map (x: x.pname or x.name) (p.nativeBuildInputs or []); propagated = map (x: x.pname or x.name) (p.propagatedBuildInputs or []); }'
{ nativeBuildInputs = []; propagated = []; }
```

`gos build` shells out to `opt`/`llc` (LLVM 18+) at *runtime*, not just build time,
so it needs to find them via `GOS_LLVM_OPT`/`$PATH` wherever `gos` itself runs —
this makes it a `propagatedBuildInputs` (or a wrapped `$PATH`) concern, not just
`nativeBuildInputs` on the package's own build.

This is already known and worked around for the package's own test suite — see
the existing comment in `default.nix`:

```nix
# Tests invoke `gos build` which requires LLVM opt at runtime.
doCheck = false;
```

`doCheck = false` sidesteps it for `checkPhase`, but any downstream consumer of
the `gossamer` package hits the same failure the moment they invoke `gos build`
in a sandboxed derivation (no ambient `$PATH` LLVM available).

## Reproduction

Confirmed from the `gossamer2nix` repo (adds a `buildGossamerApplication`
builder that wraps `gos build` in `stdenv.mkDerivation`, using this `gossamer`
package via the `mangopkgs` overlay):

```
$ gos new example.com/hello && cd hello   # trivial, dependency-free scaffold
$ nix build .#  # via buildGossamerApplication { pname = "hello"; version = "0.1.0"; src = ./hello; }
...
hello> Running phase: buildPhase
hello> error: build: native codegen cannot yet lower this program: opt (LLVM toolchain) not found. ...
```

Works fine in an *unsandboxed* `nix develop` shell only because `opt`/`llc`
happen to be present via the host system profile (`/run/current-system/sw/bin`)
on that particular machine — not because the `gossamer` derivation provides
them.

## Suggested fix

Add the appropriate `llvmPackages_18` (or newer) `opt`/`llc` providers to
`propagatedBuildInputs` in `pkgs/gossamer/default.nix` (or wrap the `gos`
binary so `$PATH` includes them, e.g. via `makeWrapper`), so any derivation
using this package — including sandboxed `nix build` — has LLVM available
without relying on the ambient environment. Once fixed, `doCheck = false` may
also be revisitable.

## Context

Filed while wiring up `buildGossamerApplication` in the `gossamer2nix` repo
(`nix/builder.nix`), which needs a working `gossamer` package to build
anything beyond `nix eval`.
