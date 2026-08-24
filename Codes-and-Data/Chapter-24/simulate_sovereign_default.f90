!     Last change:  JCH  11 Jan 2012    4:50 pm
!SOLVE ANNUITY PROBLEM WITH 2 GRIDS. ONE GRID IS OF EVENLY SPACED POINTS. USED TO COMPUTE Q_MATRIX.
!VALUE FUNCTIONS ARE APPROXIMATED USING CHEBYCHEV INTERPOLATION. THE GRID IS UPTADED IN EVERY ITERATION
!IN ORDER TO ACCOUNT FOR THE SHIFT IN THE DEFAULT REGION.
!DIFFERENCE WITH duration_spline: A MORE EFFICIENT PROCEDURE IS USED TO COMPUTE EXPECTATIONS OF q AND V

module param
DOUBLE PRECISION :: beta, sigma, r, b_inf, b_sup, y_inf, y_sup, eps_inf, eps_sup, std_eps,&
                    rho, mean_y, std_y, pi_number, lambda, zero, width, prob_excl_end, delta,&
                    cdf_inf, cdf_sup, coupon, gamma, alpha0, alpha1, recovery, max_prob_default, rec_param,&
                    d0, d1

parameter (sigma = 2d+0, r = 0.01d+0, std_eps = 0.013d+0, rho = 0.91d+0, mean_y = -0.5d+0*std_eps**2,  pi_number = 3.1415926535897932d+0, &
          lambda = 0.5d+0, zero = 0d+0,  width = 1.5d+0, prob_excl_end = 0.083d+0,  delta = 0.033d+0, & !0.045d+0, &
          cdf_inf = 3.167d-5, cdf_sup = 1d+0 - 3.167d-5, gamma = 20, alpha0=0d+0, alpha1=0d+0,&
          max_prob_default = 0.99, rec_param = 1d+7)
!COST OF DEFAULTING WHEN y = 3 std dev BELOW MEAN: 0.02
!COST OF DEFAULTING WHEN y = 3 std dev ABOVE MEAN: 0.50

!delta
!y = log(income) 
!sigma = coefficient of relative risk aversion
!r = international interest rate
!rho = coefficient of autocorrelation in income
!std_eps = standard deviation of innovation to income shocks
!mean_y = unconditional mean of the growth trend shock
!std_y = standard deviation of growth trend shock

INTEGER :: b_num, y_num, eps_num, quad_num_v, quad_num_q, nout, i_y_global,  &
           i_b_global, i_default_global, i_excl_global, i_b_next, cdf_num
parameter (b_num= 25, y_num = 25, quad_num_v = 100, eps_num = quad_num_v, quad_num_q = 100, cdf_num = 500)

DOUBLE PRECISION :: b_grid(1:b_num), y_grid(1:y_num), default_grid(1:2), indicator_tirar,indicator_tirar1,&
                    y_initial, b_initial, b_global, eps_grid(1:eps_num), cdf_grid(cdf_num), BREAK_eps(cdf_num), &
                    CSCOEF_eps(4,cdf_num), quad_w_v(1:quad_num_v), quad_x_v(1:quad_num_v), quad_w_hermite(1:eps_num),&
quad_x_hermite(1:eps_num), quad_w_q(1:quad_num_q), quad_x_q(1:quad_num_q), q_rn_global, counter, q_nodefault_global,&
b_next_inf_global

!y_initial = growth rate state. USED TO SOLVE OPTIMAL SAVINGS RULE AT EVERY ITERATION
!b_initial = debt state. USED TO SOLVE OPTIMAL SAVINGS RULE AT EVERY ITERATION

DOUBLE PRECISION, DIMENSION(b_num, y_num) :: v_matrix, w_matrix, default_decision, b_next_matrix
DOUBLE PRECISION, DIMENSION(b_num, y_num) :: v0_matrix, v1_matrix, b0_next_matrix, b1_next_matrix, q_matrix, q_matrix_nodef,&
                                             q_matrix_nodef_rn, q_matrix_rn
DOUBLE PRECISION, DIMENSION(y_num, b_num) :: break_matrix, break_matrix_v1, break_matrix_q, break_matrix_q_rn
DOUBLE PRECISION, DIMENSION(y_num, 4, b_num) :: coeff_matrix, coeff_matrix_v1, coeff_matrix_q, coeff_matrix_q_rn

