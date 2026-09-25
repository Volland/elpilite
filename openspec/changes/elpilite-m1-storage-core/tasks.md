## 1. M1 — Storage core

- [ ] 1.1 Define `STORE` signature and `Value.t`; implement Turso backend
- [ ] 1.2 Implement SQLite backend (same signature) and backend selection at open
- [ ] 1.3 System tables: `meta` (format/engine version, current tx), `sym`, `term`, `rel`, `constraint`, `clause`, `ns`, `owner`, tombstones
- [ ] 1.4 Symbol interning with in-process cache
- [ ] 1.5 Term encoding: canonical binary form, de Bruijn conversion from ELPI terms, BLAKE3-128 hashing, hash-consed insert (`ON CONFLICT DO NOTHING`)
- [ ] 1.6 Term decoding with LRU `term_id ↔ ELPI term` cache
- [ ] 1.7 Reject non-ground facts with `error (non_ground …)`
- [ ] 1.8 `:persistent` declaration handling: derive column layout from ELPI types, create physical table with bitemporal system columns and partial indexes
- [ ] 1.9 Typed insert via ELPI type checker; lookup by bound arguments
- [ ] 1.10 Format-version check on open (refuse newer)
- [ ] 1.11 QCheck generators for typed ELPI terms; property tests: round-trip, α-equivalent ⇒ same id, dedup
- [ ] 1.12 Backend differential harness (run a scenario on both backends, diff results)
