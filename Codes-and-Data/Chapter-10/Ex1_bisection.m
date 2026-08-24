clear;

%set parameters
alpha=1/3;
x=0.5;
omega=1;
gamma=2;

%bisection

%initial value
l=0;
r=1;
err=1;


while err>0.00001
    m=(l+r)/2;
    fl=(alpha*l^(alpha-1))/(l^alpha+x)-omega*l^(gamma-1);
    fm=(alpha*m^(alpha-1))/(m^alpha+x)-omega*m^(gamma-1);
    
    if sign(fl)==sign(fm)
        l=m
    else
        r=m
    end
    
    err=abs(fm)
end

answer=m

