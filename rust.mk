CARGO ?= cargo
COVERAGE_IGNORES=

ifdef IN_CI
RUST_COVER_TYPE = --codecov --output-path codecov.json
NEXTEST_FLAGS = --no-fail-fast
WITH_COVERAGE = 1
else
RUST_COVER_TYPE = --open
endif

TEST_CMD=+nightly llvm-cov nextest --config-file $(CONFIG_DIR)/nextest.toml $(NEXTEST_FLAGS) --no-report --branch

.PHONY: _version
_version:
	cargo version

_build:: _version

_test:: _version
ifeq ($(WITH_COVERAGE), 1)
	# cleaning causes a rebuild, so we only do it locally if the user requests it
	@$(CARGO) llvm-cov clean --workspace
endif

test: unit itest

.PHONY: unit
unit:
	@$(CARGO) $(TEST_CMD)

.PHONY: itest
itest:
	@$(CARGO) $(TEST_CMD) --profile itest

build:
	$(CARGO) build

# This is dumb AF
space := $(subst ,, )
_cover::
	@LLVM_COV_FLAGS='-coverage-watermark=60,30' $(CARGO) llvm-cov report $(RUST_COVER_TYPE) \
		$(if $(COVERAGE_IGNORES),--ignore-filename-regex "$(subst $(space),|,$(COVERAGE_IGNORES))",)

.PHONY: release
release: NEW_APP_VERSION=$(subst v,,$(shell git cliff --bumped-version))
release:
	cargo set-version $(NEW_APP_VERSION)
	git cliff -c $(CONFIG_DIR)/cliff.toml -u --tag $(NEW_APP_VERSION) --prepend CHANGELOG.md
	git commit -a -m "release: version v$(NEW_APP_VERSION)" && \
		git tag v$(NEW_APP_VERSION)

.PHONY: publish
publish:
	cargo ws publish --publish-as-is
