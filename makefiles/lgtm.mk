.PHONY: deploy_prometheus
deploy_prometheus: ## prometheus 설치
	@helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && \
	helm repo update && \
	helm upgrade --install prometheus prometheus-community/prometheus \
	-n monitoring --create-namespace \
	-f prometheus/values-override.yaml && \
	kubectl rollout restart deployment prometheus-server -n monitoring

.PHONY: deploy_prometheus_stack
deploy_prometheus_stack: ## kube-prometheus-stack 설치
	@helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && \
	helm repo update && \
	helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
	-n monitoring --create-namespace \
	-f prometheus-stack/values-override.yaml

.PHONY: deploy_mimir
deploy_mimir: ## mimir 설치
	@helm repo add grafana https://grafana.github.io/helm-charts && \
	helm repo update && \
	helm upgrade --install mimir grafana/mimir-distributed \
	-n mimir --create-namespace \
	-f mimir/values-override.yaml

.PHONY: deploy_loki
deploy_loki: ## loki 설치
	@helm repo add grafana https://grafana.github.io/helm-charts && \
	helm repo update && \
	helm upgrade --install loki grafana/loki-stack \
	-n logging --create-namespace \
	-f loki/values-override.yaml

.PHONY: clean_loki
clean_loki:
	kubectl delete secret -n logging -l "owner=helm,name=loki" || true && \
	helm uninstall loki -n logging || true

# https://opentelemetry.io/docs/platforms/kubernetes/helm/
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