## ADDED Requirements

### Requirement: Derived data consistency on commit
After each commit, all materialized derived relations SHALL reflect the committed state.

#### Scenario: View updated in same transaction
- **WHEN** an update asserts an `edge` fact that extends a materialized `reach` relation
- **THEN** a query at the new transaction sees the new `reach` facts

### Requirement: Forget delta operation
The delta language SHALL support `forget Selector Policy` as the only operation that physically deletes data.

#### Scenario: Forget in update
- **WHEN** an update contains `forget (episode M T _, T < 100) soft`
- **THEN** matching facts not blocked by provenance are physically deleted in that transaction
