APP := build/StickyNote.app

.PHONY: help build run test format lint app open install clean

help: ## Show available commands
	@grep -E '^[a-z]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-8s %s\n", $$1, $$2}'

build: ## Compile a debug build
	swift build

run: ## Build and run from the terminal (logs appear here)
	swift run StickyNote

test: ## Run the unit tests
	swift test

format: ## Reformat all Swift code
	swift format --in-place --recursive Package.swift Sources Tests

lint: ## Check formatting without changing files
	swift format lint --strict --recursive Package.swift Sources Tests

app: ## Build build/StickyNote.app
	./scripts/build-app.sh

open: app ## Build and launch the app
	open $(APP)

install: app ## Copy the app into /Applications
	rm -rf /Applications/StickyNote.app
	cp -R $(APP) /Applications/

clean: ## Remove all build output
	swift package clean
	rm -rf build
