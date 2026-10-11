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
  #
  # Each pre-start.sh runs an `init` wrapper, `wrapper`, which creates the
  # service's Postgres role and database and its /data directories before
  # start.sh drops to the service user.
  mkGoService =
    name: description: wrapper:
    mkComponent {
      pname = "unifi-os-server-${name}";
      inherit description;
      paths = [
        "usr/sbin/${name}-app"
        "usr/lib/${name}"
      ]
      ++ wrapper;
      units = [ "${name}.service" ];
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
      # A shell stub standing in for the console hardware's identity tool:
      # it reads the board name from files the container is given.
      "sbin/ubnt-tools"
    ];
    units = [ "unifi-core.service" ];
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
      # unifi-network-service-helper runs `ubnt-tools id` every time it loads.
      "sbin/ubnt-tools"
      # The data directory usr/lib/unifi/data links to.
      "var/lib/unifi"
    ];
    units = [ "unifi.service" ];
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

  # pre-start.sh runs `/usr/bin/ulp init`, and ulp links to ulp-go.
  ulp-go = mkGoService "ulp-go" "UniFi OS login and identity service (ulp-go)" [
    "usr/bin/ulp-go"
    "usr/bin/ulp"
  ];
  uid-agent = mkGoService "uid-agent" "UniFi Identity agent (uid-agent)" [ "usr/bin/uid-agent" ];
  ucs-agent = mkGoService "ucs-agent" "UniFi Credential Server agent (ucs-agent)" [
    "usr/sbin/ucs-agent"
  ];
  unifi-directory = mkGoService "unifi-directory" "UniFi Directory service" [
    "usr/sbin/unifi-directory"
  ];
  unifi-identity-update = mkGoService "unifi-identity-update" "UniFi Identity update service" [
    "usr/sbin/unifi-identity-update"
  ];
}
