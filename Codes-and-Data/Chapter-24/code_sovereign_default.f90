!     Last change:  JCH  13 Jan 2012   10:32 pm
!SAME AS PROBLEM IN DEFCOST BUT WITH RISK AVERSION NOT DEPENDING ON INCOME.
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

end module


!DEFINE UTILITY FUNCTION
DOUBLE PRECISION function u_fun(c)
USE param
DOUBLE PRECISION, INTENT(IN) :: c
DOUBLE PRECISION :: c_min, cons

c_min = 1d-8
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
DOUBLE PRECISION :: dos, DNORDF, delta_y, prob_mass, b_inf0, b_sup0, b_inf1, b_sup1, prob_vector(y_num),&
                    y_left, y_right
INTEGER :: b_num_half, i
EXTERNAL :: DNORDF

std_y = std_eps/ SQRT(1 - rho**2)

coupon = (r+delta)/(1d+0 + r)
y_inf = mean_y - 5*std_y
y_sup = mean_y + 5*std_y
delta_y = 5*std_y / (y_num - 1d+0)

b_inf = -4.0d+0 !* EXP(y_inf)*lambda / (1-recovery)
b_sup =  -0.0001d+0
  

!b_inf0 =  -lambda*exp(y_sup)*r*3    !NEED A SYMMETRIC GRID, SO THAT
!b_sup0 =  0d+0*EXP(y_inf)

!b_inf1 =  -lambda*exp(y_sup)
!b_sup1 =  -lambda*exp(y_sup)*r*3 -0.001

open (11, FILE='y_grid.txt',STATUS='replace')

!b_num_half = INT(0.5*b_num)
!WRITE(nout, *) b_num_half
!
!
!do i=1, b_num_half
!   b_grid(i) = b_inf1 + (b_sup1 - b_inf1) * (i-1) / (b_num_half - 1)
!   WRITE(10, '(F12.8)') b_grid(i)
!end do
!
!do i=b_num_half+1,b_num
!   b_grid(i) = b_inf0 + (b_sup0 - b_inf0) * (i-1) / (b_num-b_num_half)
!   WRITE(10, '(F12.8)') b_grid(i)
!end do


do i=1,b_num
   b_grid(i) = b_inf + (b_sup - b_inf) * (i-1) / (b_num - 1)
end do

do i=1,y_num
   y_grid(i) = y_inf + (y_sup - y_inf) * (i-1) / (y_num - 1)
   WRITE(11, '(F12.8)') y_grid(i)
end do

do i=1,cdf_num
   cdf_grid(i) = cdf_inf + (cdf_sup - cdf_inf) * (i-1) / (cdf_num - 1)
end do

dos = 2d+00

CLOSE(11)
CLOSE(12)
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

open (15, FILE='delta.txt',STATUS='replace')
WRITE(15,'(F12.8)') delta
CLOSE(15)

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

!write(6, '(F12.8, X, F12.8, X, F12.8, X, F12.8, X, F12.8, X, F12.8)') exp(y_initial), d0, d1, min(max(d0 + d1*exp(y_initial),0d+0), 0.95d+0), output


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
INTEGER :: index_b, index_y, NINTV
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
INTEGER :: index_b, index_y, NINTV
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





subroutine iterate
USE param
INTEGER :: d
DOUBLE PRECISION :: y_valor, b_valor, b_valor_def, v_valor, convergence, criteria, deviation, q_fun, b_next, g,&
                    b0_next, b1_next, b, w_value, v_valor_exl, objective_function, dev_q_paid, dev_q_scheme, dev_v,&
                    v0_value, v1_value, q, interpolate, b_next1, b_next0,  b_grid_local(b_num), b_inf_local, b_inf_old,&
                    FDATA(b_num), DLEFT, DRIGHT, BREAK_GRID(b_num), CSCOEF(4,b_num), b_tirar, DCSVAL,&
                    epsilon_grid(cdf_num), dev_q_nodef, objective_function_excl, DNORIN, ERRREL 

