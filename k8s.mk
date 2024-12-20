K8S_MANIFESTS_DIR ?= $(BUILD_DIR)/manifests
KUSTOMIZE_DIR ?= kustomize

.PHONY: pre-k8s k8s kustomize

$(K8S_MANIFESTS_DIR):
	mkdir -p $@

pre-k8s:: | $(K8S_MANIFESTS_DIR)
	if [ -f "k8s/pyproject.toml" ]; then cd k8s && poetry install; fi

k8s: pre-k8s
	cp -r k8s/raw $(K8S_MANIFESTS_DIR) || true
	if [ -f "k8s/pyproject.toml" ]; then \
	  	cd k8s && JSII_SILENCE_WARNING_UNTESTED_NODE_VERSION=1 CDK8S_OUTDIR=$(K8S_MANIFESTS_DIR) BUILD_DIR=$(BUILD_DIR) poetry run ./main.py; \
	fi

kustomize: pre-k8s
	cd k8s && rm -rf $(KUSTOMIZE_DIR)/* && mkdir -p $(KUSTOMIZE_DIR) && cp raw/* $(KUSTOMIZE_DIR)/.|| true
	cd k8s && JSII_SILENCE_WARNING_UNTESTED_NODE_VERSION=1 CDK8S_OUTDIR=$(KUSTOMIZE_DIR) BUILD_DIR=$(KUSTOMIZE_DIR) APP_VERSION=$(APP_VERSION) poetry run ./main.py --kustomize

run: k8s
	kubectl apply -f $(K8S_MANIFESTS_DIR)/raw || true
	kubectl apply -f $(K8S_MANIFESTS_DIR)
