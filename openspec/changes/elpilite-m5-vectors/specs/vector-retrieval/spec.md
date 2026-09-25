## Purpose

Makes embeddings first-class typed values and provides ranked similarity search that combines with symbolic constraints and recency/importance scoring in one query — the neural half of neuro-symbolic memory.

## ADDED Requirements

### Requirement: Vector values
The system SHALL provide a `vec` type storing fixed-dimension float vectors, supplied by clients; the engine SHALL NOT require any embedding model.

#### Scenario: Store an embedding
- **WHEN** a client asserts `emb m1 V` with a 768-dimensional vector into an index of dimension 768
- **THEN** the vector is stored and retrievable

#### Scenario: Dimension mismatch
- **WHEN** a 512-dimensional vector is asserted into a 768-dimensional index
- **THEN** the update fails with `error (dim_mismatch 768 512)`

### Requirement: Optional embedding hook
Hosts SHALL be able to register an `embed` builtin so rules and queries can convert text to vectors.

#### Scenario: Hook absent
- **WHEN** a query calls `embed` and no hook is registered
- **THEN** the query fails with `error (no_embed_hook)`

### Requirement: Ranked similarity search
`similar Index Query K Item Score` SHALL enumerate up to K current items in non-increasing similarity order, supporting cosine, L2 and dot-product metrics.

#### Scenario: Best-first enumeration
- **WHEN** `similar "memories" V 5 M S` is queried
- **THEN** at most 5 solutions are produced and their scores are non-increasing

#### Scenario: Retracted items excluded
- **WHEN** a memory's embedding fact is retracted
- **THEN** current similarity searches no longer return it

### Requirement: Hybrid symbolic and vector queries
Similarity goals SHALL combine with symbolic filters in the same query, and the result SHALL contain the best-scoring items that satisfy the filters, not merely filtered survivors of an unfiltered top-K.

#### Scenario: Selective filter
- **WHEN** `similar "memories" V 20 M S, about M (project_topic p1)` runs and only 30 of one million memories are about `p1`
- **THEN** up to 20 results about `p1` are returned in similarity order

### Requirement: Combined ranking
`rank_recall` SHALL score candidates by a caller-weighted combination of similarity, recency (with configurable half-life) and a caller-named importance attribute, and return the top K.

#### Scenario: Recency outweighs similarity
- **WHEN** two memories have similar similarity and recency weight is high
- **THEN** the more recent memory ranks first

### Requirement: Historical vector search
Similarity search under `as_of` SHALL return results consistent with the vectors current at that transaction.

#### Scenario: Past vector search
- **WHEN** `as_of 10 (similar "memories" V 5 M S)` runs after some embeddings were retracted at transaction 12
- **THEN** the retracted embeddings are eligible results
