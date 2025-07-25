.PHONY: helm_kong
helm_kong: ## Helm Kong Install
	@kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml && \
	kubectl apply -f ./kong/gateway.yaml && \
	helm repo add kong https://charts.konghq.com && \
	helm repo update && \
	helm upgrade --install kong kong/kong \
	--namespace kong \
	--create-namespace \
	-f ./kong/values-override.yaml

.PHONY: uninstall_kong
uninstall_kong:	## Helm Kong Uninstall
	@helm uninstall kong -n kong || true && \
	kubectl delete ns kong --ignore-not-found && \
	kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml --ignore-not-found && \
	kubectl delete -f ./kong/gateway.yaml --ignore-not-found && \
	echo "✅ Kong and related Gateway API resources deleted."

.PHONY: template_kong
template_kong: ## Helm Template Kong Install
	@helm template kong kong/kong \
	--namespace kong \
	--create-namespace \
	--set ingressController.installCRDs=false \
	--set proxy.type=LoadBalancer > ./kong/template.yaml

.PHONY: helm_konga
install_konga: ## Deploy Konga (admin UI for Kong)
	@kubectl apply -f ./kong/konga.yaml && \
	echo "✅ Konga deployed to namespace kong."

.PHONY: uninstall_konga
uninstall_konga: ## Uninstall Konga only
	@kubectl delete -f ./kong/konga.yaml --ignore-not-found
