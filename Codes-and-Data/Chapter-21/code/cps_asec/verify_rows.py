"""SECOND READ: recompute the two hours rows by an independent route.

Deliberately does NOT import the original module. Ratios are computed
as (group mean hours) / (overall mean hours), which is the definition
of "relative to the average", rather than as share/population-share.
The two must agree exactly; if they do not, one of them is wrong.
"""
import numpy as np
import pandas as pd

pp = pd.read_csv("pppub23.csv",
                 usecols=["PH_SEQ", "A_AGE", "MARSUPWT", "HRSWK", "WKSWORK"],
                 dtype=np.float64)
pp["MARSUPWT"] /= 100.0
pp["h"] = pp["HRSWK"] * pp["WKSWORK"]
hh = pd.read_csv("hhpub23.csv", usecols=["H_SEQ", "HSUP_WGT"], dtype=np.float64)
hh["HSUP_WGT"] /= 100.0

adults = pp[pp.A_AGE >= 16][["h", "MARSUPWT"]].to_numpy()
hholds = (pp.groupby("PH_SEQ", as_index=False)["h"].sum()
          .merge(hh, left_on="PH_SEQ", right_on="H_SEQ")
          .query("HSUP_WGT > 0")[["h", "HSUP_WGT"]].to_numpy())

BOUNDS = [("0-1", 0, 1), ("1-5", 1, 5), ("5-10", 5, 10), ("0-20", 0, 20),
          ("20-40", 20, 40), ("40-60", 40, 60), ("60-80", 60, 80),
          ("80-100", 80, 100), ("90-95", 90, 95), ("95-99", 95, 99),
          ("99-100", 99, 100)]


def rows(a):
    """a[:,0]=hours a[:,1]=weight. Returns group-mean / overall-mean."""
    a = a[np.argsort(a[:, 0], kind="stable")]
    x, w = a[:, 0], a[:, 1]
    cum = np.cumsum(w)
    tot = cum[-1]
    lo_edge = np.concatenate([[0.0], cum[:-1]]) / tot * 100.0
    hi_edge = cum / tot * 100.0
    grand = np.sum(w * x) / tot
    out = {}
    for name, lo, hi in BOUNDS:
        # weight of each unit that falls inside [lo,hi) of the population
        overlap = np.clip(np.minimum(hi_edge, hi) - np.maximum(lo_edge, lo),
                          0, None) / 100.0 * tot
        gw = overlap.sum()
        out[name] = (np.sum(overlap * x) / gw) / grand
    return out, grand, tot


def gini(a):
    a = a[np.argsort(a[:, 0], kind="stable")]
    x, w = a[:, 0].astype(float), a[:, 1].astype(float)
    cw = np.cumsum(w) / np.sum(w)
    cx = np.cumsum(w * x) / np.sum(w * x)
    p = np.concatenate([[0], cw]); L = np.concatenate([[0], cx])
    return 1 - np.sum((p[1:] - p[:-1]) * (L[1:] + L[:-1]))


ORIGINAL = {
    "per person":    [0.00, 0.00, 0.00, 0.00, 0.04, 1.18, 1.74, 2.04, 2.09, 2.40, 3.20],
    "per household": [0.00, 0.00, 0.00, 0.00, 0.41, 0.92, 1.49, 2.18, 2.15, 2.68, 3.83],
}
GINI0 = {"per person": 0.48, "per household": 0.46}

names = [n for n, _, _ in BOUNDS]
ok = True
for label, arr in [("per person", adults), ("per household", hholds)]:
    r, mean, tot = rows(arr)
    g = gini(arr)
    got = [r[n] for n in names]
    print(f"{label}")
    print("  recomputed :", "  ".join(f"{v:5.2f}" for v in got),
          f"  Gini {g:.3f}   mean {mean:,.0f}   N {tot/1e6:.1f}m")
    print("  first pass :", "  ".join(f"{v:5.2f}" for v in ORIGINAL[label]),
          f"  Gini {GINI0[label]:.2f}")
    d = max(abs(a - b) for a, b in zip(got, ORIGINAL[label]))
    dg = abs(g - GINI0[label])
    print(f"  max cell diff {d:.4f} | Gini diff {dg:.4f}"
          f" -> {'AGREE' if d < 0.006 and dg < 0.006 else 'MISMATCH'}")
    q = sum(r[n] for n in ("0-20", "20-40", "40-60", "60-80", "80-100"))
    print(f"  quintiles sum to {q:.4f} (must be 5)")
    ok &= d < 0.006 and dg < 0.006 and abs(q - 5) < 0.01
    print()

print("SECOND READ:", "PASSED" if ok else "FAILED")