DOUBLE PRECISION, DIMENSION(b_num, y_num) :: v0_matrix_new, v1_matrix_new, q_matrix_new, default_decision_new,&
                                             q_scheme, q_scheme_new
DOUBLE PRECISION, DIMENSION(b_num, y_num) :: v_matrix_new, dev_matrix, q_matrix_nodef_new
INTEGER i_b, i_y, i, j, i_def_opt, i_b_zero, indices(1:2), indice_b, num_tirar, ILEFT, IRIGHT,NINTV
EXTERNAL q_fun, objective_function, objective_function_excl, DCSDEC, DCSVAL, DNORIN



if (ABS(b_grid(b_num)) < 1d-10 ) then
   i_b_zero = b_num
else
   i_b_zero = 1
   do WHILE(b_grid(i_b_zero+1)<1d-10)   !FIND THE LARGEST GRID INDEX FOR WHICH b_grid(i) < 0
     i_b_zero = i_b_zero + 1
   end do
end if

!compute spline coefficients of inverse (gaussian cdf)
!COMPUTE SPLINE COEFFICIENT OF INVERSE cdf(epsilon)
!USED LATER TO COMPUTE EXPECTATIONS.
do i=1,cdf_num
   epsilon_grid(i) = DNORIN(cdf_grid(i)) * std_eps
end do

NINTV  = cdf_num - 1
ILEFT  = 0
IRIGHT = 0
DLEFT = (epsilon_grid(2) - epsilon_grid(1)) / (cdf_grid(2) - cdf_grid(1))
DLEFT = (epsilon_grid(cdf_num) - epsilon_grid(cdf_num-1)) / (cdf_grid(cdf_num) - cdf_grid(cdf_num-1))
call  DCSDEC (cdf_num, cdf_grid, epsilon_grid, ILEFT, DLEFT, IRIGHT, DRIGHT, BREAK_eps, CSCOEF_eps)

criteria = 1d-5   !CRITERIA FOR CONVERGENCE
convergence = -1
ERRREL = 1d-10    !PRECISION WITH WHICH THE SPLINE COEFFICIENTS ARE COMPUTED
b_inf_old = b_inf
v1_matrix_new = v1_matrix
v0_matrix_new = v0_matrix
v_matrix_new = v_matrix
q_scheme = 0d+0


do WHILE(convergence<0)
      deviation = 0d+0
      counter = counter + 1
      dev_v = 0d+0
      dev_q_scheme = 0d+0
      dev_q_paid   = 0d+0
      dev_q_nodef  = 0d+0
      do i_y = 1,y_num
!         i_y = 10
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
q_matrix_nodef_rn=0d+0
q_matrix_rn = 0d+0
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!FOR GRAPHS
!i_y_global = 37
!y_initial = y_grid(i_y_global)
!b_initial = 0d+0
!i_default_global=1
!indicator_tirar = 1
!call optimize(b_next1, v_valor)
!pause


!open (119, FILE='spread_menu.txt',STATUS='replace')
!open (120, FILE='optimal.txt',STATUS='replace')
!i_y_global = 12
!y_initial = y_grid(i_y_global)
!b_initial = -0.28 !b_grid(50)
!i_default_global=1
!indicator_tirar = 1
!call optimize(b_next1, v_valor)
!WRITE(120, '(F12.8, X, F12.8)') b_next1, q_fun(b_next1, y_initial)
!i_y_global = 19
!i_default_global=1
!indicator_tirar = 1
!y_initial = y_grid(i_y_global)
!call optimize(b_next1, v_valor)
!WRITE(120, '(F12.8, X, F12.8)') b_next1, q_fun(b_next1, y_initial)
!!i_y_global = 8
!!i_default_global=2
!!indicator_tirar = 1
!!y_initial = y_grid(i_y_global)
!!call optimize(b_next1, v_valor)
!!WRITE(120, '(F12.8, X, F12.8)') b_next1, q_fun(b_next1, y_initial)
!CLOSE(119)
!CLOSE(120)
!WRITE(nout, *) 'Finished'
!pause

      do i_y = 1,y_num
