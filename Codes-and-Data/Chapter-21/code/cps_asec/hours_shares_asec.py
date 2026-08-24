"""
Table 21.1 hours rows from CPS ASEC 2023 (calendar year 2022).

Source : https://www2.census.gov/programs-surveys/cps/datasets/2023/march/
         asecpub23csv.zip  (public use, no registration)
Layout : asec2023_ddl_pub_full.pdf / persfmt.txt

Annual hours = HRSWK (usual hours per week last year)
             x WKSWORK (weeks worked last year)
which is the raw-Census equivalent of the IPUMS construction
UHRSWORKLY x WKSWORK1 used by Boppart-Krusell-Olsson (2024, Table 3).

Weights: MARSUPWT (person, ASEC supplement) and HSUP_WGT (household).
Both carry two implied decimals in the public-use CSV.
"""

import numpy as np
import pandas as pd

PP = "pppub23.csv"
HH = "hhpub23.csv"

# 11 groups of Table 21.1: (label, lower pct, upper pct)
GROUPS = [
    ("0-1",     0.0,   1.0),
    ("1-5",     1.0,   5.0),
    ("5-10",    5.0,  10.0),
    ("0-20",    0.0,  20.0),
    ("20-40",  20.0,  40.0),
    ("40-60",  40.0,  60.0),
    ("60-80",  60.0,  80.0),
    ("80-100", 80.0, 100.0),
    ("90-95",  90.0,  95.0),
    ("95-99",  95.0,  99.0),
    ("99-100", 99.0, 100.0),
]


def weighted_shares(x, w, groups=GROUPS):
    """Percent of total weighted x held by each percentile group,
    where units are sorted by x ascending and percentiles are of the
    weighted population."""
    order = np.argsort(x, kind="mergesort")
    x, w = np.asarray(x)[order], np.asarray(w)[order]
    cw = np.cumsum(w)
    total_w = cw[-1]
    # population percentile at the *midpoint* of each unit's weight mass
    pct = 100.0 * (cw - 0.5 * w) / total_w
    total_x = np.sum(w * x)
    out = {}
    for label, lo, hi in groups:
        m = (pct >= lo) & (pct < hi) if hi < 100 else (pct >= lo)
        out[label] = 100.0 * np.sum(w[m] * x[m]) / total_x
    return out


def gini(x, w):
    order = np.argsort(x, kind="mergesort")
    x, w = np.asarray(x, float)[order], np.asarray(w, float)[order]
    cw = np.cumsum(w)
    cx = np.cumsum(w * x)
    if cx[-1] == 0:
        return np.nan
    # trapezoid on the Lorenz curve
    p = np.concatenate([[0.0], cw / cw[-1]])
    L = np.concatenate([[0.0], cx / cx[-1]])
    return float(1.0 - np.sum((p[1:] - p[:-1]) * (L[1:] + L[:-1])))


def fmt(d, gi=None):
    cells = "".join(f"{d[g]:>8.2f}" for g, _, _ in GROUPS)
    return cells + (f"{gi:>8.2f}" if gi is not None else "        ")


print("reading person file ...")
pp = pd.read_csv(
    PP,
    usecols=["PH_SEQ", "PPPOS", "A_AGE", "A_SEX", "MARSUPWT",
             "HRSWK", "WKSWORK", "WSAL_VAL", "PEARNVAL"],
    dtype=np.float64,
)
pp["MARSUPWT"] = pp["MARSUPWT"] / 100.0

# HRSWK / WKSWORK are 0 for non-workers; no NIU sentinel in the public file
pp["hours"] = pp["HRSWK"] * pp["WKSWORK"]

print("reading household file ...")
hh = pd.read_csv(HH, usecols=["H_SEQ", "HSUP_WGT"], dtype=np.float64)
hh["HSUP_WGT"] = hh["HSUP_WGT"] / 100.0

# ---------------------------------------------------------------- household
hhh = pp.groupby("PH_SEQ", as_index=False)["hours"].sum()
hhh = hhh.merge(hh, left_on="PH_SEQ", right_on="H_SEQ", how="inner")
hhh = hhh[hhh["HSUP_WGT"] > 0]

# ------------------------------------------------------------------- person
# adults; "per person" in the table is the working-age individual measure
ad = pp[(pp["A_AGE"] >= 16) & (pp["MARSUPWT"] > 0)]

