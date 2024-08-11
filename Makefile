# model explorer

SHELL := /bin/bash

ROOT  := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

DOCKER_NAME    = model-explorer
DOCKER_VERSION = 0.1

CONDA_ENV_NAME = model-explorer

APPLICATION_HOST   ?= 0.0.0.0
APPLICATION_PORT   ?= 8080
APPLICATION_FOLDER ?= /tmp/model-explorer

# -----------------------------------------------------------------------------
# run
# -----------------------------------------------------------------------------

.DEFAULT_GOAL = run

.PHONY: run
run:
	@bin/model-explorer-bootstrap

# -----------------------------------------------------------------------------
# conda environment
# -----------------------------------------------------------------------------

.PHONY: env-init
env-init:
	@conda create --yes --name $(CONDA_ENV_NAME) python=3.10.12 conda-forge::poetry=1.8.3

.PHONY: env-create
env-create:
	@conda run --no-capture-output --live-stream --name $(CONDA_ENV_NAME) poetry install --no-root --no-directory

.PHONY: env-update
env-update:
	@conda run --no-capture-output --live-stream --name $(CONDA_ENV_NAME) poetry update

.PHONY: env-remove
env-remove:
	@conda env remove --yes --name $(CONDA_ENV_NAME)

.PHONY: env-shell
env-shell:
	@conda run --no-capture-output --live-stream --name $(CONDA_ENV_NAME) bash

.PHONY: env-info
env-info:
	@conda run --no-capture-output --live-stream --name $(CONDA_ENV_NAME) conda info

.PHONY: env-list
env-list:
	@conda run --no-capture-output --live-stream --name $(CONDA_ENV_NAME) conda list

# -----------------------------------------------------------------------------
# docker
# -----------------------------------------------------------------------------

.PHONY: docker-prune
docker-prune:
	@docker image prune --force

.PHONY: docker-build
docker-build: docker-prune
	@docker build \
		--progress=plain \
		-t ${DOCKER_NAME}:${DOCKER_VERSION} \
		.

.PHONY: docker-pull
docker-pull:
	@docker pull ${DOCKER_NAME}:${DOCKER_VERSION}

.PHONY: docker-push
docker-push:
	@docker push ${DOCKER_NAME}:${DOCKER_VERSION}

.PHONY: docker-deploy
docker-deploy: docker-build docker-push

.PHONY: docker-shell
docker-shell:
	@docker run \
		--name "model-explorer" \
		--hostname="model-explorer" \
		--read-only \
		--rm \
		--interactive \
		--tty \
		${DOCKER_NAME}:${DOCKER_VERSION}

.PHONY: docker-run
docker-run:
	@echo "Open browser at http://localhost:$(APPLICATION_PORT)/"
	@echo "Directory: $(APPLICATION_FOLDER)"
	@mkdir -p "$(APPLICATION_FOLDER)"
	@docker run \
		--name "model-explorer" \
		--hostname="model-explorer" \
		--read-only \
		--rm \
		--interactive \
		--tty \
		--env "TF_ENABLE_ONEDNN_OPTS=0" \
		--volume "$(APPLICATION_FOLDER):/tmp/tensorboard" \
		--publish "$(APPLICATION_HOST):$(APPLICATION_PORT):8080/tcp" \
		${DOCKER_NAME}:${DOCKER_VERSION} \
			/opt/model-explorer/bin/model-explorer-bootstrap \
				--host=0.0.0.0 \
				--port=8080 \
				--no_open_in_browser
