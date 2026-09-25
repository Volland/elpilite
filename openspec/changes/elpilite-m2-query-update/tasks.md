## 1. M2 — Query and update

- [ ] 1.1 Session and snapshot model: snapshot tx id, visible namespaces, valid-time "now"
- [ ] 1.2 EDB builtins per `:persistent` relation with injected tx/valid/ns filters
- [ ] 1.3 `as_of`, `valid_at`, `in_ns`, `all_versions` modifiers
- [ ] 1.4 `meta`, `conf_of`, `src_of` metadata predicates
- [ ] 1.5 Step/depth limit hook and cancellation flag; structured `step_limit` / `depth_limit` / `cancelled` errors
- [ ] 1.6 Forbid write operations in query context (`error (write_in_query …)`)
- [ ] 1.7 `update Goal`: solve, extract delta, delta operation parser (`assert`, `retract`, `correct`, …)
- [ ] 1.8 Update applier: transaction, bitemporal writes, retraction by closing `tx_to`, `correct`
- [ ] 1.9 Optimistic concurrency: `base_tx`, touched-key conflict detection
- [ ] 1.10 Constraint enforcement: keys, unique, FD (valid-time aware), FK, cardinality
- [ ] 1.11 Stratified negation-as-failure with runtime safety check; `:open` relations with `known`/`unknown`
- [ ] 1.12 Aggregates: `count`, `aggr`, `group`, `top_k`, `argmax`, `argmin`, `order_by` with polymorphic ELPI types
- [ ] 1.13 Structured error term catalogue (`src/lang/errors`) with JSON encoding
- [ ] 1.14 Reference suite of ELPI programs with expected answers, run on both backends
