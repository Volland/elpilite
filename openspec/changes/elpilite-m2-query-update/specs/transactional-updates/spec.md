## Purpose

Expresses all writes as a pure ELPI goal computing a delta that the system validates and applies atomically, so writes are deterministic, checkable and safe under backtracking.

## ADDED Requirements

### Requirement: Delta-based updates
An `update Goal` SHALL evaluate `Goal` on a snapshot, take the first solution's `Delta` list, and apply all its operations as one transaction.

#### Scenario: Multi-operation update
- **WHEN** `update (Delta = [retract F1, assert F2 [conf 0.8], add_rule R])` is applied
- **THEN** after commit F1 is not current, F2 is current with confidence 0.8, and R is active — in a single new transaction

#### Scenario: Goal failure
- **WHEN** the update goal has no solution
- **THEN** nothing is written and the result is `error (no_delta)`

### Requirement: Supported delta operations
The delta language SHALL support the fact operations `assert`, `retract` and `correct`; any other operation not enabled by the engine SHALL be rejected.

#### Scenario: Unknown operation
- **WHEN** a delta contains an unrecognised operation
- **THEN** the update fails with `error (bad_delta_op ...)` and nothing is written

### Requirement: All-or-nothing validation
If any operation in a delta fails type, constraint, capability or catalog validation, the whole update SHALL be rejected with a structured error and no effects.

#### Scenario: One bad operation
- **WHEN** a delta has 99 valid asserts and one key violation
- **THEN** no facts are written and the error identifies the violating operation

### Requirement: Optimistic concurrency
Updates SHALL carry the snapshot transaction they were computed from; if any key they touch changed after that transaction, the update SHALL be rejected as a conflict.

#### Scenario: Conflict detected
- **WHEN** client A computes a delta retracting `works_at alice acme` at transaction 10 and client B commits a correction to the same key at transaction 11
- **THEN** client A's update fails with `error (conflict ...)` and client A can retry on a fresh snapshot

#### Scenario: Disjoint keys commit
- **WHEN** two updates computed from the same snapshot touch disjoint keys
- **THEN** both commit successfully

### Requirement: No triggers
The system SHALL NOT execute user code as a side effect of commits other than materialized-view maintenance and explicitly scheduled jobs.

#### Scenario: Commit runs no user callbacks
- **WHEN** a fact is asserted
- **THEN** no user-defined rule is executed for side effects other than view maintenance
