# On macOS 26 dune built with OCaml 5.x segfaults when running jobs in
# parallel; build serially there. See lat.md/roadmap.md#M0 Build Spike.
JOBS := $(if $(filter Darwin,$(shell uname -s)),-j 1,)
SW := ./scripts/sw

.PHONY: all build test turso switch clean

all: build

switch:
	opam switch create . --packages ocaml-base-compiler.5.3.0 --no-install -y
	opam install --switch=. . --deps-only --with-test -y

turso:
	./scripts/build-turso.sh

build:
	$(SW) dune build $(JOBS) --root .

test:
	$(SW) dune test $(JOBS) --root . --force

clean:
	$(SW) dune clean --root .
