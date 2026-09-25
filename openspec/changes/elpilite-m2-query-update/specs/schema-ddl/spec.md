## ADDED Requirements

### Requirement: Integrity constraints
The system SHALL support primary keys, unique constraints, functional dependencies, foreign keys and cardinality bounds, enforced on every update and evaluated per valid-time interval.

#### Scenario: Key violation rejected
- **WHEN** `:key(1 2)` is declared on `knows` and an update asserts a second current `knows alice bob _` with an overlapping valid-time interval
- **THEN** the update fails with `error (key_violation ...)`

#### Scenario: Non-overlapping valid times allowed
- **WHEN** an FD `works_at [1] -> [2]` exists and facts `works_at alice acme` valid 2021–2023 and `works_at alice globex` valid from 2023 are asserted
- **THEN** both are accepted

#### Scenario: Foreign key enforced
- **WHEN** a foreign key requires `about`'s topic to exist in `topic_decl` and an update asserts `about m1 t9` with no current `topic_decl t9`
- **THEN** the update fails with `error (fk_violation ...)`
