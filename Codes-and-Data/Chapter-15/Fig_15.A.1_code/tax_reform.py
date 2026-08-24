"""
tax_reform.py -- Python translation of the MATLAB code in this folder
(TaxIncrease.m, solveSteadyState.m, ComputeModel.m, PlotResults.m).

Chapter 15, Online Appendix 15.A.2 (Azzimonti, Heathcote, Storesletten).

Produces Figure 15.A.1, "Eliminating capital income taxes (with wealth effects)":
the same reform as Figure 15.7 -- an unexpected, permanent removal of the capital
income tax, with the labor income tax raised to keep G/Y fixed -- but under

    u(c, l) = log(c) - l^(1 + 1/phi) / (1 + 1/phi),

so the marginal utility of consumption no longer cancels from the intratemporal
first-order condition. Substitution and income effects offset exactly, leaving
hours independent of taxes (l = 1 throughout). Because labor does not fall when
the labor tax rises, output and G end up higher than in Figure 15.7: the reform
is less costly when wealth effects are present.

This file is the counterpart of Fig_7_code/tax_reform.py and differs from it only
in the WEALTH_EFFECTS switch below, which controls the three places where the two
specifications diverge (steady-state hours and the intratemporal FOC).

The equilibrium is a system of 2T-1 equations in 2T-1 unknowns -- T intratemporal
first-order conditions and T-1 Euler equations, in the capital path
{k_2, ..., k_T} and the hours path {l_1, ..., l_T} -- solved by Newton's method
with a numerical Jacobian, mirroring ComputeModel.m.

Run:  python tax_reform.py          (writes CSV + PDFs into the working directory)
"""

import argparse
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.optimize import fsolve

# This file: log utility, wealth effects on labor supply (Appendix 15.A.2).
WEALTH_EFFECTS = True

# House palette (navy, maroon, dark green).
NAVY, MAROON, DKGREEN = "#1f3a68", "#7b1e28", "#1d5c34"

# ----------------------------------------------------------------------------
# Calibration -- matches TaxIncrease.m
# ----------------------------------------------------------------------------
BETA  = 0.97    # discount factor
THETA = 1.00    # Frisch elasticity of labor supply (phi in the chapter)
DELTA = 0.07    # depreciation rate
ALPHA = 0.33    # capital share in production
Z     = 1.00    # TFP level
TAUC  = 0.00    # consumption tax
TAUK0 = 0.25    # initial capital income tax (midpoint of 2022 U.S. brackets)
GJ    = 0.20    # government purchases as a share of output, held fixed
TAUK1 = 0.00    # post-reform capital income tax

T  = 100        # periods simulated after the reform
T2 = 10         # pre-reform periods shown in the figures

# Newton's method settings -- same values as ComputeModel.m
ITR_MAX = 250
EPSILON = 1.0e-10
J_STEP  = 1.0e-08
N_ITER  = 3
N_STEP0 = 0.5

RHO = (1 - BETA) / BETA     # rate of time preference


def budget_balancing_taul(tauk):
    """Labor tax holding G/Y = GJ in steady state; equation (15.14)."""
    return (1 / (1 - ALPHA)) * (GJ - tauk * RHO *
                                (ALPHA / (RHO + (1 - tauk) * DELTA)))


def hours_ss(kss, taul):
    """Steady-state hours given capital and the labor tax.

    With GHH preferences hours follow in closed form from the intratemporal
    condition. With log utility (wealth effects) the substitution and income
    effects cancel exactly and hours are independent of taxes -- see Appendix
    15.A.2 -- so l = 1 is a normalization.
    """
    if WEALTH_EFFECTS:
        return 1.0
    return ((1 - taul) / (1 + TAUC) *
            (Z * (1 - ALPHA) * kss ** ALPHA)) ** (THETA / (1 + ALPHA * THETA))


def steady_state(tauk, taul):
    """Initial steady state -- translation of solveSteadyState.m.

    Solves the capital first-order condition (1/beta - 1)/(1 - tauk) + delta = r
    for the capital stock, then reads off the remaining quantities.
    """
    def resid(x):
        k = x[0]
        l = hours_ss(k, taul)
        r = Z * ALPHA * k ** (ALPHA - 1) * l ** (1 - ALPHA)
        return [(1 / BETA - 1) / (1 - tauk) + DELTA - r]

    kss = fsolve(resid, [2.0], xtol=1e-14)[0]
    lss = hours_ss(kss, taul)
    rss = Z * ALPHA * kss ** (ALPHA - 1) * lss ** (1 - ALPHA)
    wss = Z * (1 - ALPHA) * kss ** ALPHA * lss ** (-ALPHA)
    yss = Z * kss ** ALPHA * lss ** (1 - ALPHA)
    Rkss = 1 + (1 - tauk) * (rss - DELTA)
    cwss = ((1 - taul) * wss * lss) / (1 + TAUC)      # workers: labor income
    ckss = (Rkss * kss - kss) / (1 + TAUC)            # capitalists: capital income
    Gss = yss + (1 - DELTA) * kss - kss - cwss - ckss
    return dict(kss=kss, lss=lss, rss=rss, wss=wss, yss=yss, Rkss=Rkss,
                cwss=cwss, ckss=ckss, Gss=Gss)