!          WRITE(nout, *) i_y
          i_y_global = i_y
          y_initial = y_grid(i_y)

             i_b_global = b_num
              b_initial = 0d+0
              i_default_global=2 !Country defaults
              i_excl_global=2 !Country is excluded
              b_next1 = 0d+0
              v_valor = -objective_function_excl(b_next1)
!              call optimize(b_next1, v_valor)
              v1_matrix_new(:, i_y) = v_valor
!write(nout, *) v_valor
              

               do i_b = 1,b_num !1,i_b_zero
!                  WRITE(nout, *) i_y, i_b
                  i_b_global = i_b
                  b_initial = b_grid(i_b)
!                  if (i_y ==37) then
!                     indicator_tirar =1
!                  end if


                  i_default_global=1 !Country does not default
                  i_excl_global=1    !Country has access to credit
                  call optimize(b_next0, v_valor)
                  v0_matrix_new(i_b, i_y) = v_valor


                  q_matrix_nodef_new(i_b, i_y) = q_fun(b_next0, y_initial)
                  q_matrix_nodef_rn(i_b, i_y) = q_rn_global
                  q_nodefault_global = q_matrix_nodef_new(i_b, i_y)


!write(nout, *) i_b, v_valor, b_next1
!                  if (indicator_tirar>0) then
                  !WRITE(nout, '(F12.8, X, F12.8, X, F12.8, X, F12.8)') b_next0, b_next1
!                     pause
!                  end if
                  indicator_tirar = 0



                  if (v1_matrix_new(i_b, i_y) > v0_matrix_new(i_b, i_y)) THEN !IT IS OPTIMAL TO DEFAULT
                     b_next_matrix(i_b, i_y) = b_next1
                     default_decision_new(i_b, i_y) = 2
                     v_matrix_new(i_b, i_y) = v1_matrix_new(i_b, i_y)
                  else
                     b_next_matrix(i_b, i_y) = b_next0
                     default_decision_new(i_b, i_y) = 1
                     v_matrix_new(i_b, i_y) = v0_matrix_new(i_b, i_y)
                  END if

                  q_scheme_new(i_b, i_y) =  q_fun(b_initial, y_initial)

                   !UPDATE MATRIX OF PAID q AT EACH STATE
                   q_matrix_new(i_b, i_y) = q_fun(b_next_matrix(i_b, i_y), y_initial)
                   q_matrix_rn(i_b, i_y) = q_rn_global

!                   WRITE(nout, '(I3, X, I3, X, F10.6, X, F10.6, X, F10.6, X, F10.6)') i_y, i_b,&
!q_matrix(i_b, i_y) , q_matrix_new(i_b, i_y), q_matrix_new(i_b, i_y) - q_matrix(i_b, i_y), &
!q_matrix_nodef_rn(i_b, i_y)

                   dev_v =        max(ABS(v_matrix_new(i_b, i_y) - v_matrix(i_b, i_y)), dev_v)
                   dev_q_paid =   MAX(ABS(q_matrix_new(i_b, i_y) - q_matrix(i_b, i_y)), dev_q_paid)
                   dev_q_scheme = MAX(ABS(q_scheme_new(i_b, i_y) - q_scheme(i_b, i_y)), dev_q_scheme)
                   dev_q_nodef =   MAX(ABS(q_matrix_nodef_new(i_b, i_y) - q_matrix_nodef(i_b, i_y)), dev_q_nodef)
