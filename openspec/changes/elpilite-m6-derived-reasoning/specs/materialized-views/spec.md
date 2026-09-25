## Purpose

Stores derived relations defined by Datalog-fragment rules and keeps them incrementally up to date on every commit, with provenance, so recursive and consolidation queries are fast and terminate.

## ADDED Requirements

### Requirement: Materialized predicate declaration
Rules for a predicate marked `:materialized` SHALL be evaluated to a fixpoint and stored as derived facts that queries read like stored relations.

#### Scenario: Transitive closure terminates
- **WHEN** `reach` is `:materialized` with the left-recursive rule `reach X Z :- reach X Y, edge Y Z.` over a cyclic graph
- **THEN** `reach` queries terminate and return the full closure

### Requirement: Fragment restriction
Materialized rules SHALL be range-restricted, stratified in negation and aggregation, free of λ-terms, hypothetical implication and higher-order calls; violating rules SHALL be rejected at load or add time.

#### Scenario: Higher-order body rejected
- **WHEN** a `:materialized` rule body contains `=>`
- **THEN** adding it fails with `error (not_materializable ...)` and it is not silently evaluated top-down

### Requirement: Incremental maintenance
After each commit, materialized relations SHALL equal what full recomputation from the committed base facts would produce, for both insertions and retractions.

#### Scenario: Retraction removes unsupported derivations
- **WHEN** an `edge` is retracted and some `reach` facts had no other derivation
- **THEN** those `reach` facts are no longer current and others remain

#### Scenario: Incremental equals recompute
- **WHEN** a random sequence of inserts and retracts is applied
- **THEN** the materialized relation after each commit equals a from-scratch recomputation

### Requirement: Derived fact provenance
Each derived fact SHALL record the rule and premise facts that derive it, and derived facts SHALL obey the same bitemporal visibility as stored facts.

#### Scenario: Explain derived fact
- **WHEN** a client asks for the provenance of a current `reach a c`
- **THEN** it receives `derived_by` naming the rule and the premise facts

#### Scenario: Historical derived state
- **WHEN** `as_of T (reach a c)` is queried
- **THEN** the answer reflects derived state at transaction T