print()
hdr = "".join(f"{g:>8}" for g, _, _ in GROUPS) + f"{'Gini':>8}"
print(" " * 42 + hdr)

PRINTED_HH = [0.07, 1.05, 2.25, 9.31, 12.64, 16.84, 23.54, 37.66, 8.18, 8.04, 7.65]
PRINTED_PP = [0.09, 1.28, 2.65, 11.65, 19.89, 20.57, 20.97, 26.91, 6.67, 6.27, 2.07]
print(f"{'PRINTED  per household':<42}" + "".join(f"{v:>8.2f}" for v in PRINTED_HH))
print(f"{'PRINTED  per person':<42}" + "".join(f"{v:>8.2f}" for v in PRINTED_PP))
print()

variants = [
    ("household, all households",
     hhh["hours"].values, hhh["HSUP_WGT"].values),
    ("household, hours > 0 only",
     hhh.loc[hhh.hours > 0, "hours"].values,
     hhh.loc[hhh.hours > 0, "HSUP_WGT"].values),
    ("person 16+, all",
     ad["hours"].values, ad["MARSUPWT"].values),
    ("person 16+, hours > 0 only",
     ad.loc[ad.hours > 0, "hours"].values,
     ad.loc[ad.hours > 0, "MARSUPWT"].values),
    ("person 25-54, hours > 0 only",
     pp.loc[(pp.A_AGE.between(25, 54)) & (pp.hours > 0), "hours"].values,
     pp.loc[(pp.A_AGE.between(25, 54)) & (pp.hours > 0), "MARSUPWT"].values),
    ("person 25-54 male, hours > 0 (BKO sample)",
     pp.loc[(pp.A_AGE.between(25, 54)) & (pp.A_SEX == 1) & (pp.hours > 0), "hours"].values,
     pp.loc[(pp.A_AGE.between(25, 54)) & (pp.A_SEX == 1) & (pp.hours > 0), "MARSUPWT"].values),
]

for name, x, w in variants:
    print(f"{name:<42}" + fmt(weighted_shares(x, w), gini(x, w)))

# --- hours shares when households are sorted by EARNINGS, not by hours -----
print()
earn = pp.groupby("PH_SEQ", as_index=False).agg(
    hours=("hours", "sum"), earn=("PEARNVAL", "sum"))
earn = earn.merge(hh, left_on="PH_SEQ", right_on="H_SEQ", how="inner")
earn = earn[earn["HSUP_WGT"] > 0]


def shares_sorted_by(sortvar, valvar, w, groups=GROUPS):
    order = np.argsort(sortvar, kind="mergesort")
    s, v, w = (np.asarray(a)[order] for a in (sortvar, valvar, w))
    cw = np.cumsum(w)
    pct = 100.0 * (cw - 0.5 * w) / cw[-1]
    tot = np.sum(w * v)
    return {lab: 100.0 * np.sum(w[(pct >= lo) & ((pct < hi) if hi < 100 else True)]
                                * v[(pct >= lo) & ((pct < hi) if hi < 100 else True)]) / tot
            for lab, lo, hi in groups}

print(f"{'household hours, SORTED BY EARNINGS':<42}"
      + fmt(shares_sorted_by(earn["earn"].values, earn["hours"].values,
                             earn["HSUP_WGT"].values)))

# sanity: quintiles must sum to 100
q = ["0-20", "20-40", "40-60", "60-80", "80-100"]
print()
for name, x, w in variants:
    d = weighted_shares(x, w)
    print(f"  quintile sum check, {name:<42} {sum(d[k] for k in q):8.2f}")

print()
print("mean annual hours, working households :",
      round(np.average(hhh.loc[hhh.hours > 0, "hours"],
                       weights=hhh.loc[hhh.hours > 0, "HSUP_WGT"]), 1))
print("mean annual hours, workers 16+        :",
      round(np.average(ad.loc[ad.hours > 0, "hours"],
                       weights=ad.loc[ad.hours > 0, "MARSUPWT"]), 1))
print("share of households with zero hours   :",
      round(100 * hhh.loc[hhh.hours == 0, "HSUP_WGT"].sum()
            / hhh["HSUP_WGT"].sum(), 2), "%")
print("share of persons 16+ with zero hours  :",
      round(100 * ad.loc[ad.hours == 0, "MARSUPWT"].sum()
            / ad["MARSUPWT"].sum(), 2), "%")
