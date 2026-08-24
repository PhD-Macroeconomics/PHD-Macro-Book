"""Figure 21.7 — wealth-to-income and capital-to-GDP ratios, by SCF wave.

Run from the repository root:

    python code/figures_python/fig21_07_wealth_income_ratios.py

Inputs
    data/figure21_7_data.csv   the three plotted series, by SCF wave
    data/fred/*.csv            FRED downloads, so the capital series can
                               be recomputed from scratch (optional)
Output
    figures/fig21_07_draft_style.pdf   (also .eps and .png)

This draws the same three series as the published figure, but in the
earlier unconstrained style. The figure that appears in the book is
produced by fig21_07_exact_geometry.py, which is built to the printed
artwork's measured geometry; this script writes to its own filename so
that running it cannot overwrite the published figure. Use this one to
check the data — it is where the capital series is documented and
recomputable — and that one to regenerate the exhibit.

The capital-to-GDP series is the CURRENT-COST measure, BEA net stock of
fixed assets over nominal GDP: FRED `K1WTOTL1ES000` (millions) divided
by `GDPA` (billions). This is the same basis as Figure 2.2 of Chapter 2,
so the two chapters agree. Pass --recompute to rebuild it from
data/fred/ rather than reading the stored column.

The two wealth-to-income series are produced by the SCF pipeline
(`code/scf_stata/wealth_capital_income_ratios.do`); they are stored in
the CSV here because that pipeline needs the full SCF wave files, which
are too large to ship. See the note in README.md.
"""
import sys
import os
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA = os.path.join(ROOT, "data")
FIGS = os.path.join(ROOT, "figures")

d = pd.read_csv(os.path.join(DATA, "figure21_7_data.csv"))
years = d["year"].tolist()
scf = d["scf"].tolist()
fn = d["fa_nipa"].tolist()
cap = d["capital_gdp_currentcost"].tolist()

if "--recompute" in sys.argv:
    def fred(name):
        f = pd.read_csv(os.path.join(DATA, "fred", name + ".csv"))
        f["y"] = pd.to_datetime(f["observation_date"]).dt.year
        return pd.to_numeric(f[name], errors="coerce").groupby(f["y"]).mean()

    k = fred("K1WTOTL1ES000") / 1000.0     # $m -> $bn
    y = fred("GDPA")                        # $bn
    cap = [float(k[t] / y[t]) for t in years]
    print("capital series recomputed from data/fred/:")
    print("  " + "  ".join(f"{t}:{v:.2f}" for t, v in zip(years, cap)))

plt.rcParams.update({"font.family": "serif", "font.size": 8,
                     "axes.linewidth": 0.6})
fig, ax = plt.subplots(figsize=(4.6, 2.3), dpi=400)
BLACK, GREY = "#211f20", "#949599"

ax.plot(years, scf, color=BLACK, lw=1.5, label="Wealth-to-income ratio (SCF)")
ax.plot(years, fn, color=GREY, lw=1.5,
        label="Wealth-to-income ratio (FA & NIPA)")
ax.plot(years, cap, color=BLACK, lw=1.0, dashes=(6.6, 1.6, 1.0, 1.6),
        label="Capital-to-GDP ratio")

ax.set_ylim(2.8, 8.05)
ax.set_yticks(range(3, 9))
ax.set_xlim(1988, 2023.5)
ax.set_xticks(range(1990, 2021, 5))
ax.set_ylabel("Ratio", fontsize=8)
ax.tick_params(labelsize=7.5, length=2.5, width=0.6)
for s in ("top", "right"):
    ax.spines[s].set_visible(False)
ax.legend(loc="upper left", frameon=False, fontsize=7.5, handlelength=2.6,
          borderpad=0.1, labelspacing=0.28, handletextpad=0.6)
fig.tight_layout(pad=0.35)

os.makedirs(FIGS, exist_ok=True)
for ext in ("pdf", "eps", "png"):
    fig.savefig(os.path.join(FIGS, f"fig21_07_draft_style.{ext}"),
                bbox_inches="tight", pad_inches=0.02)
print("wrote figures/fig21_07_draft_style.{pdf,eps,png}")
