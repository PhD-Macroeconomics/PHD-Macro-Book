clear;

%parameter values
beta=0.98;%discount factor
smin=0;%minimum in state space
smax=10;%maximum in state space
Ngrids=100; %number of grids on state space
gold=0.38197; %golden section


%construct grids
step=(smax-smin)/(Ngrids-1);%interval between grids
sgrids=smin:step:smax;%construct grid


%initial value function
v=zeros(Ngrids,1);
policy=zeros(Ngrids,1);
Newv=zeros(Ngrids,1);

%initialize error
errv=100;


%Value function iteration

while errv>0.000001 %repeat until err becomes very small

    for i=1:Ngrids %state variable (how much you have today)
        
        spa=sgrids(1); % minumum value for choice
        spc=sgrids(i); % maximum value for choice
        spb=spa+gold*(spc-spa);% middle value for golden section search
        
        tempva=sqrt(sgrids(i)-spa)+beta*v(i);% next period value will be grid i (eat none)
        tempvc=sqrt(sgrids(i)-spc)+beta*v(1);% next period value will be grid 1 (eat all)
        
        % calculate the value for mid value
        
                %first find the location of spb in the grids
                %note that this is not the most efficient way of doing this
                %(see Numerical Recipes for a better method)
            
                gspb=1;
                for j=1:i-1
                    if spb>sgrids(j) && spb<=sgrids(j+1)
                        gspb=j; 
                        break
                    end
                end
            
                %interpolate
            
                vb=v(gspb)*(sgrids(gspb+1)-spb)/(sgrids(gspb+1)-sgrids(gspb))...
                     +v(gspb+1)*(spb-sgrids(gspb))/(sgrids(gspb+1)-sgrids(gspb));
             
                tempvb=sqrt(sgrids(i)-spb)+beta*vb; % Bellman equation
        
        % start golden section search
        
                errg=100;
                
            %first check bracketing, just in case (the case of corner
            %solution)
        
                if tempvb<min(tempva,tempvc)
                    if tempva>tempvc
                    spm=spa;
                    tempvm=tempva;
                    errg=0;
                    else
                    spm=spc;
                    tempvm=tempvc;
                    errg=0;
                    end
                end
        
            %start the loop   
           
            while errg>0.00001
        
                if (spb-spa)>(spc-spb) %find the longer segment
                    
                    spm=spb-gold*(spb-spa); %new value to try
                
                
                    %find the value at spm by interpolation
        
                        %first find the location of spm in the grids
               
                         gspm=1;
                            for j=1:i-1
                            if spm>sgrids(j) && spm<=sgrids(j+1)
                            gspm=j; 
                            break
                            end
                            end
            
                    %interpolate
            
                    vm=v(gspm)*(sgrids(gspm+1)-spm)/(sgrids(gspm+1)-sgrids(gspm))...
                        +v(gspm+1)*(spm-sgrids(gspm))/(sgrids(gspm+1)-sgrids(gspm));
     
             
                    tempvm=sqrt(sgrids(i)-spm)+beta*vm; % Bellman equation
        
                    if tempvm>tempvb
                        spc=spb;
                        spb=spm;
                        tempvb=tempvm;
                    else
                        spa=spm;
                    end 
                    
                else
                        
                    spm=spb+gold*(spc-spb);
                    
                    
                        %find the value at spm by interpolation
        
                        %first find the location of spm in the grids
               
                         gspm=1;
                            for j=1:i-1
                            if spm>sgrids(j) && spm<=sgrids(j+1)
                            gspm=j; 
                            break
                            end
                            end
            
                    %interpolate
            
                    vm=v(gspm)*(sgrids(gspm+1)-spm)/(sgrids(gspm+1)-sgrids(gspm))...
                        +v(gspm+1)*(spm-sgrids(gspm))/(sgrids(gspm+1)-sgrids(gspm));
     
             
                    tempvm=sqrt(sgrids(i)-spm)+beta*vm; % Bellman equation
        
                    if tempvm>tempvb
                        spa=spb;
                        spb=spm;
                        tempvb=tempvm;
                    else
                        spc=spm;
                    end 
                end
            
                errg=abs(spc-spa);
            
            end   
        policy(i)=spm;
        Newv(i)=tempvm;
    end
    
    errv=max(abs(Newv-v)) %distance between new and old value function
    v=Newv; %revise the valuie function
end



%Simulation

Nperiods=100; %number of periods
Periods=zeros(Nperiods,1);
Xseries=zeros(Nperiods,1);
Cseries=zeros(Nperiods,1);

Xseries(1)=sgrids(Ngrids); %value on the starting grid (initial cake)
Periods(1)=1; %just counting periods (for plotting)

for i=1:Nperiods
    Periods(i+1)=i+1; %just counting
    
    % interpolate for next period cake
    Xloc=1;
    for j=1:Ngrids
    if Xseries(i)>sgrids(j) && Xseries(i)<=sgrids(j+1)
    Xloc=j; 
    break
    end
    end
    Xseries(i+1)=policy(Xloc)*(sgrids(Xloc+1)-Xseries(i))/(sgrids(Xloc+1)-sgrids(Xloc))...
                        +policy(Xloc+1)*(Xseries(i)-sgrids(Xloc))/(sgrids(Xloc+1)-sgrids(Xloc));
     
    
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
plot(sgrids,policy) %policy function
title('Policy function for aprime')