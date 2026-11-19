# How a deadline is worked out

The SLA policy turns a finding's band and its application's criticality into a number of days, then into a due date. As in [SCORING.md](SCORING.md), the numbers in the tables are read from the policies as the real Rampart code evaluates them, and CI fails if they change without this page being regenerated.

## The rule

```
start    = the day the finding was first seen              (startFrom: firstSeen)
days     = matrix[band of the score][criticality of the application]
days     = maxDays                                          if days is above maxDays
due      = start + days
due      = the end of the CISA due date                     if the finding is on KEV, kevDueDate is on, and that is earlier
```

- **Rows are the band, columns the application's criticality.** An unknown criticality is read as low, and an informational finding as the low row.
- **The CISA due date** is a day. The work is due by the end of it, so a finding is late from the next midnight (UTC).
- **`restartOnReactivation`**: a finding that comes back gets a new clock. **`pauseDuringRiskAcceptance`**: the clock stops while a risk acceptance is in force. Both are on in every profile; they are Ours (the standards count from discovery or from a patch release, and say nothing about either).
- **`businessDays`** is not used: all days are calendar days.

## The profiles

One policy is in force per tenant, so one profile is rendered; you choose it with `slaPolicy.profile`. **The default is `strictest`.**

<!-- generated:profiles -->
**`cisa-bod`**: `maxDays` 180, `kevDueDate` on, from firstSeen

| Band \ criticality | critical | high | medium | low |
|---|---|---|---|---|
| critical | 15 | 15 | 15 | 15 |
| high | 30 | 30 | 30 | 30 |
| medium | 90 | 90 | 90 | 90 |
| low | 180 | 180 | 180 | 180 |

**`fedramp`**: `maxDays` 180, `kevDueDate` on, from firstSeen

| Band \ criticality | critical | high | medium | low |
|---|---|---|---|---|
| critical | 30 | 30 | 30 | 30 |
| high | 30 | 30 | 30 | 30 |
| medium | 90 | 90 | 90 | 90 |
| low | 180 | 180 | 180 | 180 |

**`pci-dss`**: `maxDays` 180, `kevDueDate` on, from firstSeen

| Band \ criticality | critical | high | medium | low |
|---|---|---|---|---|
| critical | 30 | 30 | 30 | 30 |
| high | 30 | 30 | 30 | 30 |
| medium | 90 | 90 | 90 | 90 |
| low | 180 | 180 | 180 | 180 |

**`rampart`**: `maxDays` 365, `kevDueDate` on, from firstSeen

| Band \ criticality | critical | high | medium | low |
|---|---|---|---|---|
| critical | 3 | 7 | 14 | 30 |
| high | 7 | 14 | 30 | 60 |
| medium | 30 | 45 | 90 | 120 |
| low | 90 | 120 | 180 | 365 |

**`strictest`**: `maxDays` 180, `kevDueDate` on, from firstSeen

| Band \ criticality | critical | high | medium | low |
|---|---|---|---|---|
| critical | 3 | 7 | 14 | 15 |
| high | 7 | 14 | 30 | 30 |
| medium | 30 | 45 | 90 | 90 |
| low | 90 | 120 | 180 | 180 |
<!-- /generated:profiles -->

### What each profile rests on

