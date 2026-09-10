{
  lib,
  nix2container-bin,
}:
# Re-exported from the nix2container flake input rather than rebuilt from
# source. Consumers get this exact store path from nix2container itself, so
# building the same derivation here is what puts it in the mangopkgs cache; a
# derivation of our own would produce a different path that nothing asks for.
#
# meta is not part of the derivation, so annotating it leaves the path alone.
# mainProgram is the exception: nixpkgs turns it into NIX_MAIN_PROGRAM in the
# build environment. It isn't needed here anyway, since the binary is named
# after pname.
nix2container-bin.overrideAttrs (old: {
  meta = (old.meta or { }) // {
    description = "Build container images with Nix, without a Docker daemon or a tarball";
    homepage = "https://github.com/nlewo/nix2container";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ UnstoppableMango ];
  };
})
