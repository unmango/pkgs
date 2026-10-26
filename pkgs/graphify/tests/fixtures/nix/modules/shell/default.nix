{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.demo.shell;

  aliasesFor = names: lib.genAttrs names (name: "echo ${name}");
in
{
  imports = [ ./prompt.nix ];

  options.demo.shell = {
    enable = lib.mkEnableOption "the shell";

    aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = aliasesFor [ "ll" ];
    };

    users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.home = lib.mkOption { type = lib.types.str; };
        }
      );
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.zsh ];
    programs.zsh.shellAliases = cfg.aliases;
  };
}
