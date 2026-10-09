{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage (finalAttrs: {
  pname = "remark-gfm";
  version = "4.0.1";

  src = fetchFromGitHub {
    owner = "remarkjs";
    repo = "remark-gfm";
    tag = finalAttrs.version;
    hash = "sha256-4yPS3s3qmGj2oPfmmYpeqD53EWhVgSzN2Q3CK318AqI=";
  };

  # Upstream sets package-lock=false, so the lock is vendored.
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-I0PFXb0ARezNloevVGU9DPSUyUhHG8C12wSj4leGI10=";
  # Packuments too: `npm prune` reads them offline.
  npmDepsFetcherVersion = 2;
  dontNpmBuild = true;

  # The file a unified rc names to load this package as a plugin.
  passthru.unifiedPlugin = "${finalAttrs.finalPackage}/lib/node_modules/remark-gfm/index.js";

  meta = {
    description = "remark plugin to support GFM (autolink literals, footnotes, strikethrough, tables, tasklists)";
    homepage = "https://github.com/remarkjs/remark-gfm";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ UnstoppableMango ];
  };
})
