#!/usr/bin/env python3
"""Derive the market-in-focus Portfolio chart from the Figma export.

Figma designs the Portfolio chart (174:110) with the portfolio line in focus:
dot grid and gradient fill under it, green above the dashed baseline and pink
below, the market line muted grey. There is no designed market-in-focus
version with the same treatment, so this swaps the roles using the export's
own paths, styles and dot-grid rule, recolouring the focus to the brand
accent (#5AA6DE, VistaColors.accent). The market page's pager dot is
recoloured to match. Run from app/:

    python3 tool/derive_market_focus_chart.py
"""
import re
from pathlib import Path

SRC = Path('assets/figma/portfolio_chart.svg')
OUT = Path('assets/figma/portfolio_chart_market_focus.svg')
DOTS = Path('assets/figma/pager_dots_market.svg')
MARKET = '#5AA6DE'  # VistaColors.accent
FIGMA_MARKET = '#9685E0'  # the purple Figma used for the market page

# Dot grid as found in the export: 14px lattice at x ≡ 9, y ≡ 5 (mod 14),
# kept where a dot sits more than GAP below the focus line and above the
# dashed baseline. This rule reproduces the export's 128 dots exactly.
GRID, X0, Y0, GAP = 14, 9, 5, 3.5
BASELINE_Y = 162.4

svg = SRC.read_text()


def path_d(node_id):
    return re.search(r'id="%s" d="([^"]+)"' % re.escape(node_id), svg).group(1)


def points(d):
    return [(float(x), float(y)) for x, y in re.findall(r'[ML]([\d.]+) ([\d.]+)', d)]


def y_at(pts, x):
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        if x0 <= x <= x1:
            return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    return None


def fmt(v):
    return ('%.2f' % v).rstrip('0').rstrip('.')


portfolio_d = path_d('portfolio line')
market_d = path_d('market line')
market = points(market_d)

# The export's fill path runs 5px right of its line and closes along the
# baseline; mirror that for the market line.
area_d = 'M' + 'L'.join(f'{fmt(x + 5)} {fmt(y)}' for x, y in market)
area_d += re.search(r'(V[\d.]+H[\d.]+Z)$', path_d('area gradient')).group(1)

dots = [
    (x, y)
    for x in range(X0, 381, GRID)
    for y in range(Y0, 176, GRID)
    if (ly := y_at(market, x)) is not None and ly + GAP < y < BASELINE_Y
]
lattice = '\n'.join(
    f'<circle cx="{x}" cy="{y}" r="1" fill="white" fill-opacity="0.18"/>'
    for x, y in dots
)

# Swap the roles of the two lines, keep everything else as exported.
out = svg
out = re.sub(
    r'(<g id="dot lattice[^"]*">).*?(</g>)',
    lambda m: m.group(1) + '\n' + lattice + '\n' + m.group(2),
    out,
    count=1,
    flags=re.S,
)
out = out.replace(f'id="market line" d="{market_d}"', f'id="portfolio line (muted)" d="{portfolio_d}"')
for node in ('area gradient', 'area gradient_2'):
    out = re.sub(r'(id="%s" d=")[^"]+"' % re.escape(node), lambda m: m.group(1) + area_d + '"', out)
for node, colour in (('portfolio line', MARKET), ('portfolio line_2', None)):
    out = re.sub(
        r'id="%s" d="[^"]+"( stroke="[^"]+")' % re.escape(node),
        lambda m, c=colour, n=node: f'id="{n.replace("portfolio", "market")}" d="{market_d}"'
        + (f' stroke="{c}"' if c else m.group(1)),
        out,
    )
# Focus fill above the baseline in the market colour; pink below is kept.
out = re.sub(
    r'(<linearGradient id="paint0_linear_0_18".*?</linearGradient>)',
    lambda m: m.group(1).replace('#34D399', MARKET),
    out,
    flags=re.S,
)
# Live dot moves to the market line's last point.
end_x, end_y = market[-1]
out = re.sub(r'(<circle id="Ellipse_129" cx=")[\d.]+(" cy=")[\d.]+', rf'\g<1>{fmt(end_x)}\g<2>{fmt(end_y)}', out)
out = re.sub(
    r'(<circle id="Ellipse_130" cx=")[\d.]+(" cy=")[\d.]+(" r="[\d.]+" fill=")#[0-9A-F]+',
    rf'\g<1>{fmt(end_x)}\g<2>{fmt(end_y)}\g<3>{MARKET}',
    out,
)

OUT.write_text(out)
print(f'wrote {OUT} ({len(dots)} grid dots)')

DOTS.write_text(DOTS.read_text().replace(FIGMA_MARKET, MARKET))
print(f'recoloured {DOTS}')
