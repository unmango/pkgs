"""Nix extractor (tree-sitter).

A Nix file is an expression, and most files in a configuration repository are
NixOS, Home Manager, or flake-parts modules: an attrset, usually behind a
function header and a `let`, whose `imports`, `options`, and `config` keys tie
the files together. So the graph a module repository needs is mostly about
options: which file declares one, which files set it, and which read it.

A file contributes its own node, a node per function bound in its outermost
`let` or attrset, and a node per option it declares (an attribute under
`options` whose value is a `mkOption`-style call). Option ids are global rather
than file-scoped, so `defines` from the declaring file, `configures` from a
file setting the option, and `references` from a file reading it through
`config` (directly or through a `let` alias such as `cfg = config.foo`) all
meet on the one node. An option path is matched literally: a setting under a
submodule option (`foo.bar.<name>.baz`) is linked through every prefix of its
path, and the edges to prefixes that are not declared options are dropped with
the other dangling edges. Literal paths to a `.nix` file, or to a directory
holding a `default.nix`, are `imports`, whether they appear in `imports`,
`import`, or `callPackage`. A call to a function bound in the same file is a
`calls` edge from the enclosing bound function, or from the file.
"""
from __future__ import annotations

import os
import re
from pathlib import Path

from graphify.extractors.base import _file_stem, _make_id, _read_source_bytes, _read_text

# Keys of a module that are not configuration.
_MODULE_KEYS = {"imports", "options", "config", "disabledModules", "_file", "_class", "key", "meta", "freeformType"}

# Option-tree wrappers that a configuration value can sit behind.
_WRAPPERS = {"mkIf", "mkMerge", "mkDefault", "mkForce", "mkOverride", "mkBefore", "mkAfter", "mkOrder", "mkOptionDefault"}

_DECLARATION = re.compile(r"^mk\w*Option$")

_ATTRSETS = ("attrset_expression", "rec_attrset_expression")


def _language():
    import tree_sitter_nix as tsnix
    from tree_sitter import Language
    return Language(tsnix.language())


def _option_id(path: list[str]) -> str:
    return _make_id("nix_option", ".".join(path))


def _attrpath(node, source: bytes) -> list[str] | None:
    """An attrpath's names, or None if any part is interpolated."""
    parts: list[str] = []
    for c in node.children:
        if c.type == "identifier":
            parts.append(_read_text(c, source))
        elif c.type == "string_expression":
            if any(g.type == "interpolation" for g in c.children):
                return None
            parts.append("".join(_read_text(g, source) for g in c.children if g.type == "string_fragment"))
        elif c.type == "interpolation":
            return None
    return parts


def _unwrap(node):
    """The expression a file evaluates to, under function headers, `with`,
    `assert`, `let`, and parentheses, along with the `let` bindings passed."""
    lets = []
    while node is not None:
        if node.type == "function_expression":
            node = node.child_by_field_name("body")
        elif node.type in ("with_expression", "assert_expression"):
            node = node.child_by_field_name("body")
        elif node.type == "let_expression":
            lets.append(next((c for c in node.children if c.type == "binding_set"), None))
            node = node.child_by_field_name("body")
        elif node.type == "parenthesized_expression":
            node = node.child_by_field_name("expression")
        else:
            break
    return node, [b for b in lets if b is not None]


def _apply_chain(node):
    """`f a b` as (f, [a, b])."""
    args = []
    while node.type == "apply_expression":
        args.append(node.child_by_field_name("argument"))
        node = node.child_by_field_name("function")
    while node.type == "parenthesized_expression":
        node = node.child_by_field_name("expression")
    return node, list(reversed(args))


def _callee_name(node, source: bytes) -> str | None:
    """The last name of a called function: `lib.mkIf` and `mkIf` are both `mkIf`."""
    if node.type == "variable_expression":
        return _read_text(node.child_by_field_name("name"), source)
    if node.type == "select_expression":
        parts = _attrpath(node.child_by_field_name("attrpath"), source)
        return parts[-1] if parts else None
    return None


def _bindings(attrset):
    binding_set = next((c for c in attrset.children if c.type == "binding_set"), None)
    return [] if binding_set is None else list(binding_set.children)


