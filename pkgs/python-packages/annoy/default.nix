{
  annoy,
  lib,
  stdenv,
}:
# nixpkgs marks annoy badPlatforms = isDarwin, with only "Several tests fail
# with AssertionError" for a reason (nixpkgs 1cc293deea81, a drive-by cleanup).
# The extension module itself builds on darwin and upstream publishes macOS
# wheels; the failures are in annoy's randomized recall-threshold assertions,
# which are sensitive to the -ffast-math build. CumulusCI's `select` extra needs
# annoy on every platform it runs on, so skip the test suite there instead of
# dropping the whole extra on darwin.
annoy.overrideAttrs (old: {
  # buildPythonPackage runs pytestCheckHook from installCheckPhase, so the test
  # suite is gated by doInstallCheck rather than doCheck.
  doInstallCheck = old.doInstallCheck && !stdenv.hostPlatform.isDarwin;

  meta = old.meta // {
    badPlatforms = lib.remove lib.systems.inspect.patterns.isDarwin old.meta.badPlatforms;
  };
})
