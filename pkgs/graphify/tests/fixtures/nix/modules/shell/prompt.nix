# The prompt half of the shell module.
{ lib, config, ... }:
{
  options.demo.prompt.theme = lib.mkOption {
    type = lib.types.str;
    default = "plain";
  };

  config.programs.zsh.initContent = lib.mkIf config.demo.shell.enable config.demo.prompt.theme;
}
