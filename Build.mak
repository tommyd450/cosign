
GIT_VERSION ?= $(shell git describe --tags --always --dirty)

LDFLAGS=-buildid= -X sigs.k8s.io/release-utils/version.gitVersion=$(GIT_VERSION) \
        -X sigs.k8s.io/release-utils/version.gitCommit=$(GIT_HASH) \
        -X sigs.k8s.io/release-utils/version.gitTreeState=$(GIT_TREESTATE) \
        -X sigs.k8s.io/release-utils/version.buildDate=$(BUILD_DATE)

.PHONY: 
cross-platform: cosign-darwin-arm64 cosign-darwin-amd64 cosign-linux-amd64 cosign-linux-arm64 cosign-linux-ppc64le cosign-linux-s390x cosign-windows ## Build all distributable (cross-platform) binaries

.PHONY:	cosign-darwin-arm64
cosign-darwin-arm64: ## Build for mac M1
	env CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -o cosign-darwin-arm64 -trimpath -ldflags "$(LDFLAGS) -w -s" ./cmd/cosign

.PHONY: cosign-darwin-amd64
cosign-darwin-amd64:  ## Build for Darwin (macOS)
	env CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -o cosign-darwin-amd64 -trimpath -ldflags "$(LDFLAGS) -w -s" ./cmd/cosign

.PHONY: cosign-linux-amd64 
cosign-linux-amd64: ## Build for Linux amd64
	env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o cosign-linux-amd64 -trimpath -ldflags "$(LDFLAGS) -w -s" ./cmd/cosign

.PHONY: cosign-linux-arm64
cosign-linux-arm64: ## Build for Linux arm64
	env CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o cosign-linux-arm64 -trimpath -ldflags "$(LDFLAGS) -w -s" ./cmd/cosign

.PHONY: cosign-linux-ppc64le
cosign-linux-ppc64le: ## Build for Linux ppc64le
	env CGO_ENABLED=0 GOOS=linux GOARCH=ppc64le go build -o cosign-linux-ppc64le -trimpath -ldflags "$(LDFLAGS) -w -s" ./cmd/cosign

.PHONY: cosign-linux-s390x
cosign-linux-s390x:  ## Build for Linux s390x
	env CGO_ENABLED=0 GOOS=linux GOARCH=s390x go build -o cosign-linux-s390x -trimpath -ldflags "$(LDFLAGS) -w -s" ./cmd/cosign

.PHONY: cosign-windows
cosign-windows-amd64: ## Build for Windows
	env CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -o cosign-windows-amd64 -trimpath -ldflags "$(LDFLAGS) -w -s" ./cmd/cosign