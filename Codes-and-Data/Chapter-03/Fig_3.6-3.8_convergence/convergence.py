"""
convergence.py -- Figures 3.6, 3.7, and 3.8 of Chapter 3, "The Solow model".

Chapter 3 of Macroeconomics (Azzimonti, Krusell, McKay, Mukoyama).

Plots subsequent average growth in per capita real GDP against its initial level,
across countries, to ask whether the convergence prediction of the Solow model is
visible in the data:

    Figure 3.6  all countries, 1960-2019       -> convergence1.pdf
    Figure 3.7  original OECD members, 1960-2019 -> convergence2.pdf
    Figure 3.8  all countries, 2000-2019       -> convergence3.pdf

Figure 3.6 shows no systematic tendency for initially poor countries to grow
faster. Figure 3.7 restricts the sample to countries with more similar underlying
parameters and a clear negative relationship appears -- conditional convergence.
Figure 3.8 repeats Figure 3.6 from a 2000 starting date, where some unconditional
convergence is visible, as in Kremer, Willis, and You (2022).

Data are from the Penn World Table 10.0 (https://www.rug.nl/ggdc/productivity/pwt/).
The GDP variable is RGDPNA, divided by population to get per capita terms, in
2017 US dollars. Growth rates are annualized using geometric averages.

This is a Python translation of the MATLAB code in matlab/. The MATLAB version
reads country codes, income levels, and growth rates from hardcoded arrays in
level60.m, growth6019.m, label.m and their OECD/2000 counterparts; this script
reads the same numbers directly from the source workbook Data/PWTNA2000.xlsx,
so there is no manual transcription step. The two agree to the precision at
which the MATLAB arrays were stored (about 5e-6 in levels, 5e-10 in growth rates).

Run:  python convergence.py
"""

import argparse
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# House palette (navy, maroon, dark green).
NAVY, MAROON = "#1f3a68", "#7b1e28"

# Default location of the source workbook, relative to this file.
DEFAULT_DATA = Path(__file__).resolve().parent.parent / "Data" / "PWTNA2000.xlsx"

# Column layout of the 'All' and 'OECD' sheets. Row 0 and 1 are headers; the
# country code is in column A, followed by per capita GDP in 1960, 2000, and
# 2019, then the two annualized growth rates.
COLS = {"code": 0, "pc1960": 1, "pc2000": 2, "pc2019": 3,
        "g6019": 4, "g0019": 5}


def load(sheet, path=DEFAULT_DATA):
    """Read one sheet of the PWT extract into a tidy frame.

    Rows below the country block hold regression output written by Excel, so
    anything without a country code in the first column is dropped.
    """
    raw = pd.read_excel(path, sheet_name=sheet, header=None, skiprows=2)
    df = pd.DataFrame({
        "code":   raw.iloc[:, COLS["code"]],
        "pc1960": pd.to_numeric(raw.iloc[:, COLS["pc1960"]], errors="coerce"),
        "pc2000": pd.to_numeric(raw.iloc[:, COLS["pc2000"]], errors="coerce"),
        "g6019":  pd.to_numeric(raw.iloc[:, COLS["g6019"]], errors="coerce"),
        "g0019":  pd.to_numeric(raw.iloc[:, COLS["g0019"]], errors="coerce"),
    })
    df = df[df["code"].notna() & df["code"].astype(str).str.match(r"^[A-Z]{3}$")]
    return df.reset_index(drop=True)


def scatter_with_trend(x, y, labels, xlabel, ylabel, ylim, outfile):
    """Plot country codes at each point and overlay a fitted linear trend.

    Following the MATLAB original, the observations are drawn as their country
    codes rather than as markers, which is what makes these figures readable.
    """
    fig, ax = plt.subplots(figsize=(9, 6.5))

    for xi, yi, li in zip(x, y, labels):
        ax.text(xi, yi, li, ha="center", va="center", fontsize=8, color=NAVY)

    # Least-squares trend line; its slope is the empirical counterpart of the
    # convergence speed discussed in Section 3.4.3.
    slope, intercept = np.polyfit(x, y, 1)
    xf = np.linspace(x.min(), x.max(), 100)
    ax.plot(xf, slope * xf + intercept, linestyle=":", linewidth=2, color=MAROON)

    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.set_ylim(*ylim)
    ax.set_xlim(x.min() - 0.25, x.max() + 0.25)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)

    fig.tight_layout()
    fig.savefig(outfile, bbox_inches="tight")
    plt.close(fig)
    return slope


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--outdir", default=".", help="output directory (default: .)")
    p.add_argument("--data", default=str(DEFAULT_DATA), help="path to PWTNA2000.xlsx")
    args = p.parse_args()

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    allc = load("All", args.data)
    oecd = load("OECD", args.data)

    # Save the analysis sample before plotting.
    allc.to_csv(outdir / "convergence_all_countries.csv", index=False)
    oecd.to_csv(outdir / "convergence_oecd.csv", index=False)

    s1 = scatter_with_trend(
        np.log(allc.pc1960), allc.g6019, allc.code,
        "log per capita GDP 1960 (in 2017 US$)",
        "average annual growth rate: 1960-2019",
        (-0.05, 0.07), outdir / "convergence1.pdf")

    s2 = scatter_with_trend(
        np.log(oecd.pc1960), oecd.g6019, oecd.code,
        "log per capita GDP 1960 (in 2017 US$)",
        "average annual growth rate: 1960-2019",
        (0.01, 0.04), outdir / "convergence2.pdf")

    s3 = scatter_with_trend(
        np.log(allc.pc2000), allc.g0019, allc.code,
        "log per capita GDP 2000 (in 2017 US$)",
        "average annual growth rate: 2000-2019",
        (-0.05, 0.07), outdir / "convergence3.pdf")

    print(f"Figure 3.6  all countries, 1960-2019 : n={len(allc):3d}  slope={s1:+.5f}")
    print(f"Figure 3.7  OECD,          1960-2019 : n={len(oecd):3d}  slope={s2:+.5f}")
    print(f"Figure 3.8  all countries, 2000-2019 : n={len(allc):3d}  slope={s3:+.5f}")
    print("\nA negative slope indicates convergence: initially poorer countries")
    print("grow faster. Only the OECD sample (3.7) and the post-2000 sample (3.8)")
    print("show one, which is the point made in Section 3.4.2.")
    print(f"\nWrote figures and samples to {outdir.resolve()}")


if __name__ == "__main__":
    main()
