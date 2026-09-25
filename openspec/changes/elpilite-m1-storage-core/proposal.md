## Why

Everything else rests on durable, typed, deduplicated storage of λProlog terms with a backend-neutral interface and a differential twin.

## What Changes

- `STORE` signature with Turso and SQLite backends
- system tables, symbol interning, hash-consed term DAG with de Bruijn binders
- `:persistent` declarations with type-derived column layout and bitemporal system columns
- typed insert and lookup; format-version check
- property and backend-differential test harnesses

## Capabilities

### New Capabilities
- `storage-backend`
- `term-store`
- `schema-ddl`

### Modified Capabilities
<!-- capabilities introduced by earlier milestones are extended via ADDED requirements in this change's specs -->

## Impact

Milestone M1 — Storage core of the elpilite roadmap (lat.md/roadmap.md). Code under `src/`, `bin/`, `test/`.
