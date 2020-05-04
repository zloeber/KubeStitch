{{/* vim: set filetype=mustache: */}}

{{- define "common.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Fullname of configMap/secret that contains environment variables
*/}}
{{- define "common.env.fullname" -}}
{{- $root := index . 0 -}}
{{- $postfix := index . 1 -}}
{{- printf "%s-%s-%s" (include "common.fullname" $root) "env" $postfix -}}
{{- end -}}

{{/*
Fullname of configMap/secret that contains files
*/}}
{{- define "common.files.fullname" -}}
{{- $root := index . 0 -}}
{{- $postfix := index . 1 -}}
{{- printf "%s-%s-%s" (include "common.fullname" $root) "files" $postfix -}}
{{- end -}}

{{- define "configmap.name" -}}
{{- default (printf "%s-config" .Values.project.app  | trunc 54 | trimSuffix "-") | lower -}}
{{- end -}}

{{- define "service.name" -}}
{{- default (printf "%s-svc" .Values.project.app | trunc 54 | trimSuffix "-") | lower -}}
{{- end -}}

{{- define "spark.configmap.name" -}}
{{- default (printf "%s-configmap" .Values.project.app | lower | trunc 54 | trimSuffix "-") .Values.fullnameOverride -}}
{{- end -}}

{{/*
Environment template block for deployable resources
*/}}
{{- define "common.env" -}}
{{- $root := . -}}
{{- if or ($root.Values.configMaps $root.Values.secrets) }}
envFrom:
{{- range $name, $config := $root.Values.configMaps -}}
{{- if $config.enabled }}
{{- if not ( empty $config.env ) }}
- configMapRef:
    name: {{ include "common.env.fullname" (list $root $name) }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- range $name, $secret := $root.Values.secrets -}}
{{- if $secret.enabled }}
{{- if not ( empty $secret.env ) }}
- secretRef:
    name: {{ include "common.env.fullname" (list $root $name) }}-env
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{/*
Volumes template block for deployable resources
*/}}
{{- define "common.files.volumes" -}}
{{- $root := . -}}
{{- $config := $root.Values.configMaps -}}
{{- if $config.enabled }}
{{- if not ( empty $config.files ) }}
- name: config-files
  configMap:
    name: {{ include "common.shortname" $root }}
{{- end }}
{{- end }}

{{- range $name, $secret := $root.Values.secrets -}}
{{- if $secret.enabled }}
{{- if not ( empty $secret.files ) }}
- name: secret-{{ $name }}-files
  secret:
    secretName: {{ include "common.files.fullname" (list $root $name) }}
{{- end }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
VolumeMounts template block for deployable resources
*/}}
{{- define "common.files.volumeMounts" -}}
{{- range $name, $config := .Values.configMaps -}}
{{- if $config.enabled }}
{{- if not ( empty $config.files ) }}
- mountPath: {{ default (printf "/%s" $name) $config.mountPath }}
  name: config-{{ $name }}-files
{{- end }}
{{- end }}
{{- end -}}
{{- range $name, $secret := .Values.secrets -}}
{{- if $secret.enabled }}
{{- if not ( empty $secret.files ) }}
- mountPath: {{ default (printf "/%s" $name) $secret.mountPath }}
  name: secret-{{ $name }}-files
  readOnly: true
{{- end }}
{{- end }}
{{- end -}}
{{- end -}}

{{- define "common.ingress.service" -}}
http:
  paths:
  - backend:
      serviceName: {{ include "common.fullname" . }}
      servicePort: {{ .Values.ports.default.external }}
    path: "/"
{{- end -}}

{{- define "common.container.ports" -}}
- name: www
  containerPort: {{ .Values.ports.default.internal }}
- name: metrics
  containerPort: {{ .Values.ports.default.prometheus }}
{{- end -}}

{{- define "common.service.selectors" -}}
{{- $project := .Values.project -}}
app: {{ $project.app | default (include "common.name" . ) | quote }}
release: {{ .Release.Name | quote }}
stage: {{ $project.stage | default "unknown" | quote }}
{{- end -}}

