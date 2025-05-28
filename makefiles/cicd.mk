.PHONY: deploy_argocd
deploy_argocd: ## argocd 설치
	@helm repo add argo https://argoproj.github.io/argo-helm && \
	helm repo update && \
	helm upgrade --install argocd argo/argo-cd \
	-n argocd --create-namespace \
