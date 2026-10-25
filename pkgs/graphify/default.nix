{
  lib,
  fetchPypi,
  nix-update-script,
  python3,
  runCommand,
}:
let
  version = "0.9.94";

  # grammars: extra tree-sitter grammar packages, built against python3, for
  # the extractors that import one only when it is installed.
  mkGraphify =
    grammars:
    let
      graphify = python3.pkgs.buildPythonPackage {
        pname = "graphifyy";
        inherit version;
        pyproject = true;

        src = fetchPypi {
          pname = "graphifyy";
          inherit version;
          hash = "sha256-CHCKm4/pUW6E4fsjpRA9oiah5mEH4+Qccuop+iYUp6Y=";
        };

        build-system = with python3.pkgs; [ setuptools ];

        # The bindings in python3Packages.tree-sitter-grammars track the grammar
        # repos, whose versions drift from the pins upstream declares.
        pythonRelaxDeps = true;

        dependencies =
          with python3.pkgs;
          [
            networkx
            numpy
            rapidfuzz
            tree-sitter
            # The mcp extra, which graphify-mcp needs.
            mcp
            starlette
          ]
          ++ (with tree-sitter-grammars; [
            tree-sitter-bash
            tree-sitter-c
            tree-sitter-c-sharp
            tree-sitter-cpp
            tree-sitter-elixir
            tree-sitter-fortran
            tree-sitter-go
            tree-sitter-groovy
            tree-sitter-java
            tree-sitter-javascript
            tree-sitter-json
            tree-sitter-julia
            tree-sitter-kotlin
            tree-sitter-lua
            tree-sitter-objc
            tree-sitter-php
            tree-sitter-powershell
            tree-sitter-python
            tree-sitter-ruby
            tree-sitter-rust
            tree-sitter-scala
            tree-sitter-swift
            tree-sitter-typescript
            tree-sitter-verilog
            tree-sitter-zig
          ]);

        # Reads TDL (https://github.com/UnstoppableMango/tdl) when its grammar,
        # tree_sitter_tdl, is installed, and Nix when tree_sitter_nix is. Not
        # upstream; each is written as the upstream pull request would be. The
        # Nix patch applies on top of the TDL one, since both extend the same
        # extension tables. Remove a patch if it fails to apply to two releases
        # in a row, and withGrammars with the last of them.
        patches = [
          ./tdl.patch
          ./nix.patch
        ];

        # The Nix extractor itself, which nix.patch registers.
        postPatch = ''
          cp ${./nix.py} graphify/extractors/nix.py
        '';

        # The PyPI sdist leaves out tests/fixtures, so only the cases whose
        # fixture a patch adds can run. They skip without the grammar, which
        # nothing here provides: this repository never pins tdl, and a
        # withGrammars build runs them with the grammar it is given.
        nativeCheckInputs = [ python3.pkgs.pytestCheckHook ] ++ grammars;
        enabledTestPaths = [ "tests/test_languages.py" ];
        enabledTests = [
          "test_tdl"
          "test_nix"
        ];

        pythonImportsCheck = [ "graphify" ];
      };

      # graphify runs sys.executable as `python -m graphify`: `update`, `extract`,
      # `cluster-only`, and `label` re-exec themselves to pin PYTHONHASHSEED
      # (Graphify-Labs/graphify#3641, #3779), and `graphify hook install` writes
      # sys.executable into the git hooks. buildPythonApplication's wrapper adds
      # the dependencies to sys.path inside the script, so its sys.executable is
      # a bare interpreter that cannot import graphify. Running the commands from
      # an environment makes sys.executable the environment's interpreter.
      env = python3.withPackages (_: [ graphify ] ++ grammars);
    in
    runCommand "graphify-${version}"
      {
        inherit version;

        passthru = {
          inherit (graphify) src;
          unwrapped = graphify;
          updateScript = nix-update-script { };

          # Rebuilds graphify with more grammar packages, a list or a function
          # of python3.pkgs as python3.withPackages takes, so graphify reads a
          # language whose grammar nixpkgs does not carry:
          # `graphify.withGrammars (ps: [ (ps.callPackage ./tree-sitter-tdl.nix { }) ])`,
          # or one it carries but graphify does not install by default:
          # `graphify.withGrammars (ps: [ ps.tree-sitter-grammars.tree-sitter-nix ])`.
          withGrammars =
            more: mkGraphify (grammars ++ (if builtins.isFunction more then more python3.pkgs else more));
        };

        meta = with lib; {
          description = "Turn a folder of code, docs, papers, or media into a queryable knowledge graph";
          homepage = "https://github.com/Graphify-Labs/graphify";
          license = licenses.asl20;
          maintainers = with maintainers; [ UnstoppableMango ];
          mainProgram = "graphify";
        };
      }
      ''
        mkdir -p $out/bin
        ln -s ${env}/bin/graphify ${env}/bin/graphify-mcp $out/bin/
      '';
in
mkGraphify [ ]
