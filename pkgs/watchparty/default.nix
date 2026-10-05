{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
  makeWrapper,
  nix-update-script,
  nodejs_24,
}:
buildNpmPackage {
  pname = "watchparty";
  version = "0-unstable-2026-10-04";

  src = fetchFromGitHub {
    owner = "howardchung";
    repo = "watchparty";
    rev = "bf98b0a3b551cfb9d5f070c12d4fb9387e425940";
    hash = "sha256-tVWP+OXQQvOCu8LJ9K0UjcPmXcPhfhmXxIPFTLVZVE0=";
  };

  # Upstream's lock omits peer dependencies npm 11 expects (acorn,
  # bufferutil), so `npm ci` rejects it as out of sync.
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-w1ILd8nPeiUMndh2OljjDwRfqff0dHf3bqj2SzdCALU=";

  nodejs = nodejs_24;

  # Only the client's devDependencies carry install scripts, and those fetch
  # native prebuilds (node-datachannel via webtorrent) that vite never uses.
  npmRebuildFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [ makeWrapper ];

  # Vite bakes this into the client. Unset, the client falls back to
  # watchparty.me's Firebase project; empty disables sign-in and leaves every
  # feature open.
  env.VITE_FIREBASE_CONFIG = "";

  # `npm pack` honours .gitignore, which excludes build/, so install by hand.
  installPhase = ''
    runHook preInstall

    # server/room.ts imports twitch-m3u8, which upstream lists as a
    # devDependency. It has no dependencies of its own, so carry it across
    # the prune.
    mv node_modules/twitch-m3u8 twitch-m3u8
    npm prune --omit=dev --no-save $npmInstallFlags "''${npmInstallFlagsArray[@]}" $npmFlags "''${npmFlagsArray[@]}"
    mv twitch-m3u8 node_modules/twitch-m3u8

    dest=$out/lib/watchparty
    mkdir -p $dest
    cp -r build node_modules server sql words global.d.ts package.json $dest/
    # server/config.ts calls loadEnvFile() and logs a stack trace when there
    # is no .env; configuration comes from the environment instead.
    touch $dest/.env

    # The server resolves build/ and words/ against the working directory.
    makeWrapper ${lib.getExe nodejs_24} $out/bin/watchparty \
      --chdir $dest \
      --add-flags $dest/server/server.ts

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch"
      "--generate-lockfile"
    ];
  };

  meta = with lib; {
    description = "Watch videos together with friends anywhere";
    homepage = "https://github.com/howardchung/watchparty";
    license = licenses.mit;
    maintainers = with maintainers; [ UnstoppableMango ];
    mainProgram = "watchparty";
  };
}
