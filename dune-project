(lang dune 3.0)

(name ltl2ba)

(version 0.1.0)

(generate_opam_files true)

(formatting)

(source
 (github EmileRolley/ltl2ba))

(authors "Emile Rolley")

(maintainers "Emile Rolley")

(license GNU-GPL-v3.0)

(documentation https://emilerolley.github.io/ltl2ba/ltl2ba/index.html)

(using menhir 2.1)

(package
 (name ltl2ba)
 (synopsis "A compiler of LTL formula in Büchi automata")
 (description "A compiler of LTL formula in Büchi automata")
 (depends
   (ocaml (>= 4.12.0))
   (dune (>= 3.0.3))
   (menhir (>= 20200211))
   (cmdliner (>= 1.1.0))
   (ocamlgraph (>= 2.0.0))
   (bisect_ppx (and :dev (>= 2.5.0)))
   (alcotest (and :with-test (>= 1.5.0))))
 (tags
  (topics "to describe" your project)))
