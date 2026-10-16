{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage (finalAttrs: {
  pname = "unified-args";
  version = "11.0.1";

  src = fetchFromGitHub {
    owner = "unifiedjs";
    repo = "unified-args";
    tag = finalAttrs.version;
    hash = "sha256-+hgaY46IrTcV4E909x0IPHwGYapQrFc0z8S1Hkp1vxQ=";
  };

  # Upstream sets package-lock=false, so the lock is vendored.
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-vTDB4aTUNJNlopKWWwj4PcBZeKMSuvCOryPxphCpH6w=";
  # Packuments too: `npm prune` reads them offline.
  npmDepsFetcherVersion = 2;
  dontNpmBuild = true;

  meta = {
    description = "Create CLIs for unified processors";
    homepage = "https://github.com/unifiedjs/unified-args";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ UnstoppableMango ];
  };
})
