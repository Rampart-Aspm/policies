#!/usr/bin/env python3
"""Draws the logo of each compliance framework as a standalone SVG: the flat shape with the framework's letters that the Rampart
screens draw for it (web/src/components/FrameworkMark.tsx), taken from that file, so the two cannot disagree. They are Rampart's own
marks, not anyone's trademark. A framework that is installed (not built in) is drawn in teal with dark letters, and the file
switches to the lighter teal of the dark theme by itself when the viewer's system is in dark mode.

The screens draw a logo from a framework's `logoUrl` when it has one, and from the same shape table when it does not, so a framework
looks the same either way, but with a `logoUrl` the mark is data that comes from the resource, not something built into the screens.
`--check` writes nothing and fails if a file is out of date. Usage: scripts/marks.py <path to a Rampart checkout> [--check]"""
import pathlib
import re
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "logos"

SVG = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="64" height="64" role="img">
<title>{title}</title>
<style>.m{{fill:#19c3a6}}.t{{fill:#141922}}@media (prefers-color-scheme:dark){{.m{{fill:#2dd4bf}}}}</style>
<path class="m" d="{d}"/>
<text class="t" x="16" y="16" text-anchor="middle" dominant-baseline="central" font-size="{size}" font-weight="700" letter-spacing="-0.2" font-family="system-ui,-apple-system,'Segoe UI',Roboto,sans-serif">{label}</text>
</svg>
"""


def fail(msg):
    sys.exit(f"marks.py: {msg}")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if len(args) != 1:
        fail("usage: scripts/marks.py <path to a Rampart checkout> [--check]")
    tsx = (pathlib.Path(args[0]) / "web/src/components/FrameworkMark.tsx").read_text()
    shapes = {m.group(1): (m.group(2), m.group(3), m.group(4)) for m in re.finditer(r"^\s*(\w+): \{ label: '([^']*)', size: ([\d.]+), d: '([^']+)' \}", tsx, flags=re.M)}
    rules = re.findall(r"id\.startsWith\('([^']+)'\)\) return '(\w+)'", tsx)
    if not shapes or not rules:
        fail("could not read the shape table or the family rules of FrameworkMark.tsx")

    def family(fid):
        for prefix, fam in rules:
            if fid.startswith(prefix):
                return fam
        return "custom"

    want = {}
    for p in sorted((ROOT / "frameworks").glob("*.yaml")):
        f = yaml.safe_load(p.read_text())
        fam = family(f["id"])
        if fam == "custom" or fam not in shapes:
            fail(f"{f['id']} has no family in FrameworkMark.tsx: add one there, then run this again")
        label, size, d = shapes[fam]
        title = f["displayName"].replace("&", "and").replace("<", "").replace(">", "")
        want[OUT / f"{f['id']}.svg"] = SVG.format(title=title, d=d, size=size, label=label)
    stale = [p for p, t in want.items() if not p.exists() or p.read_text() != t]
    stale += [p for p in OUT.glob("*.svg") if p not in want]
    if "--check" in sys.argv:
        if stale:
            fail("out of date, run scripts/marks.py <rampart checkout>: " + ", ".join(p.name for p in stale))
        print(f"checked {len(want)} marks")
        return
    OUT.mkdir(exist_ok=True)
    for p, t in want.items():
        p.write_text(t)
    for p in OUT.glob("*.svg"):
        if p not in want:
            p.unlink()
    print(f"wrote {len(want)} marks")


main()
