CARGO ?= cargo
COVERAGE_IGNORES=
EXCLUDE_CRATES=
CARGO_PROFILE ?= test

ifdef IN_CI
RUST_COVER_TYPE = --lcov --output-path codecov.lcov
WITH_COVERAGE = 1
else
RUST_COVER_TYPE = --open
LLVM_COV_FLAGS=LLVM_COV_FLAGS='-coverage-watermark=60,30'
endif

ifdef WITH_COVERAGE
TEST_CMD=+nightly-$(RUST_NIGHTLY_VERSION) llvm-cov nextest --config-file $(CONFIG_DIR)/nextest.toml --cargo-profile $(CARGO_PROFILE) $(NEXTEST_FLAGS) --no-report --branch $(RUST_COVER_TYPE)
else
TEST_CMD=nextest run --config-file $(CONFIG_DIR)/nextest.toml --cargo-profile $(CARGO_PROFILE) $(NEXTEST_FLAGS)
endif

.PHONY: _version
_version:
	cargo version

_setup::
	cargo install --locked git-cliff
	cargo install --locked cargo-workspaces
	cargo install --locked cargo-edit@0.13.1

_build:: _version

_test:: _version
ifeq ($(WITH_COVERAGE), 1)
	# cleaning causes a rebuild, so we only do it locally if the user requests it
	@$(CARGO) llvm-cov clean --workspace --profile $(CARGO_PROFILE)
endif

test: unit itest

.PHONY: unit
unit:
	RUST_LOG=$(RUST_LOG) $(CARGO) $(TEST_CMD) $(CARGO_TEST) --no-fail-fast

.PHONY: itest
itest:
	RUST_LOG=$(RUST_LOG) $(CARGO) $(TEST_CMD) --profile itest --no-fail-fast

build:
	$(CARGO) build
	cp $(addprefix $(BUILD_DIR)/debug/,$(ARTIFACTS)) $(BUILD_DIR)/.

# This is dumb AF
space := $(subst ,, )
_cover::
	@$(LLVM_COV_FLAGS) $(CARGO) llvm-cov report --profile $(CARGO_PROFILE) $(RUST_COVER_TYPE) \
		$(if $(COVERAGE_IGNORES),--ignore-filename-regex "$(subst $(space),|,$(COVERAGE_IGNORES))",)

.PHONY: release
release: NEW_APP_VERSION=$(subst v,,$(shell git cliff -c $(CONFIG_DIR)/cliff.toml --bumped-version))
release:
	cargo set-version $(NEW_APP_VERSION) $(if $(EXCLUDE_CRATES),--exclude $(EXCLUDE_CRATES),)
	git cliff -c $(CONFIG_DIR)/cliff.toml -u --tag $(NEW_APP_VERSION) --prepend CHANGELOG.md
	(git commit -a -m "release: version v$(NEW_APP_VERSION)" || \
	 git commit -a -m "release: version v$(NEW_APP_VERSION)") && \
		git tag v$(NEW_APP_VERSION)

# Need the --allow-dirty flag because cargo ws publish changes Cargo.toml and then complains about it
.PHONY: publish
publish:
	cargo ws publish --publish-as-is --allow-dirty
