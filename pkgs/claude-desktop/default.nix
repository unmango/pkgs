{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  addDriverRunpath,
  makeWrapper,
  # DT_NEEDED of the main Electron ELF.
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libgbm,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  nspr,
  nss,
  pango,
  systemd, # libudev.so.1
  # DT_NEEDED of the bundled virtiofsd helper.
  libcap_ng,
  libseccomp,
  # dlopen'd by the Electron main process at runtime, so absent from DT_NEEDED.
  libGL,
  libayatana-appindicator,
  libnotify,
  libpulseaudio,
  libsecret,
  libuuid,
  libxtst,
  pciutils,
  pipewire,
  wayland,
}:
# Anthropic publishes Claude Desktop for Linux only as a .deb in its own apt
# repository, so this unpacks the official package rather than building from
# source. Derived from aaddrick/claude-desktop-debian's nix/claude-desktop.nix
# (MIT / Apache-2.0).
#
# To bump: read the newest version and both SHA-256 sums out of
# https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages
# and the binary-arm64 sibling, then move `version` and both hashes together.
let
  version = "1.46388.2";

  poolBase = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop";

  srcs = {
    x86_64-linux = {
      url = "${poolBase}/claude-desktop_${version}_amd64.deb";
      hash = "sha256-mL9U6F5JFgaMQoFFmw8EMdj/aANHc/PumDEdcgZWarE=";
    };
    aarch64-linux = {
      url = "${poolBase}/claude-desktop_${version}_arm64.deb";
      hash = "sha256-uUSiFUUogVu0dr+x5wkfij4ymzxn9sEd6NQWaKYDvZ4=";
    };
  };
in
stdenv.mkDerivation {
  pname = "claude-desktop";
  inherit version;

  # Falling back rather than throwing keeps the attrset evaluable on
  # aarch64-darwin, where `nix flake show` would otherwise abort. meta.platforms
  # is what actually excludes the unsupported systems.
  src = fetchurl (srcs.${stdenv.hostPlatform.system} or srcs.x86_64-linux);

  nativeBuildInputs = [
    addDriverRunpath
    autoPatchelfHook
    dpkg
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libcap_ng
    libgbm
    libseccomp
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    nspr
    nss
    pango
    stdenv.cc.cc.lib # libstdc++ for node-pty, libgcc_s
    systemd
  ];

  runtimeDependencies = map lib.getLib [
    libGL
    libayatana-appindicator
    libnotify
    libpulseaudio
    libsecret
    libuuid
    libxtst
    pciutils
    pipewire
    systemd
    wayland
  ];

  # Not `dpkg-deb -x`: chrome-sandbox is recorded SUID in data.tar and tar's
  # mode restore fails inside the build sandbox. --no-same-permissions applies
  # the umask instead, dropping a bit the store could not carry anyway.
  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --fsys-tarfile "$src" \
      | tar -x --no-same-owner --no-same-permissions
    runHook postUnpack
  '';

  dontConfigure = true;
  dontBuild = true;

  # The bundled ELFs are already stripped upstream.
  dontStrip = true;

  # The app tree is copied whole and the Electron ELF stays a real file, so
  # /proc/self/exe resolves inside this store path and process.resourcesPath is
  # correct by construction. Running it under nixpkgs' electron breaks both.
  #
  # Upstream's bin/claude-desktop is a relative symlink into that tree; a
  # wrapper execing the same in-tree ELF replaces it so the Vulkan ICD
  # directory can be added to the loader search. Chromium's bundled Vulkan
  # loader keys on the env var and fixed FHS paths, not DT_RUNPATH, and those
  # paths are empty on NixOS. VK_ADD_DRIVER_FILES is additive, so a user's own
  # setting still wins.
  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -a usr/lib usr/share $out/
    makeWrapper $out/lib/claude-desktop/claude-desktop \
      $out/bin/claude-desktop \
      --prefix VK_ADD_DRIVER_FILES : \
        "${addDriverRunpath.driverLink}/share/vulkan/icd.d"

    runHook postInstall
  '';

  # chrome-sandbox ships SUID upstream, which the store cannot represent. On
  # kernels with unprivileged user namespaces (the NixOS default) Chromium
  # prefers the namespace sandbox and never invokes the SUID helper, so it
  # ships 0755 and sandboxing is left on. Same stance as nixpkgs' slack.
  #
  # The search path resolves the co-located libffmpeg.so, libEGL.so,
  # libGLESv2.so, libvk_swiftshader.so and libvulkan.so.1 out of the output
  # tree itself.
  preFixup = ''
    addAutoPatchelfSearchPath "$out/lib/claude-desktop"
  '';

  # Chromium's bundled ANGLE dlopen()s the glvnd dispatcher libEGL.so.1 by bare
  # soname at GPU-init time. A dlopen resolves against the calling object's
  # runpath, and runtimeDependencies only patches executables, so the .so
  # issuing the call would never find it and the GPU process crash-loops.
  # Runpath rather than an LD_LIBRARY_PATH wrapper, so the driver libs stay out
  # of the environment of the MCP servers the app spawns.
  appendRunpaths = [
    "${lib.getLib libGL}/lib"
    "${addDriverRunpath.driverLink}/lib"
  ];

  meta = {
    description = "Desktop application for Claude.ai";
    homepage = "https://claude.ai";
    downloadPage = "https://downloads.claude.ai/claude-desktop/apt/stable";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ UnstoppableMango ];
    mainProgram = "claude-desktop";
    platforms = lib.attrNames srcs;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