def unpack(x, K0):
    """Split the solution vector into capital and hours paths.

    Capital is fixed at K0 on impact (predetermined) and held flat after T,
    which imposes the terminal steady state.
    """
    xk = np.empty(T + 1)
    xk[0] = K0
    xk[1:T] = x[:T - 1]
    xk[T] = xk[T - 1]
    xl = x[T - 1:2 * T - 1]
    return xk, xl


def allocations(xk, xl, tauk_vec, taul_vec, tauc_vec):
    """Prices and quantities implied by a candidate (capital, hours) path."""
    y = Z * xk[:T] ** ALPHA * xl ** (1 - ALPHA)
    w = Z * (1 - ALPHA) * xk[:T] ** ALPHA * xl ** (-ALPHA)
    r = ALPHA * Z * xk[:T] ** (ALPHA - 1) * xl ** (1 - ALPHA)
    Rv = 1 + (1 - tauk_vec) * (r - DELTA)              # gross after-tax return
    cw = ((1 - taul_vec) * xl * w) / (1 + tauc_vec)
    ck = (Rv * xk[:T] - xk[1:T + 1]) / (1 + tauc_vec)
    # Government purchases are the residual claimant on output, which is what
    # makes G endogenous during the transition at fixed tax rates.
    Gov = y + (1 - DELTA) * xk[:T] - xk[1:T + 1] - cw - ck
    return y, w, r, Rv, cw, ck, Gov


def eval_system(x, K0, tauk_vec, taul_vec, tauc_vec):
    """Residuals of the 2T-1 equilibrium conditions -- EvalSystem in ComputeModel.m."""
    xk, xl = unpack(x, K0)
    _, w, _, Rv, cw, ck, _ = allocations(xk, xl, tauk_vec, taul_vec, tauc_vec)

    f = np.empty(2 * T - 1)

    # Intratemporal FOC: after-tax wage equals the marginal rate of substitution.
    # With GHH the marginal utility of consumption cancels; with log utility it
    # does not, which is the single substantive difference in the appendix version.
    if WEALTH_EFFECTS:
        f[:T] = w * (1 - taul_vec) / (1 + tauc_vec) / cw - xl ** (1 / THETA)
    else:
        f[:T] = w * (1 - taul_vec) / (1 + tauc_vec) - xl ** (1 / THETA)

    # Euler equation for capitalists' consumption.
    f[T:] = ((ck[1:T] / ck[:T - 1]) * (1 + tauc_vec[1:T]) / (1 + tauc_vec[:T - 1])
             - BETA * Rv[1:T])
    return f


def newton(x, K0, tauk_vec, taul_vec, tauc_vec, verbose=False):
    """Newton's method with a forward-difference Jacobian -- as in ComputeModel.m.

    The step is damped for the first N_ITER iterations, which keeps the solver
    from overshooting into a region where capital or consumption turns negative.
    """
    args = (K0, tauk_vec, taul_vec, tauc_vec)
    fx = eval_system(x, *args)
    n = x.size
    step = N_STEP0

    for it in range(1, ITR_MAX + 1):
        loss = np.max(np.abs(fx))
        if loss < EPSILON:
            break

        jac = np.empty((n, n))
        for c in range(n):                       # numerical Jacobian, column by column
            xp = x.copy()
            xp[c] += J_STEP
            jac[:, c] = (eval_system(xp, *args) - fx) / J_STEP

        if it >= N_ITER:
            step = 1.0
        x = x - step * np.linalg.solve(jac, fx)
        fx = eval_system(x, *args)

        if verbose:
            print(f"  iteration {it:3d}   error {np.max(np.abs(fx)):10.4e}")

    converged = np.max(np.abs(fx)) < 1e-8
    return x, np.max(np.abs(fx)), converged


