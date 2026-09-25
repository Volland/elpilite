## Context

M0 — Build spike. Architecture and rationale are maintained in `lat.md/`; this change implements its slice.

## Goals / Non-Goals

**Goals:** deliver the tasks in tasks.md so that the milestone's "done when" criterion in lat.md/roadmap.md holds.

**Non-Goals:** work belonging to other milestones.

## Decisions

- Toolchain: project-local opam switch (`_opam/`) with OCaml 5.x so the default switch is untouched.
- Turso built from source with cargo at a pinned git revision (`vendor/turso.rev`). Instead of linking `sqlite3-ocaml` (which would clash with stock SQLite's identical symbols), backends are loaded at runtime with `dlopen(RTLD_LOCAL)` through a small C shim with a per-library function table; library paths come from `ELPILITE_TURSO_LIB` / `ELPILITE_SQLITE_LIB` or defaults.
- Test runner: in-house `testkit` instead of alcotest (alcotest's build chain needs ocamlbuild, which segfaults on macOS 26 with OCaml 5.x).
- Streaming builtin: implemented with ELPI's builtin API; if lazy nondeterminism across backtracking is not supported, fall back to chunked prefetch with a continuation (design risk in lat.md/evaluation.md).

## Risks / Trade-offs

- [Turso C API gaps] → gap list recorded; C shim if needed.
- [ELPI API cannot stream] → chunked prefetch fallback.
