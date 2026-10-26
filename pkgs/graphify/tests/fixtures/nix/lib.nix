{ lib }:
rec {
  greet = name: "hello ${name}";

  greetAll = names: lib.concatMapStringsSep "\n" (name: greet name) names;
}