| Profile | Kind | Basis |
|---|---|---|
| `strictest` (default) | **Ours**, built from the others | every cell is the smallest number of the four profiles below, so a finding that meets it meets all of them: PCI DSS, FedRAMP, CISA BOD 19-02 and Rampart's own. It differs from `rampart` only in four cells, all for low-criticality applications (critical 30 becomes 15, high 60 becomes 30, medium 120 becomes 90, low 365 becomes 180), and its `maxDays` is 180. CI checks it cell by cell against the other four, so it cannot fall behind when one of them changes |
| `rampart` | **Ours** | tighter than every standard below, and the only profile that uses the application's criticality: the more the business depends on it, the sooner |
| `pci-dss` | critical and high: **Standard**, with a caveat; medium and low: **Ours** | PCI DSS 4.0.1 [requirement 6.3.3](https://www.schellman.com/blog/pci-compliance/pci-dss-v4-requirement-1144): one month from the release of a patch. Sources disagree on whether v4.0.1 says critical only or [critical and high](https://www.feroot.com/blog/pci-4-0-1-has-arrived); the profile reads both as 30. The standard counts from the patch's release and Rampart from the first time the finding was seen. When the patch came out before Rampart first saw the finding, Rampart's deadline is later than the standard's; when it came out after, Rampart's is earlier. Medium and low are set by the entity's own risk analysis in the standard; 90 and 180 are ours. **Check the text of the standard you are audited against** |
| `fedramp` | **Standard** | the long-standing FedRAMP [continuous monitoring schedule](https://fedramp.gov/legacy/playbook/csp/authorization/poam/): critical and high within 30 days of discovery, moderate 90, low 180. Newer FedRAMP proposals use shorter windows and their status is unclear, so they are not included |
| `cisa-bod` | critical and high: **Standard**; medium and low: **Ours** | CISA [BOD 19-02](https://cisa.gov/binding-operational-directive-19-02): critical 15 days, high 30, from first detection, for internet-accessible systems. Medium and low are not in the directive; 90 and 180 are ours |

Every profile has `kevDueDate` on: a finding on the CISA list is due at the end of the CISA due date when that is earlier, which is how [BOD 22-01](https://www.cisa.gov/known-exploited-vulnerabilities) deadlines are honoured.

### Why `maxDays` is never below the largest cell

The server caps every deadline at `maxDays`. A policy with a cell above `maxDays` is therefore silently shortened: a preset that says 90 days for medium findings and sets `maxDays` to 30 gives 30. In this chart `maxDays` equals the largest cell of each profile, and CI checks that every cell comes out of the server as written ([FOUNDATION.md](FOUNDATION.md), item 9).

## Worked examples

The same findings as in SCORING.md, with the deadline under each profile, and the due date under the `rampart` profile for a finding first seen on the date shown.

<!-- generated:sla-scenarios -->
| Example | Band, criticality | cisa-bod | fedramp | pci-dss | rampart | strictest | Due (rampart) |
|---|---|---|---|---|---|---|---|
| **S01** | high, medium | 30 | 30 | 30 | 30 | 30 | 2026-04-01 09:00 UTC |
| **S02** | medium, low | 90 | 90 | 90 | 120 | 90 | 2026-06-30 09:00 UTC |
| **S03** | high, critical | 30 | 30 | 30 | 7 | 7 | 2026-03-09 09:00 UTC |
| **S04** | high, critical | 30 | 30 | 30 | 7 | 7 | 2026-03-09 09:00 UTC |
| **S05** | critical, critical | 15 | 30 | 30 | 3 | 3 | 2026-03-05 09:00 UTC |
| **S06** | high, low | 30 | 30 | 30 | 60 | 30 | 2026-03-05 00:00 UTC (capped by the CISA due date; without it 2026-05-01 09:00 UTC) |
| **S07** | critical, critical | 15 | 30 | 30 | 3 | 3 | 2026-03-05 09:00 UTC |
| **S08** | medium, medium | 90 | 90 | 90 | 90 | 90 | 2026-05-31 09:00 UTC |
| **S09** | low, low | 180 | 180 | 180 | 365 | 180 | 2027-03-02 09:00 UTC |
| **S10** | high, medium | 30 | 30 | 30 | 30 | 30 | 2026-04-01 09:00 UTC |
| **S11** | critical, critical | 15 | 30 | 30 | 3 | 3 | 2026-03-05 09:00 UTC |
| **S12** | medium, critical | 90 | 90 | 90 | 30 | 30 | 2026-04-01 09:00 UTC |
| **S13** | medium, critical | 90 | 90 | 90 | 30 | 30 | 2026-04-01 09:00 UTC |
| **S14** | high, medium | 30 | 30 | 30 | 30 | 30 | 2026-04-01 09:00 UTC |
| **S15** | low, low | 180 | 180 | 180 | 365 | 180 | 2027-03-02 09:00 UTC |
| **S16** | critical, critical | 15 | 30 | 30 | 3 | 3 | 2026-03-05 09:00 UTC |
| **S17** | high, critical | 30 | 30 | 30 | 7 | 7 | 2026-03-09 09:00 UTC |
<!-- /generated:sla-scenarios -->

## What is not modelled

- **A clock that starts at a patch's release** (PCI DSS) rather than at first sight.
- **Different deadlines for different kinds of finding.** The matrix is by band and criticality only.
- **Business days.** The server supports them (`businessDays`); no profile here uses them.
- **Newer FedRAMP rulesets**, whose status could not be confirmed.
