{
  lib,
  stdenvNoCC,
  callPackage,
  fetchurl,
  unzip,
  jq,
  libarchive,
}:
let
  version = "5.1.42";

  # Ubiquiti publishes UniFi OS Server only as a self-extracting installer: an
  # ELF with a zip appended, whose image.tar is the OCI image the installer
  # runs under podman. There is no index to read a version from, so bump
  # `version`, both URLs and both hashes together, from the download page at
  # https://ui.com/download/software/unifi-os-server.
  releases = {
    x86_64-linux = {
      url = "https://fw-download.ubnt.com/data/unifi-os-server/5172-linux-x64-5.1.42-12e9e3cf-8f8b-4e54-928c-76b80a10c8a4.42-x64";
      hash = "sha256-9hEek5akLHQBb13emwH770hqb+ae/hN5Nebji3wi+U0=";
    };
    aarch64-linux = {
      url = "https://fw-download.ubnt.com/data/unifi-os-server/f730-linux-arm64-5.1.42-d2bca8bd-d6fc-4d20-99e5-b78235843c2f.42-arm64";
      hash = "sha256-jim9UM3o94Gs5LhVmSVu9iwCcjvcdRBE1NuQoIf7Ugc=";
    };
  };

  inherit (stdenvNoCC.hostPlatform) system;

  release =
    releases.${system}
      or (throw "unifi-os-server: no upstream installer for ${system} (x86_64-linux and aarch64-linux only)");
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "unifi-os-server";
  inherit version;

  src = fetchurl {
    inherit (release) url hash;
  };

  nativeBuildInputs = [
    unzip
    jq
    libarchive
  ];

  dontUnpack = true;

  buildPhase = ''
    runHook preBuild

    # unzip finds the archive behind the ELF stub and warns about the leading
    # bytes, which it reports as exit status 1. Its entries carry mode 0000.
    unzip -q "$src" image.tar -d installer || [ $? -eq 1 ]
    chmod u+r installer/image.tar

    mkdir layout
    tar -xf installer/image.tar -C layout
    rm -r installer

    # Apply the layers by hand rather than with umoci: it sets the setuid bits
    # the image carries even when rootless, which the build sandbox refuses.
    # bsdtar without -p drops them, and needs a UTF-8 locale for the paths.
    export LC_ALL=C.UTF-8
    blob() { echo "layout/blobs/''${1/://}"; }
    manifest=$(blob "$(jq -r '.manifests[0].digest' layout/index.json)")

    mkdir rootfs
    for digest in $(jq -r '.layers[].digest' "$manifest"); do
      layer=$(blob "$digest")

      # Whiteouts delete what lower layers put there.
      bsdtar -tf "$layer" | { grep -E '(^|/)\.wh\.' || true; } | while IFS= read -r wh; do
        dir=rootfs/$(dirname "$wh")
        name=$(basename "$wh")
        if [ "$name" = .wh..wh..opq ]; then
          find "$dir" -mindepth 1 -delete
        else
          rm -rf "$dir/''${name#.wh.}"
        fi
      done

      bsdtar -xf "$layer" -C rootfs --exclude '.wh.*'
    done
    rm -r layout

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mv rootfs $out
    runHook postInstall
  '';

  # A whole Debian userland: patching or stripping it is wasted work, and the
  # components patch what they take.
  dontFixup = true;

  passthru =
    let
      mkComponent = callPackage ./component.nix { rootfs = finalAttrs.finalPackage; };
    in
    callPackage ./components.nix { inherit mkComponent; };

  meta = {
    description = "UniFi OS Server root filesystem, unpacked from Ubiquiti's installer";
    homepage = "https://ui.com/download/software/unifi-os-server";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ UnstoppableMango ];
    platforms = lib.attrNames releases;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