!                  WRITE(nout, '(I3, X, I3, X, F10.6, X, F10.6, X, F10.6, X, F10.6)') i_y, i_b, b_next_matrix(i_b,i_y), &
!dev_v, dev_q_paid 
!                  q_matrix_new(i_b, i_y), q_matrix(i_b,i_y)
                  !, dev_q_scheme

                   deviation = MAX(deviation, MAX(dev_v, dev_q_paid))
                   dev_matrix(i_b, i_y) = (q_matrix_new( i_b, i_y) - q_matrix( i_b, i_y))
!                   write(6, '(I3, X, I3, X, F12.8, X, F12.8, X, F12.8)') i_b, i_y, ABS(v_matrix_new(i_b, i_y) - v_matrix(i_b, i_y)), ABS(q_matrix_new(i_b, i_y) - q_matrix(i_b, i_y))
          end do
     end do
!indices = MAXLOC(dev_matrix)
! CLOSE(117)

 WRITE(nout, '(F12.8, X, F5.0, X, F12.8, X, F12.8, X, F12.8, X, F12.8, X, F10.6)') deviation, counter, dev_v, dev_q_paid !, &


!if (counter > 26) then


!end if

 !                                                            dev_q_scheme, dev_q_nodef,q_matrix_new(100,80) 
!3) SAVE RESULTS OF THE CURRENT ITERATION

      open (10, FILE='v.txt',STATUS='replace')
      open (11, FILE='default.txt',STATUS='replace')
!      open (12, FILE='q.txt',POSITION='append')
      open (12, FILE='q.txt', STATUS='replace')
      open (13, FILE='b_next.txt',STATUS='replace')
      open (14, FILE='dev.txt',STATUS='replace')
!      open (16, FILE='q_paid.txt',POSITION='append')

      open (16, FILE='q_paid.txt', STATUS='replace')
      open (17, FILE='counter.txt', STATUS='replace')

      open (110, FILE='b_grid.txt',STATUS='replace')
      open (113, FILE='bounds.txt',STATUS='replace')

      WRITE(113, '(F15.11, X, F15.11)') b_inf, b_sup
      WRITE(113, '(F15.11, X, F15.11)') y_inf, y_sup
      WRITE(17, '(F10.1)') counter


         do i_b = 1,b_num
            WRITE(110, '(F12.8)') b_grid(i_b)
            do i_y = 1,y_num
                     i_y_global = i_y
                     y_initial = y_grid(i_y)
                     b_initial = b_grid(i_b)
                     i_b_global = i_b

                     indicator_tirar=0
                     WRITE(10, '(F25.6, X, F25.6, X, F25.6)') v_matrix_new(i_b, i_y), v0_matrix_new(i_b, i_y), v1_matrix_new(i_b, i_y)
                     WRITE(11, '(F6.2)') default_grid(default_decision_new(i_b, i_y))

                     d = default_decision_new(i_b, i_y)

                     b = b_grid(i_b)
                     g = y_grid(i_y)

                     WRITE(12, '(F15.11)') q_fun(b_grid(i_b), y_grid(i_y))
                     WRITE(13, '(F15.11)') b_next_matrix(i_b, i_y)
                     WRITE(14, '(F15.11)') dev_matrix(i_b, i_y)
                     WRITE(16, '(F15.10, X, F15.10, X, F15.10, X, F15.10)') q_matrix_new(i_b, i_y), q_matrix_nodef_new(i_b, i_y) ,&
                                                         q_matrix_rn(i_b, i_y), q_matrix_nodef_rn(i_b, i_y)
                     indicator_tirar=0
            end do
         end do


 CLOSE(10)
 CLOSE(11)
 CLOSE(12)
 CLOSE(13)
 CLOSE(14)
 CLOSE(16)
 CLOSE(17)
 CLOSE(110)
 CLOSE(113)




!UPDATE VALUES OF MATRICES

default_decision = default_decision_new
q_matrix = q_matrix_new
q_scheme = q_scheme_new
q_matrix_nodef = q_matrix_nodef_new
v0_matrix = v0_matrix_new
v1_matrix = v1_matrix_new
v_matrix = v_matrix_new
!PRINT*,'deviation =', deviation

   if (deviation < criteria .or. counter>501) then
      convergence =1
   end if

