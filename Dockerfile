# Build stage
FROM registry.access.redhat.com/ubi9/go-toolset@sha256:c3a9c5c7fb226f6efcec2424dd30c38f652156040b490c9eca5ac5b61d8dc3ca AS build-env

WORKDIR /cosign
COPY . .
USER root
RUN git config --global --add safe.directory /cosign && \
    git stash && \
    export GIT_VERSION=$(git describe --tags --always --dirty) && \
    git stash pop && \
    make -f Build.mak cosign-linux-amd64 && \
    make -f Build.mak cosign-darwin-amd64 && \
    make -f Build.mak cosign-windows && \
    gzip cosign-darwin-amd64 && \
    gzip cosign-windows-amd64

# Install Cosign
FROM registry.access.redhat.com/ubi9/ubi-minimal@sha256:7d1ea7ac0c6f464dac7bae6994f1658172bf6068229f40778a513bc90f47e624

LABEL description="Cosign is a container signing tool that leverages simple, secure, and auditable signatures based on simple primitives and best practices."
LABEL io.k8s.description="Cosign is a container signing tool that leverages simple, secure, and auditable signatures based on simple primitives and best practices."
LABEL io.k8s.display-name="Cosign container image for Red Hat Trusted Signer"
LABEL io.openshift.tags="cosign trusted-signer"
LABEL summary="Provides the cosign CLI binary for signing and verifying container images."
LABEL com.redhat.component="cosign"

COPY --from=build-env /cosign/cosign-darwin-amd64.gz /usr/local/bin/cosign-darwin-amd64.gz
COPY --from=build-env /cosign/cosign-linux-amd64 /usr/local/bin/cosign-linux-amd64
COPY --from=build-env /cosign/cosign-windows-amd64.gz /usr/local/bin/cosign-windows-amd64.gz

RUN mv /usr/local/bin/cosign-linux-amd64 /usr/local/bin/cosign && \
    chown root:0 /usr/local/bin/cosign-darwin-amd64.gz && chmod g+wx /usr/local/bin/cosign-darwin-amd64.gz && \
    chown root:0 /usr/local/bin/cosign && chmod g+wx /usr/local/bin/cosign && \
    chown root:0 /usr/local/bin/cosign-windows-amd64.gz && chmod g+wx /usr/local/bin/cosign-windows-amd64.gz

#Configure home directory
ENV HOME=/home
RUN chgrp -R 0 /${HOME} && chmod -R g=u /${HOME}

WORKDIR ${HOME}

# Makes sure the container stays running
CMD ["tail", "-f", "/dev/null"]