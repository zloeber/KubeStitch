FROM alpine:3.12

# Metadata
LABEL MAINTAINER="Zachary Loeber"

# Note: Latest version of kubectl may be found at:
# https://github.com/kubernetes/kubernetes/releases
ENV KUBE_LATEST_VERSION="v1.18.2"

# Note: Latest version of helm may be found at
# https://github.com/kubernetes/helm/releases
ENV HELM_VERSION="v3.2.1"
ENV HELMFILE_VERSION="0.118.7"
ENV YQ_VERSION="3.3.0"

RUN apk add --no-cache ca-certificates bash git openssh curl \
    && wget -q https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && mkdir -p /tmp/task \
    && curl --retry 3 --retry-delay 5 --fail -sSL -o /usr/local/bin/helmfile https://github.com/roboll/.helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_linux_amd64 \
    && chmod +x /usr/local/bin/helmfile \
    && wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && curl --retry 3 --retry-delay 5 --fail -sSL -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 \
    && chmod +x /usr/local/bin/yq

RUN helm plugin install https://github.com/databus23/helm-diff --version master \
    && helm plugin install https://github.com/futuresimple/helm-secrets \
	&& helm plugin install https://github.com/aslafy-z/helm-git.git

ADD . /app
WORKDIR /app

ENV CLUSTER=cicd
ENV ENVIRONMENT=default

# Pull down repos
RUN helmfile --environment $ENVIRONMENT -f helmfiles/helmfile.cluster.$CLUSTER.yaml repos

# Run deployment
CMD helmfile --environment $ENVIRONMENT -f helmfiles/helmfile.cluster.$CLUSTER.yaml sync --concurrency 1 --skip-deps