# Run Terminus locally on a k3d cluster (Kubernetes in Docker) using this chart.
#
#   make run       create/start the cluster and install or upgrade the chart
#   make stop      stop the cluster, keeping its data
#   make destroy   delete the cluster and all its data
#
# Requires: docker, k3d, helm.

CLUSTER   ?= terminus
NAMESPACE ?= terminus
RELEASE   ?= terminus
HOST      ?= terminus.localtest.me
PORT      ?= 8080

# The kubelet in k3s 1.35+ refuses to start on a cgroup v1 host, leaving an API
# server that never comes up ("connection to 127.0.0.1:6443 was refused"). On
# such hosts fall back to the last k3s release that still supports cgroup v1.
# Override with K3S_IMAGE=rancher/k3s:<tag> to pin any version on any host.
CGROUP_VERSION := $(shell docker info --format '{{.CgroupVersion}}' 2>/dev/null)
ifeq ($(CGROUP_VERSION),1)
K3S_IMAGE ?= rancher/k3s:v1.34.1-k3s1
endif
K3S_IMAGE_FLAG := $(if $(K3S_IMAGE),--image $(K3S_IMAGE))

CONTEXT := k3d-$(CLUSTER)
URL     := http://$(HOST):$(PORT)

# Always target the k3d cluster explicitly so a stray current-context can
# never receive the install.
HELM    := helm --kube-context $(CONTEXT)
KUBECTL := kubectl --context $(CONTEXT)

.DEFAULT_GOAL := help
.PHONY: help check run stop destroy status logs test

help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "} /^[a-z]+:.*## / {printf "  make %-8s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

check:
	@for tool in docker k3d helm; do \
		command -v $$tool >/dev/null || { echo "error: $$tool is required but not installed"; exit 1; }; \
	done
	@docker info >/dev/null 2>&1 || { echo "error: the Docker daemon is not running"; exit 1; }

run: check ## Start the cluster and install/upgrade Terminus
	@if k3d cluster list $(CLUSTER) >/dev/null 2>&1; then \
		k3d cluster start $(CLUSTER); \
	else \
		k3d cluster create $(CLUSTER) $(K3S_IMAGE_FLAG) --wait -p "$(PORT):80@loadbalancer"; \
	fi
	$(HELM) upgrade --install $(RELEASE) charts/terminus \
		--namespace $(NAMESPACE) --create-namespace \
		--values local/values.yaml \
		--set config.apiUri=$(URL) \
		--set ingress.host=$(HOST) \
		--wait --timeout 10m
	@echo
	@echo "Terminus is running at $(URL)"
	@echo "Stop it with 'make stop', remove everything with 'make destroy'."

stop: check ## Stop the cluster (data is kept; 'make run' resumes it)
	k3d cluster stop $(CLUSTER)

destroy: check ## Delete the cluster and all its data
	k3d cluster delete $(CLUSTER)

status: check ## Show the pods in the cluster
	$(KUBECTL) --namespace $(NAMESPACE) get pods,ingress

logs: check ## Follow the web container logs
	$(KUBECTL) --namespace $(NAMESPACE) logs --follow deployment/$(RELEASE)-web --container web

test: check ## Run the chart's helm test against the running release
	$(HELM) test $(RELEASE) --namespace $(NAMESPACE) --logs
