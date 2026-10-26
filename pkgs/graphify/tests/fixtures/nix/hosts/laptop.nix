{ lib, ... }:
{
  imports = [ ../modules/shell ];

  demo = {
    shell.enable = true;
    shell.users.alice.home = "/home/alice";
  };

  demo.prompt.theme = lib.mkForce "powerline";

  home.file.".hushlogin".source = ./hushlogin;
}
