{
  lib,
  fetchPypi,
  nix-update-script,
  python3,
  runCommand,
}:
let
  version = "0.9.84";

  graphify = python3.pkgs.buildPythonPackage {
    pname = "graphifyy";
    inherit version;
    pyproject = true;

    src = fetchPypi {
      pname = "graphifyy";
      inherit version;
      hash = "sha256-HI73HXUfEaCKm2pFxh5djsdWFNjBec4b10grLZvF/E0=";
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

    pythonImportsCheck = [ "graphify" ];
  };

  # graphify runs sys.executable as `python -m graphify`: `update`, `extract`,
  # `cluster-only`, and `label` re-exec themselves to pin PYTHONHASHSEED
  # (Graphify-Labs/graphify#3641, #3779), and `graphify hook install` writes
  # sys.executable into the git hooks. buildPythonApplication's wrapper adds
  # the dependencies to sys.path inside the script, so its sys.executable is
  # a bare interpreter that cannot import graphify. Running the commands from
  # an environment makes sys.executable the environment's interpreter.
  env = python3.withPackages (_: [ graphify ]);
in
runCommand "graphify-${version}"
  {
    inherit version;

    passthru = {
      inherit (graphify) src;
      unwrapped = graphify;
      updateScript = nix-update-script { };
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
  ''
