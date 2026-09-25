## 1. M6 — Materialized views and weighted reasoning

- [ ] 1.1 Datalog fragment checker for `:materialized` rules
- [ ] 1.2 Semi-naive evaluation: `WITH RECURSIVE` for linear recursion, OCaml loop otherwise
- [ ] 1.3 Store derived facts with `derived_by Rule Premises` provenance
- [ ] 1.4 DRed maintenance on commit with insert-only fast path
- [ ] 1.5 Property test: incremental maintenance equals recomputation after random insert/retract sequences
- [ ] 1.6 Semiring library (max_product, min_max, top_k K, add_mult) as OCaml builtins
- [ ] 1.7 `:weighted` rewrite pass; `with_semiring` query form; rule weights
- [ ] 1.8 Reject recursive non-idempotent semirings; restrict weighted aggregates to count/sum
- [ ] 1.9 Top-k proofs as explanations and as provenance for materialized weighted facts
- [ ] 1.10 Scheduled jobs (time and commit-count triggers) in the owner process
- [ ] 1.11 `forget` soft/force with tombstones; term-DAG mark-and-sweep GC
