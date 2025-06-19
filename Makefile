# Load environment variables from .env file
include .env
export

# .PHONY: help
# help: ## show help message
# 	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[$$()% 0-9a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: help
help: ## show help message
	@echo "\nUsage:\n  make \033[36m<target>\033[0m\n"
	@for mf in $(MAKEFILE_LIST); do \
		case "$$mf" in \
			*Makefile|*.env) continue ;; \
		esac; \
		echo "From file: $$mf"; \
		awk ' \
			BEGIN {FS = ":.*##";} \
			/^[$$()% 0-9a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } \
			/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } \
		' $$mf; \
		echo ""; \
	done

include makefiles/*.mk