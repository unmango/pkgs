{
  lib,
  stdenv,
  fetchFromGitHub,
  tree-sitter,
  vscode-utils,
  vimUtils,
  emacsPackages,
}:
let
  version = "0-unstable-2026-06-17";

  src = fetchFromGitHub {
    owner = "danpozmanter";
    repo = "gossamer-editor-support";
    rev = "d6ec859c8374f90e70b2ad0a830f0c598d02fc4f";
    hash = "sha256-2Esu8A85SfE4QDY5DNK1/l8Gyg0VBbfoDCqgSrWNStA=";
  };

  homepage = "https://github.com/danpozmanter/gossamer-editor-support";

  # Plain copy of an editor subdir to $out, no home-manager integration.
  mkEditorSupport =
    {
      name,
      subdir,
      description,
    }:
    stdenv.mkDerivation {
      pname = "gossamer-editor-support-${name}";
      inherit version src;

      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall
        cp -r ${lib.escapeShellArg subdir} $out
        runHook postInstall
      '';

      meta = with lib; {
        inherit description;
        inherit homepage;
        license = licenses.asl20;
        maintainers = with maintainers; [ UnstoppableMango ];
      };
    };
in
{
  # vscode/package.json declares publisher "gossamer-lang" and name
  # "gossamer" - use that identity verbatim so vscodeExtUniqueId matches
  # what the extension actually is.
  vscode = vscode-utils.buildVscodeExtension {
    pname = "gossamer-vscode";
    version = "0.2.0";

    vscodeExtPublisher = "gossamer-lang";
    vscodeExtName = "gossamer";
    vscodeExtUniqueId = "gossamer-lang.gossamer";

    inherit src;

    # src is a plain fetched directory, not a .vsix, so skip the
    # vsix-specific default unpack/sourceRoot logic.
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/$installPrefix"
      cp -r --no-preserve=mode -- "$src"/vscode/. "$out/$installPrefix/"
      runHook postInstall
    '';

    meta = with lib; {
      description = "Gossamer language support for Visual Studio Code";
      inherit homepage;
      license = licenses.asl20;
      maintainers = with maintainers; [ UnstoppableMango ];
    };
  };

  vim = vimUtils.buildVimPlugin {
    pname = "gossamer-vim";
    inherit version;
    src = "${src}/vim";
    # No doc/ dir to generate vim help tags from.
    doCheck = false;

    meta = with lib; {
      description = "Gossamer syntax and ftplugin files for Vim";
      inherit homepage;
      license = licenses.asl20;
      maintainers = with maintainers; [ UnstoppableMango ];
    };
  };

  neovim = vimUtils.buildVimPlugin {
    pname = "gossamer-nvim";
    inherit version;
    src = "${src}/neovim";
    doCheck = false;

    meta = with lib; {
      description = "Gossamer filetype detection, tree-sitter queries, and LSP config for Neovim";
      inherit homepage;
      license = licenses.asl20;
      maintainers = with maintainers; [ UnstoppableMango ];
    };
  };

  # Helix's `languages`/`themes` home-manager options only accept
  # TOML-serializable data, not a local derivation - plain copy, useful
  # only for manual install.
  helix = mkEditorSupport {
    name = "helix";
    subdir = "helix";
    description = "Gossamer language configuration for Helix";
  };

  emacs = emacsPackages.trivialBuild {
    pname = "gossamer-mode";
    inherit version;
    src = "${src}/emacs";

    meta = with lib; {
      description = "Gossamer major mode for Emacs";
      inherit homepage;
      license = licenses.asl20;
      maintainers = with maintainers; [ UnstoppableMango ];
    };
  };

  # Sublime Text has no home-manager module at all - plain copy, for
  # manual install into Packages/ (e.g. via `home.file`).
  sublime = mkEditorSupport {
    name = "sublime";
    subdir = "sublime";
    description = "Gossamer syntax and LSP settings for Sublime Text";
  };

  # `programs.zed-editor.extensions` only accepts names of extensions from
  # Zed's own remote registry, no local-derivation hook - plain copy, for
  # `zed: install dev extension` pointed at the store path.
  zed = mkEditorSupport {
    name = "zed";
    subdir = "zed";
    description = "Gossamer extension for Zed";
  };

  tree-sitter-gossamer = tree-sitter.buildGrammar {
    language = "gossamer";
    version = "0.2.0";
    inherit src;
    location = "tree-sitter-gossamer";

    meta = {
      description = "Tree-sitter grammar for the Gossamer programming language";
      inherit homepage;
      license = lib.licenses.asl20;
    };
  };
}
