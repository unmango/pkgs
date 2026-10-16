# mdx-js/mdx: @mdx-js/mdx (as mdx-js-mdx) and remark-mdx.
#
# Only these two members are built, against a root package.json naming just
# them: upstream's own lockfile also carries the website, puppeteer and the
# bundler integrations.
{
  lib,
  buildUnifiedWorkspace,
  fetchFromGitHub,
  unifiedPackages,
}:
buildUnifiedWorkspace {
  pname = "mdx";

  src = fetchFromGitHub {
    owner = "mdx-js";
    repo = "mdx";
    tag = "3.1.1";
    hash = "sha256-D8ksBCkuFvSwY6f/TBO7jSxSVDBhSRv6Gr5a4wFIwrs=";
  };

  manifest = ./package.json;
  lockfile = ./package-lock.json;
  workspaces = lib.importJSON ./workspaces.json;
  npmDepsHash = "sha256-GgKtPIVXNHfaYbzgu+vcsKq/kQUGdvVkD4z48NXz/a0=";
  packages = unifiedPackages;

  meta = {
    homepage = "https://mdxjs.com";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ UnstoppableMango ];
  };
}
