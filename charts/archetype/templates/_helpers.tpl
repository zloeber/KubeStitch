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
{{- default (printf "%s-config" .Values.app  | trunc 54 | trimSuffix "-") | lower -}}
{{- end -}}

{{- define "service.name" -}}
{{- default (printf "%s-svc" .Values.app | trunc 54 | trimSuffix "-") | lower -}}
{{- end -}}

{{- define "spark.configmap.name" -}}
{{- default (printf "%s-configmap" .Values.app | lower | trunc 54 | trimSuffix "-") .Values.fullnameOverride -}}
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
      servicePort: {{ .Values.ports.external }}
    path: "/"
{{- end -}}

{{- define "common.container.ports" -}}
- name: www
  containerPort: {{ .Values.ports.internal }}
- name: metrics
  containerPort: {{ .Values.ports.prometheus }}
{{- end -}}

{{- define "archetype.appname" -}}
{{- .Values.app | default (include "common.name" . ) -}}
{{- end -}}

{{- define "common.service.selectors" -}}
app: {{ template "archetype.appname" . | quote }}
release: {{ .Release.Name | quote }}
{{- end -}}

{{- define "common.service.ports" -}}
- name: http
  protocol: TCP
  port: {{ .Values.ports.external }}
  targetPort: {{ .Values.ports.internal }}
- name: https
  protocol: TCP
  port: {{ .Values.ports.tls_external }}
  targetPort: {{ .Values.ports.tls_internal }}
{{- end -}}

{{- define "spark.jmxmonitoring" -}}
exposeDriverMetrics: true
exposeExecutorMetrics: true
port: {{ .Values.ports.jmx }}
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

{{- /*
archetype.zonemap returns a short name for the zone.
*/ -}}
{{- define "archetype.zonemap" -}}
{{- $zoneMap := index . 0 -}}
{{- $zone := index . 1 -}}
{{- if hasKey $zoneMap $zone }}
{{- index $zoneMap $zone -}}
{{- end }}
{{- end -}}

{{- /*
archetype.ingressclassmap returns a short name for the zone.
*/ -}}
{{- define "archetype.ingressclassmap" -}}
{{- $classMap := index . 0 -}}
{{- $zone := index . 1 -}}
{{- if hasKey $classMap $zone }}
{{- index $classMap $zone -}}
{{- end }}
{{- end -}}

{{- /*
common.ingress.certissuer prints a derived ingress certmanager annotation based on zone
*/ -}}
{{- define "archetype.certissuer" -}}
{{- $issuerMap := index . 0 -}}
{{- $zone := index . 1 -}}
{{- if hasKey $issuerMap $zone }}
{{- with (index $issuerMap $zone)}}
{{- toYaml . }}
{{- end }}
{{- end }}
{{- end -}}

{{- /*
archetype.clusterdns prints a derived dns name based on zone
*/ -}}
{{- define "archetype.clusterdns" -}}
{{- $zone := include "archetype.zonemap" (list .Values.zoneMap .Values.zone) -}}
{{- printf "%s.%s" $zone .Values.dnsZone | trimPrefix "." -}}
{{- end -}}

{{- /*
archetype.ingress.class prints a derived ingress class based on zone
*/ -}}
{{- define "archetype.ingress.class" -}}
{{- $class := include "archetype.ingressclassmap" (list .Values.ingressClassMap .Values.zone) -}}
{{- if $class -}}
kubernetes.io/ingress.class: {{ $class | quote }}
{{- end -}}
{{- end -}}

{{- define "common.fullname" -}}
{{- $base := default (printf "%s-%s" .Release.Name .Chart.Name) .Values.fullnameOverride -}}
{{- $gpre := default "" .Values.global.fullnamePrefix -}}
{{- $pre := default "" .Values.fullnamePrefix -}}
{{- $suf := default "" .Values.fullnameSuffix -}}
{{- $gsuf := default "" .Values.global.fullnameSuffix -}}
{{- $name := print $gpre $pre $base $suf $gsuf -}}
{{- $name | lower | trunc 54 | trimSuffix "-" -}}
{{- end -}}

{{- define "archetype.fullname" -}}
{{- $base := default (printf "%s-%s" .Release.Name .Chart.Name) .Values.fullnameOverride -}}
{{- $gpre := default "" .Values.global.fullnamePrefix -}}
{{- $pre := default "" .Values.fullnamePrefix -}}
{{- $suf := default "" .Values.fullnameSuffix -}}
{{- $gsuf := default "" .Values.global.fullnameSuffix -}}
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
{{- $base := default (printf "%s" .Release.Name) .Values.fullnameOverride -}}
{{- $name := print $base -}}
{{- $name | lower | trunc 54 | trimSuffix "-" -}}
{{- end -}}

{{- /*
standard labels for project deployments
*/ -}}
{{- define "common.labels" -}}
app: {{ include "archetype.appname" . | quote }}
chart: {{ template "common.chartref" . }}
heritage: {{ .Release.Service | quote }}
release: {{ .Release.Name | quote }}
zone: {{ .Values.zone | quote }}
namespace: {{ .Release.Namespace | quote }}
{{- if .Values.argocd }}
app.kubernetes.io/part-of: argocd
{{- end }}
{{- end -}}

{{- /*
Create an image pull secret string
*/ -}}
{{- define "archetype.imagePullSecret" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.dockercfg.image.pullSecret.registry (printf "%s:%s" .Values.dockercfg.image.pullSecret.username .Values.dockercfg.image.pullSecret.password | b64enc) | b64enc }}
{{- end }}