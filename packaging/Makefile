# kalango packaging. Every package builds for openSUSE_Tumbleweed x86_64 in OBS.
# Run inside packaging/: make <target> PKG=<name>  (from the repo root: make -C packaging ...)

PROJECT := home:go-nick:kalango
PKG ?=

# Stops unless PKG names an existing package folder
define need-pkg
	@test -n "$(PKG)" || { echo "usage: make $@ PKG=<name>"; exit 1; }
	@test -f "$(PKG)/$(PKG).spec" || { echo "no package $(PKG): $(PKG)/$(PKG).spec not found"; exit 1; }
endef

.DEFAULT_GOAL := help
.PHONY: help new build changes

help: ## Show this help
	@echo "usage: make <target> PKG=<name>  (inside packaging/; from the repo root: make -C packaging ...)"
	@echo
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-9s %s\n", $$1, $$2}'

new: ## Scaffold packaging/<PKG>/ from templates/: spec plus an initial .changes entry
	@echo "$(PKG)" | grep -Eq '^[a-z0-9][a-z0-9.+-]*$$' || { echo "usage: make new PKG=<name> (lowercase, digits, . + -)"; exit 1; }
	@test ! -e "$(PKG)" || { echo "$(PKG) already exists"; exit 1; }
	mkdir "$(PKG)"
	sed 's/@NAME@/$(PKG)/g' templates/package.spec > "$(PKG)/$(PKG).spec"
	cd "$(PKG)" && osc vc -m "Initial package"

build: ## Build <PKG> locally in the same clean environment as OBS (asks the root password)
	$(need-pkg)
	cd "$(PKG)" && osc build --alternative-project=$(PROJECT) openSUSE_Tumbleweed x86_64 "$(PKG).spec"

changes: ## Add an entry to <PKG>.changes: make changes PKG=<name> MSG="what changed"
	$(need-pkg)
	@test -n "$(MSG)" || { echo 'usage: make changes PKG=<name> MSG="what changed"'; exit 1; }
	cd "$(PKG)" && osc vc -m "$(MSG)"
