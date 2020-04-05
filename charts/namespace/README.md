# helm-namespace

A generic helm3 namespace chart for use with helmfile or similar helm gluing toolsets. This is just a carry over solution for helm 3's inabilty to create namespaces for a release (likely going to change with helm 3.1). 

## Values

Pretty much just a list of namespaces to create as well as additional labels and annotations you'd like to append. You can also set if helm is allowed to delete the namespace or not. Default policy is 'keep'.

```
namespaces:
- namespace1
- namespace2
helmResourcePolicy: keep
annotations:
  certmanager.k8s.io/disable-validation: true
labels:
  additional_label1: myvalue
```
## Example - helmfile

A simple example helmfile that creates a namespace as part of a cert-manager deployment. The default helm resource policy of 'keep' is used so that the namespace will not be removed in a helm destroy operation. This means you will have to manually delete the namespace if you want to reinstall the deployment while testing things out. Default tillerless plugin options are also set if this helmfile is created with helm version 2. I only include the namespace generation in this example for brevity.

```
helmDefaults:
  tillerless: true
  tillerNamespace: platform
  atomic: false
  verify: false
  wait: true
  timeout: 1200
  recreatePods: true
  force: true

repositories:
- name: jetstack
  url: "https://charts.jetstack.io"
- name: "incubator"
  url: "https://kubernetes-charts-incubator.storage.googleapis.com"
- name: "zloeber"
  url: "git+https://github.com/zloeber/helm-namespace@chart"
releases:
###############################################################################
## CERT-MANAGER - Automatic Let's Encrypt for Ingress  ########################
##   Also provides local CA for issuing locally valid TLS certificates  #######
###############################################################################
# References:
# - https://github.com/jetstack/cert-manager/blob/v0.11.0/deploy/charts/cert-manager/values.yaml
# Instructions for installing and testing correct install are at
# - https://docs.cert-manager.io/en/release-0.9/getting-started/install/kubernetes.html
- name: namespace-cert-manager
  # Helm 3 needs to put deployment info into a namespace. As this creates a namespace it will not exist yet so we use 'kube-system' 
  #  which should exist in all clusters.
  chart: zloeber/namespace
  namespace: kube-system
  labels:
    chart: namespace-cert-manager
    component: "cert-manager"
    namespace: "cert-manager"
  values:
  - namespaces:
    - cert-manager
    annotations:
      certmanager.k8s.io/disable-validation: true
- name: "cert-manager"
  namespace: "cert-manager"
  labels:
    chart: "cert-manager"
    repo: "stable"
    component: "kiam"
    namespace: "cert-manager"
    vendor: "jetstack"
    default: "false"
  chart: jetstack/cert-manager
  version: "v0.9.0"
  wait: true
  installed: {{ env "CERT_MANAGER_INSTALLED" | default "true" }}
  hooks:
    # This hook adds the CRDs
    - events: ["presync"]
      showlogs: true
      command: "/bin/sh"
      args: ["-c", "kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml"]
  values:
    - fullnameOverride: cert-manager
      rbac:
        create: {{ env "RBAC_ENABLED" | default "true" }}
      ingressShim:
        defaultIssuerName: '{{ env "CERT_MANAGER_INGRESS_SHIM_DEFAULT_ISSUER_NAME" | default "letsencrypt-staging" }}'
        defaultIssuerKind: '{{ env "CERT_MANAGER_INGRESS_SHIM_DEFAULT_ISSUER_KIND" | default "ClusterIssuer" }}'
{{ if env "CERT_MANAGER_IAM_ROLE" | default "" }}
      podAnnotations:
        iam.amazonaws.com/role: '{{ env "CERT_MANAGER_IAM_ROLE" }}'
{{ end }}
      serviceAccount:
        create: {{ env "RBAC_ENABLED" | default "true" }}
        name: '{{ env "CERT_MANAGER_SERVICE_ACCOUNT_NAME" | default "" }}'
{{- if eq (env "MONITORING_ENABLED" | default "true") "true" }}
      prometheus:
        enabled: true
        servicemonitor:
          enabled: true
          prometheusInstance: {{ env "PROMETHEUS_INSTANCE" | default "kube-prometheus" }}
          targetPort: 9402
          path: /metrics
          interval: 60s
          scrapeTimeout: 30s
{{ end }}
      webhook:
        enabled: false
      cainjector:
        enabled: true
      resources:
        limits:
          cpu: "200m"
          memory: "256Mi"
        requests:
          cpu: "50m"
          memory: "128Mi"
- name: 'cert-manager-issuers'
  chart: "incubator/raw"
  namespace: "cert-manager"
  labels:
    component: "iam"
    namespace: "cert-manager"
    default: "true"
  wait: true
  force: true
  recreatePods: true
  installed: {{ env "CERT_MANAGER_INSTALLED" | default "true" }}
  values:
  - resources:
    - apiVersion: certmanager.k8s.io/v1alpha1
      kind: ClusterIssuer
      metadata:
        name: letsencrypt-staging
      spec:
        acme:
          server: https://acme-staging-v02.api.letsencrypt.org/directory
          email: {{ coalesce (env "SMTP_RECIPIENT") (env "CERT_MANAGER_EMAIL") (env "KUBE_LEGO_EMAIL") "user@example.com" }}
          privateKeySecretRef:
            name: letsencrypt-staging
          solvers:
            - http01:
                ingress:
                  class: nginx
{{- if env "CERT_MANAGER_IAM_ROLE" | default "" }}
            - dns01:
                route53: {}
{{- end }}
    - apiVersion: certmanager.k8s.io/v1alpha1
      kind: ClusterIssuer
      metadata:
        name: letsencrypt-prod
      spec:
        acme:
          server: https://acme-v02.api.letsencrypt.org/directory
          email: {{ coalesce (env "SMTP_RECIPIENT") (env "CERT_MANAGER_EMAIL") (env "KUBE_LEGO_EMAIL") "user@example.com" }}
          privateKeySecretRef:
            name: letsencrypt-prod
          solvers:
            - http01:
                ingress:
                  class: nginx
{{- if env "CERT_MANAGER_IAM_ROLE" | default "" }}
            - dns01:
                route53: {}
{{- end }}
```

