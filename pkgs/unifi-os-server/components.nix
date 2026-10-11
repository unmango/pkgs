{
  lib,
  stdenv,
  mkComponent,
  nodejs_24,
  temurin-jre-bin-25,
  systemdLibs,
}:
let
  # The Go services each ship a binary in /usr/sbin and their scripts,
  # config.props and assets under /usr/lib/<name>. ulp-go and uid-agent are
  # linked against glibc; the rest are static.
  mkGoService =
    name: description:
    mkComponent {
      pname = "unifi-os-server-${name}";
      inherit description;
      paths = [
        "usr/sbin/${name}-app"
        "usr/lib/${name}"
      ];
    };

  javaArch =
    {
      x86_64-linux = "x86_64";
      aarch64-linux = "aarch64";
    }
    .${stdenv.hostPlatform.system};
in
{
  # The UniFi OS console: a Node application plus the nginx templates it renders
  # into /data/unifi-core/config/http at runtime.
  core = mkComponent {
    pname = "unifi-os-server-core";
    description = "UniFi OS Server console (unifi-core)";
    paths = [
      "usr/share/unifi-core"
      "usr/share/unifi-assets"
      "etc/default/unifi-core"
      "etc/default/unifi-core_advanced"
      "etc/nginx/nginx.conf.disabled"
      "etc/sudoers.d/unifi-core"
      # unifi-core refuses to start unless VERSION_CODENAME is bullseye.
      "usr/lib/os-release"
      "etc/os-release"
    ];
    # sd-notify's addon links libsystemd. The musl builds of sharp's libvips
    # sit beside the glibc ones and are never loaded.
    buildInputs = [ systemdLibs ];
    autoPatchelfIgnoreMissingDeps = [ "libc.musl-*.so.1" ];
    # The unit runs /usr/bin/node24, a Node 24 the image bundles; nixpkgs' Node
    # 24 shares its module ABI, so the native addons load in either.
    postInstall = ''
      mkdir -p $out/usr/bin
      ln -s ${lib.getExe nodejs_24} $out/usr/bin/node24
    '';
    passthru.nodejs = nodejs_24;
  };

  # The Network application. 5.1.42 bundles Network 10.5.67.
  network = mkComponent {
    pname = "unifi-os-server-network";
    description = "UniFi Network application, as bundled with UniFi OS Server";
    paths = [
      "usr/lib/unifi"
      "usr/sbin/unifi-network-service-helper"
      "usr/sbin/unifi-network-service-common"
      "usr/share/unifi/gen-certs.sh"
      "sbin/uos-rabbitmq-gen-certs-wrapper"
      "etc/default/unifi"
    ];
    exclude = [
      # A link to the bundled mongod; MongoDB runs as its own service.
      "usr/lib/unifi/bin/mongod"
    ];
    # The sd_notify JNI shim links libsystemd.
    buildInputs = [ systemdLibs ];
    # ace.jar ships its JNI libraries for every platform it supports.
    postInstall = ''
      native=$out/usr/lib/unifi/lib/native
      find "$native" -mindepth 1 -maxdepth 1 ! -name Linux -exec rm -rf {} +
      find "$native/Linux" -mindepth 1 -maxdepth 1 ! -name ${javaArch} -exec rm -rf {} +

      # The unit runs /usr/bin/java, the image's Temurin 25 JRE.
      mkdir -p $out/usr/bin
      ln -s ${lib.getExe temurin-jre-bin-25} $out/usr/bin/java
    '';
    passthru.jre = temurin-jre-bin-25;
  };

  ulp-go = mkGoService "ulp-go" "UniFi OS login and identity service (ulp-go)";
  uid-agent = mkGoService "uid-agent" "UniFi Identity agent (uid-agent)";
  ucs-agent = mkGoService "ucs-agent" "UniFi Credential Server agent (ucs-agent)";
  unifi-directory = mkGoService "unifi-directory" "UniFi Directory service";
  unifi-identity-update = mkGoService "unifi-identity-update" "UniFi Identity update service";
}
