# Vectors

The neural half: embeddings are first-class typed values, and similarity search is a ranked nondeterministic builtin that joins with symbolic constraints in one query.

## Embeddings

Embeddings are supplied by the client; the engine is model-agnostic and has no network or GPU dependency.

- Type `vec` is a builtin ELPI type; values are stored as float32 blobs ([[storage#Term DAG#Term Encoding]]).
- A relation declares its vector column like any other: `:persistent pred emb i:memory, o:vec.`
- Dimension is fixed per vector index and checked at insert (runtime error `error (dim_mismatch Expected Got)`), since the schema has no refinement types ([[decisions#D3 Types]]).
- An optional `embed/2` hook can be registered from OCaml (or via the host binding) so rules can call `embed Text V`; it is a builtin supplied by the host, not a dependency of the engine.

## Vector Index

A `Vector_index` module per backend hides the implementation difference between Turso native vectors and sqlite-vec.

| Backend | Implementation |
|---|---|
| Turso ([[storage#Store Signature#Turso Backend]]) | built-in vector type, distance functions and vector index — no extension |
| SQLite ([[storage#Store Signature#SQLite Backend]]) | sqlite-vec loadable extension |

```ocaml
module type S = sig
  type t
  val create  : Store.t -> name:string -> dim:int -> metric:[`Cosine | `L2 | `Dot] -> t
  val upsert  : t -> fid:int -> float array -> unit
  val remove  : t -> fid:int -> unit
  val top_k   : t -> float array -> k:int -> ?filter:Sql.frag -> unit -> (int * float) Seq.t
end
```

Vector index entries follow the bitemporal lifecycle of their fact: retraction removes the entry from the *current* index; `as_of` vector search falls back to exact scan over historical rows.

## Similarity Builtin

`similar` enumerates the k nearest stored items in ranked order on backtracking.

```prolog
pred similar i:string, i:vec, i:int, o:A, o:float.   % index name, query, k, item, score

recall_about Q P M S :-
  embed Q V,
  similar "memories" V 20 M S, S > 0.7,
  about M (project_topic P).
```

Solutions arrive best-first. Inside a pushdown block the call becomes a table-valued join ([[evaluation#Conjunction Pushdown#Similarity In Blocks]]).

## Hybrid Retrieval

A combined ranking operator scores candidates by weighted recency, importance and similarity in one pushed-down operation.

```prolog
rank_recall "memories" V
  [w_sim 1.0, w_recency 0.5 (half_life 7d), w_importance 0.8 (col importance)]
  (about M (project_topic p1))      % symbolic filter
  20 M Score.
```

- Recency uses `valid_from` or `acc_t` ([[memory#Access Tracking]]) with exponential decay.
- The operator compiles to one SQL statement (vector top-k' join, filter, computed score, `ORDER BY … LIMIT`), avoiding an ELPI loop over candidates.
- Weights are per-call; the engine prescribes no default memory model ([[memory]]).