!2nd component = h (default decision in previous period
!4th component = b (outstanding debt)
!5th component = y (current income realization)


DOUBLE PRECISION :: indicator_beowolf
end module


!DEFINE UTILITY FUNCTION
DOUBLE PRECISION function u_fun(c)
USE param
DOUBLE PRECISION, INTENT(IN) :: c
DOUBLE PRECISION :: c_min, cons

c_min = 1d-6
cons = MAX(c,c_min)

if (sigma == 1) then
   u_fun = LOG(cons)
else
   u_fun = (cons**(1-sigma) ) / (1-sigma)
end if
end



!SPECIFY GRID VALUES
subroutine compute_grid
USE param
DOUBLE PRECISION :: dos, DNORDF, delta_y, prob_mass, b_inf0, b_sup0, b_inf1, b_sup1
INTEGER :: b_num_half, i
EXTERNAL :: DNORDF


coupon = (r+delta)/(1d+0 + r)

std_y = std_eps/ SQRT(1 - rho**2)

y_inf = mean_y - 5*std_y
y_sup = mean_y + 5*std_y
delta_y = 5*std_y / (y_num - 1d+0)

!b_inf0 =  -lambda*exp(y_sup)*r*3    !NEED A SYMMETRIC GRID, SO THAT
!b_sup0 =  0d+0*EXP(y_inf)

!b_inf1 =  -lambda*exp(y_sup)
!b_sup1 =  -lambda*exp(y_sup)*r*3 -0.001


do i=1,cdf_num
   cdf_grid(i) = cdf_inf + (cdf_sup - cdf_inf) * (i-1) / (cdf_num - 1)
end do

dos = 2d+00

default_grid(1) = 0.0d+0
default_grid(2) = 1.0d+0

eps_inf = -4*std_eps
eps_sup = 4*std_eps

do i=1,eps_num
   !GRID WHEN USING GAUSS-HERMITE QUADRATURE POINTS TO COMPUTE EXPECTED VALUES
   eps_grid(i) = SQRT(dos) * std_eps* quad_x_hermite(i)

   !GRID WHEN USING GAUSS-LEBESGUE QUADRATURE POINTS TO COMPUTE EXPECTED VALUES
   !NEED TO DIFFERENTIATE BECAUSE THE FIRST GRID ASSIGNS TO MUCH WEIGHT ON POINTS
   !WITH 'ZERO' DENSITY. THIS IS INEFFICIENT IF THE INTEGRALS ARE COMPUTED USING
   !GAUSS-LEBESGUE QUADRATURE POINTS.
!   eps_grid(i) = 4* std_eps* quad_x(i)
end do


end subroutine



!COMPUTE QUADRATURE POINTS AND WEIGHTS USING LEGENDRE AND GAUSSIAN QUADRATURE RULES
!THEY ARE USED TO COMPUTE NUMERICAL INTEGRALS
subroutine quadrature
USE param
INTEGER :: N_v, N_q, N, IWEIGH, IWEIGH4, NFIX
parameter(N_v = quad_num_v, N_q = quad_num_q, N = eps_num)
DOUBLE PRECISION:: ALPHA, BETA1, QW_v(1:N_v), QX_v(1:N_v), QW_q(1:N_q), QX_q(1:N_q),QW(1:N), QX(1:N), QXFIX(2)
PARAMETER(ALPHA=0, BETA1=0, IWEIGH=1, IWEIGH4=4)
external DGQRUL

!quad_w = weights using Gauss legendre quadrature rule
!quad_x = points using Gauss legendre quadrature rule
!quad_w_hermite = weights using Gauss Hermite quadrature rule
!quad_x_hermite = points using Gauss Hermite quadrature rule

NFIX = 0
CALL DGQRUL(N_v,IWEIGH, ALPHA, BETA1, NFIX, QXFIX, QX_v, QW_v)

quad_w_v=QW_v
quad_x_v=QX_v

CALL DGQRUL(N_q,IWEIGH, ALPHA, BETA1, NFIX, QXFIX, QX_q, QW_q)

quad_w_q=QW_q
quad_x_q=QX_q


CALL DGQRUL(N,IWEIGH4, ALPHA, BETA1, NFIX, QXFIX, QX, QW)
quad_x_hermite = QX
quad_w_hermite = QW


end subroutine


!COMPUTES THE DIFFERENCE BETWEEN THE VALUE FUNCTION UNDER NO DEFAULT AND DEFAULT
!NEED b_ylobal TO BE DEFINED BEFORE.
DOUBLE PRECISION function dif_fun(y)
USE param
DOUBLE PRECISION, INTENT(IN) :: y
DOUBLE PRECISION :: interpolate, v0_fun, v1_fun
EXTERNAL interpolate, v0_fun, v1_fun


!dif_fun = interpolate(b_global, y, v0_matrix) - interpolate(b_global, y, v1_matrix)
dif_fun = v0_fun(b_global, y) - v1_fun(b_global, y)
!WRITE(nout, '(F12.8, X, F12.8, X, F12.8)') y, v0_fun(b_global, y), v1_fun(b_global, y)
end

!FUNCTION USED TO COMPUTE THE MINIMUM INCOME FOR WHICH THE CURRENT PARTY IN POWER DOES NOT DEFAULT
!b = outstanding debt
DOUBLE PRECISION function y_fun(b)
USE param
DOUBLE PRECISION, INTENT(IN) :: b
INTEGER :: MAXFN, num_tirar
PARAMETER(num_tirar = 100)
DOUBLE PRECISION :: dif_fun, ERRABS, ERRREL, left, right, y_max, y_min, dif_right, dif_left,&
                    y_tirar(num_tirar), tirar
EXTERNAL dif_fun, DZBREN

MAXFN=1000
ERRREL = 1D-10
ERRABS = 1D-10


y_max = rho*y_initial + (1-rho)*mean_y + width*eps_sup
y_min = rho*y_initial + (1-rho)*mean_y + width*eps_inf


b_global = b     !b_global IS USED IN dif_fun TO FIX THE VALUE OF b (OUTSTANDING DEBT)

!open (120, FILE='tirar1.txt',STATUS='replace')
!do i=1,num_tirar
!    tirar = y_min + (y_max - y_min) * (i-1d+0)/(num_tirar-1)
!    left = dif_fun(tirar)
!end do
!CLOSE(120)


dif_right = dif_fun(y_max)
dif_left  = dif_fun(y_min)

!1) DETERMINE WHETHER THERE IS AN INTERIOR ROOT OR NOT
!   a) IF THERE IS AN INTERIOR ROOT, SPECIFY WHETHER THE difference function IS INCREASING IN g OR NOT.
!   b) IF THERE IS NO INTERIOR ROOT, DETERMINE WHETHER THE GOV'T ALWAYS OR NEVER DEFAULTS

!WRITE(nout, *) y_min, y_max, dif_right, dif_left


if (dif_right*dif_left<0) then  !THERE IS AN INTERIOR ROOT
   left =  y_min
   right = y_max
   CALL DZBREN (dif_fun, ERRABS, ERRREL, left, right, MAXFN)
   y_fun = right
else if (dif_left>0) then
      y_fun = y_min
else !dif_right<0
      y_fun = y_max
end if

end



DOUBLE PRECISION function dif_fun_b(b)
USE param
DOUBLE PRECISION, INTENT(IN OUT) :: b
DOUBLE PRECISION :: y_fun, DNORDF, y_standarized, prob_default, y_threshold
EXTERNAL y_fun, DNORDF

y_threshold = y_fun(b)
y_standarized = (y_threshold - rho * y_initial - (1-rho)*mean_y) / std_eps
prob_default = DNORDF(y_standarized)
dif_fun_b = prob_default - max_prob_default
!WRITE(nout, '(F12.8, X, F12.8, X, F12.8)') b, y_threshold, prob_default
end

!FUNCTION USED TO COMPUTE THE VALUE OF b
subroutine b_fun(b_value)
USE param
DOUBLE PRECISION :: dif_fun_b, b_value, ERRABS, ERRREL, b_left, b_right, dif_right, dif_left
EXTERNAL dif_fun_b, DZBREN

ERRREL = 1D-10
ERRABS = 1D-10


b_left = b_inf
dif_left = dif_fun_b(b_left)

b_right = 0d+0
dif_right = -max_prob_default

call BISEC(dif_fun_b, b_left, b_right, ERRABS, ERRREL)
b_value = b_right
end subroutine


!FUNCTION THAT COMPUTES THE PRICES ASKED FOR A COUNTRY BOND
!b_next = future debt
!y = current outcome
DOUBLE PRECISION function q_fun(b_next, y)
USE param
DOUBLE PRECISION, INTENT(IN) :: b_next, y
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!	AQUI DECLARO EL TIPO DE VARIABLE QUE ES m_next. EL m_next ES EL m_t+1, UNA REDUCED FORM EXPRESSION DEL STOCHASTIC
!	DISCOUNT FACTOR DEL FOREIGN RISK NEUTRAL LENDER. SU EXPRESION SALE DE m_t+1=1/(1+r_t+1) - gamma*eps_t+1
!   DONDE y_t+1=(1-rho)*mean_y + rho* y_t + eps_t+1 , Y gamma ES UN PARAMETRO CUYO VALOR SE USA PARA MATCHEAR UN MOMENTO
!   DE LA DISTRIBUCION DEL SPREAD DE TASAS DE INTERES. TAMBIEN DECLARO QUE TIPO DE VARIABLE ES gamma.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
DOUBLE PRECISION :: prob_no_def_tomorrow, y_current_type, DNORDF, y_fun, standarized_inf, standarized_sup,&
                    y_threshold, y_min, y_max, exp_q, interpolate, scalar, y_next, q_paid_fun, acum_int, &
                    DCSVAL, cdf, cdf_threshold, DNORIN, m_next, exp_m, gamma_t, exp_q_rn, q_paid_fun_rn, &
                    exp_q_default, exp_m_default
INTEGER :: i, NINTV
EXTERNAL DNORDF, y_fun, interpolate, q_paid_fun, DCSVAL, DNORIN, q_paid_fun_rn


!y_current_type = STANDARIZED INCOME THRESHOLDS IF THE TYPE DOES NOT CHANGE TOMORROW

