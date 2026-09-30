// This file simulates a cost-push shock in a basic New Keynesian model with
// optimal policy under commitment 
// To run the file, you will need Dynare


var y, pi, i, p;
varexo eta;

parameters beta, lambda, kappa;

// Parameter values
beta = 0.99;
lambda = 0.2/3;
kappa = 0.2;



model;
pi=beta*pi(+1)+kappa*y + eta; 
pi = - lambda/kappa * (y - y(-1));
y = y(+1) - (i - pi(+1));
p = p(-1) + pi;
end;

initval;
y=0;
pi=0;
end;

steady;
check;

shocks;
var eta;
stderr 1;
end;


stoch_simul(irf=20, order=1); 