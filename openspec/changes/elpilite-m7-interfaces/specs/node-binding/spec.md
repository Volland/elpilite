## Purpose

Embeds the full elpilite engine in-process in Node.js through a native addon, for serverless and local-first agent applications.

## ADDED Requirements

### Requirement: In-process native addon
The Node package SHALL run the engine in-process via a native addon, requiring no separate server for single-process use.

#### Scenario: Open locally
- **WHEN** a Node program calls `await open("memory.db")` with no server running
- **THEN** it obtains a read-write handle as owner

### Requirement: Non-blocking asynchronous API
All database operations SHALL return Promises or async iterators and SHALL NOT block the Node event loop.

#### Scenario: Event loop stays responsive
- **WHEN** a query takes several seconds
- **THEN** timers and I/O callbacks in the same Node process continue to run during the query

### Requirement: Streaming query results
`db.query` SHALL return an async iterator yielding solutions incrementally.

#### Scenario: Break early
- **WHEN** a `for await` loop over a query breaks after the first solution
- **THEN** the query is released without enumerating remaining solutions

### Requirement: Cancellation
Operations SHALL accept an `AbortSignal`; aborting SHALL end the operation with a cancellation error.

#### Scenario: Abort
- **WHEN** the signal is aborted during a long query
- **THEN** the iterator rejects with a cancellation error promptly

### Requirement: Ownership integration
The addon SHALL follow the writer-ownership rules, opening read-only with write proxying when another process owns the file.

#### Scenario: Server owns file
- **WHEN** the MCP server owns the file and a Node process opens it in auto mode
- **THEN** queries run in-process and updates are proxied to the server

### Requirement: Supported platforms
Prebuilt binaries SHALL be provided for macOS arm64 and x64 and Linux x64 and arm64 (glibc).

#### Scenario: Install without toolchain
- **WHEN** the package is installed on a supported platform without an OCaml toolchain
- **THEN** installation succeeds using a prebuilt binary
