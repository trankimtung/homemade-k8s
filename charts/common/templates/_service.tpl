{{/*
Render a single Service.

Usage:
  {{- include "common.service" (dict "ctx" . "name" "my-svc" "svc" .Values.services.foo "selectorLabels" "...") }}

Parameters:
  ctx            -- the root context (.)
  name           -- full resource name
  svc            -- service config object with fields:
    type
    ports           -- list of {name, port, [targetPort], [protocol]}
    extraLabels     (optional)
    annotations     (optional)
    loadBalancerIP  (optional)
  selectorLabels -- pre-rendered selector labels string (nindent applied internally)
*/}}
{{- define "common.service" }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ .name }}
  labels:
    {{- include "common.labels" .ctx | nindent 4 }}
    {{- with .svc.extraLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with .svc.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  type: {{ .svc.type }}
  {{- if .svc.loadBalancerIP }}
  loadBalancerIP: {{ .svc.loadBalancerIP }}
  {{- end }}
  ports:
    {{- range .svc.ports }}
    - name: {{ .name }}
      port: {{ .port }}
      targetPort: {{ .targetPort | default .name }}
      protocol: {{ .protocol | default "TCP" }}
    {{- end }}
  selector:
    {{- .selectorLabels | nindent 4 }}
{{- end }}
