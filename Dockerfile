# Build stage
FROM registry.access.redhat.com/ubi9/go-toolset@sha256:52ab391730a63945f61d93e8c913db4cc7a96f200de909cd525e2632055d9fa6 AS build-env

WORKDIR /cosign
COPY . .
USER root
RUN git config --global --add safe.directory /cosign
RUN make cosign

# Install Cosign
FROM registry.access.redhat.com/ubi9/ubi-minimal@sha256:0dfa71a7ec2caf445e7ac6b7422ae67f3518960bd6dbf62a7b77fa7a6cfc02b1

LABEL description="Cosign is a container signing tool that leverages simple, secure, and auditable signatures based on simple primitives and best practices."
LABEL io.k8s.description="Cosign is a container signing tool that leverages simple, secure, and auditable signatures based on simple primitives and best practices."
LABEL io.k8s.display-name="Cosign container image for Red Hat Trusted Signer"
LABEL io.openshift.tags="cosign trusted-signer"
LABEL summary="Provides the cosign CLI binary for signing and verifying container images."
LABEL com.redhat.component="cosign"

COPY --from=build-env /cosign/cosign /usr/local/bin/cosign
RUN chown root:0 /usr/local/bin/cosign && chmod g+wx /usr/local/bin/cosign

#Configure home directory
ENV HOME=/home
RUN chgrp -R 0 /${HOME} && chmod -R g=u /${HOME}

WORKDIR ${HOME}

# Makes sure the container stays running
CMD ["tail", "-f", "/dev/null"]