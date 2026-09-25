## 1. M0 — Build spike

- [ ] 1.1 Create dune project skeleton (`dune-project`, `src/`, `bin/`, `test/`) pinned to OCaml 5.x and ELPI 1.18 in an opam lock file
- [ ] 1.2 Build and vendor/pin Turso's sqlite3-compatible C library; build `sqlite3-ocaml` against it via a dune rule
- [ ] 1.3 Record the Turso C-API gap list (symbols used by sqlite3-ocaml that are missing or stubbed) in `lat.md/storage.md`
- [ ] 1.4 Embed ELPI: load an `.elpi` program and run a goal from OCaml
- [ ] 1.5 Implement one nondeterministic ELPI builtin that streams rows from a Turso cursor across backtracking; validate laziness (early stop)
- [ ] 1.6 CI on macOS arm64 and Linux x64 running `dune test` against both Turso and stock SQLite
