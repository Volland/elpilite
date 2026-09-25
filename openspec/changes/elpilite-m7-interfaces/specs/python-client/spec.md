## Purpose

Lets Python agent frameworks and embedding pipelines use elpilite through a pure-Python package that talks to the server.

## ADDED Requirements

### Requirement: Pure-Python client
The Python package SHALL require no native extension and SHALL connect to an elpilite server over HTTP or by spawning a stdio server.

#### Scenario: Connect over HTTP
- **WHEN** a user calls `elpilite.connect("http://localhost:7411")`
- **THEN** a database handle is returned

### Requirement: Query, update and similarity API
The client SHALL provide `query` (iterating solutions), `update`, and `recall_similar` accepting sequences of floats or numpy arrays.

#### Scenario: Numpy vector
- **WHEN** `db.recall_similar("memories", np_array, k=5)` is called
- **THEN** up to five ranked results are returned

### Requirement: Typed decoding
Terms SHALL be decoded into Python objects preserving functor, arguments and scalar types; structured errors SHALL raise an exception carrying the decoded error term.

#### Scenario: Error exception
- **WHEN** an update is rejected
- **THEN** an `ElpiliteError` is raised whose `.term` holds the structured error
