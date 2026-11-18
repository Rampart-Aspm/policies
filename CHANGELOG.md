# Changelog

The version of this chart is the version of the policy set (README.md, "Versioning"). Newest first.

## [0.1.0] - 2026-11-19

First release. Everything is off by default.

### Added
- Risk policy `default`: the twelve factors of the built-in policy, written out. Base points, bands and every factor are
  asserted equal to the built-in policy by CI. Explained in `docs/SCORING.md`, with fifteen worked examples evaluated by
  Rampart's own code.
- SLA policy `default` with five profiles: `strictest` (the default: in every cell the smallest number of the other four, so it meets PCI DSS, FedRAMP, CISA BOD 19-02 and Rampart's own), `rampart` (the built-in matrix), `pci-dss`, `fedramp`, `cisa-bod`. Explained in
  `docs/SLA.md`. CI checks that no profile is silently shortened by `maxDays`, and that `strictest` is the smallest of the others in every cell.
- Eleven compliance frameworks, each applying only to applications that list its scope in `complianceScope`:
  `nist-800-53-r5` (15 controls), `nist-800-171-r3` (15), `nist-csf-2.0` (15), `pci-dss-4.0.1-extended` (13, a complement to
  the built-in requirement 6 framework), `iso-27001-2022-extended` (12, a complement to the built-in Annex A.8 framework),
  `soc2-tsc` (7), `hipaa-security-rule` (9), `gdpr-art-32` (5), `owasp-api-top10-2023` (10), `eu-cra-annex-i` (15),
  `eu-nis2-art-21` (10). Identifiers were read from the publishers' own text for eight of them; PCI DSS, ISO/IEC 27001 and
  SOC 2 are marked secondary. See `docs/METHOD.md`.
- The frameworks are generated from `frameworks/*.yaml`, which also generates one documentation page per framework and each framework as a plain, readable `ClusterComplianceFramework` in `rendered/cluster/`.
- Every framework has a logo, and every logo is Rampart's own, not a publisher's trademark: an SVG in `logos/` (a flat shape with the framework's letters, drawn from the Rampart screens' own shape table by `scripts/marks.py`). Each `logoUrl` is `compliance.logoBaseUrl` plus the file name; `compliance.logos: false` leaves it out and `compliance.logoUrls.<key>` names a logo of your own. See `docs/METHOD.md`, "Logos".
- `scope: cluster` (default; `Cluster*` kinds) or `scope: namespace` (the same kinds in one tenant's namespace).
- Every resource carries `rampart.aspm.dev/policy-set-version`, so a cluster shows which release defined it.
- `docs/FOUNDATION.md`: thirteen things Rampart still needs for these policies to say exactly what the standards say.
