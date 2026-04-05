{{/*
Render a PersistentVolumeClaim.

Usage:
  {{ include "common.pvc" (dict "ctx" . "name" "data" "pvc" .Values.persistence.data) }}

Parameters:
  ctx  -- the root context (.)
  name -- suffix appended to the fullname: <fullname>-<name>
  pvc  -- the persistence config object with fields:
    enabled       (bool)
    accessMode
    size
    storageClass  (optional)
    extraLabels   (optional)
    annotations   (optional)
*/}}
{{- define "common.pvc" -}}
{{- if .pvc.enabled }}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "common.fullname" .ctx }}-{{ .name }}
  labels:
    {{- include "common.labels" .ctx | nindent 4 }}
    {{- with .pvc.extraLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with .pvc.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  accessModes:
    - {{ .pvc.accessMode }}
  resources:
    requests:
      storage: {{ .pvc.size }}
  {{- if .pvc.storageClass }}
  storageClassName: {{ .pvc.storageClass }}
  {{- end }}
{{- end }}
{{- end }}
