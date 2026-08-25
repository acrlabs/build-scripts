UPSTREAM_DOCKER_REGISTRY ?=
DOCKER_REGISTRY ?= localhost:5000

DOCKER_IMAGE_TAG_PATHSPECS+=:!.codecov.yml\
	:!.config\
	:!.github\
	:!.gitignore\
	:!.markdownlint.yaml\
	:!.markdownlintignore\
	:!.pre-commit-config.yaml\
	:!.rustfmt.toml\
	:!CHANGELOG.md\
	:!CODE_OF_CONDUCT.md\
	:!LICENSE\
	:!README.md\
	:!deny.toml\
	:!docs\
	:!examples\
	:!k8s

makeFileDir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
IMAGE_DEPS=
IMAGE_TAG=$(shell DOCKER_IMAGE_TAG_PATHSPECS='$(DOCKER_IMAGE_TAG_PATHSPECS)' $(makeFileDir)/docker_tag.sh)
IMAGE_BUILD_TARGETS=$(addprefix images/$(BUILD_MODE)/Dockerfile.,$(ARTIFACTS))
IMAGE_PULL_TARGETS=$(addprefix $(UPSTREAM_DOCKER_REGISTRY)/,$(ARTIFACTS))
_DEFAULT_BUILD_TARGETS += image

.PHONY: _image
_image::
	$(if $(IMAGE_DEPS),make $(IMAGE_DEPS),,)

.PHONY: _push_image
_push_image:
	docker push $(IMAGE_NAME)
	printf "$(IMAGE_NAME)" > $(BUILD_DIR)/$(PROJECT_NAME)-image

.PHONY: $(IMAGE_BUILD_TARGETS)
$(IMAGE_BUILD_TARGETS): PROJECT_NAME=$(subst images/$(BUILD_MODE)/Dockerfile.,,$@)
$(IMAGE_BUILD_TARGETS): IMAGE_NAME=$(DOCKER_REGISTRY)/$(PROJECT_NAME):$(IMAGE_TAG)
$(IMAGE_BUILD_TARGETS):
	docker build $(BUILD_DIR) -f $@ -t $(IMAGE_NAME)
	make _push_image PROJECT_NAME=$(PROJECT_NAME) IMAGE_NAME=$(IMAGE_NAME)

.PHONY: $(IMAGE_PULL_TARGETS)
$(IMAGE_PULL_TARGETS): PROJECT_NAME=$(subst $(UPSTREAM_DOCKER_REGISTRY)/,,$@)
$(IMAGE_PULL_TARGETS): IMAGE_NAME=$(DOCKER_REGISTRY)/$(PROJECT_NAME):$(IMAGE_TAG)
$(IMAGE_PULL_TARGETS):
	docker pull $@:$(IMAGE_TAG)
	docker tag $@:$(IMAGE_TAG) $(IMAGE_NAME)
	make _push_image PROJECT_NAME=$(PROJECT_NAME) IMAGE_NAME=$(IMAGE_NAME)

.PHONY: image
image: _image $(IMAGE_BUILD_TARGETS)

.PHONY: fetch-images
fetch-images: $(IMAGE_PULL_TARGETS)
