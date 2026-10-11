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
  buildInputs ? [ ],
  ...
}@args:
stdenv.mkDerivation (
  removeAttrs args [
    "description"
    "paths"
    "exclude"
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

      runHook postInstall
    '';

    meta = rootfs.meta // {
      inherit description;
    };
  }
)
