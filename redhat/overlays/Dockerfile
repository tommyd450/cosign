# Build stage
FROM registry.access.redhat.com/ubi9/go-toolset@sha256:82d9bc5d3ceb43635288880f26207201e55d1c688a60ebbfff4f54d4963a62a1 AS build-env

WORKDIR /cosign
COPY . .
USER root
RUN git config --global --add safe.directory /cosign
RUN make cross
RUN gzip cosign-darwin-amd64
RUN gzip cosign-windows-amd64

# Install Cosign
FROM registry.access.redhat.com/ubi9/ubi-minimal@sha256:b40f52aa68b29634ff45429ee804afbaa61b33de29ae775568933c71610f07a4

LABEL description="Cosign is a container signing tool that leverages simple, secure, and auditable signatures based on simple primitives and best practices."
LABEL io.k8s.description="Cosign is a container signing tool that leverages simple, secure, and auditable signatures based on simple primitives and best practices."
LABEL io.k8s.display-name="Cosign container image for Red Hat Trusted Signer"
LABEL io.openshift.tags="cosign trusted-signer"
LABEL summary="Provides the cosign CLI binary for signing and verifying container images."
LABEL com.redhat.component="cosign"

COPY --from=build-env /cosign/cosign-darwin-amd64.gz /usr/local/bin/cosign-darwin-amd64.gz
COPY --from=build-env /cosign/cosign-linux-amd64 /usr/local/bin/cosign-linux-amd64
COPY --from=build-env /cosign/cosign-windows-amd64.gz /usr/local/bin/cosign-windows-amd64.gz
RUN mv /usr/local/bin/cosign-linux-amd64 /usr/local/bin/cosign

RUN chown root:0 /usr/local/bin/cosign-darwin-amd64.gz && chmod g+wx /usr/local/bin/cosign-darwin-amd64.gz 
RUN chown root:0 /usr/local/bin/cosign && chmod g+wx /usr/local/bin/cosign
RUN chown root:0 /usr/local/bin/cosign-windows-amd64.gz && chmod g+wx /usr/local/bin/cosign-windows-amd64.gz

#Configure home directory
ENV HOME=/home
RUN chgrp -R 0 /${HOME} && chmod -R g=u /${HOME}

WORKDIR ${HOME}

# Makes sure the container stays running
CMD ["tail", "-f", "/dev/null"]