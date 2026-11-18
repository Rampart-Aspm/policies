# How a risk score is worked out

This page explains the risk policy of this chart completely: the formula, every factor and what it rests on, how the band limits were chosen, and worked examples. The numbers in the tables below are not typed: they are read from the policy as the real Rampart code evaluates it, and CI fails if they change without this page being regenerated.

**Read this first.** Most numbers here are Rampart's own judgement. No standard says that a KEV listing is worth 300 points, and no product publishes its weights. What is standard is marked **Standard**; what is common practice is **Convention**; what we chose is **Ours**. Nothing has been validated against outcomes yet (see [FOUNDATION.md](FOUNDATION.md), item 12). The policy is a default that is meant to be changed, with a version number to say which one you used.

## The formula

```
score = clamp( base[severity the scanner gave]  +  the sum of the points of every factor whose condition is true,  0, 1000 )
band  = critical if score >= 800;  high if >= 600;  medium if >= 300;  otherwise low
```

- The **severity** is what the scanner reported (critical, high, medium, low, info). An unknown severity weighs as low.
- A **factor** is a named condition with points. A factor whose condition cannot be evaluated counts as false and is reported as an error; it never stops a score.
- Every factor that applied is listed with the score, with its points and its reason, so a score can always be explained line by line.
- The **band** is then looked up against the limits. The band, with the application's criticality, selects the deadline ([SLA.md](SLA.md)).

## Where each input comes from

| Input | Read from |
|---|---|
| `finding.severity`, `category`, `scanner`, `rule_id`, `secret_verified` | the scanner's report |
| `finding.track` | the environment named by the upload, else the branch, else `default` |
| `vuln.kev` | CISA's Known Exploited Vulnerabilities catalogue, synchronised by the cluster feed |
| `vuln.epss` | FIRST's EPSS scores, synchronised by the cluster feed |
| `vuln.exploited` | exploitation in the wild reported by an optional source other than CISA (for example VulnCheck KEV or EUVD) |
| `vuln.exploit_maturity` | `weaponized` when a Metasploit module or another configured source has a public exploit |
| `app.criticality`, `internet_facing`, `data_classification`, `compensating_controls` | the `Application` resource |

If a feed is switched off, the factors that read it can never apply. The feed is part of the scoring.

## The factors

<!-- generated:factors -->
| Factor | Group | Condition | Points | Reason |
|---|---|---|---|---|
| `KEV` | threat | `vuln.kev` | +300 | Vulnerability listed in CISA Known Exploited Vulnerabilities catalog |
| `EPSS_HIGH` | threat | `vuln.epss >= 0.5` | +150 | EPSS exploitation probability is >= 50% |
| `EPSS_MODERATE` | threat | `vuln.epss >= 0.1 && vuln.epss < 0.5` | +60 | EPSS exploitation probability is >= 10% |
| `EXPLOITED_REPORTED` | threat | `vuln.exploited && !vuln.kev` | +300 | Exploitation in the wild reported by a configured intelligence source (not in CISA KEV) |
| `EXPLOIT_WEAPONIZED` | threat | `vuln.exploit_maturity == "weaponized"` | +120 | A weaponized public exploit exists (a Metasploit module or a configured source) |
| `SECRET_VERIFIED` | threat | `finding.secret_verified` | +250 | Secret credential verified live against upstream provider |
| `INTERNET_FACING` | context | `app.internet_facing` | +100 | Asset or application is internet-facing |
| `SENSITIVE_DATA` | context | `app.data_classification.exists(d, d in ["pci", "pii", "phi"])` | +80 | Application handles sensitive data (PCI, PII, or PHI) |
| `APP_CRITICAL` | context | `app.criticality == "critical"` | +100 | Application business criticality is rated Critical |
| `APP_HIGH` | context | `app.criticality == "high"` | +50 | Application business criticality is rated High |
| `PRODUCTION_ENV` | context | `finding.track in ["production", "prod"]` | +60 | Finding detected in production environment |
| `COMPENSATING_CONTROL` | reduction | `finding.category == "dast" && app.compensating_controls.exists(c, c in ["waf", "api_gateway"])` | -80 | The application is behind a web application firewall or an API gateway, which inspects the HTTP requests this finding needs |
<!-- /generated:factors -->

### What each factor rests on

