NAMESPACE = argocd

.PHONY: deploy_argocd2
deploy_argocd2: create_ns
	helm repo add argo https://argoproj.github.io/argo-helm && \
	helm repo update && \
	helm upgrade --install argocd argo/argo-cd \
	-n $(NAMESPACE) \
	--create-namespace \
	-f argocd/values-override.yaml
	kubectl apply -f argocd_apps/infra-environments.yaml

.PHONY: deploy_argocd
deploy_argocd: create_ns  ## argocd 설치
# --- ① Core ----------------------------------------------------
	$(call helm_full_install, \
		argocd, \
		argo, \
		https://argoproj.github.io/argo-helm, \
		argo/argo-cd, \
		argocd/values-override.yaml, \
		argocd, \
		"--atomic" \
		)
# --- ② Projects / Applications --------------------------------
	$(call helm_full_install, \
		argocd-apps, \
		argo, \
		https://argoproj.github.io/argo-helm, \
		argo/argocd-apps, \
		argocd-apps/values-override.yaml, \
		argocd, \
		"--atomic --wait" \
	)