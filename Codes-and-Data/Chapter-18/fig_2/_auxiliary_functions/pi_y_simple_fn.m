function Pi_y = pi_y_simple_fn(beta,kappa,T)

Pi_pi = zeros(T,T);
for t = 1:T
    Pi_pi(t,t) = 1;
    if t < T
    Pi_pi(t,t+1) = -beta;
    end
end

Pi_y = kappa * eye(T);

Pi_y = Pi_pi^(-1) * Pi_y;

end