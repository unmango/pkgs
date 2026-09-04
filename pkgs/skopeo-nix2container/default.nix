{
  lib,
  skopeo-nix2container,
}:
# Re-exported from the nix2container flake input rather than rebuilt from
# source. See pkgs/nix2container-bin for why.
#
# This is nixpkgs' skopeo with nix2container's nix: transport patch applied to
# its vendored container-libs, which is what `image.copyTo` and friends run.
skopeo-nix2container.overrideAttrs (old: {
  meta = old.meta // {
    description = "${old.meta.description}, with nix2container's nix: transport";
    maintainers = with lib.maintainers; [ UnstoppableMango ];
  };
})
