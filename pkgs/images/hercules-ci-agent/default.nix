{
  hercules-ci-agent,
  nix2container,
}:
nix2container.buildImage {
  name = "hercules-ci-agent";

  config = {
    Entrypoint = [ "${hercules-ci-agent}/bin/hercules-ci-agent" ];
  };
}
