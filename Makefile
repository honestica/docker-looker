email?=nil
image=looker
license?=nil
repository?=honestica
tag?=latest

all: help

.PHONY: help
help:
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@printf '\nAvailable variables:\n'
	@grep -E '^[a-zA-Z_-]+\?=.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = "?="}; {printf "\033[36m%-20s\033[0m default: %s\n", $$1, $$2}'

.PHONY: build
build: ## Build the given image (options: repository, image, tag, email, license)
	@docker build -t $(repository)/$(image):$(tag) --build-arg EMAIL=$(email) --build-arg LICENSE=$(license) .

.PHONY: setup
setup: ## Install local requirement to work on this image
	cd spec && bundle

.PHONY: sh
sh: ## Get a shell on given image (options: repository, image, tag)
	docker run --rm -it --entrypoint /bin/bash $(repository)/$(image):$(tag)

.PHONY: test
test: ## Run tests on given image (options: repository, image, tag)
	REPOSITORY=$(repository) IMAGE=$(image) TAG=$(tag) rspec -c spec

.PHONY: test-hadolint
test-hadolint: ## Run hadolint test
	docker run --rm -v $(PWD):/srv -w /srv hadolint/hadolint hadolint Dockerfile
