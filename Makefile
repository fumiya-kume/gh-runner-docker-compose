COMPOSE := docker compose
FILE := docker-compose.yml
# If you set CONTAINER_NAME=..., logs/status follow it; else default
SERVICE := $(if $(CONTAINER_NAME),$(CONTAINER_NAME),github-runner)

.PHONY: run run-fg stop down logs status restart

run:
	@if ! command -v gh >/dev/null 2>&1; then \
	  echo "gh CLI not found. Install https://cli.github.com/"; exit 1; fi
	@set -eu; \
	INPUT="$(TARGET)"; [ -n "$$INPUT" ] || INPUT="$(REPO)"; \
	if [ -z "$$INPUT" ]; then echo "Error: provide TARGET=<owner/repo|url|ssh> or REPO=<...>"; exit 2; fi; \
	case "$$INPUT" in \
	  git@github.com:*) PATH_PART="$${INPUT#git@github.com:}" ;; \
	  http://github.com/*|https://github.com/*|http://www.github.com/*|https://www.github.com/*) PATH_PART="$${INPUT#*github.com/}" ;; \
	  */*) PATH_PART="$$INPUT" ;; \
	  *) echo "Error: Unsupported repo format: '$$INPUT'"; \
	     echo "Use owner/repo or https://github.com/owner/repo or git@github.com:owner/repo(.git)"; exit 2;; \
	esac; \
	PATH_PART="$${PATH_PART%.git}"; PATH_PART="$${PATH_PART%%/}"; \
	OWNER="$${PATH_PART%%/*}"; NAME="$${PATH_PART#*/}"; \
	REPO_URL="https://github.com/$${OWNER}/$${NAME}"; \
	LABEL_REPO="$$(printf '%s-%s' "$$OWNER" "$$NAME" | tr '[:upper:]' '[:lower:]')"; \
	NAME_LOWER="$$(printf '%s' "$$NAME" | tr '[:upper:]' '[:lower:]')"; \
	echo "Using repository: $$REPO_URL"; \
	GH_PAT="$$(gh auth token)" RUNNER_LABELS="self-hosted,$$LABEL_REPO,linux,x64" RUNNER_NAME_PREFIX="ghr-$$NAME_LOWER-" REPO_URL="$$REPO_URL" $(COMPOSE) -f $(FILE) up -d

run-fg:
	@if ! command -v gh >/dev/null 2>&1; then \
	  echo "gh CLI not found. Install https://cli.github.com/"; exit 1; fi
	@set -eu; \
	INPUT="$(TARGET)"; [ -n "$$INPUT" ] || INPUT="$(REPO)"; \
	if [ -z "$$INPUT" ]; then echo "Error: provide TARGET=<owner/repo|url|ssh> or REPO=<...>"; exit 2; fi; \
	case "$$INPUT" in \
	  git@github.com:*) PATH_PART="$${INPUT#git@github.com:}" ;; \
	  http://github.com/*|https://github.com/*|http://www.github.com/*|https://www.github.com/*) PATH_PART="$${INPUT#*github.com/}" ;; \
	  */*) PATH_PART="$$INPUT" ;; \
	  *) echo "Error: Unsupported repo format: '$$INPUT'"; \
	     echo "Use owner/repo or https://github.com/owner/repo or git@github.com:owner/repo(.git)"; exit 2;; \
	esac; \
	PATH_PART="$${PATH_PART%.git}"; PATH_PART="$${PATH_PART%%/}"; \
	OWNER="$${PATH_PART%%/*}"; NAME="$${PATH_PART#*/}"; \
	REPO_URL="https://github.com/$${OWNER}/$${NAME}"; \
	LABEL_REPO="$$(printf '%s-%s' "$$OWNER" "$$NAME" | tr '[:upper:]' '[:lower:]')"; \
	NAME_LOWER="$$(printf '%s' "$$NAME" | tr '[:upper:]' '[:lower:]')"; \
	echo "Using repository: $$REPO_URL"; \
	GH_PAT="$$(gh auth token)" RUNNER_LABELS="self-hosted,$$LABEL_REPO,linux,x64" RUNNER_NAME_PREFIX="ghr-$$NAME_LOWER-" REPO_URL="$$REPO_URL" $(COMPOSE) -f $(FILE) up

stop down:
	$(COMPOSE) -f $(FILE) down

logs:
	docker logs -f $(SERVICE)

status:
	docker ps --filter "name=$(SERVICE)"

restart:
	$(COMPOSE) -f $(FILE) down
	@$(MAKE) run TARGET="$(TARGET)" REPO="$(REPO)"
