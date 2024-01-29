K8S_MANIFESTS_DIR ?= $(BUILD_DIR)/manifests

.PHONY: k8s

k8s:
	cd k8s && poetry update
	cd k8s && JSII_SILENCE_WARNING_UNTESTED_NODE_VERSION=1 CDK8S_OUTDIR=$(K8S_MANIFESTS_DIR) BUILD_DIR=$(BUILD_DIR) poetry run ./main.py

run: k8s
	cp -r k8s/raw $(K8S_MANIFESTS_DIR) || true
	kubectl apply -f $(K8S_MANIFESTS_DIR)/raw || true
	kubectl apply -f $(K8S_MANIFESTS_DIR)