q_fun = 0d+0
q_rn_global = 0d+0
recovery = 0d+0 !EXP(rec_param * b_next)
if (b_next >=0) then
   !NO SAVING
   q_fun = EXP(-r) !coupon * (1d+0 - ((1d+0 - delta)/EXP(r))**counter)/ (delta + EXP(r)-1)
   q_rn_global = EXP(-r) !100000 !coupon* (1d+0 - ((1d+0 - delta)/EXP(r))**counter)/ (delta + EXP(r)-1)
ELSEIF(b_next >=b_inf) THEN !SET POSITIVE PRICES ONLY FOR b' THAT ARE ABOVE THE MINIMUM VALUE.
                            !(AVOID OPTIMAL VALUES OUTSIDE THE RANGE)

   y_threshold = y_fun(b_next)
   y_current_type = (y_threshold - rho * y - (1-rho)*mean_y) / std_eps

!WRITE(nout, '(F12.8, X, F12.8)') b_next, DNORDF(y_current_type)
   standarized_inf = eps_grid(1)       / std_eps
   standarized_sup = eps_grid(eps_num) / std_eps

   y_min = (1-rho)*mean_y + rho* y_initial - 4*std_eps !eps_grid(1)
   y_max = (1-rho)*mean_y + rho* y_initial + 4*std_eps !eps_grid(eps_num)

   scalar = 1d+0 / SQRT(pi_number)
   NINTV = cdf_num - 1
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  
! EN SIGUIENTES LINEAS INICIALIZO EL exp_m A CERO, DONDE exp_m ES EL VALOR ESPERADO DE m_next, Y QUE SALE
! DE INTEGRAR m_next IGUAL A COMO SE HACE CON exp_q .	
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   exp_m = 0d+0
   exp_q = 0d+0
   exp_q_rn = 0d+0
   acum_int = 0d+0
   exp_q_default = 0d+0
   exp_m_default = 0d+0
   gamma_t = alpha0 + alpha1*EXP(y_initial) !USED TO COMPUTE THE PRICING KERNEL

      if (DNORDF(y_current_type) <= DNORDF(standarized_inf)+1d-10) then !THRESHOLD TOMORROW IS LOW
         prob_no_def_tomorrow = 1d+0
!         WRITE(nout, *) 'prob no def tomorrow = ', prob_no_def_tomorrow
         do i=1,quad_num_q
             cdf = 0.5*(quad_x_q(i) + 1)*(cdf_sup - cdf_inf) + cdf_inf
             y_next  = (1-rho)*mean_y + rho* y_initial + DNORIN(cdf) * std_eps
!             m_next  = 1d+0 / (1d+0 + r) - gamma * ( y_next - ( (1-rho)*mean_y + rho* y_initial ) ) !!NUEVO
             m_next = EXP(-r - gamma_t * ( y_next - ( (1-rho)*mean_y + rho* y_initial)) - 0.5d+0*(gamma_t**2d+0)*std_eps**2d+0)
             exp_m   = exp_m + m_next * coupon * 0.5* (cdf_sup - cdf_inf)*quad_w_q(i)
             exp_q = exp_q + (1d+0 - delta) * m_next * q_paid_fun(b_next, y_next) * 0.5* (cdf_sup - cdf_inf)*quad_w_q(i)
             exp_q_rn = exp_q_rn + (1d+0 - delta) * q_paid_fun_rn(b_next, y_next) * 0.5* (cdf_sup - cdf_inf)*quad_w_q(i)
         end do
         exp_q = exp_q / (cdf_sup - cdf_inf)  !NEED TO ADJUST EXPECTATION TO TAKE INTO ACCOUNT THAT THE
         !ACTUAL PROBABILITY MASS BETWEEN y_threshold and infty IS UNDERESTIMATED USING LEBESGE-..
         exp_q_rn = exp_q_rn / (cdf_sup - cdf_inf)
         exp_m = exp_m / (cdf_sup - cdf_inf)  !!NUEVO
   elseif (DNORDF(y_current_type) >= DNORDF(standarized_sup)-1d-10) then !THRESHOLD TOMORROW IS HIGH
         prob_no_def_tomorrow = 0d+0
         exp_q_default = EXP(-r) * recovery * coupon * (1d+0 - ((1d+0 - delta)/EXP(r))**(counter-1d+0))/ (delta + EXP(r)-1d+0)
         exp_q_rn = recovery * coupon * (1d+0 - ((1d+0 - delta)/EXP(r))**(counter-1d+0))/ (delta + EXP(r)-1d+0)
         exp_m_default = EXP(-r) * recovery * coupon
   else
         cdf_threshold = DNORDF(y_current_type)
         prob_no_def_tomorrow = (1d+0 - cdf_threshold)
!         WRITE(nout, *) 'prob no def tomorrow = ', prob_no_def_tomorrow
         do i=1,quad_num_q

             !compute integral for y < y_threshold
             cdf = 0.5*(quad_x_q(i) + 1)*(cdf_threshold - cdf_inf) + cdf_inf
             y_next  = (1-rho)*mean_y + rho* y_initial + DNORIN(cdf) * std_eps
             m_next = EXP(-r - gamma_t * ( y_next - ( (1-rho)*mean_y + rho* y_initial)) - 0.5d+0*(gamma_t**2d+0)*std_eps**2d+0)
             exp_m_default = exp_m_default + m_next * recovery * coupon * 0.5* (cdf_threshold - cdf_inf)*quad_w_q(i)
             exp_q_default = exp_q_default + (1d+0 - delta) * m_next * recovery * coupon * &
             (1d+0 - ((1d+0 - delta)/EXP(r))**(counter-1d+0))/ (delta + EXP(r)-1d+0) * 0.5* (cdf_threshold - cdf_inf)*quad_w_q(i)
             exp_q_rn = exp_q_rn + (1d+0 - delta) * recovery * coupon * &
             (1d+0 - ((1d+0 - delta)/EXP(r))**(counter-1d+0))/ (delta + EXP(r)-1d+0) * 0.5* (cdf_threshold - cdf_inf)*quad_w_q(i)


             !compute integral for y > y_threshold
             cdf = 0.5*(quad_x_q(i) + 1)*(cdf_sup - cdf_threshold) + cdf_threshold
             y_next  = (1-rho)*mean_y + rho* y_initial + DNORIN(cdf) * std_eps
 !            m_next  = 1 / (1d+0 + r) - gamma * ( y_next - ( (1-rho)*mean_y + rho* y_initial ))
             m_next = EXP(-r - gamma_t * ( y_next - ( (1-rho)*mean_y + rho* y_initial)) - 0.5d+0*(gamma_t**2d+0)*std_eps**2d+0)
             exp_m   = exp_m + m_next * coupon * 0.5* (cdf_sup - cdf_threshold)*quad_w_q(i)
             exp_q = exp_q + (1d+0 - delta) * m_next * q_paid_fun(b_next, y_next) * 0.5* (cdf_sup - cdf_threshold)*quad_w_q(i)
            exp_q_rn = exp_q_rn + (1d+0 - delta) *  q_paid_fun_rn(b_next, y_next) * 0.5* (cdf_sup - cdf_threshold)*quad_w_q(i)



         end do

         !NEED TO ADJUST EXPECTATION TO TAKE INTO ACCOUNT THAT
         exp_q = exp_q * prob_no_def_tomorrow / (cdf_sup - cdf_threshold)
         !THE ACTUAL PROBABILITY MASS BETWEEN y_threshold and infty IS UNDERESTIMATED USING LEBESGE-..
         exp_q_rn = exp_q_rn /(cdf_sup - cdf_inf)
         exp_m = exp_m * prob_no_def_tomorrow / (cdf_sup - cdf_threshold)
   end if


