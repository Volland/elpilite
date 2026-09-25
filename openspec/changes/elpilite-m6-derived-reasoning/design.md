## Context

M6 — Derived reasoning. Architecture and rationale are maintained in `lat.md/`; this change implements its slice.

## Goals / Non-Goals

**Goals:** deliver the tasks in tasks.md so that the milestone's "done when" criterion in lat.md/roadmap.md holds.

**Non-Goals:** work belonging to other milestones.

## Decisions

See lat.md/evaluation.md (Materialized Views, Semiring Provenance), lat.md/memory.md and decisions D6, D7.

## Risks / Trade-offs

- [DRed cost on large retractions] → insert-only fast path, batching, measure.
