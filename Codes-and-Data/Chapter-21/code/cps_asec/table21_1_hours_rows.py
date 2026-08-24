"""Produce the two "Hours worked" rows of Table 21.1, exactly as printed.

Run from this directory, after downloading and unzipping asecpub23csv.zip
here (see README.md):

    python table21_1_hours_rows.py

Entries are each group's mean annual hours relative to the overall mean,
so 1.00 is the average and the five quintiles sum to 5 — the same
convention as the earnings, income and wealth rows above them. Both rows
cover the whole population, non-workers included.
"""
import numpy as np
import pandas as pd

GROUPS = [("0-1", 0, 1), ("1-5", 1, 5), ("5-10", 5, 10), ("0-20", 0, 20),
          ("20-40", 20, 40), ("40-60", 40, 60), ("60-80", 60, 80),
          ("80-100", 80, 100), ("90-95", 90, 95), ("95-99", 95, 99),
          ("99-100", 99, 100)]


def ratios(hours, weight):
    """Group mean / overall mean, with fractional weight at the edges."""
    o = np.argsort(hours, kind="stable")
    x, w = np.asarray(hours, float)[o], np.asarray(weight, float)[o]
    cum = np.cumsum(w)
    tot = cum[-1]
    lo = np.concatenate([[0.0], cum[:-1]]) / tot * 100.0
    hi = cum / tot * 100.0
    grand = np.sum(w * x) / tot
    out = {}
    for name, a, b in GROUPS:
        share = np.clip(np.minimum(hi, b) - np.maximum(lo, a), 0, None) \
            / 100.0 * tot
        out[name] = (np.sum(share * x) / share.sum()) / grand
    return out, grand, tot


def gini(hours, weight):
    o = np.argsort(hours, kind="stable")
    x, w = np.asarray(hours, float)[o], np.asarray(weight, float)[o]
    p = np.concatenate([[0], np.cumsum(w) / w.sum()])
    L = np.concatenate([[0], np.cumsum(w * x) / np.sum(w * x)])
    return 1 - np.sum((p[1:] - p[:-1]) * (L[1:] + L[:-1]))


pp = pd.read_csv("pppub23.csv",
                 usecols=["PH_SEQ", "A_AGE", "MARSUPWT", "HRSWK", "WKSWORK"],
                 dtype=np.float64)
pp["MARSUPWT"] /= 100.0
pp["hours"] = pp["HRSWK"] * pp["WKSWORK"]

hh = pd.read_csv("hhpub23.csv", usecols=["H_SEQ", "HSUP_WGT"],
                 dtype=np.float64)
hh["HSUP_WGT"] /= 100.0

adults = pp[pp.A_AGE >= 16]
hholds = (pp.groupby("PH_SEQ", as_index=False)["hours"].sum()
          .merge(hh, left_on="PH_SEQ", right_on="H_SEQ", how="inner")
          .query("HSUP_WGT > 0"))

rows = [("per person", adults["hours"], adults["MARSUPWT"]),
        ("per household", hholds["hours"], hholds["HSUP_WGT"])]

names = [g for g, _, _ in GROUPS]
print("Table 21.1, Hours worked (1.00 = the average)\n")
print(f"{'':<16}" + "".join(f"{g:>8}" for g in names) + f"{'Gini':>8}")
latex = []
for label, x, w in rows:
    r, mean, n = ratios(x, w)
    g = gini(x, w)
    print(f"{label:<16}" + "".join(f"{r[k]:>8.2f}" for k in names)
          + f"{g:>8.2f}")
    q = sum(r[k] for k in ("0-20", "20-40", "40-60", "60-80", "80-100"))
    assert abs(q - 5) < 1e-6, f"quintiles sum to {q}, must be 5"
    latex.append(f"        \\quad {label} & "
                 + " & ".join(f"${r[k]:.2f}$" for k in names)
                 + f" & ${g:.2f}$ \\\\")
    print(f"{'':<16}mean {mean:,.0f} hours over {n/1e6:,.1f} million units")

print("\nLaTeX:\n" + "\n".join(latex))
