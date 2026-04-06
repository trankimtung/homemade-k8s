{{/*
Validate values
*/}}
{{- define "audiobookshelf.validate" -}}
{{- range $compName, $comp := .Values.components }}
{{- range $depName, $dep := $comp.deployments }}
{{- range $pvcName, $pvc := $comp.persistence }}
{{- if and (gt ($dep.replicas | int) 1) $pvc.enabled (eq $pvc.accessMode "ReadWriteOnce") -}}
{{- fail (printf "components.%s.deployments.%s: replicas > 1 is not supported with persistence.%s.accessMode=ReadWriteOnce" $compName $depName $pvcName) -}}
{{- end -}}
{{- if and (eq $dep.strategy.type "RollingUpdate") $pvc.enabled (eq $pvc.accessMode "ReadWriteOnce") -}}
{{- fail (printf "components.%s.deployments.%s: strategy.type=RollingUpdate is not supported with persistence.%s.accessMode=ReadWriteOnce" $compName $depName $pvcName) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end }}
