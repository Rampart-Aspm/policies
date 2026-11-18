{{/*
  The kind of a resource for the chosen scope: RiskPolicy in a namespace, ClusterRiskPolicy cluster-wide.
  Call: include "rampart-policies.kind" (dict "ctx" $ "kind" "RiskPolicy")
*/}}
{{- define "rampart-policies.kind" -}}
{{- if not (has .ctx.Values.scope (list "cluster" "namespace")) -}}
{{- fail (printf "scope must be cluster or namespace, got %q" .ctx.Values.scope) -}}
{{- end -}}
{{- if eq .ctx.Values.scope "cluster" }}Cluster{{ .kind }}{{ else }}{{ .kind }}{{ end -}}
{{- end }}

{{/*
  metadata of a resource: its name, the namespace when it has one, and the version of the set that defined it, so
  `kubectl get ... -o yaml` says which release a policy came from. Optional "extra" annotations.
  Call: include "rampart-policies.meta" (dict "ctx" $ "name" "default")
*/}}
{{- define "rampart-policies.meta" -}}
name: {{ .name }}
{{- if ne .ctx.Values.scope "cluster" }}
namespace: {{ .ctx.Values.namespace | quote }}
{{- end }}
labels:
  app.kubernetes.io/part-of: rampart
  app.kubernetes.io/managed-by: {{ .ctx.Release.Service }}
  helm.sh/chart: {{ printf "%s-%s" .ctx.Chart.Name .ctx.Chart.Version | quote }}
annotations:
  rampart.aspm.dev/policy-set-version: {{ .ctx.Chart.Version | quote }}
  {{- range $k, $v := (.extra | default dict) }}
  {{ $k }}: {{ $v | quote }}
  {{- end }}
{{- end }}
