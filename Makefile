GO_PKGS := chart-releaser kube-vip kubectl-get-all kubectl-get-resources kubectl-slice mmake openshift-installer terraform-plugin-codegen-framework terraform-plugin-codegen-openapi terraform-provider-pfsense

build:
	nix build --no-link $$($(CURDIR)/scripts/list-build-targets.sh | sed 's/^/.#/' | tr '\n' ' ')

update:
	nix flake update

deps: ${GO_PKGS:%=pkgs/%/gomod2nix.toml}

pkgs/%/gomod2nix.toml: pkgs/%/default.nix
	nix run .#$*.update-deps ${CURDIR}/$@

check lint:
	nix flake check

format fmt:
	nix fmt

generate gen:
	${CURDIR}/scripts/gen-packages-table.sh
	${CURDIR}/scripts/gen-package-count-badge.sh
	nix fmt
