{
  lib,
  stdenvNoCC,
  fetchzip,
  writeText,
  makeDesktopItem,
  copyDesktopItems,
  nix-update-script,
  jq,
  runtimeShell,
  mono,
  gnome-themes-extra,
  gtk2-x11,
  libgdiplus,
  libGL,
  lua5_4,
  openal,
  SDL2,
  udev,
  zstd,
}:
let
  version = "2.11.1";

  # What upstream's own Nix expression (Dist/packages.nix) puts on
  # LD_LIBRARY_PATH for a NixOS build: libGL stands in for the nixGL wrapper it
  # uses everywhere else.
  runtimeLibs = [
    (lib.getLib gtk2-x11)
    (lib.getLib libgdiplus)
    lua5_4
    mono
    openal
    (lib.getLib zstd)
    SDL2
    (lib.getLib udev)
    (lib.getLib libGL)
  ];

  # EmuHawk reads its paths from config.json; the base path is the per-user
  # data directory, filled in by the launcher on first run.
  initConfig = writeText "emuhawk-config.json" (
    builtins.toJSON {
      LastWrittenFrom = version;
      PathEntries.Paths = [
        {
          System = "Global_NULL";
          Type = "Base";
          Path = null;
        }
      ];
    }
  );
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "bizhawk";
  inherit version;

  # The release artifact rather than a source build: upstream builds it with
  # .NET 8 plus a handful of vendored managed and native dependencies, and the
  # Linux tarball is that same build.
  src = fetchzip {
    url = "https://github.com/TASEmulators/BizHawk/releases/download/${finalAttrs.version}/BizHawk-${finalAttrs.version}-linux-x64.tar.gz";
    hash = "sha256-EhsX2AtNbzjRlpf5OdwZOkRQmGevgC1x0bSI0X6A3w8=";
  };

  nativeBuildInputs = [ copyDesktopItems ];

  # The bundled native cores load through LD_LIBRARY_PATH under mono, as
  # upstream's launcher arranges, so they are left as shipped.
  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    # The immutable half (assemblies, cores, gamedb, shaders) stays in the
    # store, and BIZHAWK_HOME points there.
    mkdir -p $out/lib/bizhawk
    mv -t $out/lib/bizhawk defctrl.json DiscoHawk.exe* dll EmuHawk.exe* gamedb Shaders
    printf NixHawk >$out/lib/bizhawk/dll/custombuild.txt

    # Everything else (Lua scripts, palettes, overlays) is user-editable, so
    # the launcher copies it into the data directory on first run.
    rm EmuHawkMono.sh
    rmdir Firmware ExternalTools
    mkdir -p $out/share/bizhawk
    cp -r . $out/share/bizhawk

    mkdir -p $out/bin
    cat >$out/bin/emuhawk <<'EOF'
    #!${runtimeShell}
    set -e
    export BIZHAWK_HOME="@out@/lib/bizhawk"
    export BIZHAWK_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}/emuhawk-monort-${finalAttrs.version}"
    if [ ! -e "$BIZHAWK_DATA_HOME" ]; then
      # Staged and moved into place, so a failed copy is retried next launch.
      staging="$BIZHAWK_DATA_HOME.tmp.$$"
      rm -rf "$staging"
      mkdir -p "$staging/Firmware" "$staging/ExternalTools"
      cp -rT --no-preserve=mode "@out@/share/bizhawk" "$staging"
      mv -T "$staging" "$BIZHAWK_DATA_HOME"
    fi
    # Absolute paths rather than a cd, so ROM paths given relative to the
    # caller's directory still resolve.
    config="$BIZHAWK_DATA_HOME/config.json"
    if [ ! -e "$config" ]; then
      '${lib.getExe jq}' --arg base "$BIZHAWK_DATA_HOME" '.PathEntries.Paths[0].Path = $base' '${initConfig}' >"$config.tmp"
      mv "$config.tmp" "$config"
    fi
    export BIZHAWK_INT_SYSLIB_PATH="$BIZHAWK_HOME/dll"
    export LD_LIBRARY_PATH="''${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$BIZHAWK_INT_SYSLIB_PATH:${lib.makeLibraryPath runtimeLibs}"
    export GTK_PATH="${gnome-themes-extra}/lib/gtk-2.0''${GTK_PATH:+:$GTK_PATH}"
    export MONO_CRASH_NOFILE=1
    # https://github.com/TASEmulators/BizHawk/issues/1595
    export MONO_WINFORMS_XIM_STYLE=disabled
    exec '${lib.getExe' mono "mono"}' "$BIZHAWK_HOME/EmuHawk.exe" --config="$config" "$@"
    EOF
    substituteInPlace $out/bin/emuhawk --replace-fail @out@ $out
    chmod +x $out/bin/emuhawk

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "emuhawk";
      desktopName = "EmuHawk";
      comment = finalAttrs.meta.description;
      exec = "emuhawk %f";
      categories = [
        "Game"
        "Emulator"
      ];
    })
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Multi-system emulator front-end with recording, playback, and debugging tools for tool-assisted speedruns";
    homepage = "https://github.com/TASEmulators/BizHawk";
    changelog = "https://tasvideos.org/BizHawk/ReleaseHistory";
    # MIT for BizHawk's own code; the bundled cores carry their own licenses,
    # GPL-3.0 among them.
    license = with lib.licenses; [
      mit
      gpl3Plus
    ];
    maintainers = with lib.maintainers; [ UnstoppableMango ];
    mainProgram = "emuhawk";
    # Upstream publishes a Linux x86_64 build only.
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [
      binaryBytecode
      binaryNativeCode
    ];
  };
})
