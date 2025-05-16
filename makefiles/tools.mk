.PHONY: install_helm
install_helm: ## helm 설치
	@VERSION="v3.13.2" && \
	curl -LO https://get.helm.sh/helm-$${VERSION}-linux-amd64.tar.gz && \
	tar -zxvf helm-$${VERSION}-linux-amd64.tar.gz && \
	sudo mv linux-amd64/helm /usr/local/bin/helm && \
	rm -rf linux-amd64 helm-$${VERSION}-linux-amd64.tar.gz

.PHONY: install-telepresence
install-telepresence: ## Install Telepresence CLI
	@echo "🔧 Installing Telepresence to /usr/local/bin..."
	curl -fL https://app.getambassador.io/download/tel2/linux/amd64/latest/telepresence -o ./telepresence
	sudo chmod a+x ./telepresence
	sudo mv ./telepresence /usr/local/bin/
	@echo "✅ Installed Telepresence at /usr/local/bin"	