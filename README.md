<div align="center">
	<h1>𝝋 ⇝ 𝒜</h1>

![CI][ci-link] ![COV][cov-link] ![DOC][doc-link]

 `ltl2ba` a compiler of LTL formula to Büchi automata.

</div>

## Build

To install OCaml dependencies, run:

	make dependencies

To build the executable, run:

	make build

To run tests:

	make test

## Run

Once it's built, you can simply run the executable:

	./_build/default/src/ltl2ba.exe --help

Or, using `opam` to install the local package:

	opam install . --working-dir
	ltl2ba --help

## Documentation

Documentation can be found [here](https://emilerolley.github.io/ltl2ba/ltl2ba/index.html).

[ci-link]: https://github.com/EmileRolley/ltl2ba/actions/workflows/build.yml/badge.svg
[cov-link]: https://codecov.io/gh/EmileRolley/ltl2ba/branch/main/graph/badge.svg?token=PIIQ0CSE8C
[doc-link]: https://img.shields.io/badge/doc-online-blue?link=https://emilerolley.github.io/ltl2ba/ltl2ba/index.html
