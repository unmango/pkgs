{
  lib,
  stdenvNoCC,
  callPackage,
  fetchurl,
  unzip,
  skopeo,
  umoci,
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
    skopeo
    umoci
  ];

  dontUnpack = true;

  buildPhase = ''
    runHook preBuild

    # unzip finds the archive behind the ELF stub and warns about the leading
    # bytes, which it reports as exit status 1.
    unzip -q "$src" image.tar -d installer || [ $? -eq 1 ]

    mkdir layout
    tar -xf installer/image.tar -C layout
    rm -r installer

    # The layout's one manifest is Docker v2 schema 2, which umoci refuses.
    export HOME=$TMPDIR
    skopeo --insecure-policy copy --format oci oci:layout oci:image:uos
    rm -r layout

    # Rootless: ownership is not representable in the store, and the image's
    # device nodes are skipped. The components take files from here and set no
    # owners, so neither is lost to anything downstream.
    umoci raw unpack --rootless --image image:uos rootfs
    rm -r image

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
