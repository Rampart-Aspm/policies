# rampart-policies

The scoring policies and the compliance frameworks of [Rampart](https://github.com/taha2samy-3/Rampart), as one **versioned Helm chart**. A new version of this chart is a new version of the policy set: what a finding scores, how long you have to fix it, and what a compliance screen asks for.

**Everything is on by default.** A plain `helm install` gives every tenant the risk policy, the SLA policy (profile `strictest`) and the eleven compliance frameworks, as the cluster-wide default (scope `cluster`: a tenant that has a policy of its own keeps it). Each part is turned off with `enabled: false`. The chart is how that default policy set is versioned, pinned from Git and overridden, with a changelog to point at.

**It needs a Rampart that has the application `environment` (schema version 51).** The risk policy reads `app.environment`; an older server refuses the policy and keeps its built-in one. Use `0.1.0`, whose risk policy does not read it, until the server is upgraded.

## What is in it

| What | Kinds it creates | Choices | Explained in |
|---|---|---|---|
| Risk policy | `ClusterRiskPolicy` or `RiskPolicy`, named `default` | the twelve factors of the built-in policy, written out | [docs/SCORING.md](docs/SCORING.md) |
| SLA policy | `ClusterSLAPolicy` or `SLAPolicy`, named `default` | profile: `strictest` (default), `rampart`, `pci-dss`, `fedramp`, `cisa-bod` | [docs/SLA.md](docs/SLA.md) |
| Compliance frameworks | `ClusterComplianceFramework` or `ComplianceFramework` | eleven: NIST SP 800-53, NIST SP 800-171, NIST CSF 2.0, PCI DSS (complement), ISO 27001 (complement), SOC 2, HIPAA, GDPR, OWASP API Top 10, EU Cyber Resilience Act, EU NIS2 | [docs/frameworks/](docs/frameworks/README.md), [docs/METHOD.md](docs/METHOD.md) |

Rampart already carries OWASP Top 10, CWE Top 25, PCI DSS requirement 6, ISO/IEC 27001 Annex A.8 and NIST SSDF as built-in frameworks. They are not repeated: for PCI DSS and ISO 27001 the page here is a **complement** that adds only the controls the built-in one lacks.

## Documentation

Every number and every control is explained, so that nobody has to take it on trust:

- **[docs/SCORING.md](docs/SCORING.md)**: the formula, every factor and what it rests on, why the band limits are where they are, and fifteen worked examples evaluated by Rampart's own code.
- **[docs/SLA.md](docs/SLA.md)**: how a deadline is worked out, each profile and its basis, and the same examples with their deadlines.
- **[docs/METHOD.md](docs/METHOD.md)**: how the frameworks were written (which controls, how each is matched to scanner findings, severity floors, evidence windows), what was verified against the publishers' own text and what could not be, and what was left out and why.
- **[docs/frameworks/](docs/frameworks/README.md)**: one page per framework, control by control, with the reason for each mapping.
- **[docs/FOUNDATION.md](docs/FOUNDATION.md)**: what Rampart still lacks for these policies to say exactly what the standards say.

The tables in those pages are generated from the files that make the chart, and CI fails if they drift, so the documentation cannot describe something other than what is installed.

## Where the CRDs are

| Folder | What it is |
|---|---|
| `rendered/cluster/*.yaml` | **Read these.** Each compliance framework as an ordinary `ClusterComplianceFramework`, in plain YAML, that you can apply by hand: `rampart apply -f rendered/cluster/<name>.yaml` |
| `charts/rampart-policies/templates/` | What Helm installs: the risk policy and SLA policy (`risk-policy.yaml`, `sla-policy.yaml`, nearly plain YAML) and the frameworks (`compliance/`, generated) |
| `frameworks/*.yaml` | **Not CRDs.** The source each framework is written from: its controls, how each is matched, and why. `scripts/generate.py` turns it into the template, the plain resource above and the documentation page, so they cannot disagree |

## What the values rest on, in one paragraph

Three kinds of value are used, and each is marked wherever it appears: **Standard** (an authority defines it, such as the CVSS order of severities, CISA's KEV catalogue, FedRAMP's 30/90/180 days), **Convention** (common practice that no standard defines, such as the 0 to 1000 scale and the EPSS 0.1 cut-off), and **Ours** (Rampart's judgement: the point values, the band limits, the severity floors). Most numbers are **Ours**. They are not validated against outcomes, and nothing in the standards or in any product publishes a number to copy. They are a default that is meant to be changed, with a version to say which one you used.

## Install

```sh
# everything on, as the default of every tenant
helm install rampart-policies oci://ghcr.io/rampart-aspm/charts/rampart-policies --version 0.2.0

# leave one part out, or choose another SLA profile
helm install rampart-policies oci://ghcr.io/rampart-aspm/charts/rampart-policies --version 0.2.0 \
  --set compliance.hipaa.enabled=false --set slaPolicy.profile=pci-dss
```

`<owner>` is the GitHub owner that publishes the release. With Argo CD, point an application at the chart and keep the values in Git:

```yaml
source:
  repoURL: ghcr.io/<owner>/charts
  chart: rampart-policies
  targetRevision: 0.1.0            # the version of the policy set
  helm:
    valuesObject:
      riskPolicy: {enabled: true}
      slaPolicy: {enabled: true, profile: fedramp}
```

The cluster needs the Rampart CRDs for the kinds above (they ship with the Rampart chart).

## Values

| Value | Default | Meaning |
|---|---|---|
| `scope` | `cluster` | `cluster`: `Cluster*` kinds, the default of every tenant. `namespace`: the plain kinds in `namespace`, one tenant's own policy, which wins over a cluster one |
| `namespace` | `rampart` | used when `scope` is `namespace`; it must be a namespace of the tenant |
| `riskPolicy.enabled` | `true` | the scoring formula |
| `slaPolicy.enabled` | `true` | the deadlines |
| `slaPolicy.profile` | `strictest` | `strictest` (the smallest number of the other four in every cell, so it meets all of them), `rampart` (the built-in matrix), `pci-dss`, `fedramp` or `cisa-bod`. One policy is in force, so one profile is rendered |
| `compliance.logos` | `true` | give each framework a `logoUrl`: its own mark, an SVG that Rampart draws itself (docs/METHOD.md, "Logos"). Set `false` for a cluster that cannot reach the internet |
| `compliance.logoBaseUrl` | `https://raw.githubusercontent.com/Rampart-Aspm/policies/main/logos` | where the marks are fetched from; the repository must be public |
| `compliance.logoUrls` | `{}` | a logo of your own for one framework, by key; it wins over the two above |
| `compliance.<key>.enabled` | `true` | one flag per framework: `nist80053`, `nist800171`, `nistcsf`, `pcidss`, `iso27001`, `soc2`, `hipaa`, `gdpr`, `owaspapi`, `eucra`, `nis2` |

A framework reads an application only when the application lists the framework's scope in `complianceScope` (`nist-800-53`, `nist-800-171`, `nist-csf`, `pci-dss`, `iso-27001`, `soc2`, `hipaa`, `gdpr`, `owasp-api`, `eu-cra`, `eu-nis2`). A tenant with no policy of its own gets the cluster one. The policy named `default` is the one the server reads first, so enabling this chart's policy replaces another `default` of the same scope.

## Versioning

The chart version is the version of the policy set, in [SemVer](https://semver.org). The unit of change is what a finding scores or when it is due, because that is what people notice.

| Bump | When |
|---|---|
| **Major** | anything that can change a score, a band or a deadline (a point value, a band limit, a factor condition, a day count, a cap); a control's `match`; removing or renaming a framework, a profile or a value |
| **Minor** | a new framework, profile, control or value. A new control in a framework that is switched on can turn its status from `clear` to `open`, so say so in the changelog |
| **Patch** | wording (names, reasons, descriptions), links, documentation, CI |

Every resource carries the annotation `rampart.aspm.dev/policy-set-version`, so a cluster shows which release defined a policy.

## Development

The compliance frameworks are written once, in `frameworks/*.yaml`, and the Helm templates and their pages are generated from them:

```sh
scripts/generate.py                              # frameworks/*.yaml and docs/scenarios.golden.json -> templates and docs
scripts/marks.py <rampart checkout>              # logos/*.svg: each framework's mark, from the Rampart screens' own shape table
helm lint --strict charts/rampart-policies
scripts/check.sh <path to a Rampart checkout>    # the real Rampart code accepts every document, the risk policy is the built-in one,
                                                 # no SLA profile is capped, and every worked example gives the number the docs state
UPDATE_GOLDEN=1 scripts/check.sh <rampart>       # after changing a policy or docs/scenarios.yaml on purpose
```

CI runs these on every pull request, and fails a pull request that changes the chart without a new `version` in `Chart.yaml` and a `## [version]` section in `CHANGELOG.md`. The risk policy is asserted equal to Rampart's built-in one: if Rampart changes its built-in policy the check fails on purpose, and the change becomes a decision about this chart. Pin the Rampart version it is checked against with the repository variable `RAMPART_REF` (a tag or commit); add `RAMPART_READ_TOKEN` as a secret if the Rampart repository is private.

**To release:** bump `Chart.yaml`, add the changelog section, merge, then push a tag `vX.Y.Z` that equals the chart version. The release workflow runs CI again, packages the chart, publishes it to `oci://ghcr.io/<owner>/charts/rampart-policies`, attests provenance, signs it with cosign (keyless), and creates the GitHub release with the changelog section as its notes.
