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
      # Gather each into one place, /etc drop-ins last so they win on a
      # shared file name as they would under systemd. /lib is skipped when
      # it is the merged-usr symlink, which would find everything twice.
      units=$out/usr/lib/systemd/system
      for unit in ${lib.escapeShellArgs units}; do
        found=
        for dir in usr/lib lib etc; do
          [ "$dir" = lib ] && [ -L "${rootfs}/lib" ] && continue
          src=${rootfs}/$dir/systemd/system
          if [ -e "$src/$unit" ] && [ -z "$found" ]; then
            install -Dm644 "$src/$unit" "$units/$unit"
            found=1
          fi
          if [ -d "$src/$unit.d" ]; then
            mkdir -p "$units/$unit.d"
            cp --no-preserve=ownership,mode "$src/$unit.d"/*.conf "$units/$unit.d/"
          fi
        done
        if [ -z "$found" ]; then
          echo "unit $unit not found in the root filesystem" >&2
          exit 1
        fi
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
