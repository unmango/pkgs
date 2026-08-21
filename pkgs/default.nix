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

      packages = {
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
        ocaml-protoc = ocamlPackages.callPackage ./ocaml-protoc { };
        ocaml-protoc-plugin = callPackage ./ocaml-protoc-plugin { };
        openshift-installer = callPackage ./openshift-installer { };
        pulumi-bun = callPackage ./pulumi-bun { };
        pulumi-dotnet = callPackage ./pulumi-dotnet { };
        pulumi-java = callPackage ./pulumi-java { };
        pulumi-yaml = callPackage ./pulumi-yaml { };
        rust-analyzer-mcp = callPackage ./rust-analyzer-mcp { };
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