def solve(verbose=False):
    """Run the reform experiment and return the transition paths."""
    taul0 = budget_balancing_taul(TAUK0)
    taul1 = budget_balancing_taul(TAUK1)
    ss = steady_state(TAUK0, taul0)
    K0 = ss["kss"]

    # The reform is unexpected and permanent: new tax rates from period 1 on.
    tauk_vec = np.full(T, TAUK1)
    taul_vec = np.full(T, taul1)
    tauc_vec = np.full(T, TAUC)

    x0 = np.concatenate([np.full(T - 1, K0), np.full(T, ss["lss"])])
    x, resid, ok = newton(x0, K0, tauk_vec, taul_vec, tauc_vec, verbose)
    if not ok:
        # Fall back on a robust solver rather than silently returning a bad path.
        x = fsolve(eval_system, x0, args=(K0, tauk_vec, taul_vec, tauc_vec),
                   xtol=1e-13, maxfev=200000)
        resid = np.max(np.abs(eval_system(x, K0, tauk_vec, taul_vec, tauc_vec)))

    xk, xl = unpack(x, K0)
    y, w, r, Rv, cw, ck, Gov = allocations(xk, xl, tauk_vec, taul_vec, tauc_vec)

    # Express as percent deviations from the pre-reform steady state, padding
    # T2 periods of that steady state in front -- PlotResults.m.
    def dev(series, ssval):
        return (np.concatenate([np.ones(T2), series / ssval]) - 1) * 100

    out = pd.DataFrame({
        "period": np.arange(1, T + T2 + 1),
        "capital": dev(xk[:T], ss["kss"]),
        "labor": dev(xl, ss["lss"]),
        "consumption": dev(cw + ck, ss["cwss"] + ss["ckss"]),
        "output": dev(y, ss["yss"]),
        "G": dev(Gov, ss["Gss"]),
        "tauk": np.concatenate([np.full(T2, TAUK0), tauk_vec]),
        "taul": np.concatenate([np.full(T2, taul0), taul_vec]),
    })
    return out, ss, resid, taul0, taul1


def plot_allocations(df, outdir):
    """Right-hand panels of Figure 15.7 -- createfigure_temp.m."""
    fig, axes = plt.subplots(4, 1, figsize=(5, 6), sharex=True)
    for ax, col, title in zip(axes,
                              ["capital", "labor", "consumption", "output"],
                              ["Capital", "Labor", "Consumption", "Output"]):
        ax.plot(df.period, df[col], color=NAVY, linewidth=2)
        ax.set_title(title)
        ax.set_ylabel("%")
        ax.set_xlim(0, T + T2 + 10)
        ax.spines["top"].set_visible(False)
        ax.spines["right"].set_visible(False)
    fig.tight_layout()
    fig.savefig(Path(outdir) / "AllocationsWE.pdf", bbox_inches="tight")
    plt.close(fig)


def plot_policies(df, outdir):
    """Left-hand panels of Figure 15.7 -- createfigure_temp_tax.m.

    Tax rates are levels (in percent); G is a percent deviation.
    """
    fig, axes = plt.subplots(3, 1, figsize=(5, 6), sharex=True)
    series = [("G", "G", df.G, NAVY),
              ("tauk", "Tax capital", 100 * df.tauk, MAROON),
              ("taul", "Tax labor", 100 * df.taul, DKGREEN)]
    for ax, (_, title, vals, color) in zip(axes, series):
        ax.plot(df.period, vals, color=color, linewidth=2)
        ax.set_title(title)
        ax.set_ylabel("%")
        ax.set_xlim(0, T + T2 + 10)
        ax.spines["top"].set_visible(False)
        ax.spines["right"].set_visible(False)
    fig.tight_layout()
    fig.savefig(Path(outdir) / "PoliciesWE.pdf", bbox_inches="tight")
    plt.close(fig)


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--outdir", default=".", help="output directory (default: .)")
    p.add_argument("--no-plots", action="store_true", help="write the CSV only")
    p.add_argument("--verbose", action="store_true", help="show Newton iterations")
    args = p.parse_args()

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    df, ss, resid, taul0, taul1 = solve(args.verbose)

    # Write results to disk before plotting.
    df.to_csv(outdir / "transition_data.csv", index=False)

    if not args.no_plots:
        plot_allocations(df, outdir)
        plot_policies(df, outdir)

    label = "with wealth effects" if WEALTH_EFFECTS else "GHH, no wealth effects"
    print(f"Model: {label}")
    print(f"Solver max |residual|      : {resid:.3e}")
    print(f"Initial steady state       : k={ss['kss']:.4f}  l={ss['lss']:.4f}  "
          f"y={ss['yss']:.4f}  G/Y={ss['Gss']/ss['yss']:.4f}")
    print(f"Reform                     : tau_k {TAUK0:.2f} -> {TAUK1:.2f}, "
          f"tau_l {taul0:.4f} -> {taul1:.4f}")
    print(f"Long-run capital           : {df.capital.iloc[-1]:+.2f}%")
    print(f"Long-run output            : {df.output.iloc[-1]:+.2f}%")
    print(f"Long-run labor             : {df.labor.iloc[-1]:+.2f}%")
    print(f"Consumption trough         : {df.consumption.min():+.2f}%")
    print(f"\nWrote results{'' if args.no_plots else ' and figures'} to {outdir.resolve()}")


if __name__ == "__main__":
    main()
