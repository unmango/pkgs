{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage (finalAttrs: {
  pname = "retext-readability";
  version = "8.0.0";

  src = fetchFromGitHub {
    owner = "retextjs";
    repo = "retext-readability";
    tag = finalAttrs.version;
    hash = "sha256-Zois+WRfi25JDrSUE/WuMgjpImMy6fYPTWUyVgMT3RM=";
  };

  # Upstream sets package-lock=false, so the lock is vendored.
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-lMSQyf0+OLAkHU0aQXVBinFoZeKnIMNSs6k2mW2MqwI=";
  # Packuments too: `npm prune` reads them offline.
  npmDepsFetcherVersion = 2;
  dontNpmBuild = true;

  # The file a unified rc names to load this package as a plugin.
  passthru.unifiedPlugin = "${finalAttrs.finalPackage}/lib/node_modules/retext-readability/index.js";

  meta = {
    description = "retext plugin to check readability";
    homepage = "https://github.com/retextjs/retext-readability";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ UnstoppableMango ];
  };
})
