BUILD_DIR ?= $(shell pwd)/.build
DOCKER_REGISTRY ?= localhost:5000

IMAGE_TARGETS=$(addprefix images/Dockerfile.,$(ARTIFACTS))
SHA=$(shell git rev-parse --short HEAD)

makeFileDir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
UNCLEAN_TREE_SUFFIX=$(shell $(makeFileDir)/get_unclean_sha.sh)

.PHONY: default verify build image run $(ARTIFACTS) $(EXTRA_BUILD_ARTIFACTS) $(IMAGE_TARGETS) lint test cover clean

.DEFAULT_GOAL = default

default: build image run

verify: lint test cover

$(BUILD_DIR):
	mkdir -p $@

$(ARTIFACTS) $(EXTRA_BUILD_ARTIFACTS):: | $(BUILD_DIR)

build: $(ARTIFACTS) $(EXTRA_BUILD_ARTIFACTS)

image: $(IMAGE_TARGETS)

$(IMAGE_TARGETS):
	PROJECT_NAME=$(subst images/Dockerfile.,,$@) && \
		IMAGE_NAME=$(DOCKER_REGISTRY)/$$PROJECT_NAME:$(SHA)$(UNCLEAN_TREE_SUFFIX) && \
		docker build $(BUILD_DIR) -f $@ -t $$IMAGE_NAME && \
		docker push $$IMAGE_NAME && \
		echo -n $$IMAGE_NAME > $(BUILD_DIR)/$${PROJECT_NAME}-image

setup::
	pre-commit install

clean::
	rm -rf $(BUILD_DIR)
