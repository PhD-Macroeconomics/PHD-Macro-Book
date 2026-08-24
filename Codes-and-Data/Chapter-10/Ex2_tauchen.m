clear;

sigma=0.2;
rho=0.95;
sigmay=sigma/sqrt(1-rho^2);

ngrids=10;
ymax=sigmay*3;
ymin=-sigmay*3;
step=(ymax-ymin)/(ngrids-1);
ygrid=zeros(ngrids);
prob=zeros(ngrids,ngrids);

%create grids
ygrid(1)=ymin;
for i=2:ngrids
    ygrid(i)=ygrid(i-1)+step;
end

%create Markov matrix (prob(i,j) is the probability of i to j)

for i=1:ngrids
  prob(i,1) = normcdf((ygrid(1)-rho*ygrid(i)+ 0.5*step)/sigma);
  for j = 2:ngrids-1
		prob(i,j) = normcdf((ygrid(j)-rho*ygrid(i)+0.5*step)/sigma)-normcdf((ygrid(j)-rho*ygrid(i)-0.5*step)/sigma);
  end 
		prob(i,ngrids) = 1 - normcdf((ygrid(ngrids)-rho*ygrid(i) - 0.5*step)/sigma);
end 


