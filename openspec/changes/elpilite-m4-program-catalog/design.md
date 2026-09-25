## Context

M4 — Program catalog. Architecture and rationale are maintained in `lat.md/`; this change implements its slice.

## Goals / Non-Goals

**Goals:** deliver the tasks in tasks.md so that the milestone's "done when" criterion in lat.md/roadmap.md holds.

**Non-Goals:** work belonging to other milestones.

## Decisions

See lat.md/rules.md and decision D8.

## Risks / Trade-offs

- [Program reload cost] → cache keyed by catalog version; fact-only transactions reuse it.
