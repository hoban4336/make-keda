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