## Purpose

Stores the program — rules, declarations and constraints — in the database as versioned data that agents can evolve at runtime through a validation gate, with structured errors and controlled schema evolution.

## ADDED Requirements

### Requirement: Database is the source of truth for the program
Rules, declarations and constraints SHALL be stored in the database and SHALL be what the engine evaluates; source files SHALL be only an import/export format.

#### Scenario: Rules survive reopen
- **WHEN** a rule is added via update and the database is reopened with no source files
- **THEN** the rule is active

#### Scenario: Export and import round-trip
- **WHEN** a program is exported to ELPI text and imported into an empty database
- **THEN** the new database has an equivalent program and schema

### Requirement: Versioned program
Program changes SHALL be bitemporal; `as_of T` SHALL evaluate goals using the rules active at transaction `T`.

#### Scenario: Old conclusion reproducible
- **WHEN** rule R was dropped at transaction 30
- **THEN** `as_of 25 G` still uses R to answer G

### Requirement: Rule provenance
Every stored rule SHALL record its author namespace and a provenance term.

#### Scenario: Who added this rule
- **WHEN** an agent in namespace `agent7` adds a rule
- **THEN** the rule's metadata names `agent7` and the provenance supplied or defaulted

### Requirement: Validation gate
Every program change SHALL pass, in order: capability check, type check, mode/safety/fragment checks, whole-program stratification, validation of new constraints against current data, and a bounded trial run; failure SHALL reject the whole update.

#### Scenario: Unstratified rule rejected
- **WHEN** an agent adds `p X :- q X, not r X.` while `r X :- p X.` exists
- **THEN** the update fails with `error (unstratified [p, r])` and no rule is added

#### Scenario: Ill-typed rule rejected
- **WHEN** a rule uses a string where an `entity` is required
- **THEN** the update fails with a type error naming the clause and argument

### Requirement: Structured errors
All validation and runtime errors SHALL be returned as structured ELPI terms (and equivalent JSON), identifying the error kind, location and involved values, suitable for automated repair.

#### Scenario: Machine-readable error
- **WHEN** a rule is rejected
- **THEN** the error is a term like `error (type_error (clause 3) (arg 2) (expected entity) (got string))`, not only a text message

### Requirement: Schema evolution
Additive schema changes (new relation, new defaulted or nullable column, new constraint) SHALL be ordinary updates; breaking changes SHALL require a migration expressed as ELPI rules, and the old relation SHALL remain queryable historically.

#### Scenario: Column type change via migration
- **WHEN** a migration maps `knows A B F` (float) to `knows2 A B L` (level) and is applied
- **THEN** current queries use `knows2`, and `as_of` before the migration still sees `knows`

#### Scenario: Breaking change without migration
- **WHEN** an `alter` tries to change a column's type directly
- **THEN** the update fails with `error (requires_migration ...)`

### Requirement: Namespace capabilities
Namespaces SHALL carry capability grants (`read`, `assert_fact`, `assert_rule`, `alter_schema`, `forget`), and every operation SHALL be checked against them.

#### Scenario: Rule addition denied
- **WHEN** an agent with only `read` and `assert_fact` on `shared` adds a rule in `shared`
- **THEN** the update fails with `error (capability_denied ...)`