!if (indicator_tirar1>0) then
!    WRITE(119, '(F12.8, X, F30.8, X, F12.8)') b_next, &
!    -interpolate(b_next, y_threshold, q_matrix_nodef) * &
!    EXP(- ((y_threshold - rho*y_initial - (1-rho)* mean_y)**2) / (2*std_eps**2)) / (std_eps * SQRT(2*pi_number)) *&
!    (y_fun(b_next+0.0005) - y_fun(b_next-0.0005))/0.001d+0
!end if

!q_fun = MAX(prob_no_def_tomorrow / (1d+0 + r) + exp_q/(1d+0 + r), 0d+0)
q_fun = MAX(exp_m + exp_q + exp_m_default + exp_q_default, 0d+0)
q_rn_global = MAX(coupon*(prob_no_def_tomorrow + recovery * (1d+0 - prob_no_def_tomorrow)) + exp_q_rn, 0d+0)*EXP(-r)

end if
!WRITE(nout, '(F12.8, X, F12.8, X, F12.8)') b_next, y, q_fun


end


!Compute the objective function in the Belman equation
!Compute the objective function in the Belman equation
!Compute the objective function in the Belman equation
DOUBLE PRECISION function objective_function(bnext)
USE param
DOUBLE PRECISION, INTENT(IN) :: bnext
INTEGER :: other_type, i,j,h, t, d, NINTV
DOUBLE PRECISION :: u_fun, q_fun, acum, exp_v_next, value_next, y_next, y_fun, scalar, DCSVAL, &
                    y_threshold, y_max, y_min, y_next1, acum2,acum1, g, q, DNORDF, v0_fun, v1_fun, &
                    value_next_tirar, acum_int, acum_int_lo, acum_int_hi, borrowing, interpolate, cdf, cdf1,&
                    cdf_threshold, DNORIN, q_risk_free, output, b, penalty

EXTERNAL u_fun, q_fun, DNORDF, y_fun, interpolate, v0_fun, v1_fun, DCSVAL, DNORIN

b = max(MIN(bnext, b_sup), b_inf)
penalty = max(b_inf - bnext,0d+0)**2d+0 + max(bnext - b_sup,0d+0)**2d+0

y_threshold   = y_fun(b)
cdf_threshold = DNORDF((y_threshold - rho*y_initial - (1-rho)* mean_y)/std_eps)


exp_v_next = 0d+0
scalar = 1d+0 / SQRT(pi_number)


!do i=1,eps_num
!    y_next = y_initial*rho  + (1-rho)*mean_y + eps_grid(i)
!    if (y_next < y_threshold) then
!       !value_next = interpolate1(y_next, cheb_coeff_v1)
!        value_next = v1_fun(y_next)
!    else
!       !value_next = interpolate2(b,y_next, cheb_coeff_v0)
!       value_next = v0_fun(b,y_next)
!    end if
!    exp_v_next = exp_v_next + quad_w_hermite(i) * value_next * scalar
!end do


y_min = (1-rho)*mean_y + rho* y_initial - 4*std_eps
y_max = (1-rho)*mean_y + rho* y_initial + 4*std_eps


NINTV = cdf_num - 1
acum1=0d+0
acum2=0d+0

   if (y_threshold < y_min) then

       do i=1,quad_num_v
          cdf = 0.5*(quad_x_v(i) + 1)*(cdf_sup - cdf_inf) + cdf_inf
          y_next  = (1-rho)*mean_y + rho* y_initial + DNORIN(cdf) * std_eps
          value_next = v0_fun(b, y_next)
          acum1 = acum1 + 0.5*(cdf_sup - cdf_inf)*quad_w_v(i) * value_next
       end do

   elseif(y_threshold > y_max) then

       do i=1,eps_num
          cdf = 0.5*(quad_x_v(i) + 1)*(cdf_sup - cdf_inf) + cdf_inf
          y_next  = (1-rho)*mean_y + rho* y_initial + DNORIN(cdf) * std_eps
          value_next = v1_fun(b, y_next)
          acum1 = acum1 + 0.5*(cdf_sup - cdf_inf)*quad_w_v(i) * value_next
       end do

   else
      do i=1,eps_num

        cdf = 0.5*(quad_x_v(i) + 1)*(cdf_threshold - cdf_inf) + cdf_inf
        y_next  = (1-rho)*mean_y + rho* y_initial + DNORIN(cdf) * std_eps
        value_next = v1_fun(b, y_next)
        acum1 = acum1 + 0.5*(cdf_threshold - cdf_inf)*quad_w_v(i) * value_next


!        compute integral for y > y_threshold
        cdf1 = 0.5*(quad_x_v(i) + 1)*(cdf_sup - cdf_threshold) + cdf_threshold
        y_next1 = (1-rho)*mean_y + rho* y_initial + DNORIN(cdf1) * std_eps !DCSVAL(cdf1, NINTV, BREAK_eps, CSCOEF_eps)
        value_next = v0_fun(b, y_next1)
        acum2 = acum2 + 0.5*(cdf_sup - cdf_threshold)*quad_w_v(i) * value_next
!        WRITE(119, '(F12.8, X, F12.8, X, F12.8, X, F12.8, X, F12.8)') y_next, v1_fun(y_next), y_next1, value_next
      end do
   end if

exp_v_next = (acum1+acum2)/(cdf_sup - cdf_inf)


d  = i_default_global
q = q_fun(b, y_initial)
q_risk_free = coupon* (1d+0 - ((1d+0 - delta)/EXP(r))**(counter-1d+0))/ (delta + EXP(r)-1d+0)
borrowing =  b - b_initial*(1d+0-default_grid(d))*(1d+0 - delta)
output = (1d+0 - default_grid(i_excl_global)) * EXP(y_initial) + &
         default_grid(i_excl_global) * (EXP(y_initial) - max(exp(y_initial)* (d0 + d1*EXP(y_initial)),0d+0))
!borrowing = b - b_initial  !Borrowing con default solo en el cupon

recovery = 0d+0 !EXP(rec_param * b_initial)

objective_function = - u_fun(output + b_initial * (coupon*(1d+0 -default_grid(d)) +default_grid(d)*recovery*(coupon + &
                       (1-delta)*q_risk_free)) - borrowing*q) - beta * exp_v_next + penalty

!if (indicator_tirar1>0) then
!write(119, '(F12.8, X, F12.8, X, F12.8, X,  F12.8, X, F12.8, X, F12.8)') b, objective_function, q!, &
!!EXP(y_initial)*(1 -  lambda* default_grid(d)) + &
!!                       b_initial * (coupon*(1d+0 -default_grid(d)) +default_grid(d)*recovery*(coupon + (1-delta)*q_risk_free)) &
!!                       - borrowing*q, beta * exp_v_next
!end if

!WRITE(6, '(F12.8, X, F20.5, X, F12.6, X,  F20.5, X, F12.6, X, F12.6)') b, objective_function, q, &
!u_fun(output + b_initial * (coupon*(1d+0 -default_grid(d)) +default_grid(d)*recovery*(coupon + &
!                       (1-delta)*q_risk_free)) - borrowing*q), beta * exp_v_next


