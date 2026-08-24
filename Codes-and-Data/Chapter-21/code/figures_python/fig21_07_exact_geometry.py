"""Figure 21.7, built to the printed figure's exact geometry.

THIS IS THE SCRIPT BEHIND THE PUBLISHED FIGURE. Run from anywhere:

    python code/figures_python/fig21_07_exact_geometry.py

Inputs
    data/figure21_7_data.csv   the three plotted series, by SCF wave
Output
    figures/fig21_07_wealth_income_ratios.pdf  (also .eps and .png)

Measured off proof p. 680 (folio 680):
    artwork bounding box   297.4 x 148.4 pt
    axes frame             x 147.5-423.1, y 441.8-574.1  (275.6 x 132.3)
    all four spines drawn (the printed figure is a full box)
    every label set at 8.0 pt

Output is therefore a 1:1 drop-in: no scaling, so the type stays at
8 pt and the line weights stay as drawn.

The provenance of the plotted series — in particular how the
capital-to-GDP column is built from the FRED downloads in data/fred/ —
is documented in fig21_07_wealth_income_ratios.py, which draws the same
three series in the earlier, unconstrained style.
"""
import os
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA = os.path.join(ROOT, "data")
FIGS = os.path.join(ROOT, "figures")

# artwork geometry, in points, from the proof
W, H = 297.4, 148.4
AX_L, AX_R = 147.5 - 125.7, 423.1 - 125.7      # 21.8, 297.4
AX_T, AX_B = 441.8 - 436.2, 584.6 - 574.1      # 5.6, 10.5

d = pd.read_csv(os.path.join(DATA, "figure21_7_data.csv"))
yrs = d["year"].tolist()
scf, fn = d["scf"].tolist(), d["fa_nipa"].tolist()
cap = d["capital_gdp_currentcost"].tolist()

plt.rcParams.update({
    "font.family": "serif",
    "font.serif": ["Nimbus Roman", "Times New Roman", "DejaVu Serif"],
    "font.size": 8.0,
    "axes.linewidth": 0.5,
    "pdf.fonttype": 42,      # embed TrueType, not Type3
    "ps.fonttype": 42,
})

fig = plt.figure(figsize=(W / 72.0, H / 72.0))
ax = fig.add_axes([AX_L / W, AX_B / H, (AX_R - AX_L) / W, 1 - (AX_T + AX_B) / H])

BLACK, GREY = "#231f20", "#949599"
ax.plot(yrs, scf, color=BLACK, lw=1.4, label="Wealth-to-income ratio (SCF)",
        solid_joinstyle="miter")
ax.plot(yrs, fn, color=GREY, lw=1.4,
        label="Wealth-to-income ratio (FA & NIPA)", solid_joinstyle="miter")
ax.plot(yrs, cap, color=BLACK, lw=0.9, dashes=(6.6, 1.6, 1.0, 1.6),
        label="Capital-to-GDP ratio")

ax.set_ylim(2.955, 8.060)   # matches the proof frame exactly
ax.set_yticks(range(3, 9))
ax.set_xlim(1988.15, 2023.05)
ax.set_xticks(range(1990, 2021, 5))
ax.set_ylabel("Ratio", fontsize=8.0, labelpad=2)
ax.tick_params(labelsize=8.0, length=2.2, width=0.5, direction="out",
               pad=2)
for sp in ax.spines.values():          # the printed figure is a full box
    sp.set_visible(True)
    sp.set_linewidth(0.5)
ax.legend(loc="upper left", frameon=False, fontsize=8.0, handlelength=2.5,
          borderpad=0.15, labelspacing=0.22, handletextpad=0.5,
          borderaxespad=0.25)

os.makedirs(FIGS, exist_ok=True)
for ext in ("pdf", "eps", "png"):
    fig.savefig(os.path.join(FIGS, f"fig21_07_wealth_income_ratios.{ext}"),
                dpi=1200)

print(f"target artwork size : {W:.1f} x {H:.1f} pt")
print("written             : figures/fig21_07_wealth_income_ratios"
      ".{pdf,eps,png}")
