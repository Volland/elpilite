## ADDED Requirements

### Requirement: Scheduled jobs
The owner process SHALL run registered update goals on time-based or commit-count schedules, recording each run as a transaction with job provenance.

#### Scenario: Periodic job
- **WHEN** a job is scheduled every 6 hours
- **THEN** it runs within the scheduling tolerance and its effects carry `src (job Name)`

### Requirement: Provenance-safe forgetting
`forget Selector soft` SHALL physically delete selected facts except those that are premises of retained derived facts, reporting blockers; `forget Selector force` SHALL delete them and retract dependent derived facts.

#### Scenario: Soft forget blocked
- **WHEN** a soft forget selects a fact that supports a current materialized fact
- **THEN** that fact is not deleted and the result lists it as blocked

#### Scenario: Force forget cascades
- **WHEN** a force forget deletes a premise
- **THEN** derived facts without other support are retracted in the same transaction

### Requirement: Forgetting audit
Every physical deletion SHALL leave a tombstone recording relation, transaction, reason and requester, without the deleted content.

#### Scenario: Tombstone exists
- **WHEN** a fact is forgotten
- **THEN** a tombstone query shows that a fact of that relation was forgotten, when and by whom, and the content is not recoverable
