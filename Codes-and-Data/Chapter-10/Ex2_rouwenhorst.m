clear;

sigma=0.2;
rho=0.95;
sigmay=sigma/sqrt(1-rho^2);

ngrids=10;
p=(rho+1)/2;
ymax=sqrt(ngrids-1)*sigmay;
ymin=-ymax;

%create grids
ygrid=linspace(ymin,ymax,ngrids);

%create Markov matrix (prob(i,j) is the probability of i to j)

prob= [p 1-p; 1-p p];

for i=2:ngrids-1
  prob = p*[prob zeros(i,1);zeros(1,i+1)] + ...
         (1-p)*[zeros(i,1) prob;zeros(1,i+1)] + ...
         (1-p)*[zeros(1,i+1);prob zeros(i,1)] + ...
         p*[zeros(1,i+1); zeros(i,1) prob];
  prob(2:i,:) = prob(2:i,:)/2;
end 
