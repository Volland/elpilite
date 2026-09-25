## Purpose

Answers ELPI goals over stored facts and rules with snapshot isolation, streaming results, stratified negation, aggregation, and bounded resources.

## ADDED Requirements

### Requirement: Snapshot-isolated read-only queries
Each query SHALL run against an immutable snapshot fixed at query start and SHALL NOT modify stored state.

#### Scenario: Concurrent commit not observed
- **WHEN** a long query is streaming results and another update commits
- **THEN** the query's remaining results reflect only the snapshot taken at its start

#### Scenario: No write builtins in queries
- **WHEN** a query goal calls a storage-modifying operation
- **THEN** the query fails with `error (write_in_query ...)`

### Requirement: Streaming solutions
Solutions SHALL be produced incrementally on demand; consumers MAY stop early without the system computing remaining solutions.

#### Scenario: Early stop
- **WHEN** a client takes the first solution of a query matching one million facts and stops
- **THEN** the query completes without enumerating all matches

### Requirement: Unspecified solution order
Solution order SHALL be unspecified unless the query uses an ordering builtin (`order_by`, `top_k`, `argmax`, `argmin`).

#### Scenario: Ordered query
- **WHEN** a query uses `top_k 10 (desc T) (episode M T _) R`
- **THEN** `R` contains the 10 episodes with the largest `T` in descending order

### Requirement: Higher-order and hypothetical reasoning
Queries SHALL support the full ELPI language over rules, including higher-order terms, `pi`, and hypothetical implication `=>`, combined with stored relations.

#### Scenario: Hypothetical query
- **WHEN** a client asks `(locked home) => safe alice`
- **THEN** the answer reflects the assumption without storing `locked home`

### Requirement: Stratified negation as failure
`not G` SHALL succeed exactly when `G` has no solution in the query snapshot; unsafe negation SHALL be reported as an error.

#### Scenario: Unsafe negation
- **WHEN** a goal evaluates `not (manager X M)` with `M` unbound
- **THEN** the query fails with `error (unsafe_negation ...)` listing the unbound variables

### Requirement: Open-world relations
Relations declared `:open` SHALL distinguish "known false" from "unknown" through `known` / `unknown` predicates.

#### Scenario: Unknown fact
- **WHEN** `belief` is `:open` and no `belief a1 raining` fact exists
- **THEN** `unknown (belief a1 raining)` succeeds

### Requirement: Aggregation
The system SHALL provide `count`, `aggr` (sum, min, max, avg), `group`, `top_k`, `argmax` and `argmin` builtins with type-checked arguments.

#### Scenario: Group count
- **WHEN** a client runs `group [P] (about M P) (count M) C`
- **THEN** `C` pairs each topic with its number of memories

#### Scenario: Ill-typed aggregate
- **WHEN** a program uses `aggr sum S (name X S)` where `S` is a string
- **THEN** loading or running it fails with a type error

### Requirement: Resource limits and cancellation
Every query SHALL run under configurable step and depth limits and SHALL be cancellable; exceeding a limit or cancelling SHALL end the query with a structured error and no side effects.

#### Scenario: Left recursion bounded
- **WHEN** a non-materialized left-recursive rule `reach X Z :- reach X Y, edge Y Z.` is queried
- **THEN** the query ends with `error (step_limit N (pred reach))` instead of hanging

#### Scenario: Cancel
- **WHEN** a client cancels a running query
- **THEN** the query ends promptly with `error cancelled`
