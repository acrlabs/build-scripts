BUILD_DIR ?= $(shell pwd)/.build
DOCKER_REGISTRY ?= localhost:5000

makeFileDir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
IMAGE_TARGETS=$(addprefix images/Dockerfile.,$(ARTIFACTS))
IMAGE_TAG=$(shell $(makeFileDir)/docker_tag.sh)

.PHONY: default verify pre-build pre-image build image run main extra $(IMAGE_TARGETS) lint test cover clean

.DEFAULT_GOAL = default

default: build image run

verify: lint test cover

$(BUILD_DIR):
	mkdir -p $@

# "order-only" dependency (the `|`) ensures that the build dir exists before running the build step
build: | $(BUILD_DIR)
	make pre-build main extra

image: pre-image $(IMAGE_TARGETS)

$(IMAGE_TARGETS):
	PROJECT_NAME=$(subst images/Dockerfile.,,$@) && \
		IMAGE_NAME=$(DOCKER_REGISTRY)/$$PROJECT_NAME:$(IMAGE_TAG) && \
		docker build $(BUILD_DIR) -f $@ -t $$IMAGE_NAME && \
		docker push $$IMAGE_NAME && \
		printf "$$IMAGE_NAME" > $(BUILD_DIR)/$${PROJECT_NAME}-image

setup::
	pre-commit install

clean::
	rm -rf $(BUILD_DIR)
