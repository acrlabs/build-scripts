K8S_INPUT_DIR ?= k8s
K8S_MANIFESTS_DIR ?= $(BUILD_DIR)/manifests
KUSTOMIZE_DIR ?= kustomize

APP_VERSION=$(shell tomlq -r .workspace.package.version Cargo.toml)
_DEFAULT_BUILD_TARGETS += run

$(K8S_MANIFESTS_DIR):
	mkdir -p $@

.PHONY: _k8s
_k8s:: | $(K8S_MANIFESTS_DIR)
	if [ -f "$(K8S_INPUT_DIR)/pyproject.toml" ]; then cd $(K8S_INPUT_DIR) && poetry install; fi
	make $(K8S_DEPS)

.PHONY: k8s
k8s: _k8s
	cp -r $(K8S_INPUT_DIR)/raw $(K8S_MANIFESTS_DIR) || true
	if [ -f "$(K8S_INPUT_DIR)/pyproject.toml" ]; then \
	  	cd $(K8S_INPUT_DIR) && JSII_SILENCE_WARNING_UNTESTED_NODE_VERSION=1 CDK8S_OUTDIR=../$(K8S_MANIFESTS_DIR) BUILD_DIR=../$(BUILD_DIR) poetry run ./main.py; \
	fi

.PHONY: kustomize
kustomize: _k8s
	cd $(K8S_INPUT_DIR) && rm -rf $(KUSTOMIZE_DIR)/* && mkdir -p $(KUSTOMIZE_DIR) && cp raw/* $(KUSTOMIZE_DIR)/. || true
	cd $(K8S_INPUT_DIR) && JSII_SILENCE_WARNING_UNTESTED_NODE_VERSION=1 CDK8S_OUTDIR=$(KUSTOMIZE_DIR) BUILD_DIR=$(KUSTOMIZE_DIR) APP_VERSION=$(APP_VERSION) poetry run ./main.py --kustomize

.PHONY: run
run: $(K8S_INPUT_DIR)
	kubectl apply -f $(K8S_MANIFESTS_DIR)/raw || true
	kubectl apply -f $(K8S_MANIFESTS_DIR)
