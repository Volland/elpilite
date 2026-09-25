# Memory

Agent-memory support is mechanism, not policy: the engine provides fast primitives, and users design their memory model (episodic, semantic, procedural, tiers, graphs) for their own domain.

See [[decisions#D11 Memory model is user-defined]]. Reference designs ship under `examples/` and are never loaded by default.

## Primitives

The engine-level primitives that memory models build on, each specified in its own section.

| Primitive | Where |
|---|---|
| Bitemporal facts with confidence, provenance, namespace | [[storage#Bitemporal Rows]] |
| Time travel and history | [[language#Snapshots]] |
| Hybrid ranked retrieval | [[vectors#Hybrid Retrieval]] |
| Consolidation as incrementally maintained views | [[evaluation#Materialized Views]] |
| Explanations / proofs | [[evaluation#Semiring Provenance]] |
| Agent-authored rules with validation | [[rules#Validation Gate]] |
| Access tracking | [[memory#Access Tracking]] |
| Scheduled maintenance | [[memory#Scheduled Jobs]] |
| Safe forgetting | [[memory#Forgetting]] |

## Access Tracking

Per-fact access count and last-access time support recency and usage ranking without turning every read into a write transaction.

- Reads record `(fid, time)` in an in-memory buffer inside the owner process.
- The buffer is flushed into `acc_n` / `acc_t` with the next write transaction, or by a periodic flush job.
- Access statistics may therefore lag; they are advisory and not part of snapshot consistency.
- Read-only (non-owner) openers forward access batches to the owner with proxied writes, or drop them if configured.
- Tracking is opt-in per relation (`:track_access`).

## Scheduled Jobs

The owner process runs registered maintenance jobs on a timer or every N commits, each as an ordinary `update` goal.

```prolog
schedule (every (hours 6)) (forget_policy episodic_decay).
schedule (every_commits 1000) (refresh consolidation).
```

Jobs run with the owner's capabilities in a dedicated namespace, and each run is logged as a transaction with `src (job Name)`.

## Forgetting

`forget` is the only operation that physically deletes data; it is provenance-aware and leaves an audit tombstone.

- Selector is an ELPI goal choosing facts; policy is `soft` (default) or `force`.
- **Soft:** refuses to delete a fact that is a premise (`derived_by`) of a retained derived fact, reporting the blockers.
- **Force:** deletes and triggers DRed on dependent derived facts.
- Every deletion writes a tombstone event (fid, relation, tx, reason, requester) — content is gone, the fact that something was forgotten is not.
- Unreferenced term DAG nodes are garbage-collected by a mark-and-sweep job over live references (facts, rules, tombstones).

```prolog
update (Delta = [forget (episode M T _, T < 1690000000, importance M I, I < 0.2) soft]).
```
