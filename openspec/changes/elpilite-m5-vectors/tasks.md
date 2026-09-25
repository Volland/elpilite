## 1. M5 — Vectors

- [ ] 1.1 `vec` builtin type and storage; dimension check at insert
- [ ] 1.2 `Vector_index.S` signature; Turso native vector implementation
- [ ] 1.3 sqlite-vec implementation for the SQLite backend
- [ ] 1.4 `similar` builtin with best-first streaming; bitemporal index lifecycle (retract removes from current index)
- [ ] 1.5 `similar` inside pushdown blocks with pre-/post-filter selection and over-fetch
- [ ] 1.6 Historical (`as_of`) vector search via exact scan
- [ ] 1.7 `rank_recall` combined scoring compiled to one SQL statement
- [ ] 1.8 `embed` host hook registration (OCaml API)
- [ ] 1.9 `:track_access` with buffered access stats flushed on write/timer
- [ ] 1.10 Hybrid retrieval benchmark (1 M vectors, symbolic filter, top-20)
