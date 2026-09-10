{
  gomod2nix,
  writeShellApplication,
  src,
}:
writeShellApplication {
  name = "update-deps";

  runtimeInputs = [ gomod2nix ];

  text = ''
    dir="$(mktemp -d)"
    trap 'rm -rf "$dir"' EXIT
    gomod2nix generate --dir ${src} --outdir "$dir"
    cp "$dir/gomod2nix.toml" "$1"
  '';
}
