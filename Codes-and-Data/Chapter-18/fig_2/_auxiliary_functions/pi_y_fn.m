function Pi_y = pi_y_fn(gamma_f,gamma_b,kappa,T)

Pi_pi = zeros(T,T);
for t = 1:T
    Pi_pi(t,t) = 1;
    if t < T
        Pi_pi(t,t+1) = -1/4 * gamma_f;
    end
    if t < T-1
        Pi_pi(t,t+2) = -1/4 * gamma_f;
    end
    if t < T-2
        Pi_pi(t,t+3) = -1/4 * gamma_f;
    end
    if t < T-3
        Pi_pi(t,t+4) = -1/4 * gamma_f;
    end
    if t > 1
        Pi_pi(t,t-1) = -1/4 * gamma_b;
    end
    if t > 2
        Pi_pi(t,t-2) = -1/4 * gamma_b;
    end
    if t > 3
        Pi_pi(t,t-3) = -1/4 * gamma_b;
    end
    if t > 4
        Pi_pi(t,t-4) = -1/4 * gamma_b;
    end
end

Pi_y = kappa * eye(T);

Pi_y = Pi_pi^(-1) * Pi_y;

end