(lang dune 3.14)

(name elpilite)

(generate_opam_files true)

(source
 (github Volland/elpilite))

(authors "Volodymyr Pavlyshyn")

(maintainers "Volodymyr Pavlyshyn")

(license MIT)

(package
 (name elpilite)
 (synopsis "Typed bitemporal neuro-symbolic database with ELPI as DDL and query language")
 (description
  "elpilite stores typed λProlog facts in a Turso/SQLite file and answers ELPI queries over them, optimised for agentic memory.")
 (depends
  (ocaml
   (>= 5.1))
  dune
  (elpi
   (= 1.18.2))
  yojson
  cmdliner
  digestif
  (qcheck-core :with-test)))
