## Purpose

Makes every stored fact carry transaction time, valid time, confidence, provenance and namespace, never losing history, so agents can reason about when and why they believe things.

## ADDED Requirements

### Requirement: System metadata on every fact
Every stored fact SHALL carry transaction-time start/end, valid-time start/end, confidence in [0,1], a provenance term, and a namespace.

#### Scenario: Defaults applied
- **WHEN** a fact is asserted without metadata
- **THEN** it has confidence 1.0, valid time from −∞ to open, the committing transaction as transaction start, the session's namespace, and provenance identifying the asserting client

#### Scenario: Confidence out of range rejected
- **WHEN** a fact is asserted with confidence 1.3
- **THEN** the update fails with `error (conf_out_of_range 1.3)`

### Requirement: Append-only retraction
Retracting a fact SHALL end its transaction-time interval instead of deleting it.

#### Scenario: Retracted fact invisible now, visible in the past
- **WHEN** a fact asserted at transaction 10 is retracted at transaction 20
- **THEN** a current query does not return it, and `as_of 15` returns it

### Requirement: Current-state default visibility
Queries without temporal modifiers SHALL see only facts whose transaction interval is open and whose valid interval contains the current time, within visible namespaces.

#### Scenario: Future-valid fact hidden
- **WHEN** a fact is asserted with valid time starting next year
- **THEN** a default query does not return it and `valid_at` next year does

### Requirement: Time travel
The system SHALL evaluate any goal as of a past transaction time (`as_of`), at an arbitrary valid time (`valid_at`), or across all versions (`all_versions`).

#### Scenario: Belief history
- **WHEN** `works_at alice acme` was corrected to `works_at alice globex` at transaction 50
- **THEN** `all_versions (works_at alice C)` returns both with their transaction intervals

### Requirement: Metadata access predicates
The system SHALL provide predicates that return the metadata of the specific stored fact that satisfied a goal.

#### Scenario: Read confidence and provenance
- **WHEN** a client runs `meta (knows alice bob _) M`
- **THEN** `M` lists transaction interval, valid interval, confidence, provenance term and namespace of that fact

### Requirement: Correction preserves history
A `correct` operation SHALL atomically retract the current version and assert a new version of the same key.

#### Scenario: Correct a fact
- **WHEN** `correct (works_at alice globex) [valid 2023 none]` is applied while `works_at alice acme` is current
- **THEN** exactly one current version exists afterwards and the previous version remains queryable with `as_of`
