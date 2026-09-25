# Decisions

Decision log from the design grilling session on 2026-09-25; each entry records the choice, the rejected alternatives and why.

## D1 Hybrid execution

Stored relations live in Turso and are exposed as OCaml builtins with pushdown; rules and higher-order reasoning run in ELPI.

Rejected: ELPI over in-memory facts loaded from SQLite (does not scale — memory grows unboundedly); compiling ELPI to SQL (loses higher-order unification, `=>`, binders). See [[architecture]].

## D2 Term DAG

Non-scalar terms are hash-consed into a DAG with de Bruijn binders and interned symbols; stored facts are ground.

Rejected: opaque blobs (no indexing inside terms, no sharing). Gains: dedup, id-equality, content addressing for provenance, pattern pushdown. See [[storage#Term DAG]].

## D3 Types

ELPI native types plus `:persistent` declarations plus integrity constraints; no subtyping, no refinement types.

Ontologies are data; vector dimensions are checked at runtime. See [[language#Types As Schema]].

## D4 Turso primary

Turso (the Rust SQLite rewrite) is the primary backend via its sqlite3-compatible C API, single-writer mode; stock SQLite is kept for differential tests.

Turso gives native vectors without extensions. MVCC is avoided until it supports indexes. See [[storage#Store Signature#Turso Backend]].

## D5 Full bitemporal

Every fact has transaction time, valid time, confidence, provenance and namespace; storage is append-only.

Rejected: transaction-time only (no world-time reasoning), no built-in metadata (every schema reinvents it). See [[storage#Bitemporal Rows]].

## D6 Semirings

Opt-in `:weighted` predicates thread a per-query semiring (max-product, min-max, top-k proofs, add-mult).

Rejected: crisp-only (agents reinvent scoring), exact ProbLog inference (too costly), differentiable (deferred). See [[evaluation#Semiring Provenance]].

## D7 Hybrid evaluation

Top-down by default with step/depth limits; `:materialized` Datalog-fragment predicates evaluated semi-naively and maintained with DRed.

Rejected: pure top-down (left recursion, repeated work), adding tabling to ELPI (invasive). See [[evaluation#Materialized Views]].

## D8 DB is source of truth

Rules, declarations and constraints are stored as bitemporal quoted terms; runtime changes pass a validation gate; breaking schema changes use migrations.

Rejected: static program files (agents could not learn rules). See [[rules]].

## D9 Interfaces

OCaml library, CLI/REPL, MCP server as the single writer, Python thin client, and a native Node.js N-API addon.

The Node addon was chosen over a thin client and over WebAssembly for in-process embedded use. See [[interfaces]].

## D10 Ownership and threading

One owner process per file (advisory lock + owner row); others read-only or proxy; Node addon runs OCaml on a dedicated thread; OCaml 5.x; macOS/Linux first.

See [[interfaces#Writer Ownership]] and [[interfaces#Node Addon]].

## D11 Memory model is user-defined

The engine ships primitives (access tracking, jobs, ranked retrieval, safe forgetting); memory schemas and policies are designed by users per domain.

Reference models live in `examples/`. See [[memory]].

## D12 Pure reads, delta writes

Queries are read-only over a snapshot; writes are `update Goal` computing a delta applied atomically with optimistic concurrency; no triggers.

Rejected: imperative assert/retract during resolution (unsound under backtracking, unvalidatable). See [[language#Updates]].

## D13 Pushdown

Maximal blocks of stored goals, comparisons, patterns and similarity compile to one SQL join; solution order is unspecified; cuts are block boundaries.

Rejected: per-call lookups (N+1), full cost-based reordering across IDB calls (complexity). See [[evaluation#Conjunction Pushdown]].

## D14 Negation and aggregation

Stratified negation-as-failure over the snapshot with safety checks and an `:open` flag; explicit aggregate builtins pushed down to SQL.

See [[language#Negation]] and [[language#Aggregation]].

## D15 Milestones

M0–M7 as in the roadmap, interfaces last, differential testing throughout.

See [[roadmap]].
