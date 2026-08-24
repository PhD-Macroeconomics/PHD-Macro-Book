clear;

%parameter values
beta=0.99;%discount factor
delta=0.0233;%depreciation
alpha=1/3;%capital share
Kstar=((1/beta-1+delta)/alpha)^(1/(alpha-1))*(1/3);%steady-state K with H=1/3
xi=((1-alpha)*Kstar^alpha*(1/3)^(-alpha))/(Kstar^alpha*(1/3)^(1-alpha)-delta*Kstar); %taste parameter on labor disutility

gold=0.38197; %golden section

Kmin=0.9*Kstar;%minimum in state space
Kmax=1.1*Kstar;%maximum in state space
zgrid(1)=0.985; %L
zgrid(2)=1.015; %H
Ngrids=50; %number of grids on state space
p(1,1)=0.95; %L to L
p(1,2)=1-p(1,1); %L to H
p(2,2)=0.95; %H to H
p(2,1)=1-p(2,2); %H to L


%construct grids
step=(Kmax-Kmin)/(Ngrids-1);%interval between grids
Kgrid=Kmin:step:Kmax;%construct grid


%initial value and policy functions
v=zeros(Ngrids,2);
Newv=zeros(Ngrids,2);
policy=zeros(Ngrids,2);

%initialize error
error=100;


%Value function iteration

