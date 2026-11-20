{
  lib,
  stdenvNoCC,
  fetchzip,
  makeWrapper,
  nodejs,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencommit";
  version = "3.3.11";

  # The published out/cli.cjs is an esbuild bundle that requires only Node
  # builtins, so the tarball's dependencies are never loaded. Wrapping the
  # bundle directly avoids installing ~115M of unreferenced node_modules.
  src = fetchzip {
    url = "https://registry.npmjs.org/opencommit/-/opencommit-${finalAttrs.version}.tgz";
    hash = "sha256-W5dhkchUUlM+oFAs7qgRzbhNb1dHveHbHpzVYpcg1bw=";
  };

  nativeBuildInputs = [ makeWrapper ];

  # axios calls the bundled proxy-from-env 1.x on every request, which parses
  # the URL with the deprecated url.parse() and prints a DEP0169 warning into
  # the interactive prompt. It reads only protocol, host, and port, which a
  # WHATWG URL provides; an unparseable URL still resolves to no proxy.
  #
  # node-fetch 2.x, which the Anthropic SDK sends every request through, does
  # the same in parseURL. Its callers spread the result into http.request
  # options and url.format it, so it needs the legacy field shape that
  # urlToHttpOptions builds. Relative URLs keep url.parse, which node-fetch
  # then rejects as it always has.
  postPatch = ''
    substituteInPlace out/cli.cjs --replace-fail \
      'var parsedUrl = (typeof url2 === "string" ? parseUrl(url2) : url2) || {};' \
      'var parsedUrl = (typeof url2 === "string" ? (URL.canParse(url2) ? new URL(url2) : {}) : url2) || {};'

    substituteInPlace out/cli.cjs --replace-fail \
      '      return parse_url(urlStr);' \
      '      return URL3.canParse(urlStr) ? Url.urlToHttpOptions(new URL3(urlStr)) : parse_url(urlStr);'
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/opencommit
    cp -r out/. $out/lib/opencommit

    makeWrapper ${lib.getExe nodejs} $out/bin/opencommit \
      --add-flags $out/lib/opencommit/cli.cjs
    ln -s opencommit $out/bin/oco

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Auto-generate impressive commits in 1 second, killing lame commits with AI";
    homepage = "https://github.com/di-sukharev/opencommit";
    license = licenses.mit;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "opencommit";
  };
})
