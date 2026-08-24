# Chapter-10
This folder includes codes to accompany Chapter 10 "Computational Tools" of the book [Macroeconomics](https://phdmacrobook.org/), by Marina Azzimonti, Per Krusell, Alisdair McKay, and Toshihiko Mukoyama, plus contributing authors (Oxford University Press, 2026). 

The codes are written in Matlab by Toshihiko Mukoyama.

### <ins>Example 1:  Root finding and optimization</ins> 

* *<b>Ex1_bisection.m</b>*: solves the first-order condition eq. (9.49) numerically using the
bisection method to find the optimal $\ell \in [0, 1]$. 

* *<b>Ex1_newton.m</b>*: solves the fist-order condition eq. (9.49) numerically using the Newton-Raphson method to find the optimal  $\ell$. The code for directly maximizing eq. (9.48) with the Newton method would essentially be the same. 

* *<b>Ex1_GS.m</b>*: solves the optimization problem of maximizing eq. (9.48) using the golden section search.

### <ins>Example 2: Approximating an AR(1) process</ins>

* *<b>Ex2_tauchen.m</b>*: approximates this process by a 10-state first-order Markov process using the Tauchen method. 

* *<b>Ex2_rouwenhorst.m</b>*: performs the same task using the Rouwenhorst method.

### <ins>Example 3: Deterministic dynamic programming</ins>

* *<b>Ex3_GS.m</b>*: allows the choice for $a'$ to be on the grid points (using the golden section search for optimization) and interpolate the right-hand side values of the
Bellman equation for each potential value for $a'$.

### <ins>Example 4: Brock-Mirman model</ins>

* *<b>Ex4_gridsearch.m</b>*: restricts the choice of $K'$ to be on the grid and uses grid search in the optimization of $K'$. The solution of $H$ in eq. (9.56) is obtained using the bisection method. After solving the Bellman equation, the program simulates the time series of $Y_t$, $C_t$, $H_t$, $I_t = K_{t+1}-(1 -\delta)K_t$, and $Z_t$, for
3000 periods. After eliminating the first 100 periods, the code logs and HP-filters (using the subroutine *hpfilt.m*; see Chapter 13) each time series and compute the standard deviation and the correlation with $Y_t$ for the cyclical component of each variable.

* *<b>Ex4_GS.m</b>*: repeats the same exercise (using the subroutines *Ex4_location.m* and *Ex4_labor.m*), allowing the choice of K0 to be outside the grid points (using the linear interpolation and the golden section search).

* *<b>hpfilt.m</b>*: HP-filters a time series. Sub-routine used in Ex4_gridsearch.m.



### <ins>Example 5: Solving the log-linearized Brock-Mirman model</ins>

* *<b>Ex5_BK.m</b>*: follows the steps outlined in "Solving the log-linearized Brock-Mirman model" to compute the model numerically.

