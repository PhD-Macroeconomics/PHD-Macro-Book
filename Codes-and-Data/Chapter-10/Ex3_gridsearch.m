clear;

%parameter values
beta=0.98;%discount factor
smin=0;%minimum in state space
smax=10;%maximum in state space
Ngrids=1000; %number of grids on state space


%construct grids
step=(smax-smin)/(Ngrids-1);%interval between grids
sgrids=smin:step:smax;%construct grid


%initial value function
v=zeros(1,Ngrids);

%initialize error
err=100;


%Value function iteration
while err>0.000001 %repeat until err becomes very small
    Newv=zeros(Ngrids,1);
    policyf=zeros(Ngrids,1);
    for i=1:Ngrids %state variable (how much you have today)
        tempv=zeros(Ngrids,1);
        for j=1:Ngrids %choice variable (how much to leave for tomorrow)
            if j>i %cannot eat more than you have
                tempv(j)=-10000; %punish the consumption that is not feasible
            else
                tempv(j)=sqrt(sgrids(i)-sgrids(j))+beta*v(j); %Bellman equation
            end
        end
        %maximize
        [value,ind]=max(tempv); %maximization (simple grid search)
        policyf(i)=ind; %policy function
        Newv(i)=value; %new value function
    end
    err=max(abs(Newv-v)) %distance between new and old value function
    v=Newv; %revise the valuie function
end



%Simulation

Nperiods=100; %number of periods
Periods=zeros(Nperiods,1);
Indseries=zeros(Nperiods,1);
Xseries=zeros(Nperiods,1);
Cseries=zeros(Nperiods,1);

%initialize
Indseries(1)=Ngrids; %starting grid... start from maximum
Xseries(1)=sgrids(Ngrids); %value on the starting grid (initial cake)
Periods(1)=1; %just counting periods (for plotting)

for i=1:Nperiods
    Periods(i+1)=i+1; %just counting
    Indseries(i+1)=policyf(Indseries(i)); %next period grid (use the policy function)
    Xseries(i+1)=sgrids(Indseries(i+1)); %next period cake
    Cseries(i)=Xseries(i)-Xseries(i+1); %consumption at period i
end

%Plot
figure
plot(Periods,Xseries) %plot how much cake is left
title('Leftover cake')
figure
plot(Periods(1:Nperiods),Cseries) %plot consumption
title('Cake consumption')
figure
plot(sgrids,v) %value function
title('Value function')
figure
plot(sgrids,sgrids(policyf)) %policy function
title('Policy function for aprime')