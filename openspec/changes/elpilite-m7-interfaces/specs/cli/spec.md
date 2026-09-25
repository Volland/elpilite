## Purpose

Gives humans and scripts a single `elpilite` command for querying, updating, importing, exporting, checking and serving databases, plus an interactive REPL.

## ADDED Requirements

### Requirement: Subcommands
The CLI SHALL provide `repl`, `query`, `update`, `import`, `export`, `mcp` and `check` subcommands operating on a database file path.

#### Scenario: One-shot query
- **WHEN** a user runs `elpilite query memory.db 'knows alice X C'`
- **THEN** each solution is printed as one JSON line and the exit code is 0

#### Scenario: Failed update exit code
- **WHEN** `elpilite update` is given an update that fails validation
- **THEN** the structured error is printed and the exit code is non-zero

### Requirement: Interactive REPL
The REPL SHALL accept ELPI goals and directives for time travel, namespace selection, metadata display, explanations and backend selection.

#### Scenario: Time travel in REPL
- **WHEN** a user enters `:as_of 15` then a goal
- **THEN** the goal is evaluated as of transaction 15

### Requirement: Import and export
`import` SHALL load ELPI source (declarations, rules, facts) as one update; `export` SHALL emit the program and current (or `--as-of`) facts as ELPI source.

#### Scenario: Export as of
- **WHEN** `elpilite export memory.db --as-of 1200` is run
- **THEN** the output, imported into an empty database, reproduces the state at transaction 1200

### Requirement: Integrity check
`check` SHALL verify internal integrity (term references, constraint satisfaction, view consistency) and report problems as structured errors.

#### Scenario: Healthy database
- **WHEN** `elpilite check` runs on a consistent database
- **THEN** it reports no problems and exits 0
