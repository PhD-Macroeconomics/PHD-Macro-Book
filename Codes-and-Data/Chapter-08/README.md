# Chapter 8 figures

Run the scripts from this directory with `julia main_figure_3.jl` or `julia main_figure_4.jl`. Required Julia packages are `Plots`, `MatrixEquations`, `Parameters`, and `ForwardDiff`, in addition to the standard libraries.


## Figure 3: Local projections versus VARs

`main_figure_3.jl` compares impulse responses estimated by local projections (LP) and a vector autoregression (VAR) in a Monte Carlo experiment. The data come from a two-variable VAR with two lags, while both estimators use only one lag. The experiment uses 1,000 simulated samples of 300 observations and estimates the response of the second variable to a unit innovation in the first over horizons 0–20. The VAR identifies this innovation using a Cholesky decomposition with the first variable ordered first.

The script computes a population benchmark from the model's stationary covariance matrix and propagates the response using the true dynamics. It then compares the estimates with this benchmark to illustrate the effects of using too few lags.

The output, `results/figure3_lp_vs_var_simulation.pdf`, shows median estimated responses and bands spanning the 5th–95th percentiles across simulations, alongside the benchmark. The lower panels show deviations from the benchmark. The script also prints each method's mean squared error, averaged across simulations and horizons. Simulation and estimation helpers are in `figure_3_helpers/lpvar_share.jl`.

## Figure 4: Model of fiscal multiplier

As described on page 234, an equilibrium is a solution for $k_t, c_t, y_t, \ell_t, G_t, r_t, w_t, A_t, \eta_t$ that satisfies the following equations
$$\begin{aligned}
y_t &= A_t k_{t-1}^\alpha \ell_t^{1-\alpha} \\
y_t &= c_t + k_{t} -(1-\delta)k_{t-1} + G_t \\
A_t &= (1-\rho_A) + \rho_A A_{t-1} + \varepsilon_{A,t} \\
\eta_t &= (1-\rho_\eta) + \rho_\eta \eta_{t-1} + \varepsilon_{\eta,t} \\
\frac{1}{c_t} &= \beta (1+r_{t+1}-\delta) \frac{1}{c_{t+1}} \\
\frac{w_t}{c_t} &= \ell_t^\psi \\
r_t &= \alpha \frac{y_t}{k_{t-1}} \\
w_t &= (1-\alpha)\frac{y_t}{\ell_t}\\
\frac{\gamma\eta_t}{G_t} &= \frac{1}{c_t}
\end{aligned}$$
Note that we have changed the timing on capital so that $k_t$ is chosen at date $t$. Note also that we have dropped the expectation operator. We will linearize the model equations and then solve for a perfect-foresight transition path in response to a shock to fiscal policy. Solutions of linearized models feature certainty equivalence meaning that decisions are taken as if future variables are known to be equal to their expected values. So, to a first-order approximation, the perfect foresight transition path is the same as the solution under uncertainty.


The steady state of this economy satisfies (using variables without time subscripts to denote steady state values)
$$\begin{aligned}
A &= 1  \\
\eta &= 1 \\
G &= \gamma\eta c \\
y &=  k^\alpha \ell^{1-\alpha} \\
y &= c + \delta k  + G \\
r &= \beta^{-1} - 1 +\delta \\
\frac{w}{c} &= \ell^\psi \\
r &= \alpha \frac{y}{k} \\
w &= (1-\alpha)\frac{y}{\ell}
\end{aligned}$$
We can solve this system in a series of steps
$$\begin{aligned}
r &= \beta^{-1} - 1 +\delta \\
\frac{y}{k} &= \alpha^{-1} r  \\
\frac{k}{\ell} &= \left(\frac{y}{k}\right)^{1/(\alpha-1)}  \\
\frac{c}{\ell}  &= \left(1+\gamma \eta\right)^{-1} \left[ \frac{y}{k}\frac{k}{\ell} - \delta \frac{k}{\ell}  \right]\\
\ell   &= \left[(1-\alpha)\frac{y}{k}\frac{k}{\ell}  /\left( \frac{c}{\ell}\right)\right]^{1/(1+\psi)} \\
c &= \frac{c}{\ell} \ell \\
k &= \frac{k}{\ell} \ell\\
\vdots
\end{aligned}$$

Turning to dynamics, we solve for dates $0,\ldots,T-1$, taking initial lagged values and terminal leads at date $T$ to be at steady state. This approximates a transition that eventually returns to steady state. It presumes a stable equilibrium of the kind discussed through the Blanchard and Kahn conditions in chapter 10; the code does not separately check those conditions. Increasing $T$ checks whether the terminal approximation affects the responses of interest.

We stack the variables in a $9T \times 1$ vector $X$: first all $T$ dates of $k$, then $c$, $y$, $\ell$, $G$, $r$, $w$, $A$, and $\eta$. The equilibrium conditions are $F(X,E)=0$, where $F$ stacks each equation's residuals over all dates and $E$ contains the two sequences of innovations. Let $X_{ss}$ be the stacked steady state. Linearizing around $(X_{ss},0)$ gives
$$F_X\Delta X + F_E E = 0, \qquad \Delta X = X-X_{ss},$$
so that
$$\Delta X \approx -F_X^{-1}F_E E, \qquad X_{\mathrm{lin}} = X_{ss}+\Delta X.$$
The Jacobians are evaluated at steady state. The code solves the linear system for `dX` rather than explicitly forming an inverse, and stores response levels in `Xlin`.

The default impulse response sets $\varepsilon_{\eta,0}=1$ and all other innovations to zero. This unit innovation normalizes the first-order response.  The cumulative multiplier over $H$ quarters is
$$\frac{\sum_{t=0}^{H-1}\Delta y_t}{\sum_{t=0}^{H-1}\Delta G_t},$$
with $H=12$ by default and no discounting. 

The calculations are performed in `main_figure_4.jl` and use utilities in `figure_4_helpers/ModelUtils.jl`, from [ModelUtils.jl](https://github.com/amckay/ModelUtils.jl).
