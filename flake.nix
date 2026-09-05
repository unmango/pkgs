{
  description = "Mini-nixpkgs of dubious quality";

  nixConfig = {
    extra-substituters = [
      "https://mangopkgs.cachix.org"
    ];
    extra-trusted-public-keys = [
      "mangopkgs.cachix.org-1:uJ5FgSbOg1uiXLcL0gBh1lO+y3KVuthy6UeOFYR1fLk="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/triplet";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    gomod2nix = {
      url = "github:nix-community/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.inputs.systems.follows = "systems";
    };

    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      imports = with inputs; [
        treefmt-nix.flakeModule
        flake-parts.flakeModules.easyOverlay
        ./pkgs
      ];

      perSystem =
        { pkgs, system, ... }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config = {
              # `meta.available` is false for an unfree package unless it is
              # allowed here, and `packages` filters on that, so an unfree
              # package would otherwise be silently dropped from the flake.
              allowUnfreePredicate =
                pkg:
                builtins.elem (inputs.nixpkgs.lib.getName pkg) [
                  "coderabbit"
                ];
            };
            overlays = [
              inputs.gomod2nix.overlays.default
              (_: prev: {
                lib = prev.lib.extend (
                  _: lprev: {
                    maintainers = lprev.maintainers // (import ./lib/maintainers.nix);
                  }
                );
              })
            ];
          };

          devShells.default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              gh
              gnumake
              gomod2nix
              jq
              nix-update
              nixfmt
            ];
          };

          treefmt.programs = {
            actionlint.enable = true;
            deadnix.enable = true;
            nixfmt.enable = true;
            prettier.enable = true;
            shfmt.enable = true;
            statix.enable = true;
          };
        };
    };
}
