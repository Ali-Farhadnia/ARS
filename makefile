# Check to see if we can use ash, in Alpine images, or default to BASH.
SHELL_PATH = /bin/ash
SHELL = $(if $(wildcard $(SHELL_PATH)),/bin/ash,/bin/bash)

run:
	go run api/services/ars/main.go | go run api/tooling/logfmt/main.go

# ==============================================================================
# Define dependencies

GOLANG          := golang:1.22
ALPINE          := alpine:3.19
KIND            := kindest/node:v1.29.0
KIND_CLUSTER    := ars-cluster
ARS_APP         := ars
BASE_IMAGE_NAME := localhost/alifarhadnia
VERSION         := 0.0.1
ARS_IMAGE       := $(BASE_IMAGE_NAME)/$(ARS_APP):$(VERSION)

# ==============================================================================
# Building containers

build: ars

ars:
	docker build \
		-f zarf/docker/dockerfile.ars \
		-t $(ARS_IMAGE) \
		--build-arg BUILD_REF=$(VERSION) \
		--build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
		.


# ==============================================================================
# Running from within k8s/kind

dev-up:
	kind create cluster \
		--image $(KIND) \
		--name $(KIND_CLUSTER) \
		--config zarf/k8s/dev/kind-config.yaml
	kubectl wait --timeout=120s --namespace=local-path-storage --for=condition=Available deployment/local-path-provisioner

dev-down:
	kind delete cluster --name $(KIND_CLUSTER)

dev-status-all:
	kubectl get nodes -o wide
	kubectl get svc -o wide
	kubectl get pods -o wide --watch --all-namespaces
	
dev-status:
	watch -n 2 kubectl get pods -o wide --all-namespaces

# ==============================================================================
# Modules support

tidy:
	go mod tidy
	go mod vendor