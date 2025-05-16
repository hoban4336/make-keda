.PHONY: deploy_alb
deploy_alb: ## Install ALB Controller 민간
	kubectl --kubeconfig=$KUBE_CONFIG apply -f https://raw.githubusercontent.com/NaverCloudPlatform/nks-alb-ingress-controller/main/docs/install/pub/install.yaml

.PHONY: deploy_alb_gov_2
deploy_alb_gov_2: ## Install ALB Controller 공공
	kubectl --kubeconfig=$KUBE_CONFIG apply -f https://raw.githubusercontent.com/NaverCloudPlatform/nks-alb-ingress-controller/main/docs/install/gov-krs/install.yaml