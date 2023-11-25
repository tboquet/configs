# Makefile for setting up a generic development environment with Docker, Git, and Go

# Variables
DATE ?= $(shell git status --porcelain | grep -q . && date +%s || echo clean)
REVISION ?= $(shell git rev-parse --short=7 HEAD)
VERSION ?= $(subst /,_,$(shell git symbolic-ref --short HEAD))
DOCKER_TAG ?= $(VERSION)-$(REVISION)
PROJECT_NAME ?= generic-project
REGION ?= us-central1
TEST_ARGS ?=
CMD ?=
DEVICE ?= cpu
REPO ?= $(shell basename `git rev-parse --show-toplevel`)
TAG ?= final-$(DEVICE)-$(DOCKER_TAG)
IMAGE_LOCAL ?= $(REPO):$(TAG)
IMAGE_PATH_CLOUD ?= $(REGION)-docker.pkg.dev/$(PROJECT_NAME)/docker-registry
IMAGE_CLOUD ?= $(IMAGE_PATH_CLOUD)/$(IMAGE_LOCAL)

# Docker build helper macro
define docker_build
	BUILD_VARS=""; \
	if [ -n "$$BUILD_ARGS" ]; then \
		for build_arg in $$BUILD_ARGS; do \
			BUILD_VARS="$$BUILD_VARS --build-arg $$build_arg"; \
		done; \
	fi; \
	docker build --file Dockerfile.$(DEVICE) --build-arg USERNAME=$(shell whoami) $$BUILD_VARS --target $(1) -t $(IMAGE_LOCAL) . ;
endef

# Docker run helper macro
define docker_run
	docker rm $(1)-$(DOCKER_TAG) || true
	VOLUME_ARGS="$(HOME)/.emacs:/home/$(shell whoami)/.emacs"; \
	if [ -n "$$VOLUMES" ]; then \
		for vol in $$VOLUMES; do \
			VOLUME_ARGS="$$VOLUME_ARGS -v $$vol"; \
		done; \
	fi; \
	ENV_ARGS=""; \
	if [ -n "$$ENV_VARS" ]; then \
		for env_var in $$ENV_VARS; do \
			ENV_ARGS="$$ENV_ARGS -e $$env_var"; \
		done; \
	fi; \
	echo "Running container $(1)-$(DOCKER_TAG) with volumes $$VOLUME_ARGS and environment variables $$ENV_ARGS"; \
	docker run -it --name=$(1)-$(DOCKER_TAG) $(VOLUME_ARGS) $(ENV_ARGS) $(IMAGE_LOCAL) $(2);
endef

# Help
help:	## Display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

# Install Docker, Git, and Go on macOS
install: ## Install Docker, Git, and Go on macOS
	@echo "Setting up development tools on macOS..."
	@which brew >/dev/null || /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	@brew update
	@brew install git go
	@brew install --cask docker
	@brew install --cask xquartz
	@echo "Installation complete. Docker, Git, and Go are now installed."

# Build Spacemacs Docker image
build-spacemacs: ## Build Spacemacs Docker image
	@$(call docker_build,development)

# Run Spacemacs Docker container
run-spacemacs: ## Run Spacemacs Docker container
	@$(call docker_run,spacemacs_container,)

# Run Spacemacs Docker container with X11 forwarding
run-spacemacs-x11: ## Run Spacemacs Docker container with X11 forwarding
	open -a XQuartz
	sleep 2
	DISPLAY=:2 /opt/X11/bin/xhost +localhost || true
	sleep 2
	$(call docker_run,spacemacs_container_x11,bash)
