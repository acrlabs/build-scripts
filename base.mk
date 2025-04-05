# public variables that can be changed by projects
BUILD_DIR ?= .build
CONFIG_DIR ?= .config

# _DEFAULT_BUILD_TARGETS can be modified by sub-makefiles to add additional "default" behaviour
# when you run `make`
_DEFAULT_BUILD_TARGETS = build
.DEFAULT_GOAL = default
.PHONY: default
default:
	make $(_DEFAULT_BUILD_TARGETS)

.PHONY: verify
verify: lint test cover

$(BUILD_DIR) $(COVERAGE_DIR):
	mkdir -p $@

# We define a buch of internal make targets prefixed with '_'; these all use the double-colon
# syntax to allow us to add new commands to them in other *internal* makefiles.  They're not
# intended to be modified or overwritten in project-specific makefiles.  Each of these
# are pre-requisites for the "public" targets, which have the same name without the underscore
.PHONY: _setup
_setup::
	pre-commit install

.PHONY: _lint
_lint::
	pre-commit run --all

.PHONY: _test
_test::

.PHONY: _cover
_cover::

.PHONY: _build
_build:: | $(BUILD_DIR)

.PHONY: _clean
_clean::
	rm -rf $(BUILD_DIR)

# Public targets defined below
.PHONY: setup
setup: _setup

.PHONY: lint
lint: _lint

.PHONY: test
test: _test

.PHONY: cover
cover: _cover

.PHONY: build
build: _build

.PHONY: clean
clean: _clean
