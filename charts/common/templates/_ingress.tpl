{{/*
Render an Ingress resource.

Usage:
  {{- include "common.ingress" (dict "ctx" . "name" "" "portName" "http" "ingress" .Values.ingress) }}

Parameters:
  ctx      -- the root context (.)
  name     -- name suffix; empty string yields just the fullname, otherwise <fullname>-<name>
  portName -- default service port name for backend paths (can be overridden per path)
  ingress  -- ingress config object with fields:
    enabled
    className    (optional)
    extraLabels  (optional)
    annotations  (optional)
    hosts
    paths        -- list of path objects:
      path
      pathType
      portName     (optional, overrides the top-level portName)
      serviceName  (optional, suffix appended to fullname; empty defaults to ingress name)
    tls.enabled
    tls.secretName  (optional, defaults to <ingress-name>-tls)
*/}}
{{- define "common.ingress" -}}
{{- if .ingress.enabled }}
{{- $fullname := include "common.fullname" .ctx }}
{{- $name := ternary $fullname (printf "%s-%s" $fullname .name) (eq .name "") }}
{{- $defaultPortName := .portName }}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $name }}
  labels:
    {{- include "common.labels" .ctx | nindent 4 }}
    {{- with .ingress.extraLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with .ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if .ingress.className }}
  ingressClassName: {{ .ingress.className }}
  {{- end }}
  {{- if .ingress.tls.enabled }}
  tls:
    - hosts:
        {{- range .ingress.hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .ingress.tls.secretName | default (printf "%s-tls" $name) }}
  {{- end }}
  rules:
    {{- range .ingress.hosts }}
    - host: {{ . | quote }}
      http:
        paths:
          {{- range $.ingress.paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ if .serviceName }}{{ printf "%s-%s" $fullname .serviceName }}{{ else }}{{ $name }}{{ end }}
                port:
                  name: {{ .portName | default $defaultPortName }}
          {{- end }}
    {{- end }}
{{- end }}
{{- end }}
