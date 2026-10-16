{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage (finalAttrs: {
  pname = "retext-repeated-words";
  version = "5.0.0";

  src = fetchFromGitHub {
    owner = "retextjs";
    repo = "retext-repeated-words";
    tag = finalAttrs.version;
    hash = "sha256-6v5+5qMrrMoPTl/Ok0fSQR5AfIGw/G1zBj4Iu8gT+5Q=";
  };

  # Upstream sets package-lock=false, so the lock is vendored.
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-7bpy5JIX+MgGe3f9aObsv+5z9niNcVR72hriFoB0IW4=";
  # Packuments too: `npm prune` reads them offline.
  npmDepsFetcherVersion = 2;
  dontNpmBuild = true;

  # The file a unified rc names to load this package as a plugin.
  passthru.unifiedPlugin = "${finalAttrs.finalPackage}/lib/node_modules/retext-repeated-words/index.js";

  meta = {
    description = "retext plugin to check for repeated words";
    homepage = "https://github.com/retextjs/retext-repeated-words";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ UnstoppableMango ];
  };
})
