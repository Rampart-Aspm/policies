#!/usr/bin/env bash
# Renders the chart the way CI checks it: both scopes with everything on, and each SLA profile. Usage: scripts/render.sh <dir>
set -euo pipefail
out=${1:?usage: scripts/render.sh <output dir>}
here=$(cd "$(dirname "$0")/.." && pwd)
chart="$here/charts/rampart-policies"
mkdir -p "$out"
helm template t "$chart" -f "$chart/ci/cluster-all-values.yaml" > "$out/cluster.yaml"
{
  # a namespaced policy needs the tenant that owns the namespace
  printf 'apiVersion: rampart.aspm.dev/v1alpha1\nkind: Tenant\nmetadata: {name: ci}\nspec: {displayName: CI, namespaces: [rampart]}\n---\n'
  helm template t "$chart" -f "$chart/ci/namespace-all-values.yaml"
} > "$out/namespace.yaml"
# the plain, readable copies of the frameworks (rendered/cluster), as one document stream
: > "$out/plain.yaml"
for f in "$here"/rendered/cluster/*.yaml; do { cat "$f"; printf '\n---\n'; } >> "$out/plain.yaml"; done
for p in rampart pci-dss fedramp cisa-bod strictest; do
  helm template t "$chart" -f "$chart/ci/cluster-all-values.yaml" --set "slaPolicy.profile=$p" -s templates/sla-policy.yaml > "$out/sla-$p.yaml"
done
