CARGO ?= cargo
COVERAGE_IGNORES='../*' '/*' '*/tests/*' '*_test.rs' '$(BUILD_DIR)/*'
CARGO_TEST_PREFIX=RUSTFLAGS='-Cinstrument-coverage' LLVM_PROFILE_FILE='$(COVERAGE_DIR)/cargo-test-%p-%m.profraw'

ifdef IN_CI
RUST_COVER_TYPE ?= lcov
else
RUST_COVER_TYPE=markdown
endif

RUST_COVER_FILE=$(COVERAGE_DIR)/rust-coverage.$(RUST_COVER_TYPE)

.PHONY: _version
_version:
	cargo version

_build:: _version

_test:: _version

test: unit itest

.PHONY: unit
unit:
	@$(CARGO_TEST_PREFIX) $(CARGO) test --profile test-cover $(CARGO_TEST) -- --skip itest

.PHONY: itest
itest:
	@$(CARGO_TEST_PREFIX) $(CARGO) test itest --profile test-cover  -- --nocapture --test-threads=1

build:
	$(CARGO) build

_cover::
	grcov . --binary-path $(BUILD_DIR)/test-cover/deps -s . -t $(RUST_COVER_TYPE) -o $(RUST_COVER_FILE) --branch \
		$(addprefix --ignore ,$(COVERAGE_IGNORES)) \
		--excl-line '#\[derive' \
		--excl-start '#\[cfg\((test|feature = "testutils")'
	@if [ "$(RUST_COVER_TYPE)" = "markdown" ]; then cat $(RUST_COVER_FILE); fi

.PHONY: release
release: NEW_APP_VERSION=$(subst v,,$(shell git cliff --bumped-version))
release:
	cargo set-version $(NEW_APP_VERSION)
	git cliff -u --tag $(NEW_APP_VERSION) --prepend CHANGELOG.md
	git commit -a -m "release: version v$(NEW_APP_VERSION)" && \
		git tag v$(NEW_APP_VERSION)

.PHONY: publish
publish:
	cargo ws publish --publish-as-is
