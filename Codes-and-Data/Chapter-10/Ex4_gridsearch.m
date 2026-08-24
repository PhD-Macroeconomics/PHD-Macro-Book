clear;


%parameter values
beta=0.99;%discount factor
delta=0.0233;%depreciation
alpha=1/3;%capital share
Kstar=((1/beta-1+delta)/alpha)^(1/(alpha-1))*(1/3);%steady-state K with H=1/3
xi=((1-alpha)*Kstar^alpha*(1/3)^(-alpha))/(Kstar^alpha*(1/3)^(1-alpha)-delta*Kstar); %taste parameter on labor disutility

%steady-state

Kmin=0.9*Kstar;%minimum in state space
Kmax=1.1*Kstar;%maximum in state space
zgrid(1)=0.985; %L
zgrid(2)=1.015; %H
Ngrids=400; %number of grids on state space
p(1,1)=0.95; %L to L
p(1,2)=1-p(1,1); %L to H
p(2,2)=0.95; %H to H
p(2,1)=1-p(2,2); %H to L


%construct grids
step=(Kmax-Kmin)/(Ngrids-1);%interval between grids
Kgrid=Kmin:step:Kmax;%construct grid


%initial value function
v=zeros(Ngrids,2);

%initialize error
error=100;


%Value function iteration

while error>0.0001 %repeat until err becomes very small
    for z=1:2
        for i=1:Ngrids %state variable (how much you have today)
            for j=1:Ngrids %choice variable (how much to leave for tomorrow)
               
                
                %solve for labor - use bisection
                
                %bracket between 0.2 and 0.5
                l=0.2; 
                r=0.5;
                Herror=1;
                
                while Herror>0.0001 %repeat until Herror becomes very small
                m=(l+r)/2;
                
                denol=max(zgrid(z)*Kgrid(i)^alpha*l^(1-alpha)+(1-delta)*Kgrid(i)-Kgrid(j),0.00001);
                denom=max(zgrid(z)*Kgrid(i)^alpha*m^(1-alpha)+(1-delta)*Kgrid(i)-Kgrid(j),0.00001);
                fl=(1-alpha)*zgrid(z)*Kgrid(i)^alpha*l^(-alpha)/denol-xi;
                fm=(1-alpha)*zgrid(z)*Kgrid(i)^alpha*m^(-alpha)/denom-xi;
    
                if sign(fl)==sign(fm)
                    l=m;
                else
                    r=m;
                end
    
                Herror=abs(l-r);
                end
                
                
                
                cons=max(zgrid(z)*Kgrid(i)^alpha*m^(1-alpha)+(1-delta)*Kgrid(i)-Kgrid(j),0.00001); %consumption
                tempv(j)=log(cons)-xi*m+beta*(p(z,1)*v(j,1)+p(z,2)*v(j,2)); %Bellman equation               
                tempH(j)=m;
            end
            %maximize
            [value,ind]=max(tempv); %maximization
            policyf(i,z)=ind; %policy function of K'
            policyH(i,z)=tempH(ind); %policy function of H
            Newv(i,z)=value; %new value function
        end
    end
    
    error=max(max(abs(Newv-v))) %distance between new and old value function
    v=Newv; %revise the value function
end



%Simulation

Nperiods=3000; %number of periods

Periods=zeros(Nperiods+1,1);
Indseries=zeros(Nperiods+1,1);
Kseries=zeros(Nperiods+1,1);
Hseries=zeros(Nperiods,1);
Cseries=zeros(Nperiods,1);
ISeries=zeros(Nperiods,1);
Zvalueseries=zeros(Nperiods,1);
Yseries=zeros(Nperiods,1);
Zseries=zeros(Nperiods+1,1);

Indseries(1)=200; %starting grid (middle)
Zseries(1)=1; %first period is L
Kseries(1)=Kgrid(Indseries(1)); %value on the starting grid 
Periods(1)=1; %just counting periods (for plotting)

for i=1:Nperiods
    Periods(i+1)=i+1; %just counting
    Indseries(i+1)=policyf(Indseries(i),Zseries(i)); %next period grid (use the policy function)
    Kseries(i+1)=Kgrid(Indseries(i+1)); %next period capital
    Hseries(i)=policyH(Indseries(i),Zseries(i)); %labor
    Cseries(i)=zgrid(Zseries(i))*Kseries(i)^alpha*Hseries(i)^(1-alpha)+(1-delta)*Kseries(i)-Kseries(i+1); %consumption at period i
    ISeries(i)=Kseries(i+1)-(1-delta)*Kseries(i); %investment
    Zvalueseries(i)=zgrid(Zseries(i)); %value of z
    Yseries(i)=Cseries(i)+ISeries(i); %GDP
    
    %determine next period state
    zseed=rand;
    if zseed<p(Zseries(i),1)
        Zseries(i+1)=1;
    else
        Zseries(i+1)=2;
    end

    
    
end

%detrend

logY=log(Yseries(100:Nperiods));
logK=log(Kseries(100:Nperiods));
logC=log(Cseries(100:Nperiods));
logI=log(ISeries(100:Nperiods));
logH=log(Hseries(100:Nperiods));
logZ=log(Zvalueseries(100:Nperiods));

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


