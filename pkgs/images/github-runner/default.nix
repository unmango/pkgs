{
  nix2container,
  ...
}:
nix2container.buildImage {
  name = "github-runner";
  fromImage = nix2container.pullImageFromManifest {
    registryUrl = "ghcr.io";
    imageName = "actions/actions-runner";
    imageTag = "2.334.0";
    imageManifest = ./manifest.json;
  };

  config = {
    user = "runner";
    entrypoint = [ "/home/runner/run.sh" ];
  };
}
