TMP = tmp

# ───────────────────────────────────────────────────────
# 공통 Helm 설치 함수 정의 (envsubst + Helm)
# $(1): 릴리스 이름 (e.g. argocd)
# $(2): Helm 리포 이름 (e.g. argo)
# $(3): Helm 리포 URL (e.g. https://argoproj.github.io/argo-helm)
# $(4): 차트 이름 (e.g. argo/argo-cd)
# $(5): values-template.yaml 경로
# $(6): 네임스페이스
# $(7): 추가 Helm 플래그 (e.g. --version x.x.x --atomic)
# ───────────────────────────────────────────────────────
define helm_full_install
	@echo "🔧 Helm Rendering...: $(1)" && \
	mkdir -p $(TMP) && \
	$(call render_env_file,$(5),$(TMP)/tmp-override.yaml) && \
	$(call helm_apply,$(1),$(2),$(3),$(4),$(6),$(7),$(TMP)/tmp-override.yaml)
endef

define helm_apply
	echo "🚀 Helm 배포 실행: $(1)" && \
	helm repo add $(2) $(3) && \
	helm repo update && \
	helm upgrade --install $(1) $(4) \
	-n $(5) \
	--create-namespace \
	$(6) \
	-f $(7)
endef

define render_env_file
	echo "📄 .env → \${} 치환 중..." && \
	cp $(1) $(2) && \
	while IFS='=' read -r key val; do \
	  if [ -z "$$key" ] || echo "$$key" | grep -q '^#'; then continue; fi; \
	  val_escaped=$$(printf '%s\n' "$$val" | sed 's/[\/&]/\\&/g'); \
	  echo "🔁 치환: \$${$${key}} → $$val_escaped"; \
	  sed -i "s|\$${$${key}}|$$val_escaped|g" $(2); \
	done < .env
endef