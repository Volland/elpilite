## Why

Per-call EDB evaluation causes N+1 round trips; relational conjunctions must run as single SQL statements with answers identical to naive evaluation.

## What Changes

- ELPI-in-ELPI rewrite-pass framework
- block detection and SQL compilation (joins, NOT EXISTS, GROUP BY, ORDER BY/LIMIT)
- term-pattern pushdown
- temporal filter injection
- pushdown-vs-naive differential suite and N+1 benchmark

## Capabilities

### New Capabilities
- `query-pushdown`

### Modified Capabilities
<!-- capabilities introduced by earlier milestones are extended via ADDED requirements in this change's specs -->

## Impact

Milestone M3 — Pushdown of the elpilite roadmap (lat.md/roadmap.md). Code under `src/`, `bin/`, `test/`.
