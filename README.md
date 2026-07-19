# pkgs

[![CI](https://github.com/unmango/pkgs/actions/workflows/ci.yml/badge.svg)](https://github.com/unmango/pkgs/actions/workflows/ci.yml)
[![Cachix](https://img.shields.io/badge/cachix-unstoppablemango-blue)](https://unstoppablemango.cachix.org)
[![Last Commit](https://img.shields.io/github/last-commit/unmango/pkgs)](https://github.com/unmango/pkgs/commits/main)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![packages](https://img.shields.io/badge/packages-23-blue)](#packages)

<p align="center">

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

</p>

Mini-nixpkgs of dubious quality.

See [GOALS](GOALS.md) for purpose, non-goals, and upstream policy.

## Packages

<!-- PACKAGES:START -->

| Name                                 | Description                                                                                                     |
| ------------------------------------ | --------------------------------------------------------------------------------------------------------------- |
| `aspire-cli`                         | A CLI tool for managing Aspire projects                                                                         |
| `awxkit`                             | Official command line interface for Ansible AWX                                                                 |
| `chart-releaser`                     | Hosting Helm Charts via GitHub Pages and Releases                                                               |
| `github-runner`                      | Self-hosted runner for GitHub Actions                                                                           |
| `gossamer`                           | The Gossamer programming language compiler                                                                      |
| `hercules-ci-agent`                  | Runs Continuous Integration tasks on your machines                                                              |
| `kube-vip`                           | Kube-VIP: Virtual IP for Kubernetes clusters                                                                    |
| `kubectl-get-all`                    | Like `kubectl get all`, but get really all resources                                                            |
| `kubectl-get-resources`              | Get Kubernetes resources (cluster or namespace scope) in CSV or YAML with support for multiple filtering flags. |
| `kubectl-slice`                      | Split multiple Kubernetes files into smaller files with ease. Split multi-YAML files into individual files.     |
| `mmake`                              | Modern Make                                                                                                     |
| `oc-mirror`                          | Lifecycle manager for internet-disconnected OpenShift environments                                              |
| `ocaml-protoc`                       | Pure OCaml compiler for .proto files                                                                            |
| `ocaml-protoc-plugin`                | Maps google protobuf compiler to Ocaml types                                                                    |
| `openshift-installer`                | Install an OpenShift Cluster                                                                                    |
| `pbrt`                               | Runtime library for Protobuf tooling                                                                            |
| `pulumi-bun`                         | Pulumi language host for Bun programs                                                                           |
| `pulumi-dotnet`                      | Pulumi language host for .NET programs                                                                          |
| `pulumi-java`                        | Pulumi language host for Java programs                                                                          |
| `pulumi-yaml`                        | Pulumi language host for YAML programs                                                                          |
| `terraform-plugin-codegen-framework` | Terraform Plugin Framework Code Generation                                                                      |
| `terraform-plugin-codegen-openapi`   | OpenAPI to Terraform Provider Code Generation Specification                                                     |
| `terraform-provider-pfsense`         | Used to configure pfSense firewall/router devices with Terraform                                                |

<!-- PACKAGES:END -->

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
