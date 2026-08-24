"""
impulse_response.py -- Figure 3.9 of Chapter 3, "The Solow model".

Chapter 3 of Macroeconomics (Azzimonti, Krusell, McKay, Mukoyama).

Draws the impulse response of the capital stock to a temporary technology shock
in the Solow model with a Cobb-Douglas production function, an exogenous saving
rate, and fixed labor supply (the RBC example of Section 3.5.1).

The economy starts on its steady state. At time 0 the technology level jumps
1 percent above its long-run value and then decays geometrically:

    A_0 = (1 + eps) * Abar,     A_t = (1 + rho^t * eps) * Abar   for t >= 1,

and capital accumulates according to the fundamental equation (3.14), starting
from k_0 = kbar. Section 3.5.2 also derives a log-linearized solution,
equation (3.18),

    khat_{t+1} = (1 - delta*(1-alpha)) * khat_t + delta * Ahat_t.

Both solutions are computed here and the approximation error is printed.

A note on timing
----------------
Equation (3.14) is printed in the chapter as

    k_{t+1} = s * A_t * k_t^alpha * l^(1-alpha) + (1 - delta) * k_t,

but that convention gives a peak capital stock of 9.0913 and a maximum deviation
of 0.28 percent, whereas the text quotes a peak of 9.089 and a deviation of
0.25 percent. Those quoted values correspond instead to

    k_{t+1} = s * A_{t+1} * k_t^alpha * l^(1-alpha) + (1 - delta) * k_t,

under which the first shock to reach the capital stock is the already-decayed
rho*eps rather than eps, scaling the whole response by rho = 0.9. Since the
purpose of this file is to reproduce the published figure, that is the default
here (TIMING = "published"). Set --timing eq314 to use the equation exactly as
printed. This discrepancy is worth resolving before the code is circulated.

No MATLAB source for this figure was included in the original replication
materials; this script was written from the equations and parameter values given
in the chapter.

Run:  python impulse_response.py
"""

import argparse
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# House palette (navy, maroon, dark green).
NAVY, MAROON, DKGREEN = "#1f3a68", "#7b1e28", "#1d5c34"

# ----------------------------------------------------------------------------
# Calibration -- Section 3.5.2. The saving rate and depreciation rate are the
# values calibrated in Section 3.4.3; alpha is the capital share from Chapter 2.
# ----------------------------------------------------------------------------
S     = 0.2      # saving rate
DELTA = 0.046    # depreciation rate, implied by I/K = 0.076 with gamma=0.02, n=0.01
ALPHA = 1 / 3    # capital share
ELL   = 1.0      # labor supply, normalized
ABAR  = 1.0      # steady-state technology level, normalized
EPS   = 0.01     # size of the initial shock: A jumps 1% above Abar
RHO   = 0.9      # persistence of the shock
T     = 200      # periods plotted


def steady_state_capital(s=S, delta=DELTA, alpha=ALPHA, ell=ELL, abar=ABAR):
    """Steady-state capital, equation (3.6) generalized to A and l.

    Setting k_{t+1} = k_t = kbar in (3.14) gives delta*kbar = s*Abar*kbar^alpha*l^(1-alpha).
    """
    return (s * abar * ell ** (1 - alpha) / delta) ** (1 / (1 - alpha))


def technology_path(T=T, eps=EPS, rho=RHO, abar=ABAR):
    """Path of A_t: a 1% jump at t=0 decaying at rate rho."""
    t = np.arange(T)
    return (1 + rho ** t * eps) * abar


def simulate_nonlinear(A, k0, timing="published", s=S, delta=DELTA,
                       alpha=ALPHA, ell=ELL):
    """Iterate the fundamental equation (3.14) forward.

    timing="eq314"     uses A_t,     exactly as the equation is printed.
    timing="published" uses A_{t+1}, which reproduces the published figure.
    """
    k = np.empty(len(A))
    k[0] = k0
    for t in range(len(A) - 1):
        a = A[t + 1] if timing == "published" else A[t]
        k[t + 1] = s * a * k[t] ** alpha * ell ** (1 - alpha) + (1 - delta) * k[t]
    return k


def simulate_loglinear(A, kbar, timing="published", delta=DELTA, alpha=ALPHA,
                       abar=ABAR):
    """Log-linearized solution, equation (3.18).

    khat_{t+1} = (1 - lambda) * khat_t + delta * Ahat_t, with lambda = delta*(1-alpha)
    the convergence speed of equation (3.11). The shock is dated to match the
    timing convention used for the nonlinear solution, so that the two are
    comparable. Returns the implied level of k.
    """
    Ahat = np.log(A / abar)
    khat = np.zeros(len(A))
    lam = delta * (1 - alpha)
    for t in range(len(A) - 1):
        ahat = Ahat[t + 1] if timing == "published" else Ahat[t]
        khat[t + 1] = (1 - lam) * khat[t] + delta * ahat
    return kbar * np.exp(khat)


def plot(A, k, outdir):
    """Two panels: the impulse in A (left) and the response of k (right).

    Published as IRAR.pdf and IR1R.pdf respectively.
    """
    t = np.arange(len(A))

    fig, ax = plt.subplots(figsize=(5, 3.5))
    ax.plot(t, A, color=NAVY, linewidth=2)
    ax.set_xlabel("period")
    ax.set_ylabel(r"$A_t$")
    ax.set_xlim(0, len(A))
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    fig.tight_layout()
    fig.savefig(Path(outdir) / "IRAR.pdf", bbox_inches="tight")
    plt.close(fig)

    fig, ax = plt.subplots(figsize=(5, 3.5))
    ax.plot(t, k, color=NAVY, linewidth=2)
    ax.set_xlabel("period")
    ax.set_ylabel(r"$k_t$")
    ax.set_xlim(0, len(A))
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    fig.tight_layout()
    fig.savefig(Path(outdir) / "IR1R.pdf", bbox_inches="tight")
    plt.close(fig)


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--outdir", default=".", help="output directory (default: .)")
    p.add_argument("--no-plots", action="store_true", help="write the CSV only")
    p.add_argument("--timing", choices=["published", "eq314"], default="published",
                   help="dating of A in the accumulation equation; see module docstring")
    args = p.parse_args()

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    kbar = steady_state_capital()
    A = technology_path()
    k = simulate_nonlinear(A, kbar, args.timing)
    k_ll = simulate_loglinear(A, kbar, args.timing)

    # Save before plotting.
    pd.DataFrame({"period": np.arange(T), "A": A,
                  "k": k, "k_loglinear": k_ll}).to_csv(
        outdir / "impulse_response_data.csv", index=False)

    if not args.no_plots:
        plot(A, k, outdir)

    peak = k.max()
    print(f"Timing convention           = {args.timing}")
    print(f"Steady-state capital kbar   = {kbar:.4f}   [text: 9.066]")
    print(f"Peak capital                = {peak:.4f}   [text: 9.089]")
    print(f"Peak reached in period      = {int(k.argmax())}")
    print(f"Max deviation from kbar     = {peak/kbar - 1:.4%}   [text: 0.25%]")
    print(f"Convergence speed lambda    = {DELTA*(1-ALPHA):.4f}   [eq. (3.11), delta*(1-alpha)]")
    print(f"Max |nonlinear - loglinear| = {np.max(np.abs(k - k_ll)):.2e}")
    print(f"\nWrote results{'' if args.no_plots else ' and figures'} to {outdir.resolve()}")


if __name__ == "__main__":
    main()
