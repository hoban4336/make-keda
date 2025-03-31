## Makefile for building applications and deploying via KEDA
## Global vars

FUNCS = spring-io
DOCKER_HUB_DOMAIN = local
VERSION = 1.0

.PHONY: help
help: ## show help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[$$()% 0-9a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: build
build: ## Build docker images for services
	@for dir in $(FUNCS); do \
		echo "*************************************"; \
		echo "Setting up $$dir"; \
		if [ -f "./$$dir/.repo.github" ]; then \
			echo "Found .repo.github file, building from local repository"; \
			cd ./$$dir && \
			eval $$(cat .repo.github) && \
			rm -rf temp_repo && \
			git clone -b $$BRANCH $$REPO_URL temp_repo && \
			if [ ! -f "temp_repo/Dockerfile" ]; then \
				echo "Error: Dockerfile not found in repository"; \
				rm -rf temp_repo; \
				cd ..; \
				exit 1; \
			fi && \
			echo "Building Docker image for $$dir"; \
			docker build temp_repo -t $(DOCKER_HUB_DOMAIN)/$$dir:$(VERSION) && \
			rm -rf temp_repo && \
			cd ..; \
		else \
			echo "No .repo.github file found, skipping build for $$dir"; \
		fi; \
	done

.PHONY: copy_to_microk8s
copy_to_microk8s: ## Copies built containers to microk8s internal registry
	@for dir in $(FUNCS); do \
		echo "*************************************"; \
		echo "Copying $$dir to microk8s"; \
		docker save dev.local/$$dir:local > $$dir.tar && \
		microk8s ctr image import $$dir.tar && \
		rm $$dir.tar; \
	done

.PHONY: build_microk8s
build_microk8s: ## Build and push containers to microk8s
	make DOCKER_HUB_DOMAIN=dev.local VERSION=local build
	make copy_to_microk8s

.PHONY: deploy
deploy: ## Deploy services and KEDA scaled objects
	@for dir in $(FUNCS); do \
		echo "*************************************"; \
		echo "Deploying $$dir"; \
		kubectl apply -f ./$$dir/deployment.yaml; \
		if [ -f ./$$dir/scaledobject.yaml ]; then \
			kubectl apply -f ./$$dir/scaledobject.yaml; \
		elif [ -f ./$$dir/scaledjob.yaml ]; then \
			kubectl apply -f ./$$dir/scaledjob.yaml; \
		fi; \
	done

.PHONY: delete
delete: ## Delete KEDA scaled objects and deployments
	@for dir in $(FUNCS); do \
		echo "*************************************"; \
		echo "Deleting $$dir"; \
		if [ -f ./$$dir/scaledobject.yaml ]; then \
			kubectl delete -f ./$$dir/scaledobject.yaml; \
		elif [ -f ./$$dir/scaledjob.yaml ]; then \
			kubectl delete -f ./$$dir/scaledjob.yaml; \
		fi; \
		kubectl delete -f ./$$dir/deployment.yaml; \
	done

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
