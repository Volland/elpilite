## Purpose

Lets users declare typed stored relations and integrity constraints in ELPI, using ELPI's native type system as the single schema language.

## ADDED Requirements

### Requirement: Persistent relation declaration
A predicate declaration marked `:persistent` SHALL create a stored, typed relation whose argument types are ELPI types.

#### Scenario: Declare and use a relation
- **WHEN** a client declares `kind entity type. type person string -> entity. :persistent pred knows i:entity, i:entity, o:float.`
- **THEN** facts of `knows` can be asserted and queried, and the declaration is visible in the schema listing

### Requirement: Type-checked writes
Every asserted fact SHALL be type-checked against its relation's declaration; ill-typed facts SHALL be rejected with a structured type error.

#### Scenario: Ill-typed assert rejected
- **WHEN** an update asserts `knows "alice" (person "bob") 0.9` where the first argument must be `entity`
- **THEN** the update fails with `error (type_error ...)` naming the argument position, expected and actual type

### Requirement: Polymorphic and user-defined types
Declarations SHALL support user-defined kinds and constructors and ELPI rank-1 polymorphism in argument types.

#### Scenario: Polymorphic list argument
- **WHEN** a relation is declared with an argument of type `list entity`
- **THEN** facts with lists of entities are accepted and lists of strings are rejected

### Requirement: No schema-level subtyping or refinement types
The schema language SHALL be exactly ELPI's type system plus the declared constraints; subtype relations and value refinements SHALL NOT be part of the type checker.

#### Scenario: Ontology as data
- **WHEN** a user needs `person` to be a kind of `agent`
- **THEN** this is expressed with facts and rules (e.g. `isa`) and the type checker does not relate the two types
