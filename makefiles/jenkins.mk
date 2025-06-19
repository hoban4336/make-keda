NAMESPACE = jenkins

.PHONY: deploy_jenkins
deploy_jenkins: ## jenkins 설치
	@helm repo add jenkinsci https://charts.jenkins.io && \
	helm repo update && \
	helm upgrade --install jenkins jenkinsci/jenkins \
	-n $(NAMESPACE) \
	--create-namespace \
	-f jenkins/value-override.yaml