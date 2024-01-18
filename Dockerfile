# Build stage
FROM brew.registry.redhat.io/rh-osbs/openshift-golang-builder:rhel_9_1.21@sha256:98a0ff138c536eee98704d6909699ad5d0725a20573e2c510a60ef462b45cce0 AS build-env

WORKDIR /cosign
COPY . .
USER root
RUN git config --global --add safe.directory /cosign && \
    git stash && \
    export GIT_VERSION=$(git describe --tags --always --dirty) && \
    git stash pop && \
    go mod vendor && \
    make -f Build.mak cross-platform && \
    gzip cosign-darwin-amd64 && \
    gzip cosign-darwin-arm64 && \
    gzip cosign-linux-ppc64le && \
    gzip cosign-linux-s390x && \
    gzip cosign-linux-arm64 && \
    gzip cosign-windows-amd64

# Install Cosign
#
FROM registry.access.redhat.com/ubi9/ubi-minimal@sha256:b7a3642d6245446da03d14482740be5f2fe58f30b9dfe001e89a39071a50edfc

LABEL description="Cosign is a container signing tool that leverages simple, secure, and auditable signatures based on simple primitives and best practices."
LABEL io.k8s.description="Cosign is a container signing tool that leverages simple, secure, and auditable signatures based on simple primitives and best practices."
LABEL io.k8s.display-name="Cosign container image for Red Hat Trusted Signer"
LABEL io.openshift.tags="cosign trusted-signer"
LABEL summary="Provides the cosign CLI binary for signing and verifying container images."
LABEL com.redhat.component="cosign"

COPY --from=build-env /cosign/cosign-darwin-amd64.gz /usr/local/bin/cosign-darwin-amd64.gz
COPY --from=build-env /cosign/cosign-linux-amd64 /usr/local/bin/cosign-linux-amd64
COPY --from=build-env /cosign/cosign-windows-amd64.gz /usr/local/bin/cosign-windows-amd64.gz
COPY --from=build-env /cosign/cosign-darwin-arm64.gz /usr/local/bin/cosign-darwin-arm64.gz
COPY --from=build-env /cosign/cosign-linux-arm64.gz /usr/local/bin/cosign-linux-arm64.gz
COPY --from=build-env /cosign/cosign-linux-ppc64le.gz /usr/local/bin/cosign-linux-ppc64le.gz
COPY --from=build-env /cosign/cosign-linux-s390x.gz /usr/local/bin/cosign-linux-s390x.gz

RUN mv /usr/local/bin/cosign-linux-amd64 /usr/local/bin/cosign && \
    chown root:0 /usr/local/bin/cosign-darwin-amd64.gz && chmod g+wx /usr/local/bin/cosign-darwin-amd64.gz && \
    chown root:0 /usr/local/bin/cosign && chmod g+wx /usr/local/bin/cosign && \
    chown root:0 /usr/local/bin/cosign-windows-amd64.gz && chmod g+wx /usr/local/bin/cosign-windows-amd64.gz && \

    
    chown root:0 /usr/local/bin/cosign-linux-arm64.gz && chmod g+wx /usr/local/bin/cosign-linux-arm64.gz && \
    chown root:0 /usr/local/bin/cosign-darwin-arm64.gz && chmod g+wx /usr/local/bin/cosign-darwin-arm64.gz && \
    chown root:0 /usr/local/bin/cosign-linux-ppc64le.gz && chmod g+wx /usr/local/bin/cosign-linux-ppc64le.gz && \
    chown root:0 /usr/local/bin/cosign-linux-s390x.gz && chmod g+wx /usr/local/bin/cosign-linux-s390x.gz 

#Configure home directory
ENV HOME=/home
RUN chgrp -R 0 /${HOME} && chmod -R g=u /${HOME}

WORKDIR ${HOME}

# Makes sure the container stays running
CMD ["tail", "-f", "/dev/null"]