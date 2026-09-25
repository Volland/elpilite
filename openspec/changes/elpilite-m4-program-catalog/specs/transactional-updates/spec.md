## ADDED Requirements

### Requirement: Program and schema delta operations
The delta language SHALL support `add_rule`, `drop_rule`, `declare`, `alter` and `migrate`, each routed through the program validation gate within the same atomic update as fact operations.

#### Scenario: Rule and fact in one update
- **WHEN** an update contains `assert F` and `add_rule R` and R fails validation
- **THEN** neither F nor R is committed and the error identifies R
