## Purpose

Executes relational parts of ELPI goals as set-oriented storage operations so hybrid queries avoid per-row round trips, while returning exactly the answers of naive evaluation.

## ADDED Requirements

### Requirement: Semantic equivalence with naive evaluation
For every query, the multiset of solutions with pushdown enabled SHALL equal the multiset with pushdown disabled (ignoring order where unspecified).

#### Scenario: Differential check
- **WHEN** the reference query suite runs with pushdown on and off
- **THEN** the solution multisets are identical for every query

### Requirement: Set-oriented execution of relational conjunctions
Consecutive goals over stored relations, comparisons, negations over stored relations, aggregates and term patterns SHALL be executed as a single storage operation rather than one operation per intermediate solution.

#### Scenario: No N+1
- **WHEN** a query joins three stored relations where the first yields 10,000 rows
- **THEN** the number of storage operations issued is independent of the 10,000 intermediate rows

### Requirement: Pushdown boundaries
Pushdown SHALL NOT cross calls to derived predicates, higher-order goals, hypothetical implication, universal quantification or cut; evaluation SHALL continue correctly across such boundaries.

#### Scenario: Mixed query
- **WHEN** a query conjoins stored relations, a derived predicate, and more stored relations
- **THEN** results are correct and each stored-relation run is executed set-oriented

### Requirement: Term-pattern filtering
Goals with partially instantiated compound arguments SHALL filter by functor and arity in storage to a configurable depth, and SHALL complete matching beyond that depth by unification.

#### Scenario: Functor filter
- **WHEN** `about M (project_topic _)` is queried over one million `about` facts of which 100 match the functor
- **THEN** only matching candidates are decoded into terms

### Requirement: Temporal and namespace filters applied
Pushed-down operations SHALL apply the same snapshot, valid-time and namespace visibility as naive evaluation, including under `as_of`, `valid_at` and `in_ns`.

#### Scenario: as_of pushdown
- **WHEN** a pushed-down join runs under `as_of 15`
- **THEN** it returns exactly the rows visible at transaction 15
