{ formats }:
let
  # Mirrors upstream helix/languages.toml. Kept as a plain Nix value (rather
  # than read from the built file) so it can sit on `passthru` for
  # home-manager's `programs.helix.languages` to consume directly - reading a
  # file out of a derivation would be IFD. `toml` below is rendered from this
  # same value, so the file and the passthru can't disagree.
  languages = {
    language = [
      {
        name = "gossamer";
        scope = "source.gossamer";
        file-types = [ "gos" ];
        roots = [
          "project.toml"
          ".git"
        ];
        comment-token = "//";
        block-comment-tokens = {
          start = "/*";
          end = "*/";
        };
        indent = {
          tab-width = 4;
          unit = "    ";
        };
        auto-format = false;
        language-servers = [ "gossamer-lsp" ];
      }
    ];
    language-server.gossamer-lsp = {
      command = "gos";
      args = [ "lsp" ];
    };
    grammar = [
      {
        name = "gossamer";
        source = {
          git = "https://github.com/gossamer-lang/gossamer-site";
          rev = "main";
          subpath = "editors/tree-sitter-gossamer";
        };
      }
    ];
  };
in
{
  inherit languages;
  toml = (formats.toml { }).generate "languages.toml" languages;
}
