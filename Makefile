GO_PKGS := chart-releaser kube-vip kubectl-get-all kubectl-get-resources kubectl-slice mmake openshift-installer pulumi-bun pulumi-dotnet pulumi-java pulumi-yaml terraform-plugin-codegen-framework terraform-plugin-codegen-openapi terraform-provider-pfsense

build:
	nix build --no-link \
		.#aspire-cli \
		.#awxkit \
		.#chart-releaser \
		.#kube-vip \
		.#kubectl-get-all \
		.#kubectl-get-resources \
		.#kubectl-slice \
		.#mmake \
		.#openshift-installer \
		.#pulumi-bun \
		.#pulumi-dotnet \
		.#pulumi-java \
		.#pulumi-yaml \
		.#terraform-plugin-codegen-framework \
		.#terraform-plugin-codegen-openapi \
		.#terraform-provider-pfsense \
		.#hercules-ci-agent.image \
		.#github-runner.image

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
