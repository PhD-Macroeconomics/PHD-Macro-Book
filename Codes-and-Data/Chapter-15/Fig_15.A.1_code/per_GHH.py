"""
per_GHH.py -- Python translation of per_GHH.m

Chapter 15, "Government and public policies" (Azzimonti, Heathcote, Storesletten).

Computes the steady-state worker-capitalist model with GHH preferences and
produces the underlying data for:

  Figure 15.6  How allocations vary with tau_k   (panels A-D)
  Figure 15.8  The Laffer curve

Preferences are Greenwood-Hercowitz-Huffman,

    u(c, l) = log( c - l^(1 + 1/phi) / (1 + 1/phi) ),

so consumption drops out of the intratemporal first-order condition and there
are no wealth effects on labor supply. Every object below is a closed-form
steady-state expression -- there is no numerical solver in this file. The
transitional dynamics of Figure 15.7 are computed separately (WorkCap/).

Verified: reproduces the `tauk2` and `laffer` sheets of Govt_Chapter_Figures.xlsx
to machine precision (max abs. deviation ~4e-12).

Run:  python per_GHH.py            (writes CSVs + PDFs into the working directory)
"""

import argparse
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# House palette (navy, maroon, dark green). The book prints these figures in
# grayscale; fig6.py / fig8.py in the Codes-and-Data repo produce those versions.
NAVY, MAROON, DKGREEN = "#1f3a68", "#7b1e28", "#1d5c34"


# ----------------------------------------------------------------------------
# Calibration (Section 15.3.2 of the chapter)
# ----------------------------------------------------------------------------
ALPHA = 0.33   # capital share in Cobb-Douglas production
BETA  = 0.97   # household discount factor
DELTA = 0.07   # depreciation rate
PHI   = 1.00   # Frisch elasticity of labor supply
TAUC  = 0.00   # consumption tax, switched off to isolate tau_k vs tau_l
G     = 0.20   # government purchases as a share of output, G = g*Y


def steady_state(tauk, taul, alpha=ALPHA, beta=BETA, delta=DELTA,
                 phi=PHI, tauc=TAUC):
    """Closed-form steady state for given tax rates.

    Returns capital-labor ratio, hours, output, and the consumption of the two
    household types. Equation numbers refer to the chapter.
    """
    rho = (1.0 / beta) - 1.0                      # rate of time preference

    # Capital-labor ratio, equation (15.11). Higher tau_k depresses k/l.
    kl = (alpha * (1 - tauk) / (rho + delta * (1 - tauk))) ** (1 / (1 - alpha))

    # Hours: GHH labor supply depends only on the after-tax return to working.
    l = (((1 - taul) / (1 + tauc)) * (1 - alpha) * kl ** alpha) ** phi

    y = kl ** alpha * l                            # output, equation (15.13)

    # Workers earn labor income only; capitalists earn net rental income only.
    cw = ((1 - taul) / (1 + tauc)) * (1 - alpha) * y
    ck = (rho / (1 + tauc)) * (alpha * (1 - tauk) /
                               (rho + (1 - tauk) * delta)) * y
    return kl, l, y, cw, ck


def budget_balancing_taul(tauk, alpha=ALPHA, beta=BETA, delta=DELTA, g=G):
    """Labor tax that balances the government budget at a given tau_k.

    This is equation (15.14): the locus of (tau_l, tau_k) pairs delivering
    G/Y = g in steady state.
    """
    rho = (1.0 / beta) - 1.0
    return (1 / (1 - alpha)) * (g - tauk * rho *
                                (alpha / (rho + (1 - tauk) * delta)))


def figure_15_6_data(n_grid=101):
    """Panels A-D of Figure 15.6: allocations as tau_k varies over [0, 1].

    For each tau_k, tau_l adjusts via equation (15.14) to hold G/Y fixed at g.
    """
    # Zero-tax benchmark, used both as the "No taxes" line and as the reference
    # point for the excess-cost calculation.
    _, _, yz, cwz, ckz = steady_state(0.0, 0.0)
    ceqwz = cwz / (1 + PHI)   # consumption-equivalent flow utility of workers

    tauk = np.arange(n_grid) / (n_grid - 1)
    taul = np.empty(n_grid)
    cw = np.empty(n_grid)
    ck = np.empty(n_grid)
    exc = np.empty(n_grid)

    for j, tk in enumerate(tauk):
        tl = budget_balancing_taul(tk)
        _, _, y, cw_j, ck_j = steady_state(tk, tl)
        taul[j], cw[j], ck[j] = tl, cw_j, ck_j

        # Excess cost of taxation: private consumption (in utility units) lost
        # per dollar of public consumption financed. Workers' consumption is
        # scaled by 1/(1+phi) to net out the disutility of hours.
        #
        # At tau_k = 1 the capital-labor ratio -- and hence output -- collapses
        # to zero, so the ratio is +inf. MATLAB returns Inf here as well; the
        # point is off-scale in panel D (clipped at 200) either way.
        gy = G * y
        exc[j] = np.inf if gy == 0 else (
            (ceqwz - cw_j / (1 + PHI) + ckz - ck_j - gy) / gy)

    return pd.DataFrame({
        "tauk": tauk,
        "taul": taul,
        "cons_worker_tax": cw,
        "cons_worker_notax": cwz,     # flat reference line
        "cons_cap_tax": ck,
        "cons_cap_notax": ckz,        # flat reference line
        "excesscost": 100 * exc,      # cents per dollar of G
    })


