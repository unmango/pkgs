# retextjs/retext: retext, retext-latin, retext-english, retext-dutch and
# retext-stringify.
{
  lib,
  buildUnifiedWorkspace,
  fetchFromGitHub,
  unifiedPackages,
}:
buildUnifiedWorkspace {
  pname = "retext";

  src = fetchFromGitHub {
    owner = "retextjs";
    repo = "retext";
    tag = "9.0.0";
    hash = "sha256-NOVZmz83TUytNDANfBvBqb70LORU/06f2etkyO6XOGw=";
  };

  lockfile = ./package-lock.json;
  workspaces = lib.importJSON ./workspaces.json;
  npmDepsHash = "sha256-3VGJVXH7HkZGuOMCkWiTB/40CWp+rF3yI4/1RAuvNWs=";
  packages = unifiedPackages;

  meta = {
    homepage = "https://github.com/retextjs/retext";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ UnstoppableMango ];
  };
}
