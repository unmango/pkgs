{
  lib,
  stdenv,
  fetchFromGitHub,
  tree-sitter,
}:
let
  version = "0-unstable-2026-06-17";

  src = fetchFromGitHub {
    owner = "danpozmanter";
    repo = "gossamer-editor-support";
    rev = "d6ec859c8374f90e70b2ad0a830f0c598d02fc4f";
    hash = "sha256-2Esu8A85SfE4QDY5DNK1/l8Gyg0VBbfoDCqgSrWNStA=";
  };

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
        homepage = "https://github.com/danpozmanter/gossamer-editor-support";
        license = licenses.asl20;
        maintainers = with maintainers; [ UnstoppableMango ];
      };
    };
in
{
  vscode = mkEditorSupport {
    name = "vscode";
    subdir = "vscode";
    description = "Gossamer language support for Visual Studio Code";
  };

  vim = mkEditorSupport {
    name = "vim";
    subdir = "vim";
    description = "Gossamer syntax and ftplugin files for Vim";
  };

  neovim = mkEditorSupport {
    name = "neovim";
    subdir = "neovim";
    description = "Gossamer filetype detection, tree-sitter queries, and LSP config for Neovim";
  };

  helix = mkEditorSupport {
    name = "helix";
    subdir = "helix";
    description = "Gossamer language configuration for Helix";
  };

  emacs = mkEditorSupport {
    name = "emacs";
    subdir = "emacs";
    description = "Gossamer major mode for Emacs";
  };

  sublime = mkEditorSupport {
    name = "sublime";
    subdir = "sublime";
    description = "Gossamer syntax and LSP settings for Sublime Text";
  };

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
      homepage = "https://github.com/danpozmanter/gossamer-editor-support";
      license = lib.licenses.asl20;
    };
  };
}
