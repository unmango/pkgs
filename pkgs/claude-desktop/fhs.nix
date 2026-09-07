{
  lib,
  stdenv,
  runCommand,
  buildFHSEnv,
  claude-desktop,
  bubblewrap,
  docker,
  docker-compose,
  glibc,
  nodejs,
  openssl,
  uv,
  OVMF,
  qemu_kvm,
  virtiofsd,
}:
# Claude Desktop runs against a pure store path with no FHS layout under it,
# which breaks the MCP servers it spawns (they expect node, uv and openssl on a
# normal filesystem) and Cowork's VM launcher, which probes hardcoded absolute
# paths with no env override. This wraps the same app in an FHS sandbox that
# satisfies both. Derived from aaddrick/claude-desktop-debian's nix/fhs.nix
# (MIT / Apache-2.0).
let
  # Cowork looks for firmware at /usr/share/OVMF/OVMF_CODE_4M.fd or
  # /usr/share/OVMF/OVMF_CODE.fd on x86_64 and /usr/share/AAVMF/AAVMF_CODE.fd
  # on aarch64, then derives the writable variable-store template beside it by
  # renaming _CODE to _VARS. coworkd aborts with "no EFI variable-store template
  # configured" when that sibling is absent, so both halves of the pair have to
  # be here; a distro's edk2 package supplies VARS on its own, but on Nix this
  # shim is the only source.
  #
  # nixpkgs lands firmware under ${OVMF.fd}/FV with nothing in share/, so a bare
  # OVMF in targetPkgs never satisfies the probe. Linking into share/ puts it at
  # /usr/share inside the env. OVMF.firmware and OVMF.variables already resolve
  # the OVMF_ vs AAVMF_ prefix for the host platform.
  ovmfCompat =
    let
      link = src: dst: ''
        [[ -e ${src} ]] || {
          echo "ovmfCompat: ${src} missing; the nixpkgs OVMF layout changed" >&2
          exit 1
        }
        mkdir -p "$(dirname "$out/share/${dst}")"
        ln -s ${src} "$out/share/${dst}"
      '';
      # x86_64 aliases both Debian firmware names onto the one nixpkgs build.
      pairs =
        if stdenv.hostPlatform.isx86_64 then
          [
            (link OVMF.firmware "OVMF/OVMF_CODE.fd")
            (link OVMF.firmware "OVMF/OVMF_CODE_4M.fd")
            (link OVMF.variables "OVMF/OVMF_VARS.fd")
            (link OVMF.variables "OVMF/OVMF_VARS_4M.fd")
          ]
        else
          [
            (link OVMF.firmware "AAVMF/AAVMF_CODE.fd")
            (link OVMF.variables "AAVMF/AAVMF_VARS.fd")
          ];
    in
    runCommand "claude-desktop-ovmf-compat" { } (lib.concatStrings pairs);
in
buildFHSEnv {
  # Keeps bin/claude-desktop, which the .desktop file's `Exec=claude-desktop %U`
  # resolves from PATH, and which allowUnfreePredicate in flake.nix keys on.
  name = "claude-desktop";

  # qemu_kvm rather than qemu: the host-cpu-only build ships exactly the one
  # qemu-system-* binary Cowork searches PATH for, at a fraction of the closure.
  #
  # virtiofsd is a separate gate. Cowork probes /usr/libexec/virtiofsd then
  # /usr/bin/virtiofsd, and only falls back to its bundled copy on Ubuntu 22.
  # nixpkgs' virtiofsd installs to bin/virtiofsd, which buildFHSEnv surfaces at
  # the second probe path, so the gate resolves without patching the app.
  targetPkgs = _: [
    bubblewrap
    claude-desktop
    docker
    docker-compose
    glibc
    nodejs
    openssl
    ovmfCompat
    qemu_kvm
    uv
    virtiofsd
  ];

  runScript = "${claude-desktop}/bin/claude-desktop";

  extraInstallCommands = ''
    mkdir -p $out/share/applications $out/share/icons
    cp ${claude-desktop}/share/applications/* $out/share/applications/
    cp -r ${claude-desktop}/share/icons/* $out/share/icons/
  '';

  # /dev/kvm and /dev/vhost-vsock are reachable inside the env (buildFHSEnv
  # bind-mounts all of /dev), but the host must still add the user to the kvm
  # group and load the vhost_vsock module before Cowork can boot a VM. Neither
  # is something a package can arrange.
  meta = claude-desktop.meta // {
    description = "Desktop application for Claude.ai, in an FHS environment for MCP servers and Cowork";
  };
}
