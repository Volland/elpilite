## Context

M2 — Query and update. Architecture and rationale are maintained in `lat.md/`; this change implements its slice.

## Goals / Non-Goals

**Goals:** deliver the tasks in tasks.md so that the milestone's "done when" criterion in lat.md/roadmap.md holds.

**Non-Goals:** work belonging to other milestones.

## Decisions

See lat.md/language.md (Snapshots, Metadata Access, Queries, Updates, Negation, Aggregation) and decisions D12, D14.

## Risks / Trade-offs

- [Step limits reject legit queries] → configurable per session/call.
- [Conflict detection granularity] → key-level; documented.
