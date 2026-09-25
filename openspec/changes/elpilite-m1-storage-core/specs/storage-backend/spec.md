## Purpose

Provides durable, single-file, transactional storage for all elpilite data on Turso, with a stock-SQLite twin that must produce identical observable results.

## ADDED Requirements

### Requirement: Single-file persistence
The system SHALL persist all facts, terms, rules, schema, constraints and system metadata in one database file, and SHALL reopen that file with identical observable state.

#### Scenario: Reopen preserves state
- **WHEN** a client declares relations, asserts facts, adds rules, closes the database and reopens the same file
- **THEN** every query returns the same solutions as before closing

#### Scenario: No sidecar state required
- **WHEN** the database file is copied (with its WAL checkpointed) to another machine and opened
- **THEN** the copy answers queries identically to the original

### Requirement: Turso is the primary backend
The system SHALL use Turso Database as the default storage engine, accessed through its SQLite-compatible interface, in single-writer mode.

#### Scenario: Default open uses Turso
- **WHEN** a database is opened without specifying a backend
- **THEN** the Turso backend is used

#### Scenario: Concurrent-write mode is not enabled
- **WHEN** a database is opened by the system
- **THEN** Turso's multi-writer (MVCC) mode is not enabled

### Requirement: SQLite twin backend
The system SHALL offer a stock SQLite backend selectable at open time that implements the same observable behavior as the Turso backend.

#### Scenario: Explicit SQLite selection
- **WHEN** a database is opened with backend `sqlite`
- **THEN** the SQLite backend is used and all language features behave as with Turso

#### Scenario: Differential equivalence
- **WHEN** the same sequence of declarations, updates and queries is run against both backends
- **THEN** the sets of solutions (ignoring order where order is unspecified) are identical

### Requirement: Atomic transactions
Each committed update SHALL be atomic and durable: either all of its effects are visible after commit or none are.

#### Scenario: Crash during commit
- **WHEN** the process is killed while an update is being applied
- **THEN** after reopening, the database reflects either the complete update or none of it

### Requirement: Format versioning
The database file SHALL record its format version and engine version, and the system SHALL refuse to open a file with an unsupported newer format version.

#### Scenario: Newer format rejected
- **WHEN** a file with a format version newer than the engine supports is opened
- **THEN** opening fails with an error naming both versions and no data is modified
