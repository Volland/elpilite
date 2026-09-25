## Purpose

Exposes the database to LLM agents through the Model Context Protocol, with ELPI text in and JSON out, acting as the file's single writer.

## ADDED Requirements

### Requirement: MCP tools
The server SHALL expose the tools `query`, `remember`, `update`, `add_rule`, `recall_similar`, `explain`, `schema` and `history`, each with a published input schema.

#### Scenario: Tool listing
- **WHEN** an MCP client lists tools
- **THEN** all eight tools are listed with input schemas and descriptions

#### Scenario: Remember a fact
- **WHEN** an agent calls `remember` with `knows alice bob 0.9` and confidence metadata
- **THEN** the fact is committed and the response contains the transaction id

### Requirement: Transports
The server SHALL support stdio and streamable HTTP transports.

#### Scenario: HTTP transport
- **WHEN** the server is started with `--http :7411`
- **THEN** MCP clients can connect over HTTP on port 7411

### Requirement: JSON results and errors
Results SHALL be JSON with bindings, optional metadata and proofs, and a continuation indicator; errors SHALL be JSON encodings of the structured error terms.

#### Scenario: Paged results
- **WHEN** a query has more solutions than the requested page size
- **THEN** the response includes `"more": true` and a cursor to fetch the next page from the same snapshot

#### Scenario: Error encoding
- **WHEN** `add_rule` is rejected for a type error
- **THEN** the response contains the JSON form of `error (type_error ...)`

### Requirement: Server is the owner
Starting the server in read-write mode SHALL take ownership of the file and advertise the server endpoint for proxied writes.

#### Scenario: Advertised endpoint
- **WHEN** the HTTP server starts on a file
- **THEN** other processes opening in auto mode discover its endpoint for proxying

### Requirement: Session namespace and limits
Each MCP session SHALL be bound to a namespace with its capabilities and to configured query limits.

#### Scenario: Capability enforced via MCP
- **WHEN** an MCP session bound to a read-only namespace calls `update`
- **THEN** it receives `error (capability_denied ...)`