This helmfile will require that you use the helm-git plugin

```
helm plugin install https://github.com/aslafy-z/helm-git.git
```

## Alternatives

There are some alternatives which may be better suited to your particular need. See [this thread](https://github.com/roboll/helmfile/issues/891) for more information on each of these.

### Alternative 1 - helm-namespace

I've also done some testing with the helm-namespace plugin and it works very well. Unfortunately this requires changing your helm commands and may interrupt existing workflows. This is the first alternative and honestly, probably the best one.

```
plugin install https://github.com/thomastaylor312/helm-namespace
```

### Alternative 2 - presync hooks

There are also presync helm hooks which will allow you to run kubectl commands to create the namespace if it does not exist. A helmfile would have a presync hook like the following to accomplish this task.
```
- events: ["presync"]
      showlogs: true
      command: "/bin/sh"
      args:
      - "-c"
      - >-
        kubectl get namespace "{{`{{ .Release.Namespace }}`}}" >/dev/null 2>&1 || kubectl create namespace "{{`{{ .Release.Namespace }}`}}";
```

This has the drawback of requiring 100% certainty of your kubectl context and version. It also obscures your end helm state (imho). Benefits for using this would be that your helm deployment will not puke out on you if the resource (namespace) already exists.

### Alternative 3 - raw charts

The incubator/raw helm chart is a wonderous chart that you can do so many cool things with that of course you can also create your namespaces with it if desired. Drawback is that it is pure kubernetes declarative manifest yaml (for the most part). Plus, I just wanted a small point solution for use in all my existing helm charts so I opted to not use the raw chart for this particular need.
