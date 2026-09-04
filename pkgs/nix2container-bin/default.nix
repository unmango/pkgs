{
  lib,
  buildGoApplication,
  fetchFromGitHub,
  mkUpdateDeps,
  stdenv,
}:
let
  # Tracks the nix2container flake input's rev so this repo's binary and the
  # `nix2container` library used by pkgs/images stay on the same source.
  # Upstream has tagged only v1.0.0 and builds every commit as "1.0.0"; the
  # unstable suffix keeps scripts/update.sh from bumping it to that tag.
  version = "1.0.0-unstable-2026-04-06";

  src = fetchFromGitHub {
    owner = "nlewo";
    repo = "nix2container";
    rev = "76be9608a7f4d6c985d28b0e7be903ae2547df3e";
    hash = "sha256-2lguQpLPQaxpQCJjXhmEEAfabwsAhkP29Z7fgLzHARA=";
  };
in
buildGoApplication {
  pname = "nix2container";
  inherit version src;

  modules = ./gomod2nix.toml;

  # The nix store's case hack renames colliding paths on case-insensitive
  # filesystems; the layer builder has to undo it to reproduce the original
  # names.
  ldflags = lib.optional stdenv.hostPlatform.isDarwin "-X github.com/nlewo/nix2container/nix.useNixCaseHack=true";

  passthru = {
    update-deps = mkUpdateDeps src;
    # No updateScript: the version tracks the nix2container flake input rather
    # than an upstream release.
  };

  meta = with lib; {
    description = "Build container images with Nix, without a Docker daemon or a tarball";
    homepage = "https://github.com/nlewo/nix2container";
    license = licenses.asl20;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "nix2container";
  };
}
