## Why

Recursive and consolidation queries need terminating, incrementally maintained views; uncertainty needs principled propagation and explanations; memory needs jobs and safe forgetting.

## What Changes

- `:materialized` with semi-naive evaluation and DRed
- `:weighted` semiring rewriting and top-k proofs
- scheduled jobs, `forget`, tombstones, term GC

## Capabilities

### New Capabilities
- `materialized-views`
- `weighted-reasoning`
- `memory-maintenance`
- `term-store`
- `transactional-updates`

### Modified Capabilities
<!-- capabilities introduced by earlier milestones are extended via ADDED requirements in this change's specs -->

## Impact

Milestone M6 — Derived reasoning of the elpilite roadmap (lat.md/roadmap.md). Code under `src/`, `bin/`, `test/`.
