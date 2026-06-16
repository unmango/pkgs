build:
	nix build \
		.#aspire-cli \
		.#awxkit \
		.#chart-releaser \
		.#kube-vip \
		.#kubectl-get-all \
		.#kubectl-get-resources \
		.#kubectl-slice \
		.#mmake \
		.#openshift-installer \
		.#terraform-plugin-codegen-framework \
		.#terraform-plugin-codegen-openapi \
		.#terraform-provider-pfsense \
		.#hercules-ci-agent.image \
		.#github-runner.image

update:
	nix flake update

check lint:
	nix flake check

format fmt:
	nix fmt

generate gen:
	${CURDIR}/scripts/gen-packages-table.sh
	${CURDIR}/scripts/gen-package-count-badge.sh
