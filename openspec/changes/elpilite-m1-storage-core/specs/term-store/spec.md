## Purpose

Stores arbitrary ground λProlog terms — including nested structures and λ-binders — with structural sharing, so equal terms have one identity and round-trip exactly.

## ADDED Requirements

### Requirement: Faithful term round-trip
Any ground λProlog term of a declared type, including nested applications, strings, integers, floats, vectors and λ-abstractions, SHALL be retrievable exactly as stored, up to α-equivalence.

#### Scenario: Nested term round-trip
- **WHEN** a fact `belief a1 (implies (at X home) (safe X))`-style ground term with nested structure is asserted and then queried
- **THEN** the returned term is structurally identical to the asserted one

#### Scenario: Binder round-trip
- **WHEN** a term containing `x\ f x (g x)` is stored and retrieved
- **THEN** the retrieved term is α-equivalent to the stored one

### Requirement: Structural sharing and identity
Structurally equal terms, and α-equivalent terms, SHALL be stored once and SHALL have the same identity.

#### Scenario: α-equivalent terms share identity
- **WHEN** facts containing `x\ p x` and `y\ p y` are asserted
- **THEN** both facts reference the same stored term identity

#### Scenario: Repeated subterms are deduplicated
- **WHEN** one million facts each reference the same compound entity term
- **THEN** that compound term is stored exactly once

### Requirement: Ground facts only
Stored facts SHALL NOT contain unification variables outside binders; attempting to store one SHALL fail with a structured error.

#### Scenario: Non-ground assert rejected
- **WHEN** an update asserts `knows alice X 0.5` with `X` unbound
- **THEN** the update fails with `error (non_ground ...)` and no data changes
