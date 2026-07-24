{
  perSystem =
    {
      inputs',
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (inputs'.gomod2nix.legacyPackages) buildGoApplication;
      inherit (inputs'.nix2container.packages) nix2container;
      inherit (pkgs.callPackage ../lib/go { }) mkUpdateDeps;

      callPackage = lib.callPackageWith (
        { inherit buildGoApplication nix2container mkUpdateDeps; } // pkgs
      );
    in
    {
      packages = lib.filterAttrs (_: pkg: pkg.meta.available or true) {
        aspire-cli = callPackage ./aspire-cli { };
        awxkit = callPackage ./awxkit { };
        chart-releaser = callPackage ./chart-releaser { };
        kube-vip = callPackage ./kube-vip { };
        kubectl-get-all = callPackage ./kubectl-get-all { };
        kubectl-get-resources = callPackage ./kubectl-get-resources { };
        kubectl-slice = callPackage ./kubectl-slice { };
        mmake = callPackage ./mmake { };
        oc-mirror = callPackage ./oc-mirror { };
        pbrt = callPackage ./pbrt { };
        ocaml-protoc = callPackage ./ocaml-protoc { inherit (config.packages) pbrt; };
        ocaml-protoc-plugin = callPackage ./ocaml-protoc-plugin { };
        openshift-installer = callPackage ./openshift-installer { };
        pulumi-bun = callPackage ./pulumi-bun { };
        pulumi-dotnet = callPackage ./pulumi-dotnet { };
        pulumi-java = callPackage ./pulumi-java { };
        pulumi-yaml = callPackage ./pulumi-yaml { };
        # smarter-device-manager: awaiting UnstoppableMango/smarter-device-manager fork with go.mod fix
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

      legacyPackages.packagesTable = import ../lib/packages.nix config.packages;

      overlayAttrs = config.packages // {
        # Extends nixpkgs' pulumiPackages package set (pulumi-go, pulumi-nodejs,
        # pulumi-python) with officially-supported language plugins nixpkgs doesn't
        # package because they live outside the pulumi/pulumi repo. Merges onto
        # pkgs.pulumiPackages so overlays.default doesn't clobber nixpkgs' entries.
        pulumiPackages = pkgs.pulumiPackages // {
          inherit (config.packages)
            pulumi-bun
            pulumi-dotnet
            pulumi-java
            pulumi-yaml
            ;
        };
      };
    };
}
