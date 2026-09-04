{
  perSystem =
    {
      inputs',
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs) ocamlPackages pulumiPackages;

      tools = {
        inherit (inputs'.nix2container.packages) nix2container;
        inherit (inputs'.gomod2nix.legacyPackages) buildGoApplication;
        inherit (pkgs.callPackage ../lib/go { }) mkUpdateDeps;
      };

      callPackage = lib.callPackageWith (tools // pkgs);

      # Libraries missing from nixpkgs that CumulusCI needs.
      pythonOverrides = import ./python-packages;

      # CumulusCI requires python <3.14, so it can't ride the default interpreter.
      python313 = pkgs.python313.override {
        self = python313;
        packageOverrides = pythonOverrides;
      };

      packages = {
        aspire-cli = callPackage ./aspire-cli { };
        awxkit = callPackage ./awxkit { };
        chart-releaser = callPackage ./chart-releaser { };
        cumulusci = callPackage ./cumulusci { python313Packages = python313.pkgs; };
        gitlab-operator = callPackage ./gitlab-operator { };
        gitlab-operator-v2 =
          let
            pkg = callPackage ./gitlab-operator-v2 { };
          in
          pkg.overrideAttrs (old: {
            passthru = (old.passthru or { }) // {
              image = callPackage ./images/gitlab-operator-v2 { gitlab-operator-v2 = pkg; };
            };
          });
        kube-vip = callPackage ./kube-vip { };
        kubectl-get-all = callPackage ./kubectl-get-all { };
        kubectl-get-resources = callPackage ./kubectl-get-resources { };
        kubectl-slice = callPackage ./kubectl-slice { };
        kubernetes-mcp-server = callPackage ./kubernetes-mcp-server { };
        lsmcp = callPackage ./lsmcp { };
        mmake = callPackage ./mmake { };
        oc-mirror = callPackage ./oc-mirror { };
        opencommit = callPackage ./opencommit { };
        pbrt = callPackage ./pbrt { };
        ocaml-protoc = ocamlPackages.callPackage ./ocaml-protoc { };
        ocaml-protoc-plugin = callPackage ./ocaml-protoc-plugin { };
        openshift-installer = callPackage ./openshift-installer { };
        podman-mcp-server = callPackage ./podman-mcp-server { };
        pulumi-bun = callPackage ./pulumi-bun { };
        pulumi-dotnet = callPackage ./pulumi-dotnet { };
        pulumi-java = callPackage ./pulumi-java { };
        pulumi-yaml = callPackage ./pulumi-yaml { };
        rust-analyzer-mcp = callPackage ./rust-analyzer-mcp { };
        salesforce-cli = callPackage ./salesforce-cli { };
        # smarter-device-manager: awaiting UnstoppableMango/smarter-device-manager fork with go.mod fix
        slackdump = callPackage ./slackdump { };
        terraform-plugin-codegen-framework = callPackage ./terraform-plugin-codegen-framework { };
        terraform-plugin-codegen-openapi = callPackage ./terraform-plugin-codegen-openapi { };
        terraform-provider-pfsense = callPackage ./terraform-provider-pfsense { };

        hercules-ci-agent = pkgs.hercules-ci-agent.overrideAttrs (old: {
          passthru = (old.passthru or { }) // {
            image = callPackage ./images/hercules-ci-agent { };
          };
        });
        gossamer = callPackage ./gossamer { };

        github-runner = pkgs.github-runner.overrideAttrs (old: {
          passthru = (old.passthru or { }) // {
            image = callPackage ./images/github-runner { };
          };
        });
      };
    in
    {
      packages = lib.filterAttrs (_: pkg: pkg.meta.available or true) packages;

      legacyPackages = {
        packagesTable = import ../lib/packages.nix packages;
      };

      overlayAttrs = packages // {
        pythonPackagesExtensions = pkgs.pythonPackagesExtensions ++ [ pythonOverrides ];

        pulumiPackages = pulumiPackages // {
          inherit (packages)
            pulumi-bun
            pulumi-dotnet
            pulumi-java
            pulumi-yaml
            ;
        };
      };
    };
}
