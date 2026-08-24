%Marina Azzimonti October 2022
% Compute Steady State

function f = solveSteadyState(x)
global BETA;    global THETA;   global DELTA;   global ALPHA;   global z;
global tauk taul tauc Gss;

%lss=x(1);
kss=x(1);
lss=((1-taul)/(1+tauc)*(z*(1-ALPHA)*kss^ALPHA))^(THETA/(1+ALPHA*THETA));

rss=z*ALPHA*kss^(ALPHA-1)*lss^(1-ALPHA);
wss=z*(1-ALPHA)*kss^(ALPHA)*lss^(-ALPHA);
Rkss=1+(1-tauk)*(rss-DELTA);
yss=z*kss^(ALPHA)*lss^(1-ALPHA);

ckss=(Rkss*kss-kss)/(1+tauc);
cwss=((1-taul)*wss*lss)/(1+tauc);
css= ckss+cwss;

Gss=yss+(1-DELTA)*kss-kss-css;

f(1)=(1/BETA-1)/(1-tauk)+DELTA-rss; %FOC capital in SS
%f(2)=(1-taul)/(1+tauc)*wss-lss^(1/THETA); % FOC labor in SS