| Factor | Kind | Basis |
|---|---|---|
| Base points (order of severities) | order: **Standard**; numbers: **Ours** | the order is the CVSS qualitative scale (FIRST); the points are ours |
| `KEV` | fact: **Standard**; weight: **Ours** | listing in CISA's Known Exploited Vulnerabilities catalogue ([BOD 22-01](https://www.cisa.gov/known-exploited-vulnerabilities)) is CISA's. 300 is ours: it makes a KEV-listed high finding 700, and 100 more points of context make it critical |
| `EPSS_HIGH`, `EPSS_MODERATE` | fact: **Standard**; cut-offs: **Convention** and **Ours** | EPSS is a probability published by FIRST. FIRST gives no official cut-off ([thresholds guide](https://riskbasedprioritization.github.io/epss/EPSS_Thresholds)); 0.1 is the common convention, 0.5 is ours |
| `EXPLOITED_REPORTED` | **Ours** | exploitation reported by a source other than CISA counts as much as a KEV listing (300), because the evidence is the same kind: it is being exploited. It does not apply when the finding is already on KEV, so the two do not add up |
| `EXPLOIT_WEAPONIZED` | **Ours** | a public, working exploit is the idea of the "Exploit Maturity" threat metric of CVSS 4.0; 120 is ours |
| `SECRET_VERIFIED` | **Ours** | a credential confirmed to work needs no exploit at all |
| `INTERNET_FACING` | **Ours** | exposure is a decision point of CISA's [SSVC](https://cisa.gov/ssvc) and an environmental metric of CVSS; 100 is ours |
| `SENSITIVE_DATA` | **Ours** | the data classes that PCI DSS (card data), HIPAA (health information) and the GDPR (personal data) are about; 80 is ours, and it applies once however many classes are listed |
| `APP_CRITICAL`, `APP_HIGH` | **Ours** | business criticality is an input of the vulnerability-management products reviewed for this project; the points are ours |
| `PRODUCTION_ENV` | **Ours** | read from the name of the branch (`production` or `prod`), because the application has no environment field yet ([FOUNDATION.md](FOUNDATION.md), item 6) |
| `COMPENSATING_CONTROL` | **Ours** | PCI DSS 4.0.1 requirement 6.4.2 asks for a web application firewall (or an equivalent automated solution) in front of public web applications. It lowers only findings of a dynamic scan, because a request-inspecting control can stop what such a scan sends and cannot stop a flaw in a dependency |

## The bands

<!-- generated:bands -->
| Band | From score |
|---|---|
| critical | 800 |
| high | 600 |
| medium | 300 |
| low | below 300 |

How many more points a finding needs, on top of its base, to reach each band:

| Severity | Base | To medium | To high | To critical |
|---|---|---|---|---|
| critical | 600 | already | already | +200 |
| high | 400 | already | +200 | +400 |
| medium | 200 | +100 | +400 | +600 |
| low | 80 | +220 | +520 | +720 |
| info | 10 | +290 | +590 | +790 |
<!-- /generated:bands -->

### Why the limits are where they are

The limits (800, 600, 300) are **Ours**. They were chosen to satisfy four rules, and the worked examples below show each of them at work.

1. **Severity is the floor, not the verdict.** Base points follow the order of the CVSS scale, and the highest base (600) is below the critical limit (800). A finding the scanner calls critical is **high** until something else supports it. The reason is that severity alone is a weak predictor of what is exploited; Snyk, for one, [says](https://docs.snyk.io/~/changes/yFqnNB3gP8ZTzzxeVJ9M/manage-issues/issue-management/priority-score) it does not use CVSS alone either (S01).
2. **The critical band is for evidence.** From a critical finding it takes 200 more points to reach it, from a high one 400, from a medium one 600. That can come from threat (a KEV listing, a high EPSS, a live secret) or from context (internet-facing, card data, a critical application, production), but not from severity (S03, S05, S07).
3. **A single piece of threat evidence does not decide by itself.** KEV adds 300, which makes a high finding 700, still high; 100 more points of context make it critical. The urgency of a KEV listing is expressed by the deadline instead, which the CISA due date caps (S06). A single factor never moves a finding two bands.
4. **Round numbers, so the arithmetic can be done by hand.** Points are multiples of 10 and the limits multiples of 100, so a reader can add up a score and see which side of a limit it falls on. A score of exactly 800 is critical (S05).

For comparison, Qualys cuts its own 0 to 1000 scale at 850, 700 and 500, and calls the top band critical too ([Qualys](https://docs.qualys.com/en/etm/latest/appendix/formula_comparison.htm)). Each product chooses its own; nothing standardises them.

### What would change a limit

A limit is right if the findings in a band are the ones that deserve its deadline. Today nothing measures that. To calibrate, take the findings that were later added to KEV or reported exploited and look at the band they had when first seen: if many were `high` and few `critical`, the critical limit is too high. [FOUNDATION.md](FOUNDATION.md), item 12, proposes exporting exactly that.

## Worked examples

Each example is evaluated by Rampart's own scoring code with this policy. `firstSeen` is the same for all, and the deadlines are in [SLA.md](SLA.md).

<!-- generated:scenarios -->
| Example | What | Base | Factors that applied | Score | Band |
|---|---|---|---|---|---|
| **S01** | A critical finding and nothing else. The scanner says critical, and nothing is known about the vulnerability or the application. Severity alone does not reach the critical band. | 600 | none | **600** | high |
| **S02** | A high finding in a low-profile application. A high finding in an internal, low-criticality application with no threat data is only medium. | 400 | none | **400** | medium |
| **S03** | The same finding in a critical, internet-facing application that holds card data. Context alone adds 280 points (internet-facing 100, card data 80, critical application 100). That is high, but not critical. | 400 | `INTERNET_FACING` +100, `SENSITIVE_DATA` +80, `APP_CRITICAL` +100 | **680** | high |
| **S04** | S03 with a 20% chance of exploitation (EPSS). A moderate EPSS adds 60 points. | 400 | `EPSS_MODERATE` +60, `INTERNET_FACING` +100, `SENSITIVE_DATA` +80, `APP_CRITICAL` +100 | **740** | high |
| **S05** | S04 found on the production branch. The production factor lands exactly on the limit of the critical band, 800, which is in it. | 400 | `EPSS_MODERATE` +60, `INTERNET_FACING` +100, `SENSITIVE_DATA` +80, `APP_CRITICAL` +100, `PRODUCTION_ENV` +60 | **800** | critical |
| **S06** | A high finding on the CISA KEV list, in a low-profile application. KEV adds 300 points, which is high but not critical on its own. The deadline is what makes it urgent: it is capped by the CISA due date. | 400 | `KEV` +300 | **700** | high |
| **S07** | A critical KEV finding in a critical, internet-facing production application. Everything lines up. The points add to 1240 and are clamped to 1000. | 600 | `KEV` +300, `INTERNET_FACING` +100, `SENSITIVE_DATA` +80, `APP_CRITICAL` +100, `PRODUCTION_ENV` +60 | **1000** | critical |
| **S08** | A medium finding with a high EPSS. EPSS of 50% or more adds 150 points; a medium finding stays medium. | 200 | `EPSS_HIGH` +150 | **350** | medium |
| **S09** | A low finding with a weaponized public exploit. A weaponized exploit adds 120 points, which is not enough to leave the low band. | 80 | `EXPLOIT_WEAPONIZED` +120 | **200** | low |
| **S10** | A live (verified) secret in an internal application. A secret confirmed to work adds 250 points. | 400 | `SECRET_VERIFIED` +250 | **650** | high |
| **S11** | A live secret in a critical, internet-facing application. The same secret, with context, is critical. | 400 | `SECRET_VERIFIED` +250, `INTERNET_FACING` +100, `APP_CRITICAL` +100 | **850** | critical |
| **S12** | A medium finding of a dynamic scan, behind a WAF. A web application firewall in front lowers findings that a request-inspecting control can stop, by 80 points. | 200 | `INTERNET_FACING` +100, `SENSITIVE_DATA` +80, `APP_CRITICAL` +100, `COMPENSATING_CONTROL` -80 | **400** | medium |
| **S13** | S12 without the WAF. The same finding with no control in front is 80 points higher. | 200 | `INTERNET_FACING` +100, `SENSITIVE_DATA` +80, `APP_CRITICAL` +100 | **480** | medium |
| **S14** | A high finding reported as exploited by a source other than CISA. Exploitation reported elsewhere counts as much as a KEV listing (300), but only when the finding is not already on KEV. | 400 | `EXPLOITED_REPORTED` +300 | **700** | high |
| **S15** | An informational finding. Info findings weigh 10 and stay in the low band. | 10 | none | **10** | low |
<!-- /generated:scenarios -->

## What the score does not include

- **No CVSS vector or fix availability.** A policy cannot read them yet ([FOUNDATION.md](FOUNDATION.md), item 6).
- **No reachability.** Whether the vulnerable code is called is not known.
- **No environment on the application.** Production is read from the branch name.
- **No age.** A finding does not get worse with time in the score; time is the SLA's job.

## Reproducing a number

1. Take a finding's severity, the vulnerability's KEV and EPSS values, and the application's four facts.
2. Add the base points for the severity and the points of every factor above whose condition is true.
3. Clamp to 1000, and read the band from the limits.

Rampart shows the same breakdown on every finding, and `GET /api/v1/scoring` returns the policy in force. To check the policy itself against the code, run `scripts/check.sh <a Rampart checkout>`.

## Changing it

A change to a point value, a limit or a condition is a **major** version of this chart (README, "Versioning"), because it moves scores. Change the policy in `charts/rampart-policies/templates/risk-policy.yaml`, update the examples if needed, run `UPDATE_GOLDEN=1 scripts/check.sh <rampart>` and `scripts/generate.py`, and write what moved in the changelog.
