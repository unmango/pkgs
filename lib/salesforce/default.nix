{ pkgs }:
let
  callPackage = pkgs.lib.callPackageWith (packages // pkgs);

  packages = {
    mkSfPlugin = callPackage ./plugin.nix { };
    sfWithPlugins = callPackage ./with-plugins.nix { };
  };
in
packages
