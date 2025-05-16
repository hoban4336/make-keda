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