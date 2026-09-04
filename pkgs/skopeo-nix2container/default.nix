{
  lib,
  nix2container-bin,
  skopeo,
  stdenv,
}:
skopeo.overrideAttrs (old: {
  pname = "skopeo-nix2container";

  # The nix store's case hack renames colliding paths on case-insensitive
  # filesystems; the nix transport has to undo it to find the original store
  # paths.
  EXTRA_LDFLAGS = lib.optionalString stdenv.hostPlatform.isDarwin "-X github.com/nlewo/nix2container/nix.useNixCaseHack=true";

  # Teaches skopeo the `nix:` transport so it can read a nix2container image
  # description straight out of the store. The patch adds
  # go.podman.io/image/v5/nix and registers it with alltransports, which means
  # it has to be applied to skopeo's in-tree vendor directory, and nix2container
  # itself has to be vendored alongside it.
  preBuild = ''
    mkdir -p vendor/github.com/nlewo/nix2container/
    cp -r ${nix2container-bin.src}/* vendor/github.com/nlewo/nix2container/

    pushd vendor/go.podman.io/image/v5
    mkdir -p nix
    touch nix/transport.go
    patch -p2 <${./nix.patch}
    popd

    # Go rejects vendored packages that modules.txt doesn't declare, and every
    # package in modules.txt must also be required by go.mod.
    {
      echo '# github.com/nlewo/nix2container v1.0.0'
      echo '## explicit; go 1.13'
      echo 'github.com/nlewo/nix2container/nix'
      echo 'github.com/nlewo/nix2container/types'
      echo 'go.podman.io/image/v5/nix'
    } >>vendor/modules.txt

    {
      echo 'require ('
      echo '  github.com/nlewo/nix2container v1.0.0'
      echo ')'
    } >>go.mod
  '';

  meta = old.meta // {
    description = "${old.meta.description}, patched with nix2container's nix: transport";
    maintainers = with lib.maintainers; [ UnstoppableMango ];
  };
})
