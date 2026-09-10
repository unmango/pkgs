{ pkgs }:
let
  callPackage = pkgs.lib.callPackageWith (packages // pkgs);

  packages = {
    mkUpdateDeps = src: callPackage ./update-deps.nix { inherit src; };
  };
in
packages