def extract_nix(path: Path) -> dict:
    """Extract imports, option declarations, settings, and reads from a .nix file."""
    try:
        from tree_sitter import Parser
        language = _language()
    except ImportError:
        return {"nodes": [], "edges": [], "error": "tree_sitter_nix not installed"}
    except Exception as exc:
        return {"nodes": [], "edges": [], "error": f"Nix grammar failed to load: {exc}"}

    try:
        source = _read_source_bytes(path)
        root = Parser(language).parse(source).root_node
    except Exception as e:
        return {"nodes": [], "edges": [], "error": str(e)}

    stem = _file_stem(path)
    str_path = str(path)
    nodes: list[dict] = []
    edges: list[dict] = []
    seen_ids: set[str] = set()
    seen_edges: set[tuple[str, str, str]] = set()

    def add_node(nid: str, label: str, line: int) -> None:
        if nid not in seen_ids:
            seen_ids.add(nid)
            nodes.append({"id": nid, "label": label, "file_type": "code",
                          "source_file": str_path, "source_location": f"L{line}"})

    def add_edge(src: str, tgt: str, relation: str, line: int, target_file: Path | None = None) -> None:
        if src == tgt or (src, tgt, relation) in seen_edges:
            return
        seen_edges.add((src, tgt, relation))
        edge = {"source": src, "target": tgt, "relation": relation,
                "confidence": "EXTRACTED", "source_file": str_path,
                "source_location": f"L{line}", "weight": 1.0}
        if target_file is not None:
            edge["target_file"] = str(target_file)
        edges.append(edge)

    def line_of(node) -> int:
        return node.start_point[0] + 1

    def link_path(src: str, path_: list[str], relation: str, line: int, start: int = 1) -> None:
        # Every prefix at least two names long: one name is never an option a
        # module declares, and a longer prefix may be a submodule's option.
        for n in range(max(start, 2), len(path_) + 1):
            add_edge(src, _option_id(path_[:n]), relation, line)

    file_nid = _make_id(str(path))
    add_node(file_nid, path.name, 1)

    # The field, not the first child: a leading comment is a child too.
    body, lets = _unwrap(root.child_by_field_name("expression"))

    # Functions bound at the top of the file, and `config` aliases.
    functions: dict[str, str] = {}
    function_nodes: dict[int, str] = {}
    aliases: dict[str, list[str]] = {}

    def config_path(expr) -> list[str] | None:
        """The option path `expr` selects from `config`, through any alias."""
        while expr is not None and expr.type == "parenthesized_expression":
            expr = expr.child_by_field_name("expression")
        if expr is None:
            return None
        if expr.type == "variable_expression":
            name = _read_text(expr.child_by_field_name("name"), source)
            if name == "config":
                return []
            return aliases.get(name)
        if expr.type == "select_expression":
            base = config_path(expr.child_by_field_name("expression"))
            parts = _attrpath(expr.child_by_field_name("attrpath"), source)
            if base is None or parts is None:
                return None
            return base + parts
        return None

    top_bindings = [b for bs in lets for b in bs.children]
    if body is not None and body.type in _ATTRSETS:
        top_bindings += _bindings(body)
    for b in top_bindings:
        if b.type == "binding":
            parts = _attrpath(b.child_by_field_name("attrpath"), source)
            value = b.child_by_field_name("expression")
            if parts is None or len(parts) != 1 or value is None:
                continue
            if value.type == "function_expression":
                nid = _make_id(stem, parts[0])
                add_node(nid, parts[0], line_of(b))
                add_edge(file_nid, nid, "contains", line_of(b))
                functions[parts[0]] = nid
                function_nodes[value.id] = nid
    for bs in lets:
        for b in bs.children:
            if b.type == "binding":
                parts = _attrpath(b.child_by_field_name("attrpath"), source)
                target = config_path(b.child_by_field_name("expression"))
                if parts is not None and len(parts) == 1 and target:
                    aliases[parts[0]] = target
            elif b.type == "inherit_from":
                target = config_path(b.child_by_field_name("expression"))
                attrs = b.child_by_field_name("attrs")
                if target is not None and attrs is not None:
                    for a in attrs.children:
                        if a.type == "identifier":
                            aliases[_read_text(a, source)] = target + [_read_text(a, source)]

    # The module: imports, declarations, and settings.
    def declare(expr, prefix: list[str]) -> None:
        if expr is None:
            return
        if expr.type in _ATTRSETS:
            for b in _bindings(expr):
                if b.type != "binding":
                    continue
                parts = _attrpath(b.child_by_field_name("attrpath"), source)
                if parts is not None:
                    declare_value(b.child_by_field_name("expression"), prefix + parts, b)
        elif expr.type == "parenthesized_expression":
            declare(expr.child_by_field_name("expression"), prefix)

    def declare_value(value, path_: list[str], binding) -> None:
        if value is None:
            return
        if value.type == "apply_expression":
            head, _ = _apply_chain(value)
            name = _callee_name(head, source)
            if name is not None and _DECLARATION.match(name) and path_:
                nid = _option_id(path_)
                add_node(nid, ".".join(path_), line_of(binding))
                add_edge(file_nid, nid, "defines", line_of(binding))
                return
        declare(value, path_)

    def configure(expr, prefix: list[str], depth: int) -> None:
        if expr is None:
            return
        t = expr.type
        if t in _ATTRSETS:
            for b in _bindings(expr):
                if b.type == "binding":
                    parts = _attrpath(b.child_by_field_name("attrpath"), source)
                    if parts is None:
                        continue
                    path_ = prefix + parts
                    link_path(file_nid, path_, "configures", line_of(b), start=len(prefix) + 1)
                    configure(b.child_by_field_name("expression"), path_, depth + 1)
                elif b.type in ("inherit", "inherit_from"):
                    attrs = b.child_by_field_name("attrs")
                    for a in attrs.children if attrs is not None else []:
                        if a.type == "identifier":
                            link_path(file_nid, prefix + [_read_text(a, source)], "configures",
                                      line_of(b), start=len(prefix) + 1)
        elif t == "parenthesized_expression":
            configure(expr.child_by_field_name("expression"), prefix, depth)
        elif t == "list_expression":
            for c in expr.children:
                if c.is_named:
                    configure(c, prefix, depth)
        elif t == "apply_expression":
            head, args = _apply_chain(expr)
            if _callee_name(head, source) in _WRAPPERS:
                for a in args:
                    configure(a, prefix, depth)
        elif t in ("let_expression", "with_expression"):
            configure(expr.child_by_field_name("body"), prefix, depth)

    if body is not None and body.type in _ATTRSETS:
        module = _bindings(body)
        keys = set()
        for b in module:
            if b.type == "binding":
                parts = _attrpath(b.child_by_field_name("attrpath"), source)
                if parts:
                    keys.add(parts[0])
        explicit = bool(keys & {"options", "config"})
        for b in module:
            if b.type != "binding":
                continue
            parts = _attrpath(b.child_by_field_name("attrpath"), source)
            value = b.child_by_field_name("expression")
            if not parts or value is None:
                continue
            if parts[0] == "options":
                if len(parts) == 1:
                    declare(value, [])
                else:
                    declare_value(value, parts[1:], b)
            elif parts[0] == "config":
                link_path(file_nid, parts[1:], "configures", line_of(b))
                configure(value, parts[1:], 0)
            elif not explicit and parts[0] not in _MODULE_KEYS and parts[0] not in functions:
                link_path(file_nid, parts, "configures", line_of(b))
                configure(value, parts, 0)

    # Imports, reads, and calls, wherever they appear.
    def resolve_path(node) -> Path | None:
        if any(c.type != "path_fragment" for c in node.children):
            return None
        text = _read_text(node, source)
        if not text.startswith(("./", "../")):
            return None
        target = Path(os.path.normpath(path.parent / text))
        if target.suffix == ".nix" and target.is_file():
            return target
        if target.is_dir() and (target / "default.nix").is_file():
            return target / "default.nix"
        return None

    def walk(node, owner: str) -> None:
        owner = function_nodes.get(node.id, owner)
        t = node.type
        if t == "path_expression":
            target = resolve_path(node)
            if target is not None:
                add_edge(file_nid, _make_id(str(target)), "imports", line_of(node), target_file=target)
            return
        if t == "select_expression":
            path_ = config_path(node)
            if path_:
                link_path(owner, path_, "references", line_of(node))
        elif t == "inherit_from":
            target = config_path(node.child_by_field_name("expression"))
            attrs = node.child_by_field_name("attrs")
            if target is not None and attrs is not None:
                for a in attrs.children:
                    if a.type == "identifier":
                        link_path(owner, target + [_read_text(a, source)], "references", line_of(node))
        elif t == "apply_expression":
            head, _ = _apply_chain(node)
            if head.type == "variable_expression":
                name = _read_text(head.child_by_field_name("name"), source)
                if name in functions:
                    add_edge(owner, functions[name], "calls", line_of(node))
        for c in node.children:
            walk(c, owner)

    walk(root, file_nid)

    return {"nodes": nodes, "edges": edges}
