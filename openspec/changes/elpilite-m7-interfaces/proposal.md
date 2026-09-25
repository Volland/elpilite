## Why

The core must be reachable by humans (CLI/REPL), LLM agents (MCP), Python and Node.js, with one writer per file.

## What Changes

- OCaml public API
- writer ownership with read-only/proxy
- CLI and REPL, `check`
- MCP server (stdio + HTTP)
- Python client
- Node N-API addon with prebuilds
- end-to-end demo

## Capabilities

### New Capabilities
- `writer-ownership`
- `cli`
- `mcp-server`
- `python-client`
- `node-binding`

### Modified Capabilities
<!-- capabilities introduced by earlier milestones are extended via ADDED requirements in this change's specs -->

## Impact

Milestone M7 — Interfaces of the elpilite roadmap (lat.md/roadmap.md). Code under `src/`, `bin/`, `test/`, `bindings/`, `clients/`.