{{- define "common.service.ports" -}}
- name: http
  protocol: TCP
  port: {{ .Values.ports.default.external }}
  targetPort: {{ .Values.ports.default.internal }}
- name: https
  protocol: TCP
  port: {{ .Values.ports.default.tls_external }}
  targetPort: {{ .Values.ports.default.tls_internal }}
{{- end -}}

{{- define "spark.jmxmonitoring" -}}
exposeDriverMetrics: true
exposeExecutorMetrics: true
port: {{ .Values.ports.default.jmx }}
prometheus:
  jmxExporterJar: "/prometheus/jmx_prometheus_javaagent-0.11.0.jar"
{{- end -}}

{{- define "spark.configmap" -}}
volumeMounts:
- name: config-vol
  mountPath: /opt/spark
{{- end -}}

{{- define "common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- /*
common.chartref prints a chart name and version.
It does minimal escaping for use in Kubernetes labels.

Example output:
  zookeeper-1.2.3
  wordpress-3.2.1_20170219

*/ -}}
{{- define "common.chartref" -}}
{{- replace "+" "_" .Chart.Version | printf "%s-%s" .Chart.Name -}}
{{- end -}}

{{- define "common.fullname" -}}
{{- $global := default (dict) .Values.global -}}
{{- $base := default (printf "%s-%s" .Release.Name .Chart.Name) .Values.fullnameOverride -}}
{{- $gpre := default "" $global.fullnamePrefix -}}
{{- $pre := default "" .Values.fullnamePrefix -}}
{{- $suf := default "" .Values.fullnameSuffix -}}
{{- $gsuf := default "" $global.fullnameSuffix -}}
{{- $name := print $gpre $pre $base $suf $gsuf -}}
{{- $name | lower | trunc 54 | trimSuffix "-" -}}
{{- end -}}

{{- /*
common.fullname.unique adds a random suffix to the unique name.
This takes the same parameters as common.fullname
*/ -}}
{{- define "common.fullname.unique" -}}
{{ template "common.fullname" . }}-{{ randAlphaNum 7 | lower }}
{{- end }}

{{- define "common.shortname" -}}
{{- $global := default (dict) .Values.global -}}
{{- $base := default (printf "%s" .Release.Name) .Values.fullnameOverride -}}
{{- $name := print $base -}}
{{- $name | lower | trunc 54 | trimSuffix "-" -}}
{{- end -}}

{{- define "ingress.int.annotations" -}}
{{- $project := .Values.project -}}
ingress.kubernetes.io/rewrite-target: "/"
nginx.ingress.kubernetes.io/ssl-redirect: "{{ .Values.enableSSLRedirect }}"
certmanager.k8s.io/cluster-issuer: "{{ .Values.internalCertIssuer }}"
prometheus.io/scrape: {{ .Values.enablePrometheusScrape | default "false" | quote }}
prometheus.io/port: {{ .Values.ports.default.prometheus | default "5555" | quote }}
service.beta.kubernetes.io/azure-load-balancer-internal: {{ .Values.enableInternalIngress | default "true" | quote }}
forecastle.stakater.com/expose: {{ .Values.ingress.forecastle | default "false" | quote }}
{{- end -}}

{{- define "ingress.ext.annotations" -}}
{{- $project := .Values.project -}}
ingress.kubernetes.io/rewrite-target: "/"
certmanager.k8s.io/cluster-issuer: "{{ .Values.externalCertIssuer }}"
{{- end -}}

{{- /*
standard labels for project deployments
*/ -}}
{{- define "common.labels" -}}
{{- $project := .Values.project -}}
{{- $clusterdns :=  printf "%s.%s.%s" .Values.project.team .Values.project.target .Values.dnsZone -}}
app: {{ $project.app | default (include "common.name" . ) | quote }}
chart: {{ template "common.chartref" . }}
heritage: {{ .Release.Service | quote }}
release: {{ .Release.Name | quote }}
stage: {{ $project.stage | default "unknown" | quote }}
target: {{ $project.target | default "unknown" | quote }}
zone: {{ $clusterdns | quote }}
namespace: "{{ .Release.Namespace }}"
{{- end -}}
