CARGO_PROFILE ?= $(if $(filter $(BUILD_MODE),debug),dev,$(BUILD_MODE))
COVERAGE_IGNORES=
EXCLUDE_CRATES=

# we can get rid of this if cargo build --artifact-dir ever stabilizes
# https://github.com/rust-lang/cargo/issues/6790
CARGO_ARTIFACT_DIR = $(if $(filter $(CARGO_PROFILE),dev),debug,$(CARGO_PROFILE))

ifdef IN_CI
RUST_COVER_TYPE = --lcov --output-path codecov.lcov
WITH_COVERAGE = 1
else
RUST_COVER_TYPE = --open
LLVM_COV_FLAGS=LLVM_COV_FLAGS='-coverage-watermark=60,30'
endif

ifdef WITH_COVERAGE
CARGO_TEST_CMD=cargo +nightly-$(RUST_NIGHTLY_VERSION) llvm-cov nextest --config-file $(CONFIG_DIR)/nextest.toml $(NEXTEST_FLAGS) --no-report --branch $(RUST_COVER_TYPE)
else
CARGO_TEST_CMD=cargo nextest run --config-file $(CONFIG_DIR)/nextest.toml $(NEXTEST_FLAGS)
endif

.PHONY: _version
_version:
	cargo version

_setup::
	cargo install --locked git-cliff
	cargo install --locked cargo-workspaces@0.4.2
	cargo install --locked cargo-edit@0.13.1

_build:: _version
ifeq ($(DISPATCH_MODE), local)
	cargo build $(addprefix -p=,$(ARTIFACTS)) --profile=$(CARGO_PROFILE) --color=always
	cp $(addprefix $(BUILD_DIR)/$(CARGO_ARTIFACT_DIR)/,$(ARTIFACTS)) $(BUILD_DIR)/.
else
	make $(BUILD_TARGETS)
endif

_test:: _version
ifeq ($(WITH_COVERAGE), 1)
	# cleaning causes a rebuild, so we only do it locally if the user requests it
	@cargo llvm-cov clean --workspace
endif
	make unit itest

# This is dumb AF -- you can't include a literal space character in the function definition,
# so we define a make variable that is equal to a literal space
space := $(subst ,, )
_cover::
	@$(LLVM_COV_FLAGS) cargo llvm-cov report $(RUST_COVER_TYPE) \
		$(if $(COVERAGE_IGNORES),--ignore-filename-regex "$(subst $(space),|,$(COVERAGE_IGNORES))",)

# Additional public targets below: we don't anticipate project makefiles needing to override these
# so we don't prefix with _ (that way users can easily call, e.g., `make unit` to just run unit tests).
.PHONY: unit
unit:
	RUST_LOG=$(RUST_LOG) $(CARGO_TEST_CMD) $(CARGO_TEST) --no-fail-fast

.PHONY: itest
itest:
	RUST_LOG=$(RUST_LOG) $(CARGO_TEST_CMD) --profile itest --no-fail-fast

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
	cargo ws publish --publish-as-is
