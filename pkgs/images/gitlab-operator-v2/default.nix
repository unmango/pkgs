{
  cacert,
  gitlab-operator-v2,
  nix2container,
}:
nix2container.buildImage {
  name = "gitlab-operator-v2";

  copyToRoot = [ cacert ];

  config = {
    User = "1001";
    Entrypoint = [ "${gitlab-operator-v2}/bin/manager" ];
  };
}
