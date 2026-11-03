# kalango packaging. Every package builds for openSUSE_Tumbleweed x86_64 in OBS.
# Run from the repo root with: make -C packaging <target> PKG=<name>

PKG ?=

.DEFAULT_GOAL := help
.PHONY: help new

help: ## Show this help
	@echo "usage: make -C packaging <target> PKG=<name>"
	@echo
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-8s %s\n", $$1, $$2}'

new: ## Scaffold packaging/<PKG>/ from templates/: spec plus an initial .changes entry
	@echo "$(PKG)" | grep -Eq '^[a-z0-9][a-z0-9.+-]*$$' || { echo "usage: make new PKG=<name> (lowercase, digits, . + -)"; exit 1; }
	@test ! -e "$(PKG)" || { echo "$(PKG) already exists"; exit 1; }
	mkdir "$(PKG)"
	sed 's/@NAME@/$(PKG)/g' templates/package.spec > "$(PKG)/$(PKG).spec"
	cd "$(PKG)" && osc vc -m "Initial package"
