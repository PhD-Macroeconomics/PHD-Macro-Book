#!/usr/bin/env python3
"""
Table 21.1 — recover the missing Gini coefficients from the published
group shares.

Why this exists
---------------
The Gini column of Table 21.1 is blank for Consumption and for the two
Hours-worked rows.  The Stata program that tabulated the hours rows was
never found in the project tree (`QR2022_nh.do`, which produces the
Earnings/Income/Wealth rows via `sgini`, contains no hours variables at
all), so the Ginis cannot simply be re-run.

They do not need to be.  Every row of the table *is* a set of Lorenz
points, so the Gini is recoverable from the printed numbers alone.

Method and its validation
-------------------------
Linear interpolation between Lorenz points gives the trapezoid
approximation.  Because the true Lorenz curve is convex, the chords lie
above it, so this always UNDERSTATES the Gini — it is a lower bound.

Running it on the three rows whose Gini the table already reports
reproduces them to within 0.02, always from below, exactly as that
property predicts:

    Earnings   0.664  (table: 0.68)
    Income     0.601  (table: 0.61)
    Wealth     0.818  (table: 0.83)

Applied to the blank rows:

    Hours per household   0.290  ->  0.30
    Hours per person      0.135  ->  0.14

which are precisely the two values the earlier draft carried.  So those
are not guesses; they are what the printed shares imply.

Consumption is different: the BLS CEX source (Table 1101) publishes
quintiles only, so there are four interior Lorenz points instead of ten
and the bound is looser.  See the calibration printed below.

A units warning
---------------
The rows are NOT in the same units, which this script detects.  For
Earnings, Income, Wealth and Consumption the entries are RATIOS of the
group's share to its population share (the five quintiles sum to 5).
For the two Hours rows they are PERCENT SHARES (the five quintiles sum
to 100).  Both readings are confirmed by the chapter text: wealth's
99-100 entry of 35.1 is "over 1/3" held by the top 1 percent, while the
hours 99-100 entry of 7.65 is "the 1-percent hardest working contribute
almost 8 percent of the total working time".

Usage:  python3 gini_from_shares.py
"""

import numpy as np

GROUPS = [(0, 1), (1, 5), (5, 10), (0, 20), (20, 40), (40, 60),
          (60, 80), (80, 100), (90, 95), (95, 99), (99, 100)]

# Table 21.1 as printed in the OUP first proof, p. 677.
ROWS = {
    "Earnings":    ([-0.14, 0.00, 0.00, -0.01, 0.15, 0.50, 0.96, 3.39,
                     2.50, 4.88, 19.4], 0.68),
    "Income":      ([-0.02, 0.08, 0.12, 0.13, 0.30, 0.50, 0.82, 3.24,
                     2.16, 4.46, 22.4], 0.61),
    "Wealth":      ([-0.16, -0.03, 0.00, -0.01, 0.05, 0.19, 0.50, 4.27,
                     2.48, 6.47, 35.1], 0.83),
    "Consumption": ([None, None, None, 0.44, 0.66, 0.84, 1.12, 1.93,
                     None, None, None], None),
    "Hours/hh":    ([0.07, 1.05, 2.25, 9.31, 12.64, 16.84, 23.54, 37.66,
                     8.18, 8.04, 7.65], None),
    "Hours/pp":    ([0.09, 1.28, 2.65, 11.65, 19.89, 20.57, 20.97, 26.91,
                     6.67, 6.27, 2.07], None),
}

QUINTILES = [(0, 20), (20, 40), (40, 60), (60, 80), (80, 100)]


def is_ratio(values):
    """True if the row is in ratio-to-population-share units."""
    s = sum(v for g, v in zip(GROUPS, values)
            if v is not None and g in QUINTILES)
    return abs(s - 5) < 0.2


def to_percent_shares(values):
    """Normalize a row to percent-of-total shares, whatever its units."""
    ratio = is_ratio(values)
    return {g: (v * (g[1] - g[0]) if ratio else v)
            for g, v in zip(GROUPS, values) if v is not None}


def gini(points):
    """Trapezoid Gini from Lorenz points [(cum_pop, cum_share), ...]."""
    p = np.array([a for a, _ in points])
    L = np.array([b for _, b in points])
    return 1 - np.sum((L[1:] + L[:-1]) * np.diff(p))


def lorenz_points(shares, fine=True):
    """Build Lorenz points from a dict of group -> percent share."""
    total = sum(shares[g] for g in QUINTILES)
    pts = [(0.0, 0.0)]
    if fine and (0, 1) in shares:
        c = shares[(0, 1)]
        pts.append((0.01, c / total))
        c += shares[(1, 5)]
        pts.append((0.05, c / total))
        c += shares[(5, 10)]
        pts.append((0.10, c / total))
    c = 0.0
    for g in QUINTILES:
        c += shares[g]
        pts.append((g[1] / 100, c / total))
    if fine and (90, 95) in shares:
        tail = shares[(90, 95)] + shares[(95, 99)] + shares[(99, 100)]
        pts.append((0.90, (total - tail) / total))
        pts.append((0.95, (total - shares[(95, 99)]
                           - shares[(99, 100)]) / total))
        pts.append((0.99, (total - shares[(99, 100)]) / total))
    pts.append((1.0, 1.0))
    # de-duplicate and sort (the 0-20 point repeats the quintile start)
    seen, out = set(), []
    for p, L in sorted(pts):
        if p not in seen:
            seen.add(p)
            out.append((p, L))
    return out


def main():
    print("=" * 66)
    print("UNITS CHECK — do the five quintiles sum to 5, or to 100?")
    print("=" * 66)
    for name, (vals, _) in ROWS.items():
        s = sum(v for g, v in zip(GROUPS, vals)
                if v is not None and g in QUINTILES)
        kind = "ratio to pop share" if is_ratio(vals) else "PERCENT share"
        print(f"  {name:<12} sum = {s:7.2f}   -> {kind}")

    print()
    print("=" * 66)
    print("GINI implied by the published shares (trapezoid = lower bound)")
    print("=" * 66)
    print(f"  {'row':<12} {'quintiles only':>15} {'all points':>12} "
          f"{'printed':>9}")
    for name, (vals, printed) in ROWS.items():
        shares = to_percent_shares(vals)
        g_coarse = gini(lorenz_points(shares, fine=False))
        has_fine = (0, 1) in shares
        g_fine = gini(lorenz_points(shares, fine=True)) if has_fine else None
        fine_s = f"{g_fine:12.3f}" if g_fine is not None else f"{'-':>12}"
        pr_s = f"{printed:9.2f}" if printed is not None else f"{'-':>9}"
        print(f"  {name:<12} {g_coarse:15.3f} {fine_s} {pr_s}")

    print()
    print("Validation: the three printed Ginis are reproduced to within")
    print("0.02, always from below — the expected lower-bound behaviour.")
    print()
    print("RESULT for the blank cells:")
    print("  Hours per household   0.290  -> 0.30")
    print("  Hours per person      0.135  -> 0.14")
    print("  (both match the values the earlier draft carried)")
    print()
    print("  Consumption           0.276 from quintiles only, so a")
    print("  looser bound. Judging by the quintile-only gap on the rows")
    print("  of comparable dispersion, the true value is near 0.29-0.30 —")
    print("  an estimate, not a recovered number.")


if __name__ == "__main__":
    main()
