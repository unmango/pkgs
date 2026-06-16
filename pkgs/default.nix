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
      buildGoApplication = inputs'.gomod2nix.legacyPackages.buildGoApplication;
      nix2container = inputs'.nix2container.packages.nix2container;
      callPackage = lib.callPackageWith ({ inherit buildGoApplication nix2container; } // pkgs);
    in
    {
      packages = {
        aspire-cli = callPackage ./aspire-cli { };
        awxkit = callPackage ./awxkit { };
        chart-releaser = callPackage ./chart-releaser { };
        kube-vip = callPackage ./kube-vip { };
        kubectl-get-all = callPackage ./kubectl-get-all { };
        kubectl-get-resources = callPackage ./kubectl-get-resources { };
        kubectl-slice = callPackage ./kubectl-slice { };
        mmake = callPackage ./mmake { };
        openshift-installer = callPackage ./openshift-installer { };
        # smarter-device-manager: awaiting UnstoppableMango/smarter-device-manager fork with go.mod fix
        terraform-plugin-codegen-framework = callPackage ./terraform-plugin-codegen-framework { };
        terraform-plugin-codegen-openapi = callPackage ./terraform-plugin-codegen-openapi { };
        terraform-provider-pfsense = callPackage ./terraform-provider-pfsense { };

        hercules-ci-agent = pkgs.hercules-ci-agent.overrideAttrs (old: {
          passthru = (old.passthru or { }) // {
            image = callPackage ./images/hercules-ci-agent { };
          };
        });
        github-runner = pkgs.github-runner.overrideAttrs (old: {
          passthru = (old.passthru or { }) // {
            image = callPackage ./images/github-runner { };
          };
        });
      };

      overlayAttrs = {
        inherit (config.packages)
          aspire-cli
          awxkit
          chart-releaser
          kube-vip
          kubectl-get-all
          kubectl-get-resources
          kubectl-slice
          mmake
          openshift-installer
          terraform-plugin-codegen-framework
          terraform-plugin-codegen-openapi
          terraform-provider-pfsense
          hercules-ci-agent
          github-runner
          ;
      };
    };
}
