FROM argoproj/argocd:latest

ENV HELMFILE_VERSION="0.118.7"

# Switch to root for the ability to perform install
USER root

# Install tools needed for your repo-server to retrieve & decrypt secrets, render manifests 
RUN apt-get update \
    && wget -q https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && curl --retry 3 --retry-delay 5 --fail -sSL -o /usr/local/bin/helmfile https://github.com/roboll/.helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_linux_amd64 \
    && chmod +x /usr/local/bin/helmfile \
    && wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && helm plugin install https://github.com/databus23/helm-diff --version master \
    && helm plugin install https://github.com/futuresimple/helm-secrets \
	&& helm plugin install https://github.com/aslafy-z/helm-git.git

# Switch back to non-root user
USER argocd
