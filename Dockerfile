FROM cloudposse/packages:latest AS packages

FROM alpine:3.11

# Metadata
LABEL MAINTAINER="Zachary Loeber"

# Note: Latest version of kubectl may be found at:
# https://github.com/kubernetes/kubernetes/releases
ENV KUBE_LATEST_VERSION="v1.18.2"
#ENV GO_TASK_VERSION="2.8.1"

# Note: Latest version of helm may be found at
# https://github.com/kubernetes/helm/releases
ENV HELM_VERSION="v3.2.1"

RUN apk add --no-cache ca-certificates bash git openssh curl \
    && wget -q https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && mkdir -p /tmp/task \
    # && curl --retry 3 --retry-delay 5 --fail -sSL -o - https://github.com/go-task/task/releases/download/v${GO_TASK_VERSION}/task_linux_amd64.tar.gz | tar -zx -C  '/tmp/task' \
    # && find /tmp/task -type f -name 'task*' | xargs -I {} cp -f {} /usr/local/bin/task \
    # && chmod +x /usr/local/bin/task \
    && wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm

COPY --from=packages /packages/bin/helmfile /usr/local/bin/

RUN helm plugin install https://github.com/databus23/helm-diff --version master \
    && helm plugin install https://github.com/futuresimple/helm-secrets \
	&& helm plugin install https://github.com/aslafy-z/helm-git.git

ENV CLUSTER=cicd
ENV ENVIRONMENT=default
ENV APP_PATH=/app
ADD . ${APP_PATH}
WORKDIR ${APP_PATH}

# Pull down repos
RUN helmfile --environment $ENVIRONMENT -f helmfiles/helmfile.cluster.$CLUSTER.yaml repos

# Run deployment
CMD helmfile --environment $ENVIRONMENT -f helmfiles/helmfile.cluster.$CLUSTER.yaml charts