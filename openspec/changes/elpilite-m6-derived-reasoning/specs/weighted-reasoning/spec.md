## Purpose

Propagates confidence through rules under a caller-chosen semiring and produces proof-based explanations, bridging stored confidence scores and symbolic inference.

## ADDED Requirements

### Requirement: Opt-in weighted predicates
Only predicates marked `:weighted` SHALL propagate weights; all other predicates SHALL behave as crisp logic with no weighting overhead.

#### Scenario: Crisp rule unaffected
- **WHEN** a query uses only unmarked predicates
- **THEN** results and performance are unaffected by the weighting feature

### Requirement: Per-query semiring selection
Weighted queries SHALL be evaluated under a semiring chosen per query from `max_product`, `min_max`, `top_k K` and `add_mult`, with base weights taken from facts' confidence and optional rule weights.

#### Scenario: Best-proof confidence
- **WHEN** `safe alice` has two proofs with confidences 0.72 and 0.5 and the query uses `max_product`
- **THEN** the returned weight is 0.72

#### Scenario: Fuzzy semantics
- **WHEN** the same query uses `min_max` with premises 0.9 and 0.8 in the best proof
- **THEN** the returned weight is 0.8

### Requirement: Proof explanations
Under `top_k K`, the system SHALL return up to K highest-weight proofs, each identifying the rules and facts used.

#### Scenario: Three best proofs
- **WHEN** `with_semiring (top_k 3) (safe alice) P` is queried
- **THEN** `P` contains at most three proofs in non-increasing weight order

### Requirement: Convergence guarantee
Recursive weighted materialized predicates SHALL only be accepted with an idempotent semiring; non-idempotent semirings with recursion SHALL be rejected.

#### Scenario: add_mult recursion rejected
- **WHEN** a recursive `:weighted :materialized` predicate is declared for use with `add_mult`
- **THEN** it is rejected with `error (non_idempotent_recursion ...)`

### Requirement: Weighted aggregation limits
Over weighted predicates only `count` and `sum` SHALL be permitted, computed with the semiring's addition; other aggregates SHALL be rejected.

#### Scenario: argmax over weighted rejected
- **WHEN** a program uses `argmax` over a `:weighted` predicate
- **THEN** it is rejected at load time with a structured error
