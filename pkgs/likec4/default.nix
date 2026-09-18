{
  lib,
  buildNpmPackage,
  curl,
  fetchzip,
  jq,
  nix-update-script,
}:
let
  version = "1.59.3";

  # Injected into the minified bundle, so it can't use imports or any of the
  # bundle's minified identifiers. TMPDIR is the last resort, for sandboxed
  # builds where HOME is unset or not writable.
  cacheDir = ''(process.env.LIKEC4_VITE_CACHE_DIR||((process.env.XDG_CACHE_HOME||(process.env.HOME?process.env.HOME+"/.cache":(process.env.TMPDIR||"/tmp")))+"/likec4/${version}/vite"))'';
in
buildNpmPackage {
  pname = "likec4";
  inherit version;

  # The published package.json's devDependencies pull in pnpm workspace
  # packages (@likec4/devops, @likec4/tsconfig, ...) that aren't on the
  # public registry, so npm can't resolve them. They're also unneeded since
  # dist/ ships prebuilt. Stripping them at fetch time keeps upstream's
  # dependency list authoritative and lets `nix-update --generate-lockfile`
  # regenerate package-lock.json from the unpacked source.
  src = fetchzip {
    url = "https://registry.npmjs.org/likec4/-/likec4-${version}.tgz";
    hash = "sha256-1K6CBH0whoxtFj8+n2TUvb6ILeawmkg0CHytZHx4aRs=";
    nativeBuildInputs = [ jq ];
    postFetch = ''
      jq 'del(.devDependencies)' "$out/package.json" > "$out/package.json.tmp"
      mv "$out/package.json.tmp" "$out/package.json"
    '';
  };

  # likec4 never sets Vite's cacheDir, so it defaults to node_modules/.vite
  # under the package holding the nearest package.json. Vite's root is likec4's
  # own __app__ directory, so that lands in the store, which is read-only:
  # `likec4 start` fails to pre-bundle dependencies and answers module requests
  # with the SPA fallback HTML, rendering a blank page with nothing in the
  # browser console. The same cacheDir also backs the icon cache
  # (<cacheDir>/likec4-icons), which a model using `icon` hits during a build.
  #
  # All three Vite config builders (viteConfig, viteWebcomponentConfig,
  # viteReactConfig) emit `configFile:!1`, so one substitution covers the dev
  # server, both builds and codegen.
  #
  # sed rather than substituteInPlace: the bundle carries null bytes, and
  # substitute() refuses those outright.
  postPatch = ''
    cp ${./package-lock.json} package-lock.json

    sed -i 's#configFile:!1#configFile:!1,cacheDir:${cacheDir}#g' dist/cli/index.mjs

    # One insertion per config builder. A version bump that reshapes the bundle
    # trips this rather than silently regressing.
    inserted=$(tr -d '\0' <dist/cli/index.mjs | grep -o 'cacheDir:' | wc -l)
    if [ "$inserted" -ne 3 ]; then
      echo "likec4: expected 3 cacheDir insertions, got $inserted" >&2
      exit 1
    fi
  '';

  npmDepsHash = "sha256-rVbzJwycyU98uMbIhPZsdCcaleT1rruwvMHkIhnETpM=";

  # playwright ships without an install script, so no browser download
  # happens here. Browsers for `likec4 export png` come from a separate
  # `playwright install` (or PLAYWRIGHT_BROWSERS_PATH) at run time.

  dontNpmBuild = true;

  nativeInstallCheckInputs = [ curl ];

  doInstallCheck = true;

  # Vite only runs the dependency optimizer for the dev server, so this is the
  # one command that exercises cacheDir. A `likec4 build` check would pass with
  # or without the patch above.
  #
  # The assertion is on where the cache lands, not on the absence of EACCES:
  # $out is still writable during installCheckPhase, so an unpatched build
  # quietly writes into it here instead of failing the way it does once the
  # path is in the store.
  installCheckPhase = ''
    runHook preInstallCheck

    # The server tries to open a browser and logs a `spawn open ENOENT` when it
    # can't. That is noise, not a failure, and no environment variable turns it
    # off: likec4 calls the `open` package directly rather than going through
    # Vite, which would have honoured BROWSER.
    export HOME="$TMPDIR/home"
    export XDG_CACHE_HOME="$TMPDIR/cache"
    mkdir -p "$HOME" "$XDG_CACHE_HOME" "$TMPDIR/ws"

    cat >"$TMPDIR/ws/model.c4" <<'EOF'
    specification {
      element system
    }
    model {
      a = system 'A'
    }
    views {
      view index {
        include *
      }
    }
    EOF

    "$out/bin/likec4" start --listen 127.0.0.1 --port 5199 "$TMPDIR/ws" &
    serverPid=$!
    trap 'kill $serverPid 2>/dev/null || true' EXIT

    for _ in $(seq 1 60); do
      curl -sf http://127.0.0.1:5199/ -o /dev/null && break
      sleep 1
    done

    curl -sf http://127.0.0.1:5199/ -o /dev/null

    # Ask for the entry module the way a browser would, so the optimizer has
    # something to pre-bundle for.
    curl -sf http://127.0.0.1:5199/src/main -o /dev/null || true

    # Optimizing is asynchronous, so poll rather than asserting straight away.
    # Without the patch the directory never appears at all, and the wait costs
    # only the timeout.
    cacheDeps="$XDG_CACHE_HOME/likec4/${version}/vite/deps"
    for _ in $(seq 1 60); do
      [ -d "$cacheDeps" ] && break
      sleep 1
    done

    if [ ! -d "$cacheDeps" ]; then
      echo "likec4: dependency cache missing, cacheDir patch is not in effect" >&2
      exit 1
    fi

    runHook postInstallCheck
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--generate-lockfile" ];
  };

  meta = with lib; {
    description = "Toolchain for your architecture diagrams";
    homepage = "https://likec4.dev";
    license = licenses.mit;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "likec4";
  };
}
