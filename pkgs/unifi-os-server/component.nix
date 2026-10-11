{
  lib,
  stdenv,
  autoPatchelfHook,
  rootfs,
}:

# One UniFi OS Server service, cut out of the root filesystem.
#
# Files keep their FHS paths under $out (usr/lib/ulp-go, usr/sbin/ulp-go-app, ...)
# because the vendor's scripts and configs name them absolutely, so an image
# copies a component to / unchanged.
{
  pname,
  description,
  # Paths relative to the root filesystem. A missing path fails the build.
  paths,
  # Paths removed from $out after the copy, e.g. native libraries for other platforms.
  exclude ? [ ],
  # systemd units the service runs as, e.g. "unifi-core.service". Each is
  # installed with its drop-ins under usr/lib/systemd/system, wherever the
  # image put them, for notsystemd to run.
  units ? [ ],
  buildInputs ? [ ],
  ...
}@args:
stdenv.mkDerivation (
  removeAttrs args [
    "description"
    "paths"
    "exclude"
    "units"
  ]
  // {
    inherit pname;
    inherit (rootfs) version;

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;
    # Keep a top-level sbin (/sbin/uos-rabbitmq-gen-certs-wrapper) where the vendor put it.
    dontMoveSbin = true;

    nativeBuildInputs = [ autoPatchelfHook ] ++ args.nativeBuildInputs or [ ];
    buildInputs = [ stdenv.cc.cc.lib ] ++ buildInputs;

    installPhase = ''
      runHook preInstall

      for path in ${lib.escapeShellArgs paths}; do
        mkdir -p "$out/$(dirname "$path")"
        cp -a --no-preserve=ownership "${rootfs}/$path" "$out/$path"
      done
      chmod -R u+w "$out"

      for path in ${lib.escapeShellArgs exclude}; do
        rm -rf "$out/$path"
      done

      # Debian ships units in /lib or /usr/lib and local overrides in /etc.
      # The unit file comes from the first of /etc, /lib, /usr/lib that has
      # it, as systemd picks it; drop-ins are gathered from all three, /etc
      # last so it wins on a shared file name. /lib is skipped when it is
      # the merged-usr symlink, which would find everything twice.
      # resolve follows a symlink inside the root filesystem, since an
      # absolute target such as an Alias= link's names the image's /lib,
      # not the build host's.
      resolve() {
        local path=$1 target
        while [ -L "$path" ]; do
          target=$(readlink "$path")
          case "$target" in
            /*) path=${rootfs}$target ;;
            *) path=$(dirname "$path")/$target ;;
          esac
        done
        echo "$path"
      }
      units=$out/usr/lib/systemd/system
      for unit in ${lib.escapeShellArgs units}; do
        found=
        for dir in etc lib usr/lib; do
          [ "$dir" = lib ] && [ -L "${rootfs}/lib" ] && continue
          file=$(resolve "${rootfs}/$dir/systemd/system/$unit")
          if [ -f "$file" ]; then
            install -Dm644 "$file" "$units/$unit"
            found=1
            break
          fi
        done
        if [ -z "$found" ]; then
          echo "unit $unit not found in the root filesystem" >&2
          exit 1
        fi
        for dir in usr/lib lib etc; do
          [ "$dir" = lib ] && [ -L "${rootfs}/lib" ] && continue
          for conf in ${rootfs}/$dir/systemd/system/$unit.d/*.conf; do
            [ -e "$conf" ] || continue
            mkdir -p "$units/$unit.d"
            cp --no-preserve=ownership,mode "$conf" "$units/$unit.d/"
          done
        done
      done

      runHook postInstall
    '';

    passthru = {
      # Where each unit lands, for an image's `notsystemd run` entrypoint.
      unitFiles = lib.genAttrs units (unit: "/usr/lib/systemd/system/${unit}");
    }
    // args.passthru or { };

    meta = rootfs.meta // {
      inherit description;
    };
  }
)
