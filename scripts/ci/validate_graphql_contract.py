#!/usr/bin/env python3
"""Valida los contratos GraphQL de este repo contra el schema de PRODUCCIÓN.

Por qué existe: los clientes (iOS, Android, Business, Mensajeros, web, panel admin)
escriben sus operaciones a mano contra el backend. Si el backend renombra o quita un
campo, o si un cliente pide uno que no existe, la app falla en tiempo de ejecución y el
compilador no lo detecta (las queries son texto). Este script descarga el schema real que
sirve producción por introspección y valida TODAS las operaciones del repo contra él.

Qué valida (se detecta por extensión, así que es el mismo archivo en todos los repos):
  - Archivos .graphql / .gql, con fragments compartidos entre archivos.
  - Operaciones embebidas en TypeScript/JavaScript/Svelte/Astro (plantillas con
    backticks, p. ej. gql`query ...`).
  - Cadenas de triple comilla en Swift y Kotlin cuyo contenido empieza por
    query / mutation / subscription / fragment (queries "crudas" enviadas por HTTP).

Qué ignora: el schema local (.graphqls), los directorios ocultos (.git, .gradle, ...),
build, node_modules, Pods, DerivedData, dist, y los archivos generados (@generated).

Operaciones que no se pueden validar: las cadenas con interpolación (\\(x) en Swift,
${x} en Kotlin/TypeScript) se construyen en tiempo de ejecución. Se listan como
advertencia; con --strict cuentan como error.

Códigos de salida:
  0  todas las operaciones son válidas
  1  hay operaciones inválidas (o no validables con --strict)
  2  error de infraestructura: no se pudo obtener el schema o no se encontró ninguna
     operación (un CI que no valida nada no debe pasar en verde)

Uso local:
  pip install "graphql-core>=3.2,<3.3"
  python3 scripts/ci/validate_graphql_contract.py
  LLEGO_GRAPHQL_URL=http://localhost:8000/graphql python3 scripts/ci/validate_graphql_contract.py
  python3 scripts/ci/validate_graphql_contract.py --schema-file schema.graphqls   # sin red

Sin dependencias aparte de graphql-core (la descarga usa solo la biblioteca estándar).
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path

try:
    from graphql import (
        DocumentNode,
        FragmentDefinitionNode,
        GraphQLError,
        GraphQLSchema,
        NoDeprecatedCustomRule,
        OperationDefinitionNode,
        Source,
        TypeSystemDefinitionNode,
        TypeSystemExtensionNode,
        build_client_schema,
        build_schema,
        get_introspection_query,
        parse,
        print_ast,
        specified_rules,
        validate,
    )
    from graphql.language import Visitor, visit
    from graphql.validation import NoUndefinedVariablesRule, NoUnusedFragmentsRule
except ImportError:  # pragma: no cover - mensaje claro en lugar de un traceback
    sys.stderr.write(
        'Falta graphql-core. Instálalo con: pip install "graphql-core>=3.2,<3.3"\n'
    )
    raise SystemExit(2)

DEFAULT_URL = "https://llegobackend-production.up.railway.app/graphql"

# Consultas de introspección, de la más completa a la básica. La primera incluye los
# argumentos y campos de input deprecados; la segunda es el respaldo por si el servidor
# (graphql-core < 3.2) no entiende esa variante.
INTROSPECTION_QUERIES = (
    get_introspection_query(descriptions=False, input_value_deprecation=True),
    get_introspection_query(descriptions=False),
)

# Directorios que nunca contienen operaciones propias del repo. Además se ignoran todos
# los directorios ocultos (.git, .gradle, .kotlin, .idea, .build, .astro, ...).
IGNORED_DIRS = {
    "build",
    "node_modules",
    "Pods",
    "DerivedData",
    "dist",
    "out",
    "venv",
    "__pycache__",
    "Carthage",
    "xcuserdata",
}

GRAPHQL_EXTS = {".graphql", ".gql"}
TEMPLATE_EXTS = {".ts", ".tsx", ".mts", ".js", ".jsx", ".mjs", ".cjs", ".svelte", ".astro"}
SWIFT_EXTS = {".swift"}
KOTLIN_EXTS = {".kt", ".kts"}

# Una cadena "parece GraphQL" si empieza (tras comentarios #) por una operación o fragment.
OP_START = re.compile(
    r"\A\s*(?:#[^\n]*\n\s*)*"
    r"(?:(?:query|mutation|subscription)\b\s*(?:[A-Za-z_]\w*)?\s*[({@]"
    r"|fragment\s+[A-Za-z_]\w*\s+on\s+[A-Za-z_]\w*)"
)
TRIPLE_QUOTED = re.compile(r'(?P<hash>#*)"""(?P<body>.*?)"""(?P=hash)', re.S)
TEMPLATE_OPEN = re.compile(
    r"`(?=\s*(?:#[^\n]*\n\s*)*(?:query|mutation|subscription|fragment)\b)"
)
SWIFT_ESCAPE = re.compile(r'\\(["\\nt]|\n)')
SWIFT_ESCAPES = {'"': '"', "\\": "\\", "n": "\n", "t": "\t", "\n": ""}


@dataclass
class Snippet:
    """Texto GraphQL extraído de un archivo, con la línea donde empieza (base 1)."""

    path: str  # relativa a la raíz, con / como separador
    line: int  # línea del archivo que corresponde a la línea 1 del texto
    text: str
    origin: str  # "graphql" o "embebida"


@dataclass
class Skipped:
    path: str
    line: int
    reason: str


@dataclass
class Problem:
    path: str
    line: int
    message: str


@dataclass
class Unit:
    """Operación o fragment validado: lo que se muestra al informar de un fallo."""

    kind: str  # query / mutation / subscription / fragment
    name: str
    path: str
    line: int
    origin: str = "graphql"  # "graphql" (archivo .graphql) o "embebida" (cadena en código)

    @property
    def label(self) -> str:
        return f"{self.kind} {self.name}"


@dataclass
class Report:
    files: set[str] = field(default_factory=set)
    operations: int = 0
    fragments: int = 0
    valid: list[Unit] = field(default_factory=list)
    invalid: list[tuple[Unit, list[Problem]]] = field(default_factory=list)
    broken: list[Problem] = field(default_factory=list)  # errores de sintaxis
    skipped: list[Skipped] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    deprecated: list[tuple[str, list[Problem]]] = field(default_factory=list)


# --------------------------------------------------------------------------- schema


def _is_github() -> bool:
    return os.environ.get("GITHUB_ACTIONS") == "true"


def fetch_schema(url: str, timeout: float, retries: int) -> GraphQLSchema:
    """Descarga el schema de producción por introspección, con reintentos."""
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": "llego-graphql-contract-check/1.0",
    }
    last_error = "sin detalle"
    for attempt in range(1, retries + 1):
        try:
            # Se piden también los argumentos y campos de input deprecados: sin eso la
            # introspección los omite y un argumento deprecado (pero aún válido) daría un
            # falso "Unknown argument". Si el servidor rechaza esa variante, se usa la básica.
            for query in INTROSPECTION_QUERIES:
                body = json.dumps({"query": query}).encode()
                request = urllib.request.Request(url, data=body, headers=headers, method="POST")
                with urllib.request.urlopen(request, timeout=timeout) as response:
                    payload = json.load(response)
                if not payload.get("errors"):
                    break
            if payload.get("errors") or not payload.get("data"):
                raise RuntimeError(
                    f"respuesta sin schema (¿introspección desactivada?): "
                    f"{json.dumps(payload.get('errors'))[:300]}"
                )
            return build_client_schema(payload["data"])
        except (urllib.error.URLError, TimeoutError, OSError, ValueError, RuntimeError) as exc:
            last_error = f"{type(exc).__name__}: {exc}"
            print(f"  intento {attempt}/{retries} fallido: {last_error}", file=sys.stderr)
            if attempt < retries:
                time.sleep(5 * attempt)
    raise RuntimeError(f"no se pudo descargar el schema de {url}: {last_error}")


def load_schema_file(path: Path) -> GraphQLSchema:
    """Carga un schema local (SDL o introspección JSON). Solo para pruebas sin red."""
    text = path.read_text(encoding="utf-8")
    if path.suffix == ".json":
        data = json.loads(text)
        return build_client_schema(data.get("data", data))
    return build_schema(text)


# ----------------------------------------------------------------------- extracción


def _walk(root: Path):
    for current, dirs, files in os.walk(root):
        dirs[:] = sorted(d for d in dirs if not d.startswith(".") and d not in IGNORED_DIRS)
        for name in sorted(files):
            yield Path(current) / name


def _is_generated(text: str) -> bool:
    return "@generated" in text[:600] or "automatically generated" in text[:600].lower()


def _line_of(text: str, index: int) -> int:
    return text.count("\n", 0, index) + 1


def _commented_out(text: str, index: int) -> bool:
    """True si la cadena empieza en una línea comentada (// ..., * ..., /* ...)."""
    line_start = text.rfind("\n", 0, index) + 1
    prefix = text[line_start:index].lstrip()
    return prefix.startswith(("//", "*", "/*"))


class _Unresolved(Exception):
    """La cadena depende de un valor que solo existe en tiempo de ejecución."""


# Constantes de texto con triple comilla (`let campos = """..."""` en Swift, `val campos = """..."""`
# en Kotlin): patrón habitual para compartir una selección de campos entre varias queries.
CONST_DECL = {
    "swift": re.compile(r"\b(?:let|var)\s+([A-Za-z_]\w*)\s*(?::\s*String\s*)?=\s*$"),
    "kotlin": re.compile(r"\b(?:val|var)\s+([A-Za-z_]\w*)\s*(?::\s*String\s*)?=\s*$"),
}
SWIFT_REF = re.compile(r"\\\(\s*(?:\w+\.)*(\w+)\s*\)")
SWIFT_RAW_REF = re.compile(r"\\#\(\s*(?:\w+\.)*(\w+)\s*\)")
KOTLIN_REF = re.compile(r"\$\{\s*(\w+)\s*\}|\$([A-Za-z_]\w*)")


def _inline_const(name: str, consts: dict, lang: str, depth: int) -> str:
    if depth > 4 or name not in consts:
        raise _Unresolved(name)
    body, raw = consts[name]
    text = _resolve(body, consts, lang, raw, depth + 1)
    # Sin saltos de línea para no desplazar las líneas de los errores posteriores.
    return " ".join(re.sub(r"#[^\n]*", "", text).split())


def _resolve(body: str, consts: dict, lang: str, raw: bool, depth: int = 0) -> str:
    """Devuelve el texto GraphQL real de una cadena Swift/Kotlin; _Unresolved si depende
    de valores dinámicos."""
    if lang == "kotlin":
        masked = body.replace("${'$'}", "\0").replace('${"$"}', "\0")
        masked = KOTLIN_REF.sub(
            lambda m: _inline_const(m.group(1) or m.group(2), consts, lang, depth), masked
        )
        return masked.replace("\0", "$")
    ref = SWIFT_RAW_REF if raw else SWIFT_REF
    body = ref.sub(lambda m: _inline_const(m.group(1), consts, lang, depth), body)
    if ("\\#(" if raw else "\\(") in body:
        raise _Unresolved("interpolación")
    return body if raw else SWIFT_ESCAPE.sub(lambda m: SWIFT_ESCAPES[m.group(1)], body)


def _extract_triple(rel: str, text: str, lang: str, report: Report) -> list[Snippet]:
    matches = list(TRIPLE_QUOTED.finditer(text))
    consts = {}
    for m in matches:
        line_start = text.rfind("\n", 0, m.start()) + 1
        decl = CONST_DECL[lang].search(text[line_start : m.start()])
        if decl:
            consts[decl.group(1)] = (m.group("body"), bool(m.group("hash")))
    found = []
    for m in matches:
        body = m.group("body")
        if not OP_START.match(body) or _commented_out(text, m.start()):
            continue
        line = _line_of(text, m.start("body"))
        try:
            resolved = _resolve(body, consts, lang, bool(m.group("hash")))
        except _Unresolved as exc:
            report.skipped.append(
                Skipped(rel, line, f"depende de un valor dinámico ({exc}) que solo existe al ejecutar")
            )
            continue
        found.append(Snippet(rel, line, resolved, "embebida"))
    return found


def _extract_templates(rel: str, text: str, report: Report) -> list[Snippet]:
    found = []
    size = len(text)
    for m in TEMPLATE_OPEN.finditer(text):
        if _commented_out(text, m.start()):
            continue
        start = i = m.end()
        depth = 0
        while i < size:
            ch = text[i]
            if ch == "\\":
                i += 2
                continue
            if depth == 0 and ch == "`":
                break
            if ch == "$" and text[i + 1 : i + 2] == "{":
                depth += 1
                i += 2
                continue
            if depth and ch == "{":
                depth += 1
            elif depth and ch == "}":
                depth -= 1
            i += 1
        body = text[start:i]
        line = _line_of(text, start)
        if not OP_START.match(body):
            continue
        if "${" in body:
            report.skipped.append(Skipped(rel, line, "interpolación en la plantilla"))
            continue
        found.append(Snippet(rel, line, body, "embebida"))
    return found


def collect_snippets(root: Path, report: Report) -> list[Snippet]:
    snippets: list[Snippet] = []
    for path in _walk(root):
        ext = path.suffix.lower()
        if ext not in GRAPHQL_EXTS | TEMPLATE_EXTS | SWIFT_EXTS | KOTLIN_EXTS:
            continue
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError as exc:
            report.warnings.append(f"no se pudo leer {path}: {exc}")
            continue
        rel = path.relative_to(root).as_posix()
        if ext in GRAPHQL_EXTS:
            if text.strip():
                snippets.append(Snippet(rel, 1, text, "graphql"))
            continue
        if _is_generated(text):
            continue
        if ext in TEMPLATE_EXTS:
            snippets += _extract_templates(rel, text, report)
        else:
            snippets += _extract_triple(rel, text, "kotlin" if ext in KOTLIN_EXTS else "swift", report)
    return snippets


# ---------------------------------------------------------------------- validación


def _spreads(node) -> set[str]:
    names: set[str] = set()

    class Collector(Visitor):
        def enter_fragment_spread(self, spread, *_):
            names.add(spread.name.value)

    visit(node, Collector())
    return names


def _closure(node, fragments: dict[str, FragmentDefinitionNode]) -> list[FragmentDefinitionNode]:
    """Fragments que necesita un nodo, de forma transitiva y en orden estable."""
    seen: set[str] = set()
    pending = sorted(_spreads(node))
    while pending:
        name = pending.pop()
        if name in seen or name not in fragments:
            continue
        seen.add(name)
        pending += sorted(_spreads(fragments[name]) - seen)
    return [fragments[n] for n in sorted(seen)]


def _problems(errors: list[GraphQLError], sources: dict[str, tuple[str, int]]) -> list[Problem]:
    """Convierte errores de graphql-core en (archivo, línea absoluta, mensaje) sin repetir."""
    out: list[Problem] = []
    seen = set()
    for err in errors:
        path, line = "?", 0
        if err.source is not None and err.locations:
            base_path, base_line = sources.get(err.source.name, ("?", 1))
            path, line = base_path, base_line + err.locations[0].line - 1
        key = (path, line, err.message)
        if key not in seen:
            seen.add(key)
            out.append(Problem(path, line, err.message))
    return sorted(out, key=lambda p: (p.path, p.line, p.message))


def validate_snippets(
    schema: GraphQLSchema, snippets: list[Snippet], report: Report, check_deprecated: bool
) -> None:
    sources: dict[str, tuple[str, int]] = {}
    operations: list[tuple[OperationDefinitionNode, Unit]] = []
    fragments: dict[str, FragmentDefinitionNode] = {}
    fragment_origin: dict[str, tuple[str, int]] = {}

    for snippet in snippets:
        report.files.add(snippet.path)
        name = f"{snippet.path}:{snippet.line}"
        sources[name] = (snippet.path, snippet.line)
        try:
            document = parse(Source(snippet.text, name=name))
        except GraphQLError as err:
            report.broken.append(_problems([err], sources)[0])
            continue
        executable = [
            d for d in document.definitions
            if not isinstance(d, (TypeSystemDefinitionNode, TypeSystemExtensionNode))
        ]
        for definition in executable:
            loc = definition.loc
            line = snippet.line + (_line_of(snippet.text, loc.start) - 1 if loc else 0)
            if isinstance(definition, OperationDefinitionNode):
                unit = Unit(
                    definition.operation.value,
                    definition.name.value if definition.name else "<anónima>",
                    snippet.path,
                    line,
                    snippet.origin,
                )
                operations.append((definition, unit))
            elif isinstance(definition, FragmentDefinitionNode):
                key = definition.name.value
                if key in fragments:
                    if print_ast(fragments[key]) != print_ast(definition):
                        report.warnings.append(
                            f'fragment "{key}" definido con contenido distinto en '
                            f"{fragment_origin[key][0]}:{fragment_origin[key][1]} y "
                            f"{snippet.path}:{line}; se valida contra el primero"
                        )
                    continue
                fragments[key] = definition
                fragment_origin[key] = (snippet.path, line)

    report.operations = len(operations)
    report.fragments = len(fragments)

    used_fragments: set[str] = set()
    for node, unit in operations:
        needed = _closure(node, fragments)
        used_fragments |= {f.name.value for f in needed}
        document = DocumentNode(definitions=(node, *needed))
        errors = validate(schema, document)
        if errors:
            report.invalid.append((unit, _problems(errors, sources)))
        else:
            report.valid.append(unit)
        if not errors and check_deprecated:
            warnings = validate(schema, document, rules=[NoDeprecatedCustomRule])
            if warnings:
                report.deprecated.append((unit.label, _problems(warnings, sources)))

    # Fragments que ninguna operación usa: se validan solos. Se omiten las reglas que
    # dependen de la operación que los use (fragment sin uso, variables no definidas).
    standalone_rules = [
        r for r in specified_rules if r not in (NoUnusedFragmentsRule, NoUndefinedVariablesRule)
    ]
    for key, definition in sorted(fragments.items()):
        if key in used_fragments:
            continue
        needed = _closure(definition, fragments)
        errors = validate(
            schema, DocumentNode(definitions=(definition, *needed)), rules=standalone_rules
        )
        unit = Unit("fragment", key, *fragment_origin[key])
        if errors:
            report.invalid.append((unit, _problems(errors, sources)))
        else:
            report.valid.append(unit)


# ------------------------------------------------------------------------- salida


def _escape_annotation(value: str, prop: bool = False) -> str:
    value = value.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
    if prop:
        value = value.replace(":", "%3A").replace(",", "%2C")
    return value


def _annotate(level: str, path: str, line: int, message: str) -> None:
    if _is_github():
        print(
            f"::{level} file={_escape_annotation(path, True)},line={max(line, 1)},"
            f"title=Contrato GraphQL::{_escape_annotation(message)}"
        )


def print_report(report: Report, schema_label: str, strict: bool, verbose: bool) -> int:
    print(f"\nSchema: {schema_label}")
    embedded = sum(1 for u in report.valid + [u for u, _ in report.invalid] if u.origin == "embebida")
    print(
        f"Analizado: {report.operations} operaciones y {report.fragments} fragments en "
        f"{len(report.files)} archivos (operaciones embebidas en código: {embedded})"
    )

    if verbose:
        print("\nVálidas:")
        for unit in report.valid:
            print(f"  ✓ {unit.label}  [{unit.path}:{unit.line}]")

    for problem in sorted(report.broken, key=lambda p: (p.path, p.line)):
        print(f"\n✗ SINTAXIS  {problem.path}:{problem.line}\n    - {problem.message}")
        _annotate("error", problem.path, problem.line, f"Error de sintaxis: {problem.message}")

    for unit, problems in sorted(report.invalid, key=lambda item: (item[0].path, item[0].line)):
        print(f"\n✗ {unit.label}  [{unit.path}:{unit.line}]")
        for problem in problems:
            where = f"{problem.path}:{problem.line}" if problem.path != unit.path else f"línea {problem.line}"
            print(f"    - {where}: {problem.message}")
            _annotate("error", problem.path, problem.line, f"{unit.label}: {problem.message}")

    if report.skipped:
        print(f"\nNo validadas ({len(report.skipped)}): se construyen en tiempo de ejecución")
        for item in report.skipped:
            print(f"  ? {item.path}:{item.line}  {item.reason}")
            _annotate("error" if strict else "warning", item.path, item.line,
                      f"Operación no validable: {item.reason}")

    for message in report.warnings:
        print(f"\nAdvertencia: {message}")
        if _is_github():
            print(f"::warning title=Contrato GraphQL::{_escape_annotation(message)}")

    if report.deprecated:
        print(f"\nUsan campos deprecados ({len(report.deprecated)} operaciones)")
        for label, problems in report.deprecated:
            for problem in problems:
                print(f"  ~ {label}  [{problem.path}:{problem.line}]  {problem.message}")
                _annotate("warning", problem.path, problem.line, f"{label}: {problem.message}")

    invalid = len(report.invalid) + len(report.broken) + (len(report.skipped) if strict else 0)
    print(
        f"\nRESULTADO: {report.operations} operaciones, {len(report.invalid)} inválidas, "
        f"{len(report.broken)} con error de sintaxis, {len(report.skipped)} no validables"
        + (" (con --strict cuentan como error)" if strict and report.skipped else "")
    )
    if invalid:
        print(
            "Las operaciones inválidas fallarán contra producción. Corrige el cliente o, "
            "si el cambio es del backend, coordina el despliegue antes."
        )
        return 1
    print("OK: el repo es compatible con el schema de producción.")
    return 0


# --------------------------------------------------------------------------- main


def main(argv: list[str] | None = None) -> int:
    default_root = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(
        description="Valida las operaciones GraphQL del repo contra el schema de producción."
    )
    parser.add_argument("--root", type=Path, default=default_root,
                        help="raíz del repo a analizar (por defecto, la de este script)")
    parser.add_argument("--schema-url",
                        default=os.environ.get("LLEGO_GRAPHQL_URL") or DEFAULT_URL,
                        help=f"endpoint GraphQL (env LLEGO_GRAPHQL_URL; por defecto {DEFAULT_URL})")
    parser.add_argument("--schema-file", type=Path,
                        help="usar un schema local (.graphql/.graphqls o introspección .json) en lugar de descargarlo")
    parser.add_argument("--strict", action="store_true",
                        help="contar como error las operaciones que no se pueden validar")
    parser.add_argument("--no-deprecated", action="store_true",
                        help="no avisar del uso de campos deprecados")
    parser.add_argument("--timeout", type=float, default=60.0, help="timeout de la descarga (s)")
    parser.add_argument("--retries", type=int, default=3, help="intentos de descarga")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args(argv)

    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")

    root = args.root.resolve()
    report = Report()

    try:
        if args.schema_file:
            schema = load_schema_file(args.schema_file)
            label = str(args.schema_file)
        else:
            print(f"Descargando el schema de {args.schema_url} ...")
            schema = fetch_schema(args.schema_url, args.timeout, args.retries)
            label = args.schema_url
    except (RuntimeError, OSError, ValueError, GraphQLError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        _annotate("error", "scripts/ci/validate_graphql_contract.py", 1, str(exc))
        return 2

    snippets = collect_snippets(root, report)
    validate_snippets(schema, snippets, report, check_deprecated=not args.no_deprecated)

    if report.operations == 0 and not report.broken:
        msg = f"no se encontró ninguna operación GraphQL en {root}; ¿ruta o extensiones incorrectas?"
        print(f"ERROR: {msg}", file=sys.stderr)
        return 2
    return print_report(report, label, args.strict, args.verbose)


if __name__ == "__main__":
    raise SystemExit(main())