!if (indicator_tirar >0 ) then
!   WRITE(114, '(F20.8)') max(u_fun(output + b_initial * (coupon*(1d+0 -default_grid(d)) +default_grid(d)*recovery*(coupon + &
!                       (1-delta)*q_risk_free)) - borrowing*q), -999d+0)
!   
!   WRITE(115, '(F20.8)') beta*exp_v_next
!end if

end



!Compute the objective function in the Belman equation
DOUBLE PRECISION function objective_function_excl(b)
USE param
DOUBLE PRECISION, INTENT(IN) :: b
INTEGER :: other_type, i,j,h, t, d, NINTV
DOUBLE PRECISION :: u_fun, q_fun, acum, acum_excl, exp_v_next, value_next, y_next, y_fun, scalar, DCSVAL, &
                    y_threshold, y_max, y_min, y_next1,  g, q, DNORDF, v0_fun, v1_fun, &
                    value_next_tirar, acum_int, acum_int_lo, acum_int_hi, borrowing, interpolate, cdf, cdf1,&
                    cdf_threshold, DNORIN, q_risk_free, output

EXTERNAL u_fun, q_fun, DNORDF, y_fun, interpolate, v0_fun, v1_fun, DCSVAL, DNORIN



exp_v_next = 0d+0
scalar = 1d+0 / SQRT(pi_number)

NINTV = cdf_num - 1
acum=0d+0
acum_excl=0d+0


       do i=1,quad_num_v
          cdf = 0.5*(quad_x_v(i) + 1)*(cdf_sup - cdf_inf) + cdf_inf
          y_next  = (1-rho)*mean_y + rho* y_initial + DNORIN(cdf) * std_eps
          value_next = v0_fun(b, y_next)
          acum = acum + 0.5*(cdf_sup - cdf_inf)*quad_w_v(i) * value_next

          value_next = v1_fun(b, y_next)
          acum_excl = acum_excl + 0.5*(cdf_sup - cdf_inf)*quad_w_v(i) * value_next
       end do

exp_v_next = (prob_excl_end*acum + (1d+0 - prob_excl_end)*acum_excl)/(cdf_sup - cdf_inf)
output = EXP(y_initial) - exp(y_initial)*min(max(d0 + d1*exp(y_initial),0d+0), 0.95d+0)

objective_function_excl = - u_fun(output) - beta * exp_v_next

end




subroutine optimize(b_next, v_value)
USE param
integer :: MAXFN, t, d, i, index_opt, index_vector(1), num, num_tirar
parameter (num=25, num_tirar = 500)
DOUBLE PRECISION :: b_next, v_value, objective_function, new_value, q_fun, old_value, b, u_fun,q,vector(b_num),&
                    b_next_grid(num), STEP, BOUND, XACC, b_next_guess, b_tirar, b_next_inf, b_next_sup, dif_fun_b,&
                    difference, b_next_graph
EXTERNAL objective_function, q_fun, u_fun, DUVMIF, dif_fun_b

!if (indicator_tirar>0) then
!   open (117, FILE='tirar1.txt',STATUS='replace')
!end if


!difference = dif_fun_b(b_inf)
!if (difference<0) then   !THE DEFAULT PROBABILITY AT THE MAXIMUM DEBT LEVEL IS < max_def_prob
!   b_next_inf = b_inf    !SET THE BORROWING LIMIT EQUAL THE MAXIMUM DEBT IN THE GRID
!else
!   call b_fun(b_next_inf)
!end if
b_next_inf = b_inf 
b_next_inf_global = b_next_inf

b_next_sup = b_sup

!b_next_inf = -1.9
!b_next_sup = -1.2

old_value = 10d+3
do i=1,num
   b_next_grid(i) = b_next_inf + (b_next_sup - b_next_inf) * (i-1)/ (num - 1)
   new_value = objective_function(b_next_grid(i))
   if (new_value <= old_value) then
      index_opt = i
      b_next_guess = b_next_grid(i)
      old_value = new_value
  end if
end do


STEP = (b_next_grid(2) - b_next_grid(1))*0.5
BOUND = 10*EXP(y_sup)
XACC = 1d-6
MAXFN = 1000


!if (indicator_tirar>0) then
!!!WRITE(nout, '(A15, X, F12.8)') 'candidate', b_next_guess
!   indicator_tirar1 = 1
!!   open (118, FILE='tirar1.txt',STATUS='replace')
!!!!   open (119, FILE='tirar2.txt',STATUS='replace')
!!!!
!  do i=1,num_tirar
!      b_tirar   =  b_inf + (b_sup - b_inf) * (i-1)/ (num_tirar - 1)
!      new_value = objective_function(b_tirar)
!   end do
!!   CLOSE(118)
!!!!   CLOSE(119)
!indicator_tirar1 = 0
!end if

b_tirar = -1.0d-4
if (index_opt == 1) then
   b_next = b_next_guess
   v_value = -old_value
ELSEIF(index_opt == num .AND. objective_function(b_tirar)< objective_function(b_next_grid(index_opt))) then
       !THE MAXIMUM MAY BE CLOSE TO 0 BUT NOT AT ZERO
       b_next_guess = b_tirar
       call DUVMIF(objective_function, b_next_guess, STEP, BOUND, XACC, MAXFN, b_next)
       v_value = -objective_function(b_next)
else
   if (ABS(old_value - objective_function(b_next_grid(index_opt-1)))/(b_next_grid(2)-b_next_grid(1)) < 1d-10 .OR.  &
       ABS(old_value - objective_function(b_next_grid(index_opt+1)))/(b_next_grid(2)-b_next_grid(1)) < 1d-10) then
       b_next = b_next_guess
       v_value = -old_value
   else
       call DUVMIF(objective_function, b_next_guess, STEP, BOUND, XACC, MAXFN, b_next)
       v_value = -objective_function(b_next)
       indicator_tirar1 =0
   end if
end if
!if (indicator_tirar>0) then
!WRITE(nout, '(A15, X, F12.8, X, F12.8)') 'solution', b_next_guess, b_next
!pause
!CLOSE(117)
!end if

!indicator_tirar = 1
!open (111, FILE='b.txt',STATUS='replace')
!open (112, FILE='o.txt',STATUS='replace')
!open (113, FILE='qtest.txt',STATUS='replace')
!open (114, FILE='u.txt',STATUS='replace')
!open (115, FILE='EV.txt',STATUS='replace')
!
!   do j=1,num_tirar
!!      b_next_graph = b_inf + (b_sup - b_inf) * (j-1d+0) / (num_tirar - 1d+0)
!      b_next_graph = -0.15d+0 + 0.15d+0 * (j-1d+0) / (num_tirar - 1d+0)
!
!        WRITE(111, '(F12.8)') b_next_graph
!
!      WRITE(112, '(F20.8, X, F20.8)')  MAX(- objective_function(b_next_graph), -4000d+0) 
!      WRITE(113, '(F20.8, X, F20.8)')  q_fun(b_next_graph, y_initial)
!end do
!close (110)
!CLOSE(111)
!CLOSE(112)
!CLOSE(113)
!CLOSE(114)
!CLOSE(115)
!indicator_tirar = 0


10 end subroutine




DOUBLE PRECISION function interpolate(b, y, matrix)
USE param
DOUBLE PRECISION, INTENT(IN) :: b, y, matrix(b_num, y_num)
DOUBLE PRECISION ::  slope, weight, acum, ratio_b, ratio_y
INTEGER :: index_b, index_y, i_b, i_y



