## Purpose

Provides policy-free primitives that agent memory models need — access statistics, scheduled maintenance, and safe, audited forgetting — without imposing any particular memory model.

## ADDED Requirements

### Requirement: No built-in memory model
The engine SHALL NOT define or load any memory schema (episodic, semantic, tiers) by default; reference models SHALL be optional examples.

#### Scenario: Empty database
- **WHEN** a new database is created
- **THEN** it contains no user relations or rules beyond engine builtins

### Requirement: Opt-in access tracking
Relations marked `:track_access` SHALL record per-fact access count and last-access time for facts returned by queries; statistics MAY lag and SHALL NOT turn read queries into write transactions.

#### Scenario: Access recorded
- **WHEN** a tracked fact is returned by a query and statistics are flushed
- **THEN** its access count increased and last-access time is at or after the query time

#### Scenario: Untracked relation
- **WHEN** a relation is not marked `:track_access`
- **THEN** no access statistics are kept for it