def figure_15_8_data(n_grid=101):
    """Figure 15.8: steady-state labor tax revenue as tau_l varies, tau_k = 0.

    Revenue is hump-shaped: at tau_l = 0 nothing is levied, and as tau_l -> 1
    hours and output go to zero, so there is nothing left to tax. With GHH
    preferences the peak is at tau_l = 1/(1+phi).
    """
    taul = np.arange(n_grid) / (n_grid - 1)
    revenue = np.empty(n_grid)
    for j, tl in enumerate(taul):
        _, _, y, _, _ = steady_state(0.0, tl)
        revenue[j] = tl * (1 - ALPHA) * y
    return pd.DataFrame({"taul": taul, "revenue": revenue})


def plot_figure_15_6(df, outdir):
    fig, axes = plt.subplots(2, 2, figsize=(10, 7))

    ax = axes[0, 0]
    ax.plot(df.tauk, df.taul, color=NAVY, linewidth=2)
    ax.set_title(r"A. $\tau_\ell$")
    ax.set_xlabel(r"$\tau_k$")
    ax.set_xlim(0, 1)
    ax.set_ylim(-0.2, 0.4)

    ax = axes[0, 1]
    ax.plot(df.tauk, df.cons_worker_tax, color=NAVY, linewidth=2, label="Taxes")
    ax.plot(df.tauk, df.cons_worker_notax, color=MAROON, linewidth=2,
            linestyle="--", label="No taxes")
    ax.set_title("B. Worker consumption")
    ax.set_xlabel(r"$\tau_k$")
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 2)
    ax.legend(frameon=False, ncol=2, loc="upper center")

    ax = axes[1, 0]
    ax.plot(df.tauk, df.cons_cap_tax, color=NAVY, linewidth=2, label="Taxes")
    ax.plot(df.tauk, df.cons_cap_notax, color=MAROON, linewidth=2,
            linestyle="--", label="No taxes")
    ax.set_title("C. Capitalist consumption")
    ax.set_xlabel(r"$\tau_k$")
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 0.5)
    ax.legend(frameon=False, ncol=2, loc="upper center")

    ax = axes[1, 1]
    ax.plot(df.tauk, df.excesscost, color=DKGREEN, linewidth=2)
    ax.set_title("D. Excess cost of taxation")
    ax.set_xlabel(r"$\tau_k$")
    ax.set_ylabel(r"Cost per \$ of $G$")
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 200)

    for ax in axes.flat:                 # show axes only, no surrounding box
        ax.spines["top"].set_visible(False)
        ax.spines["right"].set_visible(False)

    fig.tight_layout()
    fig.savefig(Path(outdir) / "tauk.pdf", bbox_inches="tight")
    plt.close(fig)


def plot_figure_15_8(df, outdir):
    fig, ax = plt.subplots(figsize=(6, 4.5))
    ax.plot(df.taul, df.revenue, color=NAVY, linewidth=2)
    ax.set_xlabel(r"$\tau_\ell$")
    ax.set_ylabel("Tax revenue")
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 0.4)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    fig.tight_layout()
    fig.savefig(Path(outdir) / "Laffer.pdf", bbox_inches="tight")
    plt.close(fig)


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--outdir", default=".", help="output directory (default: .)")
    p.add_argument("--n-grid", type=int, default=101,
                   help="number of tax-rate grid points (default: 101)")
    p.add_argument("--no-plots", action="store_true",
                   help="write CSVs only, skip the figures")
    args = p.parse_args()

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    # Save the data before plotting so intermediate results survive on disk.
    d6 = figure_15_6_data(args.n_grid)
    d8 = figure_15_8_data(args.n_grid)
    d6.to_csv(outdir / "fig_15_6_data.csv", index=False)
    d8.to_csv(outdir / "fig_15_8_data.csv", index=False)

    if not args.no_plots:
        plot_figure_15_6(d6, outdir)
        plot_figure_15_8(d8, outdir)

    # Checks against numbers quoted in the text.
    peak = d8.taul[d8.revenue.idxmax()]
    exc20 = float(d6.loc[np.isclose(d6.tauk, 0.20), "excesscost"].iloc[0])
    print(f"Revenue-maximizing tau_l  = {peak:.2f}   [theory 1/(1+phi) = {1/(1+PHI):.2f}]")
    print(f"Peak labor tax revenue    = {d8.revenue.max():.4f}")
    print(f"Excess cost at tau_k=0.20 = {exc20:.1f} cents per $ of G   [text: ~50]")
    print(f"tau_l at tau_k=0.25       = {budget_balancing_taul(0.25):.4f}   [text: 0.2529]")
    print(f"tau_l at tau_k=0          = {budget_balancing_taul(0.00):.4f}   [text: 0.2985]")
    print(f"\nWrote CSVs{'' if args.no_plots else ' and PDFs'} to {outdir.resolve()}")


if __name__ == "__main__":
    main()
