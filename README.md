# pkgs

[![CI](https://github.com/unmango/pkgs/actions/workflows/ci.yml/badge.svg)](https://github.com/unmango/pkgs/actions/workflows/ci.yml)
[![Cachix](https://img.shields.io/badge/cachix-unstoppablemango-blue)](https://unstoppablemango.cachix.org)
[![Last Commit](https://img.shields.io/github/last-commit/unmango/pkgs)](https://github.com/unmango/pkgs/commits/main)

Mini-nixpkgs of dubious quality.

See [GOALS.md](GOALS.md) for purpose, non-goals, and upstream policy.

## Packages

| Name | Description |
|------|-------------|
| `aspire-cli` | A CLI tool for managing Aspire projects |
| `awxkit` | Official command line interface for Ansible AWX |
| `chart-releaser` | Hosting Helm Charts via GitHub Pages and Releases |
| `kube-vip` | Virtual IP for Kubernetes clusters |
| `kubectl-get-all` | Like `kubectl get all`, but get really all resources |
| `kubectl-get-resources` | Get Kubernetes resources in CSV or YAML with filtering |
| `kubectl-slice` | Split multi-YAML files into individual files |
| `mmake` | Modern Make |
| `openshift-installer` | Install an OpenShift cluster |
| `terraform-plugin-codegen-framework` | Terraform Plugin Framework code generation |
| `terraform-plugin-codegen-openapi` | OpenAPI to Terraform provider code generation |
| `terraform-provider-pfsense` | Terraform provider for pfSense |
| `hercules-ci-agent` (+ `.passthru.image`) | Hercules CI agent with container image |
| `github-runner` (+ `.passthru.image`) | GitHub Actions runner with container image |

## Usage

### Flake input

```nix
{
  inputs.pkgs.url = "github:unmango/pkgs";
}
```

### Install a package

```bash
nix run github:unmango/pkgs#kubectl-slice
nix shell github:unmango/pkgs#kube-vip
```

### Overlay

```nix
{
  nixpkgs.overlays = [ inputs.pkgs.overlays.default ];
}
```

### Binary cache

```bash
cachix use unstoppablemango
```

## Development

```bash
nix develop     # enter dev shell
make            # build all packages
make check      # lint + build check
make fmt        # format
```

Requires [gomod2nix](https://github.com/nix-community/gomod2nix) for Go packages. Run `gomod2nix` after changing `go.mod`.
