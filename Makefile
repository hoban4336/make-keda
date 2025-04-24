## Makefile for building applications and deploying via KEDA
## Global vars

# Load environment variables from .env file
include .env
export

FUNCS = spring-io nginx spring-a spring-b
# FUNCS = nginx
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
			echo "No build founded in $$dir"; \
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

# .PHONY: push_to_all_nodes
# push_to_all_nodes: ## Pushes images to all cluster nodes
# 	@for node in $(NODES); do \
# 		for dir in $(FUNCS); do \
# 			echo ">>> Exporting $(CLUSTER_REGISTRY)/$$dir:$(VERSION) to $$node"; \
# 			docker save $(CLUSTER_REGISTRY)/$$dir:$(VERSION) > $$dir.tar; \
# 			scp $$dir.tar $$node:/tmp/$$dir.tar; \
# 			ssh $$node "sudo ctr -n=k8s.io images import /tmp/$$dir.tar && rm /tmp/$$dir.tar"; \
# 			rm $$dir.tar; \
# 		done; \
# 	done

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

.PHONY: restart ## Restart
restart:
	kubectl rollout restart deployment nginx-deployment -n nginx

.PHONY: deploy_keda
deploy_keda: ## Deploy KEDA into the cluster
#	kubectl apply -f https://github.com/kedacore/keda/releases/download/v2.14.0/keda-2.14.0.yaml
	@helm repo add kedacore https://kedacore.github.io/charts && \
	helm repo update && \
	helm upgrade --install keda kedacore/keda \
	-n keda --create-namespace \
	--set prometheus.metricServer.enabled=true \
	--set prometheus.operator.enabled=true && \
	helm upgrade --install http-add-on kedacore/keda-add-ons-http \
	-n keda --create-namespace

.PHONY: template_keda
template_keda: # helm tempalte keda
	helm template keda kedacore/keda \
	-n keda --create-namespace \
	--set prometheus.metricsServer.enabled=true \
	--set prometheus.metricsServer.port=8080

.PHONY: delete_keda
delete_keda: ## Delete KEDA from the cluster
#	kubectl delete -f https://github.com/kedacore/keda/releases/download/v2.14.0/keda-2.14.0.yaml
	helm uninstall keda -n keda
	helm uninstall http-add-on -n keda

.PHONY: deploy_alb
deploy_alb: ## Install ALB Controller 민간
	kubectl --kubeconfig=$KUBE_CONFIG apply -f https://raw.githubusercontent.com/NaverCloudPlatform/nks-alb-ingress-controller/main/docs/install/pub/install.yaml

.PHONY: deploy_alb_gov_2
deploy_alb_gov_2: ## Install ALB Controller 공공
	kubectl --kubeconfig=$KUBE_CONFIG apply -f https://raw.githubusercontent.com/NaverCloudPlatform/nks-alb-ingress-controller/main/docs/install/gov-krs/install.yaml

.PHONY: install_helm
install_helm: ## helm 설치
	@VERSION="v3.13.2" && \
	curl -LO https://get.helm.sh/helm-$${VERSION}-linux-amd64.tar.gz && \
	tar -zxvf helm-$${VERSION}-linux-amd64.tar.gz && \
	sudo mv linux-amd64/helm /usr/local/bin/helm && \
	rm -rf linux-amd64 helm-$${VERSION}-linux-amd64.tar.gz

.PHONY: deploy_prometheus
deploy_prometheus: ## prometheus 설치
	@helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && \
	helm repo update && \
	helm upgrade --install prometheus prometheus-community/prometheus \
	-n monitoring --create-namespace \
	-f prometheus/values-override.yaml && \
	kubectl rollout restart deployment prometheus-server -n monitoring

.PHONY: deploy_loki
deploy_loki: ## loki 설치
	@helm repo add grafana https://grafana.github.io/helm-charts && \
	helm repo update && \
	helm upgrade --install loki grafana/loki-stack \
	-n logging --create-namespace \
	-f loki/values-override.yaml

.PHONY: deploy_collector
deploy_collector: ## oltk-collector 설치
	@helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts && \
	helm repo update && \
	helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
	-n observability --create-namespace \
	-f otel/otel-collector-values-override.yaml

.PHONY: deploy_tempo
deploy_tempo: ## tempo 설치
	@helm repo add grafana https://grafana.github.io/helm-charts && \
	helm repo update && \
	helm upgrade --install tempo grafana/tempo \
	-n observability --create-namespace \
	-f tempo/tempo-values-override.yaml

.PHONY: deploy_grafana
deploy_grafana: ## grafana 설치
	@helm repo add grafana https://grafana.github.io/helm-charts && \
	helm repo update && \
	helm upgrade --install grafana grafana/grafana \
	-n monitoring --create-namespace \
	-f grafana/grafana-values.yaml

.PHONY: deploy_authentik
deploy_authentik: ## authentik 설치
	@bash -c '\
	PASSWORD=$$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 12); \
	helm repo add authentik https://charts.goauthentik.io; \
	helm repo update; \
	helm upgrade --install authentik authentik/authentik \
	  -n auth-proxy --create-namespace \
	  -f authentik/values-override.yaml \
	  --set postgresql.auth.password="$$PASSWORD"; \
	echo "[INFO] Generated Password: $$PASSWORD"; \
	kubectl get secret --namespace auth-proxy authentik-postgresql \
	  -o jsonpath="{.data}"; echo'

.PHONY: rebuild_authentik
rebuild_authentik: ## authentik 재설치
	helm uninstall authentik -n auth-proxy && \
	kubectl delete pvc -l app.kubernetes.io/instance=authentik -n auth-proxy && \
	deploy_authentik

.PHONY: ingress_patch
ingress_patch:
	kustomize build ./ingress/overlays/dev/ | kubectl apply -f -