index_y = (MAX(MIN(INT((y_num-1)*(y-y_grid(1))/(y_grid(y_num)-y_grid(1)))+1,y_num-1), 1))
index_b = (MAX(MIN(INT((b_num-1)*(b-b_grid(1))/(b_grid(b_num)-b_grid(1)))+1,b_num-1), 1))


ratio_b = (b - b_grid(index_b)) / (b_grid(index_b+1) - b_grid(index_b))
!ratio_y = MIN(MAX((y - y_grid(index_y)) / (y_grid(index_y+1) - y_grid(index_y)),0d+0), 1d+0)
ratio_y = (y - y_grid(index_y)) / (y_grid(index_y+1) - y_grid(index_y))
acum=0



do i_b=0,1
   do i_y=0,1
        weight = ((1-i_b)*(1 - ratio_b) + i_b*ratio_b )* ((1-i_y)*(1 - ratio_y) + i_y*ratio_y )
        acum = acum + matrix(index_b + i_b, index_y + i_y)*weight
!        if (indicator_tirar>0) then
!            WRITE(nout, '(F12.8, X, I4, X, F12.8)')&
!            i_y*ratio_y, i_y,ratio_y
!        end if
   end do
end do

!if (indicator_tirar >0) then
!    WRITE(nout, '(I4, X, I4)') index_b, index_y
!    WRITE(nout, '(F12.8, X, F12.8)') ratio_b, ratio_y
!    WRITE(nout, '(A10, X, F12.8, X, F12.8)') '(0,0) ', matrix(index_b, index_y)
!    WRITE(nout, '(A10, X, F12.8, X, F12.8)') '(1,0) ',matrix(index_b+1, index_y)
!    WRITE(nout, '(A10, X, F12.8, X, F12.8)') '(0,1) ',matrix(index_b, index_y+1)
!    WRITE(nout, '(A10, X, F12.8, X, F12.8)') '(1,1) ',matrix(index_b+1, index_y+1)
!    WRITE(nout, '(A10, X, F12.8, X, F12.8)') 'interp', acum
!    pause
!end if


!f_value = acum
interpolate = acum
end


DOUBLE PRECISION function v0_fun(b, y)
USE param
DOUBLE PRECISION, INTENT(IN) :: b, y
DOUBLE PRECISION ::  slope, DCSVAL, value_left, value_right
INTEGER :: index_b, index_y,  NINTV
EXTERNAL DCSVAL

NINTV = b_num - 1
index_y = (MAX(MIN(INT((y_num-1)*(y-y_grid(1))/(y_grid(y_num)-y_grid(1)))+1,y_num-1), 1))

value_left  = DCSVAL(b, NINTV, break_matrix(index_y,:), coeff_matrix(index_y,:,:))
value_right = DCSVAL(b, NINTV, break_matrix(index_y+1,:), coeff_matrix(index_y+1,:,:))


slope = (value_right - value_left)/ (y_grid(index_y+1) - y_grid(index_y))

v0_fun = value_left + slope * (y - y_grid(index_y))
end


DOUBLE PRECISION function v1_fun(b, y)
USE param
DOUBLE PRECISION, INTENT(IN) :: b, y
DOUBLE PRECISION ::  slope, DCSVAL, value_left, value_right
INTEGER :: index_b, index_y,  NINTV
EXTERNAL DCSVAL


NINTV = b_num - 1
index_y = (MAX(MIN(INT((y_num-1)*(y-y_grid(1))/(y_grid(y_num)-y_grid(1)))+1,y_num-1), 1))

value_left  = DCSVAL(b, NINTV, break_matrix_v1(index_y,:), coeff_matrix_v1(index_y,:,:))
value_right = DCSVAL(b, NINTV, break_matrix_v1(index_y+1,:), coeff_matrix_v1(index_y+1,:,:))


slope = (value_right - value_left)/ (y_grid(index_y+1) - y_grid(index_y))

v1_fun = value_left + slope * (y - y_grid(index_y))

end



DOUBLE PRECISION function q_paid_fun(b, y)
USE param
DOUBLE PRECISION, INTENT(IN) :: b, y
DOUBLE PRECISION ::  slope, DCSVAL, value_left, value_right
INTEGER :: index_b, index_y, NINTV
EXTERNAL DCSVAL

NINTV = b_num - 1
index_y = (MAX(MIN(INT((y_num-1)*(y-y_grid(1))/(y_grid(y_num)-y_grid(1)))+1,y_num-1), 1))

value_left  = DCSVAL(b, NINTV, break_matrix_q(index_y,:), coeff_matrix_q(index_y,:,:))
value_right = DCSVAL(b, NINTV, break_matrix_q(index_y+1,:), coeff_matrix_q(index_y+1,:,:))


slope = (value_right - value_left)/ (y_grid(index_y+1) - y_grid(index_y))

q_paid_fun = value_left + slope * (y - y_grid(index_y))
end


DOUBLE PRECISION function q_paid_fun_rn(b, y)
USE param
DOUBLE PRECISION, INTENT(IN) :: b, y
DOUBLE PRECISION ::  slope, DCSVAL, value_left, value_right
INTEGER :: index_b, index_y, NINTV
EXTERNAL DCSVAL

NINTV = b_num - 1
index_y = (MAX(MIN(INT((y_num-1)*(y-y_grid(1))/(y_grid(y_num)-y_grid(1)))+1,y_num-1), 1))

value_left  = DCSVAL(b, NINTV, break_matrix_q_rn(index_y,:),   coeff_matrix_q_rn(index_y,:,:))
value_right = DCSVAL(b, NINTV, break_matrix_q_rn(index_y+1,:), coeff_matrix_q_rn(index_y+1,:,:))


slope = (value_right - value_left)/ (y_grid(index_y+1) - y_grid(index_y))

q_paid_fun_rn = value_left + slope * (y - y_grid(index_y))

end



!SPECIFY GRID VALUES
subroutine read_data
USE param
integer :: i_type, i, i_h, i_b, i_y, i_pi, def,i_b_zero, i_excl, ILEFT, IRIGHT,NINTV
DOUBLE PRECISION :: FDATA(b_num), DNORIN, DLEFT, DRIGHT, BREAK_GRID(b_num), CSCOEF(4,b_num), b_tirar, DCSVAL,&
                    epsilon_grid(cdf_num)
EXTERNAL DCSDEC, DNORIN




eps_inf = -4*std_eps
eps_sup = 4*std_eps


if (indicator_beowolf>0.5) then
   open (10, FILE='graphs_b_grid.txt')
   open (11, FILE='graphs_y_grid.txt')
   open (13, FILE='graphs_bounds.txt')

else
   open (10, FILE='b_grid.txt')
   open (11, FILE='y_grid.txt')
   open (13, FILE='bounds.txt')
end if



READ(13, '(F15.11, X, F15.11)') b_inf, b_sup
READ(13, '(F15.11, X, F15.11)') y_inf, y_sup

do i=1,b_num
   READ(10, '(F12.8)') b_grid(i)
end do

do i=1,y_num
   READ(11, '(F12.8)') y_grid(i)
   !y_grid(i) = LOG(y_grid(i))
end do

