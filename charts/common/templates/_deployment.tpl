{{/*
Render a single Deployment.

Usage:
  {{- include "common.deployment" (dict "ctx" . "name" "my-dep" "dep" $dep "root" $root "selectorLabels" "...") }}

Parameters:
  ctx            -- the root context (.)
  name           -- full resource name
  dep            -- deployment config object
  root           -- component root (used for cm/persistence volume wiring)
  selectorLabels -- pre-rendered selector labels string
  base           -- component base name (used for cm volume names)
  isPrimary      -- bool, true when component == fullname
  comp           -- component name
  depName        -- deployment key (used to resolve cm.mountTo)
*/}}
{{- define "common.deployment" }}
{{- $ctx       := .ctx }}
{{- $dep       := .dep }}
{{- $root      := .root }}
{{- $base      := .base }}
{{- $comp      := .comp }}
{{- $isPrimary := .isPrimary }}
{{- $depName   := .depName }}
{{- $fullname  := include "common.fullname" $ctx }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .name }}
  labels:
    {{- include "common.labels" $ctx | nindent 4 }}
spec:
  replicas: {{ $dep.replicas }}
  strategy:
    {{- toYaml $dep.strategy | nindent 4 }}
  selector:
    matchLabels:
      {{- .selectorLabels | nindent 6 }}
  template:
    metadata:
      labels:
        {{- .selectorLabels | nindent 8 }}
    spec:
      securityContext:
        runAsUser: {{ $ctx.Values.global.uid }}
        runAsGroup: {{ $ctx.Values.global.gid }}
        fsGroup: {{ $ctx.Values.global.gid }}
      {{- with $dep.initContainers }}
      initContainers:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        {{- range $cName, $c := $dep.containers }}
        - name: {{ $cName }}
          image: {{ $c.image }}
          imagePullPolicy: {{ $c.imagePullPolicy }}
          {{- with $c.args }}
          {{- if $root.cm }}
          args:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- end }}
          env:
            {{- range $k, $v := merge $c.extraEnv $dep.extraEnv $c.env }}
            - name: {{ $k }}
              value: {{ $v | quote }}
            {{- end }}
          {{- $envFrom := concat $c.envFrom $dep.envFrom }}
          {{- with $envFrom }}
          envFrom:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $c.ports }}
          ports:
            {{- range $portName, $port := . }}
            - name: {{ $portName }}
              {{- toYaml $port | nindent 14 }}
            {{- end }}
          {{- end }}
          {{- with $c.securityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
            runAsUser: {{ $c.uid | default $ctx.Values.global.uid }}
            runAsGroup: {{ $c.gid | default $ctx.Values.global.gid }}
          {{- end }}
          {{- with $c.probes.startup }}
          startupProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $c.probes.liveness }}
          livenessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $c.probes.readiness }}
          readinessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          volumeMounts:
            {{- range $pvcName, $pvc := $root.persistence }}
            {{- $mountPath := index $pvc.mountTo $depName }}
            {{- if $mountPath }}
            - name: pvc-{{ $pvcName }}
              mountPath: {{ $mountPath }}
            {{- end }}
            {{- end }}
            {{- range $cmName, $cm := $root.cm }}
            {{- $mountPath := index $cm.mountTo $depName }}
            {{- if and $cm.data $mountPath }}
            - name: cm-{{ $cmName }}
              mountPath: {{ $mountPath }}
              readOnly: true
            {{- end }}
            {{- end }}
            {{- with $c.extraVolumeMounts }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
            {{- with $dep.extraVolumeMounts }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
          {{- with $c.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
        {{- end }}
      volumes:
        {{- range $pvcName, $pvc := $root.persistence }}
        - name: pvc-{{ $pvcName }}
          {{- if $pvc.existingClaim }}
          persistentVolumeClaim:
            claimName: {{ $pvc.existingClaim }}
          {{- else if $pvc.enabled }}
          {{- $suffix := ternary $pvcName (printf "%s-%s" $comp $pvcName) $isPrimary }}
          persistentVolumeClaim:
            claimName: {{ $fullname }}-{{ $suffix }}
          {{- else }}
          emptyDir: {}
          {{- end }}
        {{- end }}
        {{- range $cmName, $cm := $root.cm }}
        {{- if $cm.data }}
        {{- $cmRname := ternary $base (printf "%s-%s" $base $cmName) (eq $cmName $comp) }}
        - name: cm-{{ $cmName }}
          configMap:
            name: {{ $cmRname }}
        {{- end }}
        {{- end }}
        {{- with $dep.extraVolumes }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
{{- end }}
