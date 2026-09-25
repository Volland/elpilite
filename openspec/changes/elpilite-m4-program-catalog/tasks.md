## 1. M4 — Rules in the database

- [ ] 1.1 Store clauses as quoted terms in `clause` with attributes, namespace, provenance, bitemporal columns
- [ ] 1.2 Program loader per snapshot with compiled-program cache keyed by catalog version
- [ ] 1.3 `as_of` over rules (load program at historical catalog version)
- [ ] 1.4 Validation gate: capability → type → mode/safety/fragment → whole-program stratification → constraint validation → trial run
- [ ] 1.5 `add_rule`, `drop_rule`, `declare`, `alter` delta operations through the gate
- [ ] 1.6 Migrations: `migrate` with ELPI mapping rules, closing old relation's catalog entry
- [ ] 1.7 Namespaces and capability grants; enforcement on every operation
- [ ] 1.8 `import` / `export` (ELPI text ⇄ database, `--as-of`)
- [ ] 1.9 Fuzz test: random and malformed rules and deltas never corrupt state; every rejection is a structured error
