## Why

Agents must learn and revise rules and schema at runtime; the database must be the single source of truth for the program, guarded by a validation gate.

## What Changes

- clauses stored as bitemporal quoted terms; loader with compiled-program cache
- validation gate and structured errors
- rule/schema delta operations and migrations
- namespaces and capabilities
- import/export; fuzz testing

## Capabilities

### New Capabilities
- `program-catalog`
- `transactional-updates`

### Modified Capabilities
<!-- capabilities introduced by earlier milestones are extended via ADDED requirements in this change's specs -->

## Impact

Milestone M4 — Program catalog of the elpilite roadmap (lat.md/roadmap.md). Code under `src/`, `bin/`, `test/`.
