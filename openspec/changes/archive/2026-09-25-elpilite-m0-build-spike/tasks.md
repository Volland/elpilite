## 1. M0 — Build spike

- [x] 1.1 Create dune project skeleton (`dune-project`, `src/`, `bin/`, `test/`) on a project-local OCaml 5.3 switch with ELPI 1.18.2 (`make switch`, `scripts/sw`)
- [x] 1.2 Build and pin Turso's sqlite3-compatible C library (`scripts/build-turso.sh`, `vendor/turso.rev`); bind it through a runtime-loaded (dlopen) C shim instead of `sqlite3-ocaml`, so Turso and SQLite coexist in one process
- [x] 1.3 Record the Turso C-API gap list (symbols used by sqlite3-ocaml that are missing or stubbed) in `lat.md/storage.md`
- [x] 1.4 Embed ELPI: load an `.elpi` program and run a goal from OCaml
- [x] 1.5 Implement one nondeterministic ELPI builtin that streams rows from a Turso cursor across backtracking; validate laziness (early stop)
- [x] 1.6 CI on macOS arm64 and Linux x64 running `dune test` against both Turso and stock SQLite
