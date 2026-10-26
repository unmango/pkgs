"""Tests for the Nix extractor (graphify/extractors/nix.py)."""
from __future__ import annotations

import importlib.util as _ilu
from pathlib import Path

import pytest

from graphify.extract import extract, extract_nix

FIXTURES = Path(__file__).parent / "fixtures"

_needs_nix = pytest.mark.skipif(
    _ilu.find_spec("tree_sitter_nix") is None,
    reason="tree-sitter-nix not installed (optional [nix] extra)",
)

NIX = FIXTURES / "nix"


def _nix_edges(r, relation):
    labels = {n["id"]: n["label"] for n in r["nodes"]}
    return {
        (labels.get(e["source"], e["source"]), labels.get(e["target"], e["target"]))
        for e in r["edges"] if e["relation"] == relation
    }


@_needs_nix
def test_nix_options_are_declared_by_full_path():
    r = extract_nix(NIX / "modules" / "shell" / "default.nix")
    assert "error" not in r
    defines = _nix_edges(r, "defines")
    assert defines == {
        ("default.nix", "demo.shell.enable"),
        ("default.nix", "demo.shell.aliases"),
        ("default.nix", "demo.shell.users"),
    }
    # A submodule's own options belong to the option holding it.
    assert "home" not in {n["label"] for n in r["nodes"]}


@_needs_nix
def test_nix_functions_and_calls():
    r = extract_nix(NIX / "lib.nix")
    assert ("lib.nix", "greet") in _nix_edges(r, "contains")
    assert ("greetAll", "greet") in _nix_edges(r, "calls")
    shell = extract_nix(NIX / "modules" / "shell" / "default.nix")
    # A let-bound function is a node, and its caller here is the file.
    assert ("default.nix", "aliasesFor") in _nix_edges(shell, "calls")
    assert "cfg" not in {n["label"] for n in shell["nodes"]}


@_needs_nix
def test_nix_path_imports():
    r = extract_nix(NIX / "hosts" / "laptop.nix")
    imports = [e for e in r["edges"] if e["relation"] == "imports"]
    # A directory resolves to its default.nix, and a path that is not a Nix
    # file is not an import.
    assert [e["target_file"] for e in imports] == [
        str(NIX / "modules" / "shell" / "default.nix")
    ]


def _nix_corpus(tmp_path):
    import shutil
    shutil.copytree(NIX, tmp_path / "nix")
    files = sorted((tmp_path / "nix").rglob("*.nix"))
    r = extract(files, root=tmp_path, cache_root=tmp_path, parallel=False)
    nodes = {n["id"]: n for n in r["nodes"]}
    def where(nid):
        n = nodes[nid]
        return n["label"], Path(n["source_file"]).name
    return r, {
        (where(e["source"]), e["relation"], where(e["target"]))
        for e in r["edges"] if e["source"] in nodes and e["target"] in nodes
    }


@_needs_nix
def test_nix_settings_land_on_the_declaring_module(tmp_path):
    r, edges = _nix_corpus(tmp_path)
    laptop = ("laptop.nix", "laptop.nix")
    assert (laptop, "configures", ("demo.shell.enable", "default.nix")) in edges
    assert (laptop, "configures", ("demo.prompt.theme", "prompt.nix")) in edges
    # A setting under a submodule option links to the option.
    assert (laptop, "configures", ("demo.shell.users", "default.nix")) in edges
    assert (laptop, "imports", ("default.nix", "default.nix")) in edges
    # Options nobody in the corpus declares leave no stubs behind.
    assert all(n["source_file"] for n in r["nodes"])
    assert "programs.zsh.shellAliases" not in {n["label"] for n in r["nodes"]}


@_needs_nix
def test_nix_reads_through_config_and_aliases(tmp_path):
    _, edges = _nix_corpus(tmp_path)
    shell = ("default.nix", "default.nix")
    prompt = ("prompt.nix", "prompt.nix")
    # `cfg = config.demo.shell` makes `cfg.enable` a read of demo.shell.enable.
    assert (shell, "references", ("demo.shell.enable", "default.nix")) in edges
    assert (shell, "references", ("demo.shell.aliases", "default.nix")) in edges
    assert (prompt, "references", ("demo.shell.enable", "default.nix")) in edges
    assert (prompt, "references", ("demo.prompt.theme", "prompt.nix")) in edges


def test_nix_without_the_grammar(monkeypatch):
    import builtins
    real_import = builtins.__import__
    def no_nix(name, *args, **kwargs):
        if name == "tree_sitter_nix":
            raise ImportError(name)
        return real_import(name, *args, **kwargs)
    monkeypatch.setattr(builtins, "__import__", no_nix)
    r = extract_nix(NIX / "lib.nix")
    assert r == {"nodes": [], "edges": [], "error": "tree_sitter_nix not installed"}