do i=1,eps_num
   !GRID WHEN USING GAUSS-HERMITE QUADRATURE POINTS TO COMPUTE EXPECTED VALUES
   eps_grid(i) = SQRT(2d+0) * std_eps* quad_x_hermite(i)
end do

CLOSE(10)
CLOSE(11)
CLOSE(12)
CLOSE(13)
default_grid(1) = 0d+00
default_grid(2) = 1d+00


if (indicator_beowolf>0.5) then
    open (20, FILE='graphs_v.txt')
    open (21, FILE='graphs_default.txt')
    open (24, FILE='graphs_q_paid.txt')
else
    open (20, FILE='v.txt')
    open (24, FILE='q_paid.txt')
end if



 do i_b = 1,b_num
     do i_y = 1,y_num
         READ(20, '(F25.6, X, F25.6, X, F25.6)') v_matrix(i_b, i_y), v0_matrix(i_b, i_y), v1_matrix(i_b, i_y)
         READ(24, '(F15.11, X, F15.11, X, F15.11, X, F15.11)') q_matrix(i_b, i_y), q_matrix_nodef(i_b, i_y),&
                                         q_matrix_rn(i_b, i_y), q_matrix_nodef_rn(i_b, i_y)



     end do
 end do


CLOSE(20)
CLOSE(24)

do i_y = 1,y_num
     FDATA = v0_matrix(:,i_y)
     ILEFT  = 0
     IRIGHT = 0
     DLEFT = (FDATA(2)-FDATA(1)) / (b_grid(2) - b_grid(1))
     DLEFT = (FDATA(b_num)-FDATA(b_num-1)) / (b_grid(b_num) - b_grid(b_num-1))
     call  DCSDEC (b_num, b_grid, FDATA, ILEFT, DLEFT, IRIGHT, DRIGHT, BREAK_GRID, CSCOEF)

     break_matrix(i_y, :) = BREAK_GRID
     coeff_matrix(i_y, :,:) = CSCOEF

         FDATA = v1_matrix(:,i_y)
         ILEFT  = 0
         IRIGHT = 0
         DLEFT = (FDATA(2)-FDATA(1)) / (b_grid(2) - b_grid(1))
         DLEFT = (FDATA(b_num)-FDATA(b_num-1)) / (b_grid(b_num) - b_grid(b_num-1))
         call  DCSDEC (b_num, b_grid, FDATA, ILEFT, DLEFT, IRIGHT, DRIGHT, BREAK_GRID, CSCOEF)
         break_matrix_v1(i_y, :) = BREAK_GRID
         coeff_matrix_v1(i_y, :,:) = CSCOEF



      FDATA = q_matrix_nodef(:,i_y)
      ILEFT  = 0
      IRIGHT = 0
      call  DCSDEC (b_num, b_grid, FDATA, ILEFT, DLEFT, IRIGHT, DRIGHT, BREAK_GRID, CSCOEF)
      break_matrix_q(i_y, :) = BREAK_GRID
      coeff_matrix_q(i_y, :,:) = CSCOEF

      FDATA = q_matrix_nodef_rn(:,i_y)
      ILEFT  = 0
      IRIGHT = 0
      call  DCSDEC (b_num, b_grid, FDATA, ILEFT, DLEFT, IRIGHT, DRIGHT, BREAK_GRID, CSCOEF)
      break_matrix_q_rn(i_y, :) = BREAK_GRID
      coeff_matrix_q_rn(i_y, :,:) = CSCOEF

end do


!compute spline coefficients of inverse (gaussian cdf)
!COMPUTE SPLINE COEFFICIENT OF INVERSE cdf(epsilon)
!USED LATER TO COMPUTE EXPECTATIONS.
do i=1,cdf_num
   epsilon_grid(i) = DNORIN(cdf_grid(i)) * std_eps
end do

ILEFT  = 0
IRIGHT = 0
DLEFT = (epsilon_grid(2) - epsilon_grid(1)) / (cdf_grid(2) - cdf_grid(1))
DLEFT = (epsilon_grid(cdf_num) - epsilon_grid(cdf_num-1)) / (cdf_grid(cdf_num) - cdf_grid(cdf_num-1))
call  DCSDEC (cdf_num, cdf_grid, epsilon_grid, ILEFT, DLEFT, IRIGHT, DRIGHT, BREAK_eps, CSCOEF_eps)

end subroutine


subroutine simulate
USE param
integer :: period_num, i,j,k, gov_type, random_num, ivalue, sample_num, MAXFN
parameter (sample_num = 500, period_num=501)
DOUBLE PRECISION :: random_matrix(period_num, sample_num, 2), random_vector(1:2*sample_num*period_num), &
                    z(period_num,sample_num), b(period_num+1,sample_num), &
                    q(period_num,sample_num), eps, b_interp(b_num, y_num), v_def, v_no_def, b_next, q_fun, &
                    q_interp(b_num, y_num),q_paid, b_zero, c(period_num,sample_num), tb(period_num,sample_num),&
                    y(period_num,sample_num), STEP, BOUND, XACC, objective_function, b_next_guess,&
                    v_valor, v0_fun, v1_fun, DNORIN, q_risk_neutral, q_risk_free
INTEGER :: excl(period_num, sample_num), d(period_num, sample_num)
EXTERNAL RNSET, DRNUN, DNORIN, q_fun, DUVMIF, objective_function, v0_fun, v1_fun

b_zero = 0d+0  !IF THE COUNTRY IS NOT EXCLUDED AFTER A DEFAULT EPISODE ==> BORROWS AS IF IT STARTS WITH ZERO DEBT
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!! NOTE !!!!!!
! z DENOTE UNDERLYING SHOCK TO THE ENDOWMENT
! y DENOTE REALIZED ENDOWMENT (EXP(z))
! CODE WAS WRITEN WITH y = SHOCK, SO mean_y ACTUALLY = E(z)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



STEP = (b_grid(2) - b_grid(1))*0.5
BOUND = 10*y_sup
XACC = 1d-6
MAXFN = 1000

ivalue=139719
call RNSET(ivalue)       !INITIALIZE THE SEED SO THE SAME RANDOM NUMBERS ARE GENERATED IN EVERY REALIZATION
call DRNUN(2*period_num*sample_num, random_vector)

counter = 1.0d+6
q_risk_free = coupon* (1d+0 - ((1d+0 - delta)/EXP(r))**(counter-1d+0))/ (delta + EXP(r)-1d+0)

!open (UNIT=1, FILE="r_vector.txt", status = 'replace')
!   do i=1,period_num*sample_num*2
!      write(1,'(F12.8)') random_vector(i)
!      !READ
!      end do
!CLOSE(1)

!First column of random_matrix is used to generate transitory shocks.
!Second column of random_matrix is used to generate type changes.
do j=1,sample_num
    do i=1,period_num
       random_matrix(i,j,1)=random_vector((j-1)*period_num+i)
       random_matrix(i,j,2)=random_vector(period_num*sample_num + (j-1)*period_num+i)
    end do
end do

open (UNIT=21, FILE="data_sim.txt", status = 'replace')
open (UNIT=22, FILE="def_per.txt", status = 'replace')
open (UNIT=23, FILE="param.txt", status = 'replace')

