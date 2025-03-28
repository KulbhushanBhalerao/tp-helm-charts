{{/*
Copyright 2019 HAProxy Technologies LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "kubernetes-ingress.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "kubernetes-ingress.namespace" -}}
{{- if .Values.namespaceOverride -}}
{{- .Values.namespaceOverride -}}
{{- else -}}
{{- .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kubernetes-ingress.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kubernetes-ingress.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Encode an imagePullSecret string.
*/}}
{{- define "kubernetes-ingress.imagePullSecret" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.controller.imageCredentials.registry (printf "%s:%s" .Values.controller.imageCredentials.username .Values.controller.imageCredentials.password | b64enc) | b64enc }}
{{- end }}


{{/*
Generate default certificate for HAProxy.
*/}}
{{- define "kubernetes-ingress.gen-certs" -}}
{{- $ca := genCA "kubernetes-ingress-ca" 365 -}}
{{- $cn := printf "%s.%s" .Release.Name (include "kubernetes-ingress.namespace" .) -}}
{{- $cert := genSignedCert $cn nil nil 365 $ca -}}
tls.crt: {{ $cert.Cert | b64enc }}
tls.key: {{ $cert.Key | b64enc }}
{{- end -}}

{{/*
Create the name of the controller service account to use.
*/}}
{{- define "kubernetes-ingress.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "kubernetes-ingress.fullname" .) (tpl .Values.serviceAccount.name .) }}
{{- else -}}
    {{ default "default" (tpl .Values.serviceAccount.name .) }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the backend service account to use - only used when podsecuritypolicy is also enabled
*/}}
{{- define "kubernetes-ingress.defaultBackend.serviceAccountName" -}}
{{- if or .Values.serviceAccount.create .Values.defaultBackend.serviceAccount.create -}}
    {{ default (printf "%s-%s" (include "kubernetes-ingress.fullname" .) .Values.defaultBackend.name) .Values.defaultBackend.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.defaultBackend.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified default backend name.
*/}}
{{- define "kubernetes-ingress.defaultBackend.fullname" -}}
{{- printf "%s-%s" (include "kubernetes-ingress.fullname" .) .Values.defaultBackend.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified default cert secret name.
*/}}
{{- define "kubernetes-ingress.defaultTLSSecret.fullname" -}}
{{- printf "%s-%s" (include "kubernetes-ingress.fullname" .) "default-cert" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Construct the path for the publish-service.
By default this will use the <namespace>/<service-name> matching the controller's service name.
Users can provide an override for an explicit service they want to use via `.Values.controller.publishService.pathOverride`
*/}}
{{- define "kubernetes-ingress.publishServicePath" -}}
{{- $defServicePath := printf "%s/%s" (include "kubernetes-ingress.namespace" .) (include "kubernetes-ingress.fullname" .) -}}
{{- $servicePath := default $defServicePath .Values.controller.publishService.pathOverride }}
{{- print $servicePath | trimSuffix "-" -}}
{{- end -}}

{{/*
Construct the syslog-server annotation
*/}}
{{- define "kubernetes-ingress.syslogServer" -}}
{{- range $key, $val := .Values.controller.logging.traffic -}}
{{- printf "%s:%s, " $key $val }}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified ServiceMonitor name.
*/}}
{{- define "kubernetes-ingress.serviceMonitorName" -}}
{{- default (include "kubernetes-ingress.fullname" .) .Values.controller.serviceMonitor.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified PodMonitor name.
*/}}
{{- define "kubernetes-ingress.podMonitorName" -}}
{{- default (include "kubernetes-ingress.fullname" .) .Values.controller.podMonitor.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a FQDN for the Service metrics.
*/}}
{{- define "kubernetes-ingress.serviceMetricsName" -}}
{{- printf "%s-%s" (include "kubernetes-ingress.fullname" . | trunc 56 | trimSuffix "-") "metrics" }}
{{- end -}}

{{/*
Create a default fully qualified unique CRD job name.
*/}}
{{- define "kubernetes-ingress.crdjob.fullname" -}}
{{- printf "%s-%s-%d" (include "kubernetes-ingress.fullname" .) "crdjob" .Release.Revision | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kubernetes-ingress.image.registry" }}
  {{- .Values.global.tibco.containerRegistry.url }}
{{- end -}}

{{/* set repository based on the registry url. We will have different repo for each one. */}}
{{- define "kubernetes-ingress.image.repository" -}}
  {{- .Values.global.tibco.containerRegistry.repository }}
{{- end -}}

{{/*
Create a FQDN for the proxy pods.
*/}}
{{- define "kubernetes-ingress.serviceProxyName" -}}
{{- printf "%s-%s" (include "kubernetes-ingress.fullname" . | trunc 58 | trimSuffix "-") "proxy" }}
{{- end -}}

{{/* vim: set filetype=mustache: */}}
