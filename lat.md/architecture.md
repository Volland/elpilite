# Architecture

elpilite is a hybrid engine: stored relations live in Turso/SQLite and are exposed to ELPI as OCaml builtins, while rules and higher-order reasoning run natively in ELPI.

See [[decisions#D1 Hybrid execution]] for why neither "ELPI over dumb storage" nor "ELPI compiled to SQL" alone was chosen.

## Layers

The system is five layers; each only talks to the one directly below it.

```plantuml
@startuml layers
skinparam componentStyle rectangle
skinparam shadowing false

package "Interfaces" {
  [OCaml API] as api
  [CLI / REPL] as cli
  [MCP server] as mcp
  [Node N-API addon] as node
  [Python client] as py
}

package "Session" {
  [Session & Snapshot] as sess
  [Ownership / Writer lock] as own
}

package "Language" {
  [Program loader\n(catalog → ELPI program)] as loader
  [Validation gate] as gate
  [Rewrite passes\n(pushdown, semiring, safety)] as rw
}

package "Evaluation" {
  [ELPI runtime\n(top-down SLD)] as elpi
  [EDB builtins] as edb
  [Pushdown block executor] as blk
  [Materializer\n(semi-naive + DRed)] as mat
  [Update applier] as upd
}

package "Storage" {
  [Term store\n(hash-consed DAG)] as terms
  [Catalog] as cat
  [Vector_index] as vec
  [Store signature] as store
  [Turso backend] as turso
  [SQLite backend] as sqlite
}

database "memory.db" as file

api --> sess
cli --> api
mcp --> api
node --> api
py ..> mcp : JSON-RPC
sess --> loader
sess --> own
loader --> rw
loader --> gate
sess --> elpi
elpi --> edb
edb --> blk
blk --> store
edb --> terms
upd --> gate
upd --> mat
upd --> store
mat --> blk
terms --> store
cat --> store
vec --> store
store <|.. turso
store <|.. sqlite
turso --> file
sqlite --> file
@enduml
```

## Components

Each component owns one concern; the list maps components to the knowledge-base section that specifies them.

| Component | Responsibility | Spec |
|---|---|---|
| `Store` | Backend-neutral SQL access, transactions, prepared cursors | [[storage#Store Signature]] |
| Term store | Interning, hash-consing, de Bruijn encoding of λ-terms | [[storage#Term DAG]] |
| Catalog | Persistent declarations, constraints, rules, versions | [[storage#Catalog]] |
| `Vector_index` | Similarity search per backend | [[vectors#Vector Index]] |
| Program loader | Rebuilds the ELPI program from the catalog for a snapshot | [[rules#Loading]] |
| Rewrite passes | Pushdown blocks, `:weighted` threading, safety checks | [[evaluation#Rewrite Pipeline]] |
| EDB builtins | Stored relations as nondeterministic ELPI predicates | [[evaluation#EDB Builtins]] |
| Materializer | Semi-naive fixpoint and incremental maintenance | [[evaluation#Materialized Views]] |
| Update applier | Validates and commits deltas atomically | [[language#Updates]] |
| Validation gate | Type, mode, fragment, stratification, trial-run checks | [[rules#Validation Gate]] |
| Session | Snapshot lifecycle, step limits, cancellation | [[language#Snapshots]] |
| Ownership | One writer per file; read-only or proxy for others | [[interfaces#Writer Ownership]] |

## Query Flow

A read query runs over a fixed snapshot; stored-relation goals are batched into SQL, everything else resolves in ELPI.

```plantuml
@startuml query-flow
actor Agent
participant "Interface" as I
participant "Session" as S
participant "ELPI runtime" as E
participant "Block executor" as B
participant "Store (Turso)" as T

Agent -> I : query "recall p1 M"
I -> S : open snapshot (tx = N)
S -> E : run goal with program@N
loop resolution
  E -> B : pushdown block(bound args)
  B -> T : prepared SQL join\n(+ tx_to IS NULL / as_of filters)
  T --> B : cursor
  B --> E : stream solutions (lazy, on backtrack)
end
E --> S : solutions (bindings + meta)
S --> I : JSON / OCaml values
I --> Agent : results
@enduml
```

## Update Flow

Writes are computed as a delta by a pure goal, then validated, written, and propagated in one transaction.

```plantuml
@startuml update-flow
actor Agent
participant "Session" as S
participant "ELPI runtime" as E
participant "Validation gate" as G
participant "Update applier" as U
participant "Materializer" as M
participant "Store" as T

Agent -> S : update Goal (based on snapshot N)
S -> E : solve Goal → Delta
E --> S : Delta = [assert F [meta], retract F', add_rule R, ...]
S -> U : apply(Delta, base = N)
U -> T : BEGIN
U -> U : conflict check (keys touched since N?)
alt conflict
  U -> T : ROLLBACK
  U --> Agent : error(conflict, ...)
end
U -> G : validate(Delta)
alt invalid
  U -> T : ROLLBACK
  U --> Agent : error(structured term)
end
U -> T : close tx_to of retracted rows\ninsert new bitemporal rows
U -> M : propagate(Delta) (DRed)
M -> T : insert/close derived rows
U -> T : COMMIT (tx = N+1)
U --> Agent : ok(tx = N+1)
@enduml
```

## Source Layout

The planned dune layout mirrors the layers; library names are prefixed `elpilite_`.

```
bin/elpilite.ml            CLI / REPL / MCP entry point
src/store/                 Store signature, Turso + SQLite backends, Vector_index
src/terms/                 interning, hash-consing, de Bruijn, (de)serialisation
src/catalog/               declarations, constraints, rules, versions
src/lang/                  loader, rewrite passes, validation gate, errors
src/eval/                  EDB builtins, block executor, materializer, semirings
src/session/               snapshots, updates, ownership, step limits
src/mcp/                   MCP server (stdio + HTTP)
bindings/node/             N-API addon (C stubs + TS wrapper)
clients/python/            thin MCP/HTTP client
elpi/prelude.elpi          engine builtins' ELPI signatures
examples/                  reference memory models (not loaded by default)
test/                      unit, property, differential, e2e
```