WRITE(23, '(I10)') period_num-1
WRITE(23, '(I10)') sample_num
CLOSE(23)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
i_default_global = 1  !USED TO INVOKE WHICH CHEBYCHEV MATRIX TO USE
                      !NEED TO MODIFY THIS WHEN DEFAULT AFFECTS OUTPUT REGARDLESS OF THE EXCLUSION STATUS
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
do j=1,sample_num   !SOLVE FOR SAMPLE j
WRITE(nout, *) j
!Set initial values

    z(1,j) = mean_y
    y(1,j) = EXP(z(1,j))
    b(1,j) = zero
    b_initial = b(1,j)
    y_initial = z(1,j)
    i_default_global = 1
    i_excl_global = 1
    call optimize(b_next, v_valor)
    b(2,j) = b_next


    d(1,j) = 1   !NO DEFAULT IN FIRST PERIOD
    excl(1,j) = 1   !Low beta type = -1 // High beta type = 1


    do i=2,period_num
!epsilon = realization of standard gaussian * standard deviation

    !epsilon = realization of standard gaussian * standard deviation

        eps = DNORIN(random_matrix(i,j,1)) * std_eps
!GROWTH SHOCK
        z(i,j) = rho*z(i-1,j) + (1-rho)*mean_y + eps   !current output = ex ante mean + epsilon
        b_initial = b(i,j)
        y_initial = z(i,j)


        v_no_def = v0_fun(b_initial, y_initial)
        v_def    = v1_fun(b_initial, y_initial)

!       WRITE(nout, '(F12.8, X, F12.8, X, F12.8, X, F12.8)') b_initial, y_initial, v_no_def, v_def

           if (v_def>v_no_def) then  !COUNTRY DEFAULTS
               d(i,j) = 2
               i_default_global = 2

               call optimize(b_next, v_valor)

               recovery = EXP(rec_param * b(i,j))

               b(i+1,j) = b_next
                  b_global = b_next
               !    !Compute the bond price paid when an amount b_next is issued.
               !    !the bond price depends on the current default decision and output (both will affect output tomorrow)
               !    !It also depends on the current type in power.

                   q(i,j) = q_fun(b_next, z(i,j))
                   q_risk_neutral = q_rn_global
                   y(i,j) = EXP(z(i,j)) * (1-d0) - d1*EXP(z(i,j))**2d+0
                   c(i,j) = y(i,j) - q(i,j)* b(i+1,j) + b(i,j)*recovery*(coupon + (1-delta)*q_risk_free)
                   tb(i,j) = y(i,j) - c(i,j)

               WRITE(22, '(I7)') i-1 !NEED TO SUBSTRACT 1. REASON: files start saving data on period 2
           else
               d(i,j) = 1   !COUNTRY DOES NOT DEFAULT
               i_default_global = 1
               call optimize(b_next, v_valor)
               b(i+1,j) = b_next
               !Compute the bond price paid when an amount b_next is issued.
               !the bond price depends on the current default decision and output (both will affect output tomorrow)
               !It also depends on the current type in power.

               q(i,j) = q_fun(b_next, z(i,j))
               q_risk_neutral = q_rn_global
               y(i,j) = EXP(z(i,j))
               c(i,j) = y(i,j) + coupon*b(i,j) - q(i,j)*(b(i+1,j) - b(i,j)*(1d+0 - delta))
               tb(i,j) = y(i,j) - c(i,j)
        end if

        WRITE(21, '(F12.8, X, F12.8, X, F12.8, X, F12.8, X, F12.8, X, I3, X, F12.8, X, F7.3)') &
        LOG(y(i,j)), b(i,j), q(i,j), LOG(c(i,j)), tb(i,j)/y(i,j), d(i,j), q_risk_neutral, recovery

!       WRITE(nout, '(F12.8, X, F12.8, X, F12.8, X, F12.8, X, F12.8, X, I3, X, I3, X, F8.5)') &
!       LOG(y(i,j)), b(i+1,j), q(i,j), LOG(c(i,j)), tb(i,j)/y(i,j), d(i,j)
!        WRITE(nout, '(F12.8, X, F12.8, X, F12.8, X, F12.8, X, I3, X, I3, X, F8.5)') &
!        z(i,j), b(i,j), q(i,j), b(i+1,j)
        !if (ABS(y)<1d) then
        !  WRITE(nout, '(F12.8, X, F12.8, X, F12.8, X, I3, X, I3, X, I3)') y(i,j), b(i,j), q(i,j), excl(i,j), d(i,j)
        !  pause
        !end if
!       if (y(i,j)>1.03d+0 .AND. y(i,j)<1.04d+0) then
!          WRITE(24, '(F12.8, X, F12.8, X, F12.8, X, F12.8)') y(i,j), b(i,j), b(i+1,j), q(i,j)
!       end if
    end do
end do
CLOSE(21)
CLOSE(22)
CLOSE(24)

end subroutine



program main
USE param
DOUBLE PRECISION :: start_time, end_time

open (1987, FILE='beta.txt')
read(1987, '(F10.4)') beta
close(1987)

open (1987, FILE='d0.txt')
read(1987, '(F10.4)') d0
close(1987)

open (1987, FILE='d1.txt')
read(1987, '(F10.4)') d1
close(1987)

d0 = d0-d1

call cpu_time(start_time)

call quadrature
indicator_beowolf = 0  !READ FILES CREATED BY BEOWOLF
call compute_grid

call read_data
call simulate

call cpu_time(end_time)
WRITE(nout, '(A7, X, A7, X, A7)') 'Hours ', 'Minutes', 'Seconds'
WRITE(nout, '(I7, X, I7, X, I7)') INT((end_time - start_time) / 3600d+0), &
             INT((end_time-start_time)/60d+0 - INT((end_time - start_time) / 3600d+0)*60d+0),&
INT(end_time-start_time - INT((end_time - start_time) / 3600d+0)*3600d+0 - &
INT((end_time-start_time)/60d+0 - INT((end_time - start_time) / 3600d+0)*60d+0)*60d+0)

end program


subroutine BISEC(func, x1, x2, ERRABS, ERRREL)
implicit none
DOUBLE PRECISION, INTENT(IN) ::  ERRABS, ERRREL
DOUBLE PRECISION, INTENT(IN OUT) :: x2, x1
DOUBLE PRECISION :: diff
INTEGER :: nout

interface
        function func(x)
        implicit none
        DOUBLE PRECISION, INTENT(IN) :: x
        DOUBLE PRECISION :: func
        end function func
END interface

DOUBLE PRECISION :: fl, fh, f_mean, xl, xh, xmean, rel_error

xl=x1
xh=x2
fl=func(xl)
fh=func(xh)
diff = fh-fl

rel_error=1

do WHILE( MIN((ABS(fh)-ERRABS), rel_error-ERRREL) > 0)

xmean =  0.5d+0 * (xl+xh)
!xl - fl / ((fh - fl)/(xh-xl) )  !Use linear approx to find the zero !(xl+xh)/2
f_mean = func(xmean)

if (fl*fh>0) then
   !WRITE(nout,*) 'Wrong range'       !Need change of signs to compute the root
   !call BREAK
else
   if (diff < 0) then
      if (f_mean > 0) then
         xl=xmean
         fl=f_mean
      else
         xh=xmean
         fh=f_mean
      end if
   else
      if (f_mean > 0) then
         xh=xmean
         fh=f_mean
      else
         xl=xmean
         fl=f_mean
      end if
    end if

end if
rel_error=ABS(xh-xl)

!WRITE(6,*) rel_error, fh
end do
x1 = xl
x2 = xh


end subroutine




