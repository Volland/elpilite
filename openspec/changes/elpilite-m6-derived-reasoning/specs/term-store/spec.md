## ADDED Requirements

### Requirement: Unreferenced term reclamation
Terms no longer referenced by any fact, rule, constraint or tombstone SHALL be reclaimable by a garbage-collection operation without affecting query results.

#### Scenario: GC after forget
- **WHEN** all facts referencing a term are forgotten and garbage collection runs
- **THEN** the term's storage is reclaimed and all remaining queries return the same results as before GC
