DOCKER_REGISTRY ?= localhost:5000

makeFileDir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
IMAGE_DEPS=
IMAGE_TARGETS=$(addprefix images/Dockerfile.,$(ARTIFACTS))
IMAGE_TAG=$(shell $(makeFileDir)/docker_tag.sh)
_DEFAULT_BUILD_TARGETS += image

.PHONY: _image
_image::
ifneq ($(IMAGE_DEPS),)
	make $(IMAGE_DEPS)
endif

.PHONY: $(IMAGE_TARGETS)
$(IMAGE_TARGETS):
	PROJECT_NAME=$(subst images/Dockerfile.,,$@) && \
		IMAGE_NAME=$(DOCKER_REGISTRY)/$$PROJECT_NAME:$(IMAGE_TAG) && \
		docker build $(BUILD_DIR) -f $@ -t $$IMAGE_NAME && \
		docker push $$IMAGE_NAME && \
		printf "$$IMAGE_NAME" > $(BUILD_DIR)/$${PROJECT_NAME}-image

.PHONY: image
image: _image $(IMAGE_TARGETS)
