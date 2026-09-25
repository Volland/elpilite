## Context

M0 — Build spike. Architecture and rationale are maintained in `lat.md/`; this change implements its slice.

## Goals / Non-Goals

**Goals:** deliver the tasks in tasks.md so that the milestone's "done when" criterion in lat.md/roadmap.md holds.

**Non-Goals:** work belonging to other milestones.

## Decisions

- Toolchain: project-local opam switch (`_opam/`) with OCaml 5.x so the default switch is untouched.
- Turso built from source with cargo at a pinned git revision; the C library (sqlite3-compatible API) is linked into sqlite3-ocaml through a dune rule selecting the library path via an environment variable (`ELPILITE_BACKEND_LIB`).
- Streaming builtin: implemented with ELPI's builtin API; if lazy nondeterminism across backtracking is not supported, fall back to chunked prefetch with a continuation (design risk in lat.md/evaluation.md).

## Risks / Trade-offs

- [Turso C API gaps] → gap list recorded; C shim if needed.
- [ELPI API cannot stream] → chunked prefetch fallback.
