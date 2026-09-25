## Why

Turso is beta and its sqlite3-compatible C API is only partially guaranteed; ELPI builtins must stream rows lazily across backtracking. Both are load-bearing assumptions of the whole design (lat.md/decisions.md D1, D4) and must be proven before building on them.

## What Changes

- dune project skeleton on a project-local OCaml 5 opam switch
- Turso C library built from source and sqlite3-ocaml linked against it
- ELPI embedded with a streaming nondeterministic builtin over a SQL cursor
- CI on macOS and Linux against Turso and stock SQLite
- Recorded Turso C-API gap list

## Capabilities

### New Capabilities
<!-- none: tooling spike, skip_specs -->

### Modified Capabilities
<!-- capabilities introduced by earlier milestones are extended via ADDED requirements in this change's specs -->

## Impact

Milestone M0 — Build spike of the elpilite roadmap (lat.md/roadmap.md). Code under `src/`, `bin/`, `test/`.
