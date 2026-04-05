{{/*
Component-scoped resource templates.

All templates take (dict "ctx" . "name" "<component>" "root" .Values.<component>).

  name  -- component key; when it equals the chart fullname the component is
           considered "primary" and owns the root namespace (no name suffix on
           resources, no extra label needed to distinguish from a second component).

Resource naming within a component:
  base     = fullname          (primary)   or  fullname-component  (secondary)
  rname    = base              when key == componentName
           = base-key          otherwise

Selector label: app.kubernetes.io/component: <name> is always added so that
two components' Deployments / Services never cross-select each other's pods.
*/}}

{{/*─────────────────────────── ConfigMaps ───────────────────────────────────*/}}
{{- define "common.componentConfigmaps" -}}
{{- $ctx  := .ctx }}
{{- $comp := .name }}
{{- $root := .root }}
{{- $base := include "common.componentBase" (dict "ctx" $ctx "component" $comp) }}
{{- range $name, $cm := $root.cm }}
{{- $rname := ternary $base (printf "%s-%s" $base $name) (eq $name $comp) }}
{{- include "common.configmap" (dict "ctx" $ctx "name" $rname "data" $cm.data) }}
{{- end }}
{{- end }}

{{/*─────────────────────────── PVCs ─────────────────────────────────────────*/}}
{{- define "common.componentPvcs" -}}
{{- $ctx       := .ctx }}
{{- $comp      := .name }}
{{- $root      := .root }}
{{- $fullname  := include "common.fullname" $ctx }}
{{- $isPrimary := eq $comp $fullname }}
{{- range $name, $pvc := $root.persistence }}
{{- if not $pvc.existingClaim }}
{{- $suffix := ternary $name (printf "%s-%s" $comp $name) $isPrimary }}
{{ include "common.pvc" (dict "ctx" $ctx "name" $suffix "pvc" $pvc) }}
{{- end }}
{{- end }}
{{- end }}

{{/*─────────────────────────── Services ─────────────────────────────────────*/}}
{{- define "common.componentServices" -}}
{{- $ctx      := .ctx }}
{{- $comp     := .name }}
{{- $root     := .root }}
{{- $base     := include "common.componentBase" (dict "ctx" $ctx "component" $comp) }}
{{- $selLabels := include "common.componentSelectorLabels" (dict "ctx" $ctx "component" $comp) }}
{{- range $name, $svc := $root.services }}
{{- $rname := ternary $base (printf "%s-%s" $base $name) (eq $name $comp) }}
{{- include "common.service" (dict "ctx" $ctx "name" $rname "svc" $svc "selectorLabels" $selLabels) }}
{{- end }}
{{- end }}

{{/*─────────────────────────── Ingresses ────────────────────────────────────*/}}
{{- define "common.componentIngresses" -}}
{{- $ctx      := .ctx }}
{{- $comp     := .name }}
{{- $root     := .root }}
{{- $fullname := include "common.fullname" $ctx }}
{{- $base     := include "common.componentBase" (dict "ctx" $ctx "component" $comp) }}
{{- range $name, $ingress := $root.ingresses }}
{{- $rname := ternary $base (printf "%s-%s" $base $name) (eq $name $comp) }}
{{- $param := ternary "" (trimPrefix (printf "%s-" $fullname) $rname) (eq $rname $fullname) }}
{{- include "common.ingress" (dict "ctx" $ctx "name" $param "portName" $ingress.portName "ingress" $ingress) }}
{{- end }}
{{- end }}

{{/*─────────────────────────── Deployments ──────────────────────────────────*/}}
{{- define "common.componentDeployments" -}}
{{- $ctx       := .ctx }}
{{- $comp      := .name }}
{{- $root      := .root }}
{{- $fullname  := include "common.fullname" $ctx }}
{{- $base      := include "common.componentBase" (dict "ctx" $ctx "component" $comp) }}
{{- $isPrimary := eq $comp $fullname }}
{{- $selLabels := include "common.componentSelectorLabels" (dict "ctx" $ctx "component" $comp) }}
{{- range $deployName, $dep := $root.deployments }}
{{- $rname := ternary $base (printf "%s-%s" $base $deployName) (eq $deployName $comp) }}
{{- include "common.deployment" (dict "ctx" $ctx "name" $rname "dep" $dep "root" $root "selectorLabels" $selLabels "base" $base "comp" $comp "isPrimary" $isPrimary "depName" $deployName) }}
{{- end }}
{{- end }}

{{/*─────────────────────────── Composite ────────────────────────────────────*/}}

{{/*
Render all resources (configmaps, pvcs, services, ingresses, deployments)
for a single named component.

Usage:
  {{- include "common.component" (dict "ctx" . "name" "mycomp" "root" .Values.mycomp) }}
*/}}
{{- define "common.component" -}}
{{- include "common.componentConfigmaps"  . }}
{{- include "common.componentPvcs"        . }}
{{- include "common.componentServices"    . }}
{{- include "common.componentIngresses"   . }}
{{- include "common.componentDeployments" . }}
{{- end }}

{{/*
Render all resources for every component in a map.

Usage:
  {{- include "common.components" (dict "ctx" . "components" (dict "app" .Values.app "sidecar" .Values.sidecar)) }}
*/}}
{{- define "common.components" -}}
{{- $ctx := .ctx }}
{{- range $name, $root := .components }}
{{- include "common.component" (dict "ctx" $ctx "name" $name "root" $root) }}
{{- end }}
{{- end }}
