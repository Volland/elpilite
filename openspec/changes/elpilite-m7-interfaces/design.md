## Context

M7 — Interfaces. Architecture and rationale are maintained in `lat.md/`; this change implements its slice.

## Goals / Non-Goals

**Goals:** deliver the tasks in tasks.md so that the milestone's "done when" criterion in lat.md/roadmap.md holds.

**Non-Goals:** work belonging to other milestones.

## Decisions

See lat.md/interfaces.md and decisions D9, D10.

## Risks / Trade-offs

- [OCaml runtime inside Node] → single dedicated OCaml thread; stress tests.
