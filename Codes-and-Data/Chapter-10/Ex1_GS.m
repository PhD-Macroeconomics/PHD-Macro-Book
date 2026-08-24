clear all;

%set parameters
alpha=1/3;
x=0.5;
omega=1;
gamma=2;
gold=0.38197; %golden section




%initial value
a=0;
c=1;
b=c-gold;
err=1;


while err>0.00001
    
    fb=log(b^alpha+x)-omega*b^gamma/gamma;
    
    if (b-a)>(c-b) %longer segment
        m=b-gold*(b-a); %new value to try
        fm=log(m^alpha+x)-omega*m^gamma/gamma;
        if fm>fb
            c=b;
            b=m;
        else
            a=m;
        end
    else
        m=b+gold*(c-b);
        fm=log(m^alpha+x)-omega*m^gamma/gamma;
        if fm>fb
            a=b;
            b=m;
        else
            c=m;
        end
    end
    
    err=abs(a-c)    
        
end

answer=m

