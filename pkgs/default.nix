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
        inherit (pkgs.callPackage ../lib/salesforce { }) mkSfPlugin sfWithPlugins;
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
        java-jdtls-mcp-server = callPackage ./java-jdtls-mcp-server { };
        jdtls-mcp = callPackage ./jdtls-mcp { };
        kube-vip = callPackage ./kube-vip { };
        kubectl-get-all = callPackage ./kubectl-get-all { };
        kubectl-get-resources = callPackage ./kubectl-get-resources { };
        kubectl-slice = callPackage ./kubectl-slice { };
        kubernetes-mcp-server = callPackage ./kubernetes-mcp-server { };
        likec4 = callPackage ./likec4 { };
        lsmcp = callPackage ./lsmcp { };
        lsp4j-mcp = callPackage ./lsp4j-mcp { };
        mmake = callPackage ./mmake { };
        nix2container-bin = callPackage ./nix2container-bin {
          inherit (inputs'.nix2container.packages) nix2container-bin;
        };
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
        sf-plugin-code-analyzer = callPackage ./sf-plugin-code-analyzer { };
        sfdx-git-delta = callPackage ./sfdx-git-delta { };
        skopeo-nix2container = callPackage ./skopeo-nix2container {
          inherit (inputs'.nix2container.packages) skopeo-nix2container;
        };
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

      # Unfree, prebuilt vendor binaries. Held out of `packages` because `make
      # build` builds every attr of packages.<system> and CI pushes the results
      # to the public caches, which would redistribute the vendor's binary.
      # Reachable as legacyPackages.<system>.<name> and through overlays.default.
      unfreePackages = {
        claude-desktop = callPackage ./claude-desktop { };
        # Not in nixpkgs, so callPackage can't fill claude-desktop in itself.
        claude-desktop-fhs = callPackage ./claude-desktop/fhs.nix {
          inherit (unfreePackages) claude-desktop;
        };
        coderabbit = callPackage ./coderabbit { };
      };
    in
    {
      packages = lib.filterAttrs (_: pkg: pkg.meta.available or true) packages;

      legacyPackages = (lib.filterAttrs (_: pkg: pkg.meta.available or true) unfreePackages) // {
        packagesTable = import ../lib/packages.nix (packages // unfreePackages);
      };

      overlayAttrs =
        packages
        // unfreePackages
        // {
          # A drop-in skopeo that also understands nix2container's `nix:`
          # transport, so overlay consumers get it without opting in per-call.
          skopeo = packages.skopeo-nix2container;

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