end do
!FINALLY, STORE VALUE FUNCTIONS, POLICY FUNCTIONS AND PRICES USING A FINER GRID.
!THIS HELPS TO VISUALIZE THE RESULTS.
end subroutine


program main
USE param
DOUBLE PRECISION :: y_valor, b_valor, f_valor, q_fun, u_fun, start_time, end_time, indicator_external, def
INTEGER  i_b, i_y, IOstatus
EXTERNAL q_fun, u_fun


call cpu_time(start_time)
call quadrature

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

indicator_external = 0 !FROM EXTERNAL FILE
if (indicator_external < 0.5) then
      !INITIAL BOUNDS ON GRID FOR b
      call compute_grid
      counter = 0
      open (10, FILE='v.txt',STATUS='replace')
      open (11, FILE='default.txt',STATUS='replace')

         do i_b = 1,b_num
                 b_initial = b_grid(i_b)
                 !WRITE(nout, '(A10, X, A10, X, A10, X, A10)') 'y', 'b', 'c1', 'c0'

                 do i_y = 1,y_num
                 y_initial = y_grid(i_y)
                 recovery = 0d+0 !EXP(rec_param*b_initial)
                 v1_matrix(i_b, i_y) = u_fun(EXP(y_initial) - exp(y_initial)*min(max(d0 + d1*exp(y_initial),0d+0), 0.95d+0) + recovery*coupon*b_grid(i_b))
!                 v1_matrix(i_b, i_y) = u_fun(EXP(y_grid(i_y)) + b_grid(i_b))
                 v0_matrix(i_b, i_y) = u_fun(EXP(y_grid(i_y)) + coupon*b_grid(i_b))
                 v_matrix(i_b, i_y) = MAX(v1_matrix(i_b, i_y), v0_matrix(i_b,i_y))
                 if (v1_matrix(i_b, i_y) <= v0_matrix(i_b, i_y)) then
                   default_decision(i_b, i_y) = 1
                 else
                   default_decision(i_b, i_y) = 2
                 end if
                 WRITE(10, '(F15.10, X, F15.10, X, F15.10)') v_matrix(i_b, i_y), v0_matrix(i_b, i_y), v1_matrix(i_b, i_y)
                 WRITE(11, '(F6.2)') default_grid(default_decision(i_b, i_y))
                 q_matrix(i_b, i_y) = 0
                 q_matrix_nodef(i_b, i_y) = 0
            end do

         end do
         CLOSE(10)
         CLOSE(11)


else !READ DATA FROM EXTERNAL FILES

open (10, FILE='v.txt')
open (1116, FILE='q_paid.txt')
open (17, FILE='counter.txt')

      call compute_grid
      READ(17, '(F10.1)') counter
      do i_b = 1,b_num
         do i_y = 1,y_num
!                WRITE(nout,*) i_b, i_y
             READ(10, '(F25.6, X, F25.6, X, F25.6)') v_matrix(i_b, i_y),  v0_matrix(i_b, i_y), v1_matrix(i_b, i_y)

!             write(6, '(F15.10, X, F15.10, X, F15.10)') v_matrix(i_b, i_y), &
!                     v0_matrix(i_b, i_y), v1_matrix(i_b, i_y)
           READ(1116, '(F15.10, X, F15.10, X, F15.10, X, F15.10)') q_matrix(i_b, i_y) , q_matrix_nodef(i_b, i_y),&
                                                                    q_matrix_rn(i_b, i_y), q_matrix_nodef_rn(i_b, i_y)

!           write(6, '(F15.10, X, F15.10, X, F15.10, X, F15.10)') q_matrix(i_b, i_y) , q_matrix_nodef(i_b, i_y),&
!                                                                    q_matrix_rn(i_b, i_y), q_matrix_nodef_rn(i_b, i_y)


             if (v1_matrix(i_b, i_y) > v0_matrix(i_b, i_y)) then
                 default_decision(i_b, i_y) =2
             else
                 default_decision(i_b, i_y) =1
             end if

             
