## 1. M3 — Pushdown

- [ ] 1.1 Rewrite-pass framework (ELPI-in-ELPI over quoted clauses) integrated into program loading
- [ ] 1.2 Block detection: maximal runs of EDB goals, comparisons, `not` over EDB, aggregates; boundaries at IDB, `=>`, `pi`, cut, unknown builtins
- [ ] 1.3 SQL compiler for blocks (joins, filters, `NOT EXISTS`, `GROUP BY`, `ORDER BY … LIMIT`), prepared-statement cache
- [ ] 1.4 Term-pattern pushdown via `term` table joins to configurable depth
- [ ] 1.5 Temporal/namespace filter injection for blocks, including `as_of`/`valid_at`/`in_ns`
- [ ] 1.6 Runtime flag to disable pushdown; pushdown-vs-naive differential test over the full reference suite
- [ ] 1.7 N+1 benchmark and CI tracking
