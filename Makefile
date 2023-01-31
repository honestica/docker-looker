email?=nil
image=looker
license?=nil
repository?=honestica
version?=22.20

all: help

.PHONY: help
help:
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@printf '\nAvailable variables:\n'
	@grep -E '^[a-zA-Z_-]+\?=.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = "?="}; {printf "\033[36m%-20s\033[0m default: %s\n", $$1, $$2}'

.PHONY: build
build: download ## Build the given image (options: repository, image, version, email, license)
	@docker build -t $(repository)/$(image):$(shell scripts/full_version --version $(version) --email $(email) --license $(license)) --build-arg EMAIL=$(email) --build-arg LICENSE=$(license) .

.PHONY: download
download: ## Download looker jar (version, email, license)
	@scripts/download --version $(version) --email $(email) --license $(license)

.PHONY: setup
setup: ## Install local requirement to work on this image
	cd spec && bundle

.PHONY: sh
sh: ## Get a shell on given image (options: repository, image, version)
	@docker run --rm -it -v $(PWD):/srv --entrypoint /bin/bash $(repository)/$(image):$(shell scripts/full_version --version $(version) --email $(email) --license $(license))

.PHONY: test
test: ## Run tests on given image (options: repository, image, version)
	@REPOSITORY=$(repository) IMAGE=$(image) TAG=$(shell scripts/full_version --version $(version) --email $(email) --license $(license)) rspec -c spec

.PHONY: test-hadolint
test-hadolint: ## Run hadolint test
	docker run --rm -v $(PWD):/srv -w /srv hadolint/hadolint hadolint Dockerfile

.PHONY: push
push: ## Push the image to docker hub (options: repository, image, version, email, license)
	@docker push $(repository)/$(image):$(shell scripts/full_version --version $(version) --email $(email) --license $(license))
