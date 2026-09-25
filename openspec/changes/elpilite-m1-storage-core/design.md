## Context

M1 — Storage core. Architecture and rationale are maintained in `lat.md/`; this change implements its slice.

## Goals / Non-Goals

**Goals:** deliver the tasks in tasks.md so that the milestone's "done when" criterion in lat.md/roadmap.md holds.

**Non-Goals:** work belonging to other milestones.

## Decisions

See lat.md/storage.md (Store Signature, Term DAG, Catalog, Bitemporal Rows, Physical Schema) and lat.md/decisions.md D2–D5.

## Risks / Trade-offs

- [Hash-consing write amplification] → batched `ON CONFLICT DO NOTHING` inserts and in-process hash→id cache.
- [Backend divergence] → differential harness from day one.
