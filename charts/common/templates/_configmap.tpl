{{/*
Render a single ConfigMap.

Usage:
  {{- include "common.configmap" (dict "ctx" . "name" "my-cm" "data" .Values.cm.config.data) }}

Parameters:
  ctx  -- the root context (.)
  name -- full resource name
  data -- map of filename -> content
*/}}
{{- define "common.configmap" }}
{{- with .data }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $.name }}
  labels:
    {{- include "common.labels" $.ctx | nindent 4 }}
data:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
