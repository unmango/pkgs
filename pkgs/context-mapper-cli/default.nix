{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  jre,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "context-mapper-cli";
  version = "6.12.0";

  # Upstream builds with Gradle and publishes this distribution to Maven
  # Central: the CLI's jar, its runtime dependencies, and Gradle's start
  # scripts. The jars are platform independent, so one archive serves every
  # system.
  src = fetchurl {
    url = "https://repo1.maven.org/maven2/org/contextmapper/context-mapper-cli/${finalAttrs.version}/context-mapper-cli-${finalAttrs.version}.tar";
    hash = "sha256-Gj4qaki0KMMoMcj0PmFS9F4lOINrrYhSzqfgymwE9rY=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/context-mapper-cli
    cp -r lib $out/share/context-mapper-cli/
    install -Dm755 bin/cm $out/share/context-mapper-cli/bin/cm

    # The start script finds the jars relative to itself and the JVM through
    # JAVA_HOME or PATH.
    makeWrapper $out/share/context-mapper-cli/bin/cm $out/bin/cm \
      --set JAVA_HOME ${jre.home}

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    # cm exits 0 whatever it finds, so the check reads what it prints.
    echo 'BoundedContext Check { Aggregate A { Entity A { aggregateRoot String name } } }' > check.cml
    $out/bin/cm validate -i check.cml | tee check.out
    grep -q 'validated without errors' check.out
    runHook postInstallCheck
  '';

  # Versions come from the source repository's tags; the archive is the one
  # Maven Central holds for that version.
  passthru.updateScript = nix-update-script {
    extraArgs = [ "--url=https://github.com/ContextMapper/context-mapper-cli" ];
  };

  meta = {
    description = "Command line interface to validate Context Mapper (CML) files and run its generators";
    homepage = "https://github.com/ContextMapper/context-mapper-cli";
    changelog = "https://github.com/ContextMapper/context-mapper-cli/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
    maintainers = with lib.maintainers; [ UnstoppableMango ];
    mainProgram = "cm";
    platforms = jre.meta.platforms;
  };
})
