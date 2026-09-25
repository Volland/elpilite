## Purpose

Guarantees exactly one writing process per database file while letting other processes read locally and route their writes to the owner.

## ADDED Requirements

### Requirement: Single owner
At most one process SHALL hold read-write ownership of a database file at a time, and the owner's identity and optional endpoint SHALL be recorded in the database.

#### Scenario: Second writer refused
- **WHEN** process B opens a file in read-write mode while process A owns it
- **THEN** B's open fails with `error (owned_by A ...)`

### Requirement: Auto mode read-only with write proxy
A process opening in auto mode while another process owns the file SHALL get read-only access and SHALL forward updates to the owner's endpoint if one is advertised.

#### Scenario: Proxied update
- **WHEN** a Node process opens in auto mode while the MCP server owns the file and calls update
- **THEN** the update is executed by the owner and the Node process receives the resulting transaction id

#### Scenario: No endpoint
- **WHEN** the owner advertises no endpoint and a non-owner calls update
- **THEN** the call fails with `error (read_only ...)`

### Requirement: Stale ownership recovery
If the recorded owner is no longer alive and its lock is released, the next read-write opener SHALL take over ownership.

#### Scenario: Owner crashed
- **WHEN** the owning process crashed and a new process opens read-write
- **THEN** the new process becomes owner without manual intervention

### Requirement: Concurrent readers
Any number of processes SHALL be able to query a database concurrently with the owner's writes, each observing consistent snapshots.

#### Scenario: Read during write
- **WHEN** a reader queries while the owner commits
- **THEN** the reader sees either the pre- or post-commit state, never a partial one