while error>0.0001 %repeat until err becomes very small
    for z=1:2
        for i=1:Ngrids %state variable (how much you have today)
            
            kpa=Kmin; % minumum value for choice
            kpc=Kmax; % maximum value for choice
            kpb=kpa+gold*(kpc-kpa);% middle value
        
            % calculate the values 
        
                %first find the location of kpa, kpb, kpc in the grids
                loca=Ex4_location(kpa,Kgrid,Ngrids);
                locb=Ex4_location(kpb,Kgrid,Ngrids);
                locc=Ex4_location(kpc,Kgrid,Ngrids);
                
                %interpolate
                va1=v(loca,1)*(Kgrid(loca+1)-kpa)/(Kgrid(loca+1)-Kgrid(loca))...
                     +v(loca+1,1)*(kpa-Kgrid(loca))/(Kgrid(loca+1)-Kgrid(loca));
                va2=v(loca,2)*(Kgrid(loca+1)-kpa)/(Kgrid(loca+1)-Kgrid(loca))...
                     +v(loca+1,2)*(kpa-Kgrid(loca))/(Kgrid(loca+1)-Kgrid(loca));
                laba=Ex4_labor(Kgrid(i),kpa,z,alpha,zgrid,xi,delta); %labor
                consa=max(zgrid(z)*Kgrid(i)^alpha*laba^(1-alpha)+(1-delta)*Kgrid(i)-kpa,0.00001); %consumption
                tempva=log(consa)-xi*laba+beta*(p(z,1)*va1+p(z,2)*va2); %Bellman equation              
                
                vb1=v(locb,1)*(Kgrid(locb+1)-kpb)/(Kgrid(locb+1)-Kgrid(locb))...
                     +v(locb+1,1)*(kpb-Kgrid(locb))/(Kgrid(locb+1)-Kgrid(locb));
                vb2=v(locb,2)*(Kgrid(locb+1)-kpb)/(Kgrid(locb+1)-Kgrid(locb))...
                     +v(locb+1,2)*(kpb-Kgrid(locb))/(Kgrid(locb+1)-Kgrid(locb));
                labb=Ex4_labor(Kgrid(i),kpb,z,alpha,zgrid,xi,delta); %labor
                consb=max(zgrid(z)*Kgrid(i)^alpha*labb^(1-alpha)+(1-delta)*Kgrid(i)-kpb,0.00001); %consumption
                tempvb=log(consb)-xi*labb+beta*(p(z,1)*vb1+p(z,2)*vb2); %Bellman equation  
                
                vc1=v(locc,1)*(Kgrid(locc+1)-kpc)/(Kgrid(locc+1)-Kgrid(locc))...
                     +v(locc+1,1)*(kpc-Kgrid(locc))/(Kgrid(locc+1)-Kgrid(locc));
                vc2=v(locc,2)*(Kgrid(locc+1)-kpc)/(Kgrid(locc+1)-Kgrid(locc))...
                     +v(locc+1,2)*(kpc-Kgrid(locc))/(Kgrid(locc+1)-Kgrid(locc));
                labc=Ex4_labor(Kgrid(i),kpc,z,alpha,zgrid,xi,delta); %labor
                consc=max(zgrid(z)*Kgrid(i)^alpha*labc^(1-alpha)+(1-delta)*Kgrid(i)-kpc,0.00001); %consumption
                tempvc=log(consc)-xi*labc+beta*(p(z,1)*vc1+p(z,2)*vc2); %Bellman equation  
            
                
            % start golden section search
        
                errg=100;
                
            %first check bracketing, just in case
        
                if tempvb<min(tempva,tempvc)
                    if tempva>tempvc
                    kpm=kpa;
                    tempvm=tempva;
                    errg=0;
                    else
                    kpm=kpc;
                    tempvm=tempvc;
                    errg=0;
                    end
                end
        
            %start the loop   
           
            while errg>0.00001
                
                if (kpb-kpa)>(kpc-kpb) %find the longer segment
                    
                    kpm=kpb-gold*(kpb-kpa); %new value to try
                
                    %find the value at kpm by interpolation
                    %first find the location of kpm in the grids
                    locm=Ex4_location(kpm,Kgrid,Ngrids);
                    %interpolate
                    vm1=v(locm,1)*(Kgrid(locm+1)-kpm)/(Kgrid(locm+1)-Kgrid(locm))...
                        +v(locm+1,1)*(kpm-Kgrid(locm))/(Kgrid(locm+1)-Kgrid(locm));
                    vm2=v(locm,2)*(Kgrid(locm+1)-kpm)/(Kgrid(locm+1)-Kgrid(locm))...
                        +v(locm+1,2)*(kpm-Kgrid(locm))/(Kgrid(locm+1)-Kgrid(locm));
                    labm=Ex4_labor(Kgrid(i),kpm,z,alpha,zgrid,xi,delta); %labor
                    consm=max(zgrid(z)*Kgrid(i)^alpha*labm^(1-alpha)+(1-delta)*Kgrid(i)-kpm,0.00001); %consumption
                    tempvm=log(consm)-xi*labm+beta*(p(z,1)*vm1+p(z,2)*vm2); %Bellman equation    
        
                    if tempvm>tempvb
                        kpc=kpb;
                        kpb=kpm;
                        tempvb=tempvm;
                    else
                        kpa=kpm;
                    end 
                    
                else
                        
                    kpm=kpb+gold*(kpc-kpb);
                    
                    %find the value at kpm by interpolation
                    %first find the location of kpm in the grids
                    locm=Ex4_location(kpm,Kgrid,Ngrids);
                    %interpolate
                    vm1=v(locm,1)*(Kgrid(locm+1)-kpm)/(Kgrid(locm+1)-Kgrid(locm))...
                        +v(locm+1,1)*(kpm-Kgrid(locm))/(Kgrid(locm+1)-Kgrid(locm));
                    vm2=v(locm,2)*(Kgrid(locm+1)-kpm)/(Kgrid(locm+1)-Kgrid(locm))...
                        +v(locm+1,2)*(kpm-Kgrid(locm))/(Kgrid(locm+1)-Kgrid(locm));
                    labm=Ex4_labor(Kgrid(i),kpm,z,alpha,zgrid,xi,delta); %labor
                    consm=max(zgrid(z)*Kgrid(i)^alpha*labm^(1-alpha)+(1-delta)*Kgrid(i)-kpm,0.00001); %consumption
                    tempvm=log(consm)-xi*labm+beta*(p(z,1)*vm1+p(z,2)*vm2); %Bellman equation    
             
                    if tempvm>tempvb
                        kpa=kpb;
                        kpb=kpm;
                        tempvb=tempvm;
                    else
                        kpc=kpm;
                    end 
                end
            
                errg=abs(kpc-kpa);
            
            end   
        policy(i,z)=kpm;
        Newv(i,z)=tempvm;   
      
        end
    end
    
    error=max(max(abs(Newv-v))) %distance between new and old value function
    v=Newv; %revise the valuie function
end



%Simulation
Nperiods=3000; %number of periods

Periods=zeros(Nperiods+1,1);
Kseries=zeros(Nperiods+1,1);
Hseries=zeros(Nperiods,1);
Cseries=zeros(Nperiods,1);
ISeries=zeros(Nperiods,1);
Zvalueseries=zeros(Nperiods,1);
Yseries=zeros(Nperiods,1);
Zseries=zeros(Nperiods+1,1);

Zseries(1)=1; %first period is L
Kseries(1)=Kstar; %starting value
Periods(1)=1; %just counting periods (for plotting)

for i=1:Nperiods
    Periods(i+1)=i+1; %just counting
    %next period capital
    Kloc=Ex4_location(Kseries(i),Kgrid,Ngrids);
    Kseries(i+1)=policy(Kloc,Zseries(i))*(Kgrid(Kloc+1)-Kseries(i))/(Kgrid(Kloc+1)-Kgrid(Kloc))...
                        +policy(Kloc+1,Zseries(i))*(Kseries(i)-Kgrid(Kloc))/(Kgrid(Kloc+1)-Kgrid(Kloc));
    Hseries(i)=Ex4_labor(Kseries(i), Kseries(i+1), Zseries(i),alpha,zgrid,xi,delta); %labor
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


