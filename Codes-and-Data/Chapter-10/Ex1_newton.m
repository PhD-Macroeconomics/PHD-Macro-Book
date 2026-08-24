clear all;

%set parameters
alpha=1/3;
x=0.5;
omega=1;
gamma=2;



%initial value
err=1;
m=0.5;%initial guess

while err>0.00001
    
    gm=(alpha*m^(alpha-1))/(m^alpha+x)-omega*m^(gamma-1); 
    
    %first derivative
    gprimem=(alpha*(alpha-1)*m^(alpha-2))/(m^alpha+x)-((alpha*m^(alpha-1))^2)/((m^alpha+x)^2)-(gamma-1)*omega*m^(gamma-2);
    
    Newm=m-gm/gprimem;
    
    err=abs(gm)
        
    m=Newm
end

answer=m

