This directory defines the high-level concepts, business logic, and architecture of this project using markdown. It is managed by [lat.md](https://www.npmjs.com/package/lat.md) — a tool that anchors source code to these definitions. Install the `lat` command with `npm i -g lat.md` and run `lat --help`.

# elpilite

A typed, bitemporal, neuro-symbolic database in OCaml: λProlog (ELPI) is the DDL and query language, Turso (SQLite-compatible) is the persistent store.

It is optimised for agentic memory: agents store typed facts with time, confidence and provenance, retrieve them by symbolic constraints *and* vector similarity in one query, and evolve their own rules and schema at runtime — all in a single database file.

## Map

The knowledge base is split by concern; each file is self-contained and cross-linked.

- [[architecture]] — layers, components, request flow
- [[storage]] — `Store` signature, Turso/SQLite backends, term DAG, catalog, bitemporal rows
- [[language]] — DDL, types, constraints, queries, updates, negation, aggregation
- [[evaluation]] — top-down resolution, conjunction pushdown, materialized views, semirings
- [[vectors]] — embeddings, similarity search, hybrid ranked retrieval
- [[rules]] — program-as-data, validation gate, schema migrations, capabilities
- [[interfaces]] — OCaml library, CLI/REPL, MCP server, Python and Node.js clients, writer ownership
- [[memory]] — agent-memory primitives the engine provides (and what it deliberately does not)
- [[roadmap]] — milestones M0–M7, testing strategy, performance targets
- [[decisions]] — decision log from the design grilling session (D1–D15)

## Design Principles

A handful of principles resolve most ambiguous design choices; when in doubt, apply these.

1. **One language.** Schema, rules, queries, updates, migrations and policies are all λProlog. No second DSL.
2. **The database is the source of truth.** Facts, rules and schema live in the file; `.elpi` files are import/export.
3. **Never lose history.** Storage is append-only and bitemporal; only explicit `forget` removes data.
4. **Pure reads, atomic writes.** Queries are side-effect-free over a snapshot; writes are validated deltas.
5. **Push work down.** Anything relational goes to the SQL engine; λProlog handles what SQL cannot.
6. **Mechanism, not policy.** The engine provides memory primitives; users design memory models for their domain.
7. **Differential everything.** Every optimisation has a naive twin it is tested against.
