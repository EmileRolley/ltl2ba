#> Available Makefile rules:
#> -------------------------
help : Makefile
	@sed -n 's/^#> //p' $<

#> dependencies | Install all OCaml ltl2ba dependencies
dependencies:
	opam install . --deps-only --with-doc --with-test --yes --working-dir

#> build        | Builds the ltl2ba executable
build:
	dune build

#> test         | Run unit tests
test:
	dune test -f

#> test-cov     | Run unit tests instrumented with bisect-ppx
test-cov:
	dune runtest --instrument-with bisect_ppx --force
	bisect-ppx-report summary

#> doc          | Generates the HTML documentation via odoc
doc:
	dune build @doc
	ln -sf $(PWD)/_build/default/_doc/_html/index.html docs/index.html

#> doc-watch    | Alias for the command: dune build @doc --watch
doc-watch:
	dune build @doc --watch

#> clean        | Cleans build artifacts
clean:
	dune clean
