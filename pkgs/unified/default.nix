# The unified.js package set (remark, rehype, retext, MDX and their plugins):
# one derivation per npm package, built from source. Extend it with
# `overrideScope`; plugins are passed to `withPlugins` as derivations.
{ lib, newScope }:
lib.makeScope newScope (
  self:
  let
    # One fetch and one lockfile for the whole remarkjs/remark monorepo.
    remarkPackages = self.callPackage ./remark { unifiedPackages = self; };
  in
  {
    buildUnifiedWorkspace = self.callPackage ./build-unified-workspace.nix { };
    wrapUnifiedCli = self.callPackage ./wrap-unified-cli.nix { };

    inherit (remarkPackages)
      remark
      remark-cli
      remark-parse
      remark-stringify
      ;

    remark-gfm = self.callPackage ./remark-gfm { };
  }
)
