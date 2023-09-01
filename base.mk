BUILD_DIR ?= $(shell pwd)/.build
K8S_MANIFESTS_DIR ?= $(BUILD_DIR)/manifests
DOCKER_REGISTRY ?= localhost:5000

IMAGE_TARGETS=$(addprefix images/Dockerfile.,$(ARTIFACTS))
SHA=$(shell git rev-parse --short HEAD)

makeFileDir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
UNCLEAN_TREE_SUFFIX=$(shell $(makeFileDir)/get_unclean_sha.sh)

define RUN_COMMANDS
	cd k8s && CDK8S_OUTDIR=$(K8S_MANIFESTS_DIR) BUILD_DIR=$(BUILD_DIR) poetry run ./main.py 
	kubectl apply -f $(K8S_MANIFESTS_DIR)
endef

.PHONY: default verify build image run $(ARTIFACTS) $(IMAGE_TARGETS) lint test cover clean

.DEFAULT_GOAL = default

default: build image run

verify: lint test cover

build: $(ARTIFACTS)

image: $(IMAGE_TARGETS)

run:
	$(call RUN_COMMANDS)

$(IMAGE_TARGETS):
	PROJECT_NAME=$(subst images/Dockerfile.,,$@) && \
		IMAGE_NAME=$(DOCKER_REGISTRY)/$$PROJECT_NAME:$(SHA)$(UNCLEAN_TREE_SUFFIX) && \
		docker build $(BUILD_DIR) -f $@ -t $$IMAGE_NAME && \
		docker push $$IMAGE_NAME && \
		echo -n $$IMAGE_NAME > $(BUILD_DIR)/$${PROJECT_NAME}-image

setup::
	pre-commit install
	cd k8s && poetry install

clean::
	rm -rf $(BUILD_DIR)
