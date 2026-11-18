# How the compliance frameworks are written

This is the method behind every page in [frameworks/](frameworks/README.md). It exists so that anyone can see why a control is matched the way it is, and can disagree with a specific decision instead of with a vague one.

## What a framework is to Rampart

A `ComplianceFramework` is a list of controls. For each control the server does one of three things:

| The control says | The server |
|---|---|
| `match` (weakness numbers, kinds of scan, a severity floor) | counts the **open findings** that match, and reads the control as `open` if there are any |
| `evidence` (kinds of scan) | needs a scan of one of those kinds to have run **within the evidence window**, or reads the control as `not assessed` |
| `manual: true` | leaves it to a person to attest |

A control that is matched only by weakness numbers and names no evidence is evidenced by a code scan (`sast` or `dast`), because a dependency or image scan finds weaknesses in other people's code and does not assess this application's own. A control must be either manual or matched; the server refuses one that is neither.

So a `clear` control means **no open finding of the kind the control watches, and a recent scan**. It does not mean the requirement is met. This is the central limit of all scanner-based compliance, and the framework pages say so.

## Which controls are listed

1. **A control is listed if a scanner, an SBOM or a test can say something about it**, or if a short, fixed list of requirements has to be answered in full (NIS2 Article 21(2) and the Cyber Resilience Act's Annex I Part II are such lists: all ten and all eight points are there, with the ones nobody can scan marked manual).
2. **Governance, people, premises and contracts are not listed** just to make a list longer. A framework with a thousand controls where 950 are manual is a questionnaire, not a view of findings. Each page says what it leaves out.
3. **Where Rampart already carries a built-in framework** (OWASP Top 10, CWE Top 25, PCI DSS requirement 6, ISO 27001 Annex A.8, NIST SSDF), this repository does not repeat it. Where the standard is wider (PCI DSS, ISO 27001), the page here is a **complement** that adds only the controls the built-in one lacks, so a control is never answered twice with two different results.

## How a control is matched

| Rule | When it applies |
|---|---|
| **R1: use the publisher's own mapping** | The standard itself lists weaknesses. Only OWASP's API Security Top 10 does: its weakness lists are copied as OWASP gives them, in OWASP's order. |
| **R2: use the weakness classes of the property** | The control names a technical property (cryptography, data in transit, data at rest, input validation, authentication, authorisation, integrity) but no weaknesses. The classes below are ours, and are the usual way that property breaks. |
| **R3: use the kind of scan** | The control is about scanning, testing, vulnerability management, secrets, configuration or supply chain. It is matched to the kinds of scan that find those things, with a severity floor. |
| **R4: manual** | Policies, processes, training, contracts, governance, design. |
| **R5: never green by construction** | A control is not matched to something a scanner cannot evidence only so that it can turn green. If it cannot be evidenced, it is manual. |

### The weakness classes of rule R2

Names are MITRE's, from CWE catalogue 5.0 (2026-10-28). The classes are ours: MITRE and the standards do not map controls to them.

| Class | Weaknesses |
|---|---|
| Cryptography itself | CWE-326 Inadequate Encryption Strength; CWE-327 Use of a Broken or Risky Cryptographic Algorithm; CWE-328 Use of Weak Hash; CWE-330 Use of Insufficiently Random Values; CWE-759 Use of a One-Way Hash without a Salt; CWE-916 Use of Password Hash With Insufficient Computational Effort |
| Data in transit | CWE-319 Cleartext Transmission of Sensitive Information; CWE-295 Improper Certificate Validation; CWE-297 Improper Validation of Certificate with Host Mismatch |
| Data at rest | CWE-311 Missing Encryption of Sensitive Data; CWE-312 Cleartext Storage of Sensitive Information; CWE-313 Cleartext Storage in a File or on Disk |
| Input validation and injection | CWE-20 Improper Input Validation; CWE-22 Path Traversal; CWE-77 and CWE-78 command and OS command injection; CWE-79 cross-site scripting; CWE-89 SQL injection; CWE-94 code injection; CWE-502 Deserialization of Untrusted Data; CWE-611 XML External Entity Reference; CWE-918 Server-Side Request Forgery |
| Authentication | CWE-287 Improper Authentication; CWE-306 Missing Authentication for Critical Functionality; CWE-798 Use of Hard-coded Credentials |
| Authorisation | CWE-285 Improper Authorization; CWE-862 Missing Authorization; CWE-863 Incorrect Authorization |
| Integrity | CWE-345 Insufficient Verification of Data Authenticity; CWE-494 Download of Code Without Integrity Check |

## Severity floors

| Floor | Used for | Why |
|---|---|---|
| none | secrets, supply-chain findings, and weakness-based controls | a hard-coded credential or a malicious package is a failure at any severity; a weakness control is about the class, not the rating |
| `medium` | configuration (infrastructure-as-code, cloud posture) | low findings there are style and hygiene |
| `high` | vulnerability management, flaw remediation, patching, scanning | the standards that set deadlines (FedRAMP, PCI DSS, CISA BOD 19-02) set them for critical and high |
| `critical` | controls that say "regularly tested", "evaluated", "effectiveness assessed" | the control is that testing **happens**; failing it on every finding the testing is meant to find would punish doing the testing. Each such control says: *read as: tested lately, and nothing critical left open* |

The floors are Ours: no standard defines them.

## Evidence windows

A scan counts as evidence for `evidenceWindowDays` days. The default here is **30**, which follows FedRAMP's monthly scanning cycle. PCI DSS uses **90** because requirement 11.3.1 asks for scans every three months. One number applies to a whole framework; a control-level window is a feature Rampart lacks (see [FOUNDATION.md](FOUNDATION.md), item 5).

## Verification: what was read, and where

Every page says whether its identifiers are **primary** (read from the publisher's own text or data) or **secondary** (taken from published guidance because the standard is not freely available). All of it was done on 2026-11-18.

| Framework | Level | What was read |
|---|---|---|
| NIST SP 800-53 Rev. 5 | primary | NIST's OSCAL catalogue (`usnistgov/oscal-content`); all ids and titles compared programmatically |
| NIST SP 800-171 Rev. 3 | primary | NIST's OSCAL catalogue; ids and titles compared programmatically |
| NIST CSF 2.0 | primary | NIST's own reference download (Excel workbook); wording read programmatically |
| HIPAA Security Rule | primary | the eCFR text of 45 CFR part 164, subpart C |
| GDPR Articles 25 and 32 | primary | EUR-Lex, Regulation (EU) 2016/679 |
| EU Cyber Resilience Act, Annex I | primary | EUR-Lex, Regulation (EU) 2024/2847 |
| EU NIS2, Article 21 | primary | EUR-Lex, Directive (EU) 2022/2555 |
| OWASP API Security Top 10 2023 | primary | the project's own repository (one page per risk); weakness references copied as published |
| Weakness names | primary | MITRE's CWE catalogue 5.0 (2026-10-28) |
| PCI DSS 4.0.1 | **secondary** | distributed behind a licence by the PCI SSC; ids and subjects from published guidance |
| ISO/IEC 27001:2022 | **secondary** | sold by ISO; ids and titles from published guidance |
| SOC 2 Trust Services Criteria | **secondary** | sold by the AICPA; ids and subjects from published guidance |

Secondary does not mean wrong. It means the check against the standard's own text has to be done by whoever holds a licensed copy, before an audit.

## Wording and licensing

- **Public domain and EU law** (NIST, HIPAA, GDPR, CRA, NIS2): the published wording is used, shortened where long.
- **Copyrighted standards** (PCI DSS, ISO/IEC 27001, SOC 2): control names are in our own words, and only the identifiers are the standard's.
- **OWASP**: titles are used with attribution to the OWASP API Security Project, whose content is under a Creative Commons Attribution-ShareAlike licence.

## Left out on purpose

- **CIS Controls v8.** It is published under a Creative Commons Attribution-NonCommercial-NoDerivatives licence, and commercial use needs CIS's approval. Writing derived control text into a product would need that approval first.
- **CSA Cloud Controls Matrix v4.** Published sources disagree on the titles of its vulnerability-management controls, and no authoritative text was found to settle it. It is better left out than guessed.
- **OWASP ASVS, SLSA, DORA, FedRAMP's newer rulesets.** Not written yet; none was rejected.

## Logos

**Every framework has a logo, and every logo is Rampart's own.** The official logos of NIST, PCI SSC, ISO, the AICPA, HHS, OWASP, the EU and the others are trademarks (and often copyrighted) of their owners, and some are guarded by law or by the owners' brand rules. Showing one beside a framework can look like the owner's approval or a certification, and whether it may be used could not be answered with confidence (the licence notes on Wikimedia Commons are the uploader's, not the owner's). So none is used.

- **What the logo is.** A flat shape with the framework's letters, in the colours of the Rampart screens: `NIST` on an arch, `PCI` on a square, `ISO` on an octagon, `OWASP` on a disc, `SOC2`, `HIPAA`, `GDPR`, `CRA`, `NIS2`, `NCA` and `SAMA` each on a shape of their own. They are drawn from the very shape table the Rampart screens use (`web/src/components/FrameworkMark.tsx` in Rampart), by `scripts/marks.py`, so the two cannot disagree. An installed framework is teal with dark letters; the file switches to the lighter teal by itself when the viewer's system is in dark mode.
- **Where they are.** `logos/<framework id>.svg` in this repository, about 550 bytes each. Each framework's `logoUrl` is `compliance.logoBaseUrl` plus that file name (`https://raw.githubusercontent.com/Rampart-Aspm/policies/main/logos/` by default), and the Rampart server fetches it, keeps it for a day and serves it from its own address. **The repository has to be public**, or the server cannot fetch them. If it is named differently, change `compliance.logoBaseUrl`.
- **Why a `logoUrl` at all.** The screens draw the same mark when a framework has no `logoUrl`, so it looks the same either way. With one, the logo is data that comes from the resource, not something built into the screens, and an operator can replace it.
- **Switching it off or replacing it.** `compliance.logos: false` leaves `logoUrl` out, which is also what a cluster that cannot reach the internet should do. `compliance.logoUrls.<key>` names a logo of your own for one framework (for example `nist80053: "https://example.org/nist.png"`); whether you may use a given official logo is for you, and your lawyer, to decide.
- **Checked.** The server's own logo checker accepts every file (an SVG without scripts or external references, far under its 256 KiB limit), and CI checks that the files are up to date with the screens' shape table.

## What this is not

It is not legal advice, a certification, or a statement that an application complies. It shows where scanner evidence supports a requirement and where it contradicts one.

## Changing a framework

Edit its file in `frameworks/`, run `scripts/generate.py`, and bump the chart version (see the README, "Versioning"). The template and the page are both generated from that one file, and CI fails if either is out of date.
