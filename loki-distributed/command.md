###
- https://artifacthub.io/packages/helm/grafana/loki-distributed


## install
```
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm show values grafana/loki-distributed --version 2.10.2
helm upgrade --install loki-distribute --namespace=loki-distribute grafana/loki-distributed --version 2.10.2
```