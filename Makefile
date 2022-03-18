#> Available Makefile rules:
#> -------------------------
help : Makefile
	@sed -n 's/^#> //p' $<

#> dependencies | Install all OCaml ltl2ba dependencies
dependencies:
	opam install . --deps-only --with-doc --with-test --yes

#> build        | Builds the ltl2ba executable
build:
	dune build

#> test         | Run unit tests
test:
	dune test

#> doc          | Generates the HTML documentation via odoc
doc:
	dune build @doc
	ln -sf $(PWD)/_build/default/_doc/_html/index.html docs/odoc.html

#> clean        | Cleans build artifacts
clean:
	dune clean
