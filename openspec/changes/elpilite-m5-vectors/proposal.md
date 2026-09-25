## Why

The neural half of neuro-symbolic memory: embeddings, similarity search joined with symbolic constraints, combined ranking, and access statistics for recency.

## What Changes

- `vec` type and `Vector_index` for both backends
- `similar` builtin and in-block hybrid execution
- `rank_recall`
- `embed` host hook
- opt-in access tracking
- hybrid retrieval benchmark

## Capabilities

### New Capabilities
- `vector-retrieval`
- `memory-maintenance`

### Modified Capabilities
<!-- capabilities introduced by earlier milestones are extended via ADDED requirements in this change's specs -->

## Impact

Milestone M5 — Vectors of the elpilite roadmap (lat.md/roadmap.md). Code under `src/`, `bin/`, `test/`.
