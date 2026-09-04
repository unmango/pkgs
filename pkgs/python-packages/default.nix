# Python libraries that CumulusCI depends on and nixpkgs doesn't carry.
# Applied as a python package-set extension so `pkgs/default.nix` can build an
# interpreter that has them, and so `overlays.default` can offer them for every
# interpreter via `pythonPackagesExtensions`.
final: prev: {
  # Override rather than a fresh derivation; see the file for why.
  annoy = final.callPackage ./annoy { inherit (prev) annoy; };
  faker-edu = final.callPackage ./faker-edu { };
  faker-nonprofit = final.callPackage ./faker-nonprofit { };
  gvgen = final.callPackage ./gvgen { };
  robotframework-pabot = final.callPackage ./robotframework-pabot { };
  salesforce-bulk = final.callPackage ./salesforce-bulk { };
  snowfakery = final.callPackage ./snowfakery { };
}
