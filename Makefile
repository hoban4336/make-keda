## Makefile for building applications and deploying via KEDA
## Global vars

# Load environment variables from .env file
include .env
export

FUNCS = spring-io nginx
DOCKER_HUB_DOMAIN = local
VERSION = 1.0
GITHUB_TOKEN ?= $(shell echo $$GITHUB_TOKEN)
CLUSTER_REGISTRY = dev.local

.PHONY: help
help: ## show help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[$$()% 0-9a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: build
build: ## Build docker images for services
	@if [ -z "$(GITHUB_TOKEN)" ]; then \
		echo "Error: GITHUB_TOKEN is not set in .env file"; \
		echo "Please set your GitHub token in .env file"; \
		exit 1; \
	fi
	@for dir in $(FUNCS); do \
		echo "*************************************"; \
		echo "Setting up $$dir"; \
		if [ -f "./$$dir/.repo.github" ]; then \
			echo "Found .repo.github file, building from local repository"; \
			cd ./$$dir && \
			eval $$(cat .repo.github) && \
			rm -rf temp_repo && \
			echo "Cloning repository: $$REPO_URL"; \
			if ! git clone https://$(GITHUB_TOKEN)@github.com/$$REPO_URL temp_repo -b $$BRANCH; then \
				echo "Error: Failed to clone repository. Please check your GitHub token and repository URL."; \
				cd ..; \
				exit 1; \
			fi && \
			if [ ! -f "temp_repo/Dockerfile" ]; then \
				echo "Error: Dockerfile not found in repository"; \
				rm -rf temp_repo; \
				cd ..; \
				exit 1; \
			fi && \
			echo "Building Docker image for $$dir"; \
			if ! docker build --tag $(CLUSTER_REGISTRY)/$$dir:$(VERSION) temp_repo; then \
				echo "Error: Failed to build Docker image"; \
				rm -rf temp_repo; \
				cd ..; \
				exit 1; \
			fi && \
			rm -rf temp_repo && \
			cd ..; \
		else \
			echo "Building Docker image for $$dir"; \
			if ! docker build --tag $(CLUSTER_REGISTRY)/$$dir:$(VERSION) temp_repo; then \
				echo "Error: Failed to build Docker image"; \
				rm -rf temp_repo; \
				cd ..; \
				exit 1; \
			fi && \
			rm -rf temp_repo && \
			cd ..; \
		fi; \
	done

.PHONY: copy_to_ncp
copy_to_ncp: ## Copies built containers to containerd registry
	@for dir in $(FUNCS); do \
		echo "*************************************"; \
		echo "Checking image for $$dir"; \
		if docker image inspect $(CLUSTER_REGISTRY)/$$dir:$(VERSION) >/dev/null 2>&1; then \
			echo "Copying $$dir to containerd registry"; \
			docker save $(CLUSTER_REGISTRY)/$$dir:$(VERSION) > $$dir.tar && \
			sudo ctr -n=k8s.io images import $$dir.tar && \
			rm $$dir.tar; \
		else \
			echo "Image $(CLUSTER_REGISTRY)/$$dir:$(VERSION) not found, skipping..."; \
		fi; \
	done

.PHONY: build_ncp
build_ncp: ## Build and push containers to containerd
	make build
	make copy_to_ncp

.PHONY: deploy
deploy: ## Deploy services and KEDA scaled objects
	@for dir in $(FUNCS); do \
		echo "*************************************"; \
		echo "Deploying $$dir"; \
		kubectl create namespace $$dir --dry-run=client -o yaml | kubectl apply -f -; \
		kubectl apply -f ./$$dir/deployment.yaml -n $$dir; \
		if [ -f ./$$dir/scaledobject.yaml ]; then \
			kubectl apply -f ./$$dir/scaledobject.yaml -n $$dir; \
		elif [ -f ./$$dir/scaledjob.yaml ]; then \
			kubectl apply -f ./$$dir/scaledjob.yaml -n $$dir; \
		fi; \
	done
	@echo "Deploying unified ingress configuration..."
	@kubectl create namespace nginx --dry-run=client -o yaml | kubectl apply -f -
	@kubectl apply -f ingress.yaml

.PHONY: delete
delete: ## Delete KEDA scaled objects and deployments
	@for dir in $(FUNCS); do \
		echo "*************************************"; \
		echo "Deleting $$dir"; \
		if [ -f ./$$dir/scaledobject.yaml ]; then \
			kubectl delete -f ./$$dir/scaledobject.yaml -n $$dir --ignore-not-found; \
		elif [ -f ./$$dir/scaledjob.yaml ]; then \
			kubectl delete -f ./$$dir/scaledjob.yaml -n $$dir --ignore-not-found; \
		fi; \
		kubectl delete -f ./$$dir/deployment.yaml -n $$dir --ignore-not-found; \
	done
	@echo "Deleting unified ingress configuration..."
	@kubectl delete -f ingress.yaml --ignore-not-found

.PHONY: rebuild
rebuild: ## Rebuild by deleting and redeploying services
	make delete
	make deploy

.PHONY: deploy_keda
deploy_keda: ## Deploy KEDA into the cluster
	kubectl apply -f https://github.com/kedacore/keda/releases/download/v2.14.0/keda-2.14.0.yaml

.PHONY: delete_keda
delete_keda: ## Delete KEDA from the cluster
	kubectl delete -f https://github.com/kedacore/keda/releases/download/v2.14.0/keda-2.14.0.yaml
