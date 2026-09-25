## Context

M5 — Vectors. Architecture and rationale are maintained in `lat.md/`; this change implements its slice.

## Goals / Non-Goals

**Goals:** deliver the tasks in tasks.md so that the milestone's "done when" criterion in lat.md/roadmap.md holds.

**Non-Goals:** work belonging to other milestones.

## Decisions

See lat.md/vectors.md, lat.md/memory.md#Access Tracking and decisions D4, D11.

## Risks / Trade-offs

- [Filtered ANN recall] → pre-/post-filter choice with over-fetch; exact scan for as_of.
