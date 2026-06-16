# pkgs — Goals

## Purpose

Collection of Nix derivations not available in, or not yet accepted by, nixpkgs. Packages may be here because they are too niche, proprietary, or under active development where upstream lag is unacceptable. Also serves as an experimentation ground for packaging approaches before upstreaming.

## Non-goals

- NixOS modules
- Home Manager modules
- Library functions (see [UnstoppableMango/nix](https://github.com/UnstoppableMango/nix))

## Structure

`flake-parts`-based flake initialized from `github:UnstoppableMango/nix#default`. Packages exposed via `packages.<system>.<name>`.

## Consumers

Any Nix user. No support guarantees or SLAs.

## Overlays

- `overlays.default` — all packages
- Category overlays (e.g. `overlays.k8s`, `overlays.terraform`) as groups grow

## Upstream policy

Prefer upstreaming to nixpkgs. Packages may coexist here indefinitely for speed or control. Deprecation is case-by-case.

## Package categories (initial)

Migrated from [UnstoppableMango/nix](https://github.com/UnstoppableMango/nix/tree/main/pkgs):

- Kubernetes tooling (`kube-vip`, `kubectl-get-all`, `kubectl-get-resources`, `kubectl-slice`)
- OpenShift tooling (`openshift-installer`)
- Terraform providers and codegen plugins
- .NET / Aspire tooling (`aspire-cli`)
- Helm tooling (`chart-releaser`)
- Misc CLI tools (`mmake`, `awxkit`, `smarter-device-manager`)
- Proprietary / non-redistributable (`omnissa-horizon-client`)
