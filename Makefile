# Makefile for NeoAi

.PHONY: all build clean test jupyter-build jupyter-start jupyter-stop jupyter-clean vscode-build vscode-clean vscode-test nvim-build nvim-clean intellij-build intellij-clean

# Default target
all: build

# Main targets
build: vscode-build nvim-build intellij-build jupyter-build
	@echo "All components built successfully."

clean: vscode-clean nvim-clean intellij-clean jupyter-clean
	@echo "All components cleaned."

test: vscode-test
	@echo "All tests passed."

# Jupyter Extension
jupyter-build:
	@echo "Building Jupyter NeoAi Docker image..."
	@cd jupyter && bash build-image.sh

jupyter-start:
	@echo "Starting Jupyter NeoAi server..."
	@cd jupyter && bash start-server.sh

jupyter-stop:
	@echo "Stopping Jupyter NeoAi server..."
	@cd jupyter && bash stop-server.sh

jupyter-clean:
	@echo "Cleaning up Jupyter NeoAi Docker image..."
	@docker rmi neoai-server:latest || true
	@echo "Jupyter NeoAi Docker image cleaned."

# VSCode Extension
vscode-build:
	@echo "Building VSCode extension..."
	@cd vscode && npm install && npm run build

vscode-clean:
	@echo "Cleaning VSCode extension..."
	@cd vscode && npm run clean

vscode-test:
	@echo "Running VSCode extension tests..."
	@cd vscode && npm test

# Neovim Plugin
nvim-build:
	@echo "Building Neovim plugin..."
	@cd nvim/chat && cargo build --release

nvim-clean:
	@echo "Cleaning Neovim plugin..."
	@cd nvim/chat && cargo clean

# IntelliJ Plugin
intellij-build:
	@echo "Building IntelliJ plugin..."
	@cd intellij && ./gradlew build

intellij-clean:
	@echo "Cleaning IntelliJ plugin..."
	@cd intellij && ./gradlew clean