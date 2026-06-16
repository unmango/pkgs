pkgs:
let
  names = builtins.sort builtins.lessThan (builtins.attrNames pkgs);
  row = name: "| \`${name}\` | ${pkgs.${name}.meta.description or ""} |";
  rows = map row names;
  header = [
    "| Name | Description |"
    "| ---- | ----------- |"
  ];
in
builtins.concatStringsSep "\n" (header ++ rows)
