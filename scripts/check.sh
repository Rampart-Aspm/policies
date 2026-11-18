#!/usr/bin/env bash
# Checks the chart against the real Rampart code: the server's own apply library accepts every document, the risk policy
# is the built-in one, and no SLA profile is silently capped. Usage: scripts/check.sh <path to a Rampart checkout>
# It copies one test file into the checkout while it runs and removes it afterwards. It never touches a database: the
# `rampart apply` run below has the database variables unset, so it applies into memory. UPDATE_GOLDEN=1 rewrites
# docs/scenarios.golden.json from the worked examples of docs/scenarios.yaml.
set -euo pipefail
rampart=${1:?usage: scripts/check.sh <path to a Rampart checkout>}
here=$(cd "$(dirname "$0")/.." && pwd)
out=$(mktemp -d)
test_file="$rampart/internal/config/apply/zz_policyset_test.go"
trap 'rm -f "$test_file"; rm -rf "$out"' EXIT

"$here/scripts/render.sh" "$out"
cp "$here/tests/policyset_test.go.in" "$test_file"
update=""; [[ "${UPDATE_GOLDEN:-}" == "1" ]] && update=1
(cd "$rampart" && POLICYSET_RENDER="$out" POLICYSET_SCENARIOS="$here/docs/scenarios.yaml" POLICYSET_GOLDEN="$here/docs/scenarios.golden.json" POLICYSET_UPDATE="$update" go test ./internal/config/apply -run '^TestPolicySet' -count=1)

(cd "$rampart" && go build -o "$out/rampart" ./cmd/rampart)
for f in cluster namespace; do
  env -u RAMPART_DATABASE_SYSTEM_URL -u RAMPART_DATABASE_URL -u DATABASE_URL "$out/rampart" apply -f "$out/$f.yaml" > /dev/null
  echo "rampart apply: $f.yaml accepted"
done
