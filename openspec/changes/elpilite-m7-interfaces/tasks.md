## 1. M7 — Interfaces

- [ ] 1.1 OCaml public API (`open_`, `query`, `update`, `import`, `export`, `register_builtin`) with docs
- [ ] 1.2 Writer ownership: advisory lock, `owner` row, stale takeover, auto mode read-only + proxy
- [ ] 1.3 CLI subcommands `repl`, `query`, `update`, `import`, `export`, `mcp`, `check`
- [ ] 1.4 REPL directives (`:as_of`, `:ns`, `:meta`, `:explain`, `:backend`)
- [ ] 1.5 `elpilite check`: integrity, constraint, view consistency, optional backend comparison
- [ ] 1.6 MCP server: tools, input schemas, stdio + streamable HTTP, paging cursors, session namespace and limits
- [ ] 1.7 Python client package (HTTP + spawned stdio), term decoding, numpy vectors, `ElpiliteError`
- [ ] 1.8 Node N-API addon: complete-obj OCaml link, dedicated OCaml thread, Promise and async-iterator API, AbortSignal
- [ ] 1.9 Node prebuilds for macOS arm64/x64 and Linux x64/arm64 in CI; TypeScript types
- [ ] 1.10 End-to-end agent demo in `examples/` exercised via MCP, Python and Node
- [ ] 1.11 Update `lat.md/` with implementation anchors (`@lat:` refs) and run `lat check`
