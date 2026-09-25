## Why

With storage in place, agents need snapshot-consistent queries, time travel, metadata, negation, aggregation and safe atomic writes with constraints.

## What Changes

- snapshot sessions and EDB builtins with temporal/namespace filters
- `as_of`, `valid_at`, `in_ns`, `all_versions`, `meta`
- step/depth limits and cancellation
- `update` deltas (assert/retract/correct), optimistic concurrency, constraint enforcement
- negation, `:open` relations, aggregates, structured errors
- reference suite on both backends

## Capabilities

### New Capabilities
- `schema-ddl`
- `bitemporal-facts`
- `query-engine`
- `transactional-updates`

### Modified Capabilities
<!-- capabilities introduced by earlier milestones are extended via ADDED requirements in this change's specs -->

## Impact

Milestone M2 — Query and update of the elpilite roadmap (lat.md/roadmap.md). Code under `src/`, `bin/`, `test/`.
