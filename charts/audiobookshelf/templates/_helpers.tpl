{{/*
Expand the name of the chart.
*/}}
{{- define "audiobookshelf.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "audiobookshelf.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "audiobookshelf.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "audiobookshelf.labels" -}}
helm.sh/chart: {{ include "audiobookshelf.chart" . }}
{{ include "audiobookshelf.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "audiobookshelf.selectorLabels" -}}
app.kubernetes.io/name: {{ include "audiobookshelf.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Validate values
*/}}
{{- define "audiobookshelf.validate" -}}
{{- if and (gt (.Values.replicas | int) 1) (or (eq .Values.persistence.config.accessMode "ReadWriteOnce") (eq .Values.persistence.metadata.accessMode "ReadWriteOnce")) -}}
{{- fail "replicas > 1 is not supported when any persistence volume uses accessMode=ReadWriteOnce" -}}
{{- end -}}
{{- end }}
