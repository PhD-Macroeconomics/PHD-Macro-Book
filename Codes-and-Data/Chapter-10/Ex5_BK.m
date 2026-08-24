clear;


%parameter values
beta=0.99;%discount factor
delta=0.0233;%depreciation
alpha=1/3;%capital share
Kbar=((1/beta-1+delta)/alpha)^(1/(alpha-1))*(1/3);%steady-state K with H=1/3
xi=((1-alpha)*Kbar^alpha*(1/3)^(-alpha))/(Kbar^alpha*(1/3)^(1-alpha)-delta*Kbar); %taste parameter on labor disutility
rho=0.95;

%other steady state variables
Hbar=1/3;
Cbar=Kbar^alpha*Hbar^(1-alpha)-delta*Kbar;

%Matrices
B=[Kbar 0; 0 beta*(1-alpha)*Kbar^(alpha-1)*Hbar^(1-alpha)+1];
A=[Kbar^alpha*Hbar^(1-alpha)+(1-delta)*Kbar -((1-alpha)*Kbar^alpha*Hbar^(1-alpha)/alpha+Cbar); 0 1];
E=[Kbar^alpha*Hbar^(1-alpha)/alpha; beta*Kbar^(alpha-1)*Hbar^(1-alpha)*rho];
F=B\A;
G=B\E;
[Htemp,Jtemp]=jordan(F);

% sort by the eigenvalue
[Jvect,ind]=sort(diag(Jtemp));
J=Jtemp(ind,ind);
H=Htemp(:,ind);

tildeH=inv(H);
Gamma=H\G;
Lambda=-1/(J(2,2)-rho);

%coefficients for c,.k', and h
ccoef1=-tildeH(2,2)^(-1)*tildeH(2,1);
ccoef2=tildeH(2,2)^(-1)*Lambda*Gamma(2);

kcoef1=F(1,1)-F(1,2)*tildeH(2,2)^(-1)*tildeH(2,1);
kcoef2=G(1)+F(1,2)*tildeH(2,2)^(-1)*Lambda*Gamma(2);

hcoef1=1-ccoef1/alpha;
hcoef2=1/alpha-ccoef2/alpha;

%impulse responses (% deviation)
IR_y=zeros(150,1);
IR_c=zeros(150,1);
IR_h=zeros(150,1);
IR_z=zeros(151,1);
IR_i=zeros(150,1);
IR_k=zeros(151,1);
tseries=1:1:150;

IR_k(1)=0;
IR_z(1)=0.7;
for time=1:150 
IR_c(time)=ccoef1*IR_k(time)+ccoef2*IR_z(time);
IR_h(time)=hcoef1*IR_k(time)+hcoef2*IR_z(time);
IR_y(time)=IR_z(time)+alpha*IR_k(time)+(1-alpha)*IR_h(time);
IR_k(time+1)=kcoef1*IR_k(time)+kcoef2*IR_z(time);
IR_i(time)=(IR_k(time+1)-(1-delta)*IR_k(time))/delta;
IR_z(time+1)=rho*IR_z(time);
end 

subplot(2,3,1)
plot(tseries,IR_y)
title(texlabel('y_t'))
subplot(2,3,2)
plot(tseries,IR_c)
title(texlabel('c_t'))
subplot(2,3,3)
plot(tseries,IR_h)
title(texlabel('h_t'))
subplot(2,3,4)
plot(tseries,IR_z(1:150))
title(texlabel('z_t'))
subplot(2,3,5)
plot(tseries,IR_i)
title(texlabel('i_t'))
subplot(2,3,6)
plot(tseries,IR_k(1:150))
title(texlabel('k_t'))


%Simulation
Nperiods=3000; %number of periods

Periods=1:1:Nperiods;
% all in logs
Kseries=zeros(Nperiods+1,1);
Hseries=zeros(Nperiods,1);
Cseries=zeros(Nperiods,1);
Iseries=zeros(Nperiods,1);
Zvalueseries=zeros(Nperiods+1,1);
Yseries=zeros(Nperiods,1);


Zvalueseries(1)=0; %first period is ss
Kseries(1)=0; %starting value

for time=1:Nperiods
Cseries(time)=ccoef1*Kseries(time)+ccoef2*Zvalueseries(time);
Hseries(time)=hcoef1*Kseries(time)+hcoef2*Zvalueseries(time);
Yseries(time)=Zvalueseries(time)+alpha*Kseries(time)+(1-alpha)*Hseries(time);
Kseries(time+1)=kcoef1*Kseries(time)+kcoef2*Zvalueseries(time);
Iseries(time)=(Kseries(time+1)-(1-delta)*Kseries(time))/delta;
eps=normrnd(0,0.007);
Zvalueseries(time+1)=rho*Zvalueseries(time)+eps;
end

%detrend

logY=Yseries(100:Nperiods);
logK=Kseries(100:Nperiods);
logC=Cseries(100:Nperiods);
logI=Iseries(100:Nperiods);
logH=Hseries(100:Nperiods);
logZ=Zvalueseries(100:Nperiods);

Ytrend=hpfilt(logY,1600);
Ktrend=hpfilt(logK,1600);
Ctrend=hpfilt(logC,1600);
Itrend=hpfilt(logI,1600);
Htrend=hpfilt(logH,1600);
Ztrend=hpfilt(logZ,1600);

Ycycle=logY-Ytrend;
Kcycle=logK-Ktrend;
Hcycle=logH-Htrend;
Ccycle=logC-Ctrend;
Icycle=logI-Itrend;
Zcycle=logZ-Ztrend;
%standard deviations

stdY=std(Ycycle)
stdK=std(Kcycle)
stdH=std(Hcycle)
stdC=std(Ccycle)
stdI=std(Icycle)
stdZ=std(Zcycle)


corrKY=corrcoef(Kcycle,Ycycle)
corrHY=corrcoef(Hcycle,Ycycle)
corrCY=corrcoef(Ccycle,Ycycle)
corrIY=corrcoef(Icycle,Ycycle)
corrZY=corrcoef(Zcycle,Ycycle)


