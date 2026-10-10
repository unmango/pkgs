# pkgs

[![CI](https://github.com/unmango/pkgs/actions/workflows/ci.yml/badge.svg)](https://github.com/unmango/pkgs/actions/workflows/ci.yml)
[![Cachix](https://img.shields.io/badge/cachix-unstoppablemango-blue)](https://unstoppablemango.cachix.org)
[![Last Commit](https://img.shields.io/github/last-commit/unmango/pkgs)](https://github.com/unmango/pkgs/commits/main)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![packages](https://img.shields.io/badge/packages-136-blue)](#packages)
[![Hercules CI](https://hercules-ci.com/api/v1/site/github/account/unmango/project/pkgs/badge)](https://hercules-ci.com/github/unmango/pkgs)

<p align="center">

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

</p>

Mini-nixpkgs of dubious quality.

## Packages

<!-- PACKAGES:START -->

| Name                                            | Description                                                                                                                 |
| ----------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `aspire-cli`                                    | A CLI tool for managing Aspire projects                                                                                     |
| `awxkit`                                        | Official command line interface for Ansible AWX                                                                             |
| `chart-releaser`                                | Hosting Helm Charts via GitHub Pages and Releases                                                                           |
| `claude-desktop`                                | Desktop application for Claude.ai                                                                                           |
| `claude-desktop-fhs`                            | Desktop application for Claude.ai, in an FHS environment for MCP servers and Cowork                                         |
| `coderabbit`                                    | CodeRabbit AI code review, in the terminal                                                                                  |
| `cumulusci`                                     | Build and release tools for Salesforce developers                                                                           |
| `github-runner`                                 | Self-hosted runner for GitHub Actions                                                                                       |
| `gitlab-operator`                               | Kubernetes Operator for managing the lifecycle of GitLab instances                                                          |
| `gitlab-operator-v2`                            | Kubernetes Operator for managing the lifecycle of GitLab instances (experimental V2 rewrite)                                |
| `gossamer`                                      | The Gossamer programming language compiler                                                                                  |
| `graphify`                                      | Turn a folder of code, docs, papers, or media into a queryable knowledge graph                                              |
| `hercules-ci-agent`                             | Runs Continuous Integration tasks on your machines                                                                          |
| `java-jdtls-mcp-server`                         | Model Context Protocol (MCP) server for Java using Eclipse JDT.LS                                                           |
| `jdtls-mcp`                                     | Model Context Protocol (MCP) server embedding Eclipse JDT Language Server via OSGi                                          |
| `kube-vip`                                      | Kube-VIP: Virtual IP for Kubernetes clusters                                                                                |
| `kubectl-get-all`                               | Like `kubectl get all`, but get really all resources                                                                        |
| `kubectl-get-resources`                         | Get Kubernetes resources (cluster or namespace scope) in CSV or YAML with support for multiple filtering flags.             |
| `kubectl-slice`                                 | Split multiple Kubernetes files into smaller files with ease. Split multi-YAML files into individual files.                 |
| `kubernetes-mcp-server`                         | Model Context Protocol (MCP) server for Kubernetes and OpenShift                                                            |
| `likec4`                                        | Toolchain for your architecture diagrams                                                                                    |
| `lsmcp`                                         | Unified MCP server for language-service/LSP-based code analysis across multiple languages                                   |
| `lsp4j-mcp`                                     | Model Context Protocol (MCP) server exposing Java IDE features via JDTLS                                                    |
| `mmake`                                         | Modern Make                                                                                                                 |
| `nix2container-bin`                             | Build container images with Nix, without a Docker daemon or a tarball                                                       |
| `oc-mirror`                                     | Lifecycle manager for internet-disconnected OpenShift environments                                                          |
| `ocaml-protoc`                                  | Pure OCaml compiler for .proto files                                                                                        |
| `ocaml-protoc-plugin`                           | Maps google protobuf compiler to Ocaml types                                                                                |
| `opencommit`                                    | Auto-generate impressive commits in 1 second, killing lame commits with AI                                                  |
| `openshift-installer`                           | Install an OpenShift Cluster                                                                                                |
| `pbrt`                                          | Runtime library for Protobuf tooling                                                                                        |
| `podman-mcp-server`                             | Model Context Protocol (MCP) server for container runtimes (Podman and Docker)                                              |
| `rehype`                                        | HTML processor powered by plugins part of the unified collective                                                            |
| `rehype-cli`                                    | CLI to process HTML with rehype                                                                                             |
| `rehype-parse`                                  | rehype plugin to parse HTML                                                                                                 |
| `rehype-stringify`                              | rehype plugin to serialize HTML                                                                                             |
| `remark`                                        | markdown processor powered by plugins part of the unified collective                                                        |
| `remark-cli`                                    | CLI to process markdown with remark                                                                                         |
| `remark-gfm`                                    | remark plugin to support GFM (autolink literals, footnotes, strikethrough, tables, tasklists)                               |
| `remark-lint`                                   | remark plugin to lint Markdown code style                                                                                   |
| `remark-lint-blockquote-indentation`            | remark-lint rule to check whitespace after block quote markers                                                              |
| `remark-lint-checkbox-character-style`          | remark-lint rule to check list item checkbox characters                                                                     |
| `remark-lint-checkbox-content-indent`           | remark-lint rule to warn when too much whitespace follows list item checkboxes                                              |
| `remark-lint-code-block-style`                  | remark-lint rule to warn when code blocks do not adhere to a given style                                                    |
| `remark-lint-correct-media-syntax`              | remark-lint rule to check for accidental bracket and paren mixup for images and links                                       |
| `remark-lint-definition-case`                   | remark-lint rule to warn when definition labels are not lowercase                                                           |
| `remark-lint-definition-sort`                   | remark-lint rule to check definition order                                                                                  |
| `remark-lint-definition-spacing`                | remark-lint rule to warn when consecutive whitespace is used in a definition                                                |
| `remark-lint-directive-attribute-sort`          | remark-lint rule to check directive attribute order                                                                         |
| `remark-lint-directive-collapsed-attribute`     | remark-lint rule to check that collapsed attributes are used in directives                                                  |
| `remark-lint-directive-quote-style`             | remark-lint rule to check quotes of directive attributes                                                                    |
| `remark-lint-directive-shortcut-attribute`      | remark-lint rule to check that shortcut attributes are used in directives                                                   |
| `remark-lint-directive-unique-attribute-name`   | remark-lint rule to check that attribute names are unique                                                                   |
| `remark-lint-emphasis-marker`                   | remark-lint rule to warn when emphasis markers violate the given style                                                      |
| `remark-lint-fenced-code-flag`                  | remark-lint rule to warn when fenced code blocks occur without language flag                                                |
| `remark-lint-fenced-code-marker`                | remark-lint rule to warn when fenced code markers violate the given style                                                   |
| `remark-lint-file-extension`                    | remark-lint rule to warn when the file’s extension violates the given style                                                 |
| `remark-lint-final-definition`                  | remark-lint rule to warn when definitions are not placed at the end of the file                                             |
| `remark-lint-final-newline`                     | remark-lint rule to warn when a newline at the end of a file is missing                                                     |
| `remark-lint-first-heading-level`               | remark-lint rule to warn when the first heading has a level other than a specified value                                    |
| `remark-lint-hard-break-spaces`                 | remark-lint rule to warn when too many spaces are used to create a hard break                                               |
| `remark-lint-heading-increment`                 | remark-lint rule to warn when headings increment with more than 1 level at a time                                           |
| `remark-lint-heading-style`                     | remark-lint rule to warn when heading style violates the given style                                                        |
| `remark-lint-linebreak-style`                   | remark-lint rule to warn when linebreaks violate a given or detected style                                                  |
| `remark-lint-link-title-style`                  | remark-lint rule to warn when link and definition titles occur with incorrect quotes                                        |
| `remark-lint-list-item-bullet-indent`           | remark-lint rule to warn when list item bullets are indented                                                                |
| `remark-lint-list-item-content-indent`          | remark-lint rule to warn when the content of a list item has mixed indentation                                              |
| `remark-lint-list-item-indent`                  | remark-lint rule to check the spacing between list item bullets and content                                                 |
| `remark-lint-list-item-spacing`                 | remark-lint rule to warn when list looseness is incorrect                                                                   |
| `remark-lint-maximum-heading-length`            | remark-lint rule to warn when headings are too long                                                                         |
| `remark-lint-maximum-line-length`               | remark-lint rule to warn when lines are too long                                                                            |
| `remark-lint-mdx-jsx-attribute-sort`            | remark-lint rule to check mdx jsx attribute order                                                                           |
| `remark-lint-mdx-jsx-no-void-children`          | remark-lint rule to check mdx jsx quotes                                                                                    |
| `remark-lint-mdx-jsx-quote-style`               | remark-lint rule to check mdx jsx quotes                                                                                    |
| `remark-lint-mdx-jsx-self-close`                | remark-lint rule to check that self-closing tags are used when possible                                                     |
| `remark-lint-mdx-jsx-shorthand-attribute`       | remark-lint rule to check that shorthand attributes are used in MDX JSX                                                     |
| `remark-lint-mdx-jsx-unique-attribute-name`     | remark-lint rule to check that mdx jsx attributes are unique                                                                |
| `remark-lint-media-style`                       | remark-lint rule to check whether references or resources are used                                                          |
| `remark-lint-no-blockquote-without-marker`      | remark-lint rule to warn when block quotes have blank lines without markers                                                 |
| `remark-lint-no-consecutive-blank-lines`        | remark-lint rule to warn for too many consecutive blank lines                                                               |
| `remark-lint-no-duplicate-defined-urls`         | remark-lint rule to warn on definitions that define the same urls                                                           |
| `remark-lint-no-duplicate-definitions`          | remark-lint rule to warn on duplicate definitions                                                                           |
| `remark-lint-no-duplicate-headings`             | remark-lint rule to warn on duplicate headings                                                                              |
| `remark-lint-no-duplicate-headings-in-section`  | remark-lint rule to warn on duplicate headings in a section                                                                 |
| `remark-lint-no-emphasis-as-heading`            | remark-lint rule to warn when emphasis or importance is used instead of a heading                                           |
| `remark-lint-no-empty-url`                      | remark-lint rule to warn on empty URLs in links and images                                                                  |
| `remark-lint-no-file-name-articles`             | remark-lint rule to warn when file name start with an article                                                               |
| `remark-lint-no-file-name-consecutive-dashes`   | remark-lint rule to warn when file names contain consecutive dashes                                                         |
| `remark-lint-no-file-name-irregular-characters` | remark-lint rule to warn when file names contain irregular characters                                                       |
| `remark-lint-no-file-name-mixed-case`           | remark-lint rule to warn when file names use mixed case                                                                     |
| `remark-lint-no-file-name-outer-dashes`         | remark-lint rule to warn when file names contain initial or final dashes                                                    |
| `remark-lint-no-heading-content-indent`         | remark-lint rule to warn when heading content is indented                                                                   |
| `remark-lint-no-heading-indent`                 | remark-lint rule to warn when headings are indented                                                                         |
| `remark-lint-no-heading-like-paragraph`         | remark-lint rule to for too many hashes (h7+ “headings”)                                                                    |
| `remark-lint-no-heading-punctuation`            | remark-lint rule to warn when headings end in illegal characters                                                            |
| `remark-lint-no-hidden-table-cell`              | remark-lint rule to check superfluous table cells                                                                           |
| `remark-lint-no-html`                           | remark-lint rule to warn when HTML nodes are used                                                                           |
| `remark-lint-no-literal-urls`                   | remark-lint rule to warn when URLs without angle brackets are used                                                          |
| `remark-lint-no-missing-blank-lines`            | remark-lint rule to warn when missing blank lines                                                                           |
| `remark-lint-no-multiple-toplevel-headings`     | remark-lint rule to warn when multiple top level headings are used                                                          |
| `remark-lint-no-paragraph-content-indent`       | remark-lint rule to warn when the content in paragraphs are indented                                                        |
| `remark-lint-no-reference-like-url`             | remark-lint rule to warn when URLs are also defined identifiers                                                             |
| `remark-lint-no-shell-dollars`                  | remark-lint rule to warn when shell code is prefixed by dollars                                                             |
| `remark-lint-no-shortcut-reference-image`       | remark-lint rule to warn when shortcut reference images are used                                                            |
| `remark-lint-no-shortcut-reference-link`        | remark-lint rule to warn when shortcut reference links are used                                                             |
| `remark-lint-no-table-indentation`              | remark-lint rule to warn when tables are indented                                                                           |
| `remark-lint-no-tabs`                           | remark-lint rule to warn when hard tabs are used instead of spaces                                                          |
| `remark-lint-no-undefined-references`           | remark-lint rule to warn when references to undefined definitions are found                                                 |
| `remark-lint-no-unneeded-full-reference-image`  | remark-lint rule to check that full reference images can be collapsed                                                       |
| `remark-lint-no-unneeded-full-reference-link`   | remark-lint rule to check that full reference links can be collapsed                                                        |
| `remark-lint-no-unused-definitions`             | remark-lint rule to warn when unused definitions are found                                                                  |
| `remark-lint-ordered-list-marker-style`         | remark-lint rule to warn when the markers of ordered lists violate a given style                                            |
| `remark-lint-ordered-list-marker-value`         | remark-lint rule to check the marker value of ordered lists                                                                 |
| `remark-lint-rule-style`                        | remark-lint rule to warn when horizontal rules violate a given style                                                        |
| `remark-lint-strikethrough-marker`              | remark-lint rule to warn when strikethrough markers violate the given style                                                 |
| `remark-lint-strong-marker`                     | remark-lint rule to warn when importance (strong) markers violate the given style                                           |
| `remark-lint-table-cell-padding`                | remark-lint rule to warn when table cells are incorrectly padded                                                            |
| `remark-lint-table-pipe-alignment`              | remark-lint rule to warn when table pipes are not aligned                                                                   |
| `remark-lint-table-pipes`                       | remark-lint rule to warn when table rows are not fenced with pipes                                                          |
| `remark-lint-unordered-list-marker-style`       | remark-lint rule to warn when markers of unordered lists violate a given style                                              |
| `remark-parse`                                  | remark plugin to add support for parsing markdown input                                                                     |
| `remark-preset-lint-consistent`                 | remark preset to configure remark-lint with rules that enforce consistency                                                  |
| `remark-preset-lint-markdown-style-guide`       | remark preset to configure remark-lint with rules that enforce the markdown style guide                                     |
| `remark-preset-lint-recommended`                | remark preset to configure remark-lint with rules that prevent mistakes or stuff that fails across vendors.                 |
| `remark-stringify`                              | remark plugin to add support for serializing markdown                                                                       |
| `rust-analyzer-mcp`                             | Model Context Protocol (MCP) server that provides integration with rust-analyzer                                            |
| `salesforce-cli`                                | CLI for developing against the Salesforce Platform                                                                          |
| `sf-plugin-code-analyzer`                       | Salesforce Code Analyzer, a Salesforce CLI plugin for static analysis                                                       |
| `sfdx-git-delta`                                | Salesforce CLI plugin that generates a delta package from a git diff                                                        |
| `skopeo-nix2container`                          | Command line utility for various operations on container images and image repositories, with nix2container's nix: transport |
| `slackdump`                                     | Save or export your private and public Slack messages, threads, files, and users locally without admin privileges           |
| `terraform-plugin-codegen-framework`            | Terraform Plugin Framework Code Generation                                                                                  |
| `terraform-plugin-codegen-openapi`              | OpenAPI to Terraform Provider Code Generation Specification                                                                 |
| `terraform-provider-pfsense`                    | Used to configure pfSense firewall/router devices with Terraform                                                            |
| `unified-lint-rule`                             | unified plugin to make it a bit easier to create linting rules                                                              |
| `watchparty`                                    | Watch videos together with friends anywhere                                                                                 |

<!-- PACKAGES:END -->

## Usage

### Flake input

```nix
{
  inputs.mangopkgs.url = "github:unmango/pkgs";
}
```

### Install a package

```bash
nix run github:unmango/pkgs#kubectl-slice
nix shell github:unmango/pkgs#kube-vip
```

### Salesforce CLI plugins

`salesforce-cli.withPlugins` links plugins in as core plugins, so they come from
the store instead of `sf plugins install`'s mutable copy under
`$XDG_DATA_HOME/sf`.

```nix
pkgs.salesforce-cli.withPlugins [
  pkgs.sfdx-git-delta
  pkgs.sf-plugin-code-analyzer
]
```

### Overlay

```nix
{
  nixpkgs.overlays = [ inputs.mangopkgs.overlays.default ];
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
