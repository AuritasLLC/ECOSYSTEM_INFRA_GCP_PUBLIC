{{/* Build collision-safe resource names from the Marketplace deployment name. */}}
{{- define "ecosystem.resourceName" -}}
{{- $root := index . 0 -}}
{{- $component := index . 1 -}}
{{- $maxBaseLength := sub 62 (len $component) | int -}}
{{- $base := trunc $maxBaseLength $root.Release.Name | trimSuffix "-" -}}
{{- printf "%s-%s" $base $component | trunc 63 | trimSuffix "-" -}}
{{- end -}}
