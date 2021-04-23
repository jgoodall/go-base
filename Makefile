-include .env

GIT_MAIN_BRANCH := main

GOBUILD  := $(GO) build
GOARCH   := amd64
MAIN_DIR := ./cmd
BIN_DIR  := ./bin
GOFILES  := $(shell find . -name "*.go")
PROJECT  := $(shell basename "$(PWD)")

# These are injected into the build.
BUILD_TIME := $(shell date "+%s")
GO_VERSION := $(shell go version | cut -d' ' -f3)
# Git version and sha are set using GitLab CI variables or on CLI.
VERSION := ${CI_COMMIT_TAG}
ifeq ($(VERSION),)
VERSION := $(shell git describe ${GIT_MAIN_BRANCH} --tags --abbrev=0)
endif
GIT_SHA := ${CI_COMMIT_SHORT_SHA}
ifeq ($(GIT_SHA),)
GIT_SHA := $(shell git rev-parse --short HEAD)
endif

# Use linker flags to provide version/build settings.
LDFLAGS=-ldflags "-X=main.Version=$(VERSION) -X=main.GitSHA=$(GIT_SHA) -X main.BuildTime=$(BUILD_TIME) -X main.GoVersion=$(GO_VERSION)"


## `make`: By default, build binaries for all platforms.
.PHONY: default
default: all

## `make all`: Build binaries for all platforms.
.PHONY: all
all: darwin linux

.PHONY: darwin linux
## `make darwin`: Compile binary for darwin.
darwin: vet lint $(BIN_DIR)/$(PROJECT)-darwin-$(GOARCH)
## `make linux`: Compile binary for linux.
linux: vet lint $(BIN_DIR)/$(PROJECT)-linux-$(GOARCH)


## `make vet`: Run go vet to see if there are any issues.
.PHONY: vet
vet:
	$(info >  Checking if there are issues reported by go vet...)
	@$(GO) vet -composites=false ./...

## `make lint`: Run golangci-lint to see if there are any issues.
# https://github.com/golangci/golangci-lint
.PHONY: lint
lint:
ifneq (, $(shell which golangci-lint))
	$(info >  Checking if there are issues reported by golangci-lint...)
	@golangci-lint run
else
	$(error >  golangci-lint is not installed, unable to check.)
endif

## `make test`: Run unit test to identify simple issues.
.PHONY: test
test:
	$(info >  Running unit tests...)
	@$(GO) test -v -short ./...

## `make outdated`: Check dependencies to see if there are any outdated.
.PHONY: outdated
outdated:
	$(info >  Checking if there is any outdated dependencies...)
	@$(GO) list -u -m -f '{{if not .Indirect}}{{if .Update}}{{.}}{{end}}{{end}}' all 2> /dev/null

## `make clean`: Clean build files. Runs `go clean` internally.
.PHONY: clean
clean:
	$(info >  Removing binaries...)
	@-rm -rf $(BIN_DIR)

.PHONY: help
help: Makefile
	@echo
	@echo " Choose a command run in "$(PROJECT)":"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo

# Build for Darwin/Linux.
$(BIN_DIR)/$(PROJECT)-%-$(GOARCH): $(GOFILES)
	$(info >  Building binary for $*...)
	CGO_ENABLED=0 GOOS=$* GOARCH=$(GOARCH) $(GOBUILD) $(LDFLAGS) -o $(BIN_DIR)/$(PROJECT)-$*-$(GOARCH) $(MAIN_DIR)
