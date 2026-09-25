# Language

λProlog (ELPI 1.18 dialect) is the only user-facing language: it declares schema, states constraints, writes rules, asks queries and computes updates.

## Types As Schema

ELPI's own type system — `kind`, `type`, `pred` with modes, rank-1 polymorphism — is the schema language; there is no second type system.

```prolog
kind entity type.
type person  string -> entity.
type project string -> entity.

kind topic type.
type project_topic entity -> topic.

:persistent
:key(1 2)
pred knows i:entity, i:entity, o:float.

:persistent
:index(1) :index(2)
pred about i:memory, o:topic.
```

- A predicate marked `:persistent` is an **EDB relation**: stored, typed, exposed as a builtin ([[evaluation#EDB Builtins]]).
- Column layout is derived from argument types: `int` → INTEGER, `float` → REAL, `string` → TEXT, anything else → term id ([[storage#Term DAG]]).
- Every insert is type-checked by ELPI's checker against the declared signature before it reaches storage.
- There is **no subtyping and no refinement typing** at schema level ([[decisions#D3 Types]]). Ontologies (`isa`, taxonomies) are data plus rules. Vector dimension is checked at insert time, not statically.

## Constraints

Integrity constraints are declared as attributes or `constraint` clauses and enforced at update time by the [[rules#Validation Gate]].

| Constraint | Syntax | Enforcement |
|---|---|---|
| Primary key | `:key(1 2)` | at most one *current* row per key per overlapping valid-time interval |
| Unique | `constraint (unique knows [3])` | same, on arbitrary columns |
| Functional dependency | `constraint (fd works_at [1] [2])` | current rows agreeing on LHS agree on RHS (valid-time-aware) |
| Foreign key | `constraint (fk about 2 topic_decl 1)` | referenced value must exist as a current fact |
| Cardinality | `constraint (card about 1 0 20)` | per-LHS row count bounds |

Keys and FDs are **valid-time aware**: `works_at alice acme [2021,2023)` and `works_at alice globex [2023,∞)` do not conflict.

Adding a constraint to a non-empty relation validates existing current data first; failure rejects the change.

## Snapshots

Every query runs against an immutable snapshot identified by the transaction id current when it started.

- Default visibility: rows with `tx_to IS NULL` whose valid interval contains *now*, in the session's visible namespaces.
- `as_of T Goal` — evaluate `Goal` as of transaction time `T` (rules too: [[rules#Program As Data]]).
- `valid_at V Goal` — evaluate at world time `V` instead of *now*.
- `in_ns [N1, N2] Goal` — restrict/extend visible namespaces (capability-checked).
- `all_versions Goal` — lift the tx filter, e.g. for belief-revision history.

## Metadata Access

System columns are read through meta-predicates rather than extra arguments, keeping ordinary rules clean.

```prolog
meta (knows alice bob _) Meta.        % Meta = [tx 41 none, valid 0 none, conf 0.9, src (tool "crm"), ns shared]
conf_of (knows alice bob _) C.
src_of  (safe home) S.                % S = derived_by rule_12 [f_881, f_902]
```

`meta` binds to the specific stored row that satisfied the inner goal, so it can be combined with any query.

## Queries

A query is an ELPI goal; solutions are streamed lazily as bindings plus optional metadata and proofs.

```prolog
recall P M :-
  about M (project_topic P),
  episode M T _, T > 1700000000,
  importance M I, I > 0.5.
```

- Queries are **read-only** and **pure**: no builtin with a storage side effect exists in query context ([[decisions#D12 Pure reads, delta writes]]).
- **Solution order is unspecified** unless `order_by` / `top_k` / `argmax` is used ([[evaluation#Conjunction Pushdown]]).
- Every query runs under a step limit and depth limit; exceeding them raises `error (step_limit N)` rather than hanging ([[evaluation#Top-Down Resolution]]).
- Cancellation (e.g. JS `AbortSignal`) is observed at the same check points.

## Updates

Writes are expressed by a pure goal that computes a delta list; the engine validates and applies it atomically.

```prolog
update (
  recall p1 M, stale M,
  Delta = [ retract M,
            assert (works_at alice acme) [valid 2021 2023, conf 0.9, src (tool "linkedin")],
            add_rule (colleague X Y :- manager X M, manager Y M, not (X = Y)) ]).
```

Delta operations:

| op | effect |
|---|---|
| `assert F Meta` | insert a new current row (metadata optional) |
| `retract F` | close `tx_to` on the matching current row(s) |
| `correct F Meta` | retract + assert with the same key, preserving history |
| `add_rule R` / `drop_rule Id` | catalog change through the validation gate |
| `declare D` / `alter A` / `migrate M` | schema change ([[rules#Schema Evolution]]) |
| `forget Selector Policy` | physical deletion ([[memory#Forgetting]]) |

Semantics:

1. The goal runs on snapshot `N`; its first solution's `Delta` is taken.
2. Conflict check: if any key touched by `Delta` changed after `N`, reject with `error (conflict Keys)`; the client retries on a fresh snapshot (optimistic concurrency).
3. [[rules#Validation Gate]] runs on the whole delta.
4. Rows are written bitemporally; materialized views are maintained ([[evaluation#Materialized Views]]).
5. Commit produces transaction `N+1`. Any failure ⇒ no effect and a structured error term.

There are **no triggers** in v1.

## Negation

`not G` is negation-as-failure over the current snapshot (closed world per snapshot), required to be safe and stratified.

- **Safety:** all variables of `G` must be bound when `not G` runs. Checked at load time for `:materialized` rules and at runtime otherwise; violations raise `error (unsafe_negation Goal)`.
- **Stratification:** no recursion through negation among `:materialized` rules and across the whole rule set when a rule is added ([[rules#Validation Gate]]).
- Inside a pushdown block, `not` over a stored relation compiles to `NOT EXISTS`.
- **Open-world relations:** a relation declared `:open` returns `unknown` instead of failing for absent facts when queried via `known G` / `unknown G`. This is catalog metadata only — no three-valued logic engine.

## Aggregation

Aggregates are explicit builtins with group-by semantics, pushed down to SQL when their body is a pushdown block.

```prolog
count  (episode M _ _, about M P)            N.
aggr   sum I (importance M I, about M P)     Total.
group  [P] (about M P) (count M)             Counts.   % list (pair entity int)
top_k  10 (desc T) (episode M T _)           Recent.
argmax T (episode M T _)                     Latest.
```

- Aggregate builtins have polymorphic ELPI types; `sum` over a `string` column is a type error.
- In `:materialized` rules aggregates must be stratified (aggregate only over lower strata; no recursion through aggregates in v1).
- Over `:weighted` predicates only `count` and `sum` are defined, using the semiring ⊕ ([[evaluation#Semiring Provenance]]); others are rejected at load time.
