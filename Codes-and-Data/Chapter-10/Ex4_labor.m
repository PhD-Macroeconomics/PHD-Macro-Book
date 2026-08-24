function [lab]=Ex4_labor(kval,kpval,zstate,alpha,zgrid,xi,delta)

%solve for labor - use bisection
                
                %bracket between 0.2 and 0.5
                l=0.2; 
                r=0.5;
                lerr=1;
                
                while lerr>0.0001 %repeat until lerr becomes very small
                m=(l+r)/2;
                
                denol=max(zgrid(zstate)*kval^alpha*l^(1-alpha)+(1-delta)*kval-kpval,0.00001);
                denom=max(zgrid(zstate)*kval^alpha*m^(1-alpha)+(1-delta)*kval-kpval,0.00001);
                fl=(1-alpha)*zgrid(zstate)*kval^alpha*l^(-alpha)/denol-xi;
                fm=(1-alpha)*zgrid(zstate)*kval^alpha*m^(-alpha)/denom-xi;
    
                if sign(fl)==sign(fm)
                    l=m;
                else
                    r=m;
                end
    
                lerr=abs(l-r);
                end
 lab=m;