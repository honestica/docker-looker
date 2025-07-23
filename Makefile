email?=nil
image=looker
license?=nil
repository?=honestica
version?=nil

all: help

.PHONY: help
help:
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@printf '\nAvailable variables:\n'
	@grep -E '^[a-zA-Z_-]+\?=.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = "?="}; {printf "\033[36m%-20s\033[0m default: %s\n", $$1, $$2}'

.PHONY: build
build: download ## Build the given image | make build version=25.10 email=some@email.com license=ABCD [repository=honestica] [image=looker]
	@docker build -t $(repository)/$(image):$(shell scripts/full_version --version $(version) --email $(email) --license $(license)) --build-arg EMAIL=$(email) --build-arg LICENSE=$(license) docker

.PHONY: download
download: ## Download looker jar | make download version=25.10 email=some@email.com license=ABCD
	@scripts/download --version $(version) --email $(email) --license $(license)

.PHONY: setup
setup: ## Install local requirement to work on this image
	cd spec && bundle

.PHONY: sh
sh: ## Get a shell on given image | make sh version=20.20 [repository=honestica] [image=looker]
	docker volume create --name looker-test
	@docker run --rm -it --read-only -w /home/looker --mount 'type=tmpfs,dst=/tmp' -v looker-test:/home/looker:rw -v $(PWD):/srv --entrypoint /bin/bash $(repository)/$(image):$(shell scripts/full_version --version $(version) --email $(email) --license $(license))

.PHONY: test
test: ## Run tests on given image | make test version=25.10 [repository=] [image=]
	docker volume create --name looker-test
	@REPOSITORY=$(repository) IMAGE=$(image) TAG=$(shell scripts/full_version --version $(version) --email $(email) --license $(license)) rspec -c spec

.PHONY: test-hadolint
test-hadolint: ## Run hadolint test
	docker run --rm -v $(PWD):/srv -w /srv hadolint/hadolint hadolint docker/Dockerfile

.PHONY: version
version: ## Run the full version (with patch) for the minor one
	@scripts/full_version --version $(version) --email $(email) --license $(license)