!             WRITE(nout, '(I4, X, I4, X, F12.8, X, F12.8, X, F12.8, X, F12.8)') i_b, i_y, &
!v_matrix(i_b, i_y), v0_matrix(i_b, i_y), v1_matrix(i_b, i_y), q_matrix(i_b, i_y)
!             if (def - default_grid(default_decision(i_b, i_y))>0) then
!                WRITE(nout, *) 'puto'
!                pause
!             end if

         end do
      end do
CLOSE(10)
CLOSE(1116)
CLOSE(17)
end if




call iterate
!call simulate
!call compute_initial_guess

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



!y_min = (1-rho)*mean_y + rho* y_initial + eps_grid(1)
!y_max = (1-rho)*mean_y + rho* y_initial + eps_grid(eps_num)
!
!acum_int_lo = 0d+0
!acum_int_hi = 0d+0
!
!   if (y_threshold < y_min) then
!
!       do i=1,eps_num
!          y_next  = 0.5*(quad_x(i) + 1)*(y_max - y_min) + y_min
!          value_next = v0_fun(b, y_next)
!          acum1 = acum1 + 0.5*(y_max - y_min)*quad_w(i) * value_next * &
!                  EXP(- ((y_next - rho*y_initial - (1-rho)* mean_y)**2) / (2*std_eps**2)) / (std_eps * SQRT(2*pi_number))
!          acum_int_lo = acum_int_lo + 0.5*(y_max - y_min)*quad_w(i) * &
!                  EXP(- ((y_next - rho*y_initial - (1-rho)* mean_y)**2) / (2*std_eps**2)) / (std_eps * SQRT(2*pi_number))
!
!       end do
!
!   elseif(y_threshold > y_max) then
!
!       do i=1,eps_num
!          y_next  = 0.5*(quad_x(i) + 1)*(y_max - y_min) + y_min
!          value_next = v1_fun(y_next)
!          acum1 = acum1 + 0.5*(y_max - y_min)*quad_w(i) * value_next * &
!                  EXP(- ((y_next - rho*y_initial - (1-rho)* mean_y)**2) / (2*std_eps**2)) / (std_eps * SQRT(2*pi_number))
!
!
!        acum1 = acum1 + 0.5*(y_threshold - y_min)*quad_w(i) * value_next * &
!        EXP(- ((y_next - rho*y_initial - (1-rho)* mean_y)**2) / (2*std_eps**2)) / (std_eps * SQRT(2*pi_number))
!
!        acum_int_lo = acum_int_lo + 0.5*(y_threshold - y_min)*quad_w(i) * &
!                  EXP(- ((y_next - rho*y_initial - (1-rho)* mean_y)**2) / (2*std_eps**2)) / (std_eps * SQRT(2*pi_number))
!
!
!        !compute integral for y > y_threshold
!         y_next1 = (quad_x(i) + 1)*(y_max - y_threshold)/2 + y_threshold
!         value_next = v0_fun(b, y_next1)
!
!         acum2 = acum2 + 0.5*(y_max - y_threshold)*quad_w(i) * value_next* &
!        EXP(- ((y_next1 - rho*y_initial - (1-rho)* mean_y)**2) / (2*std_eps**2)) / &
!        (std_eps * SQRT(2*pi_number))
!
!        acum_int_hi = acum_int_hi + 0.5*(y_max - y_threshold)*quad_w(i) * &
!                    EXP(- ((y_next1 - rho*y_initial - (1-rho)* mean_y)**2) / (2*std_eps**2)) / (std_eps * SQRT(2*pi_number))
!
!      end do
!   end if
!
!
!
!exp_v_next = (acum1+acum2)/(acum_int_lo + acum_int_hi)
!!
