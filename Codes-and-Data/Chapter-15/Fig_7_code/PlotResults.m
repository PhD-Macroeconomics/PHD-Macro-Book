%Marina Azzimonti October 2022

clear all
global tax_exper

%load results
load results.mat
load parameters.mat
T2=10;

%normalized by SS
anticipated=1;

Gov_vec=results(:,10);

if anticipated==1
   
years=T+T2;

output=([ones(T2,1); results(:,1)./yss]-1)*100;

if DELTA>0
investment=([ones(T2,1);results(:,2)./(DELTA*kss)]-1)*100;
else
   investment=[zeros(T2,1);results(:,2)];
end

labor=  ([ones(T2,1); results(:,3)./lss]-1)*100 ;
consumption_w= ( [ones(T2,1); results(:,4)./cwss]-1)*100 ;
consumption_k= ( [ones(T2,1); results(:,11)./ckss]-1)*100 ;
consumption= ( [ones(T2,1);(results(:,4)+results(:,11))./(ckss+cwss)] -1)*100 ;

capital= ([ones(T2,1);results(:,5)./kss] -1)*100;
MPK=([ones(T2,1); results(:,6)./rss]-1 )*100;
wages=([ones(T2,1); results(:,8)./wss]-1 )*100;
InterestRate=([ones(T2,1);results(:,9)/Rkss]-1 )*100;

%Transfers=([ones(T2,1); results(:,7)/Tss]-1 )*100;
tauk_vec2=([tauk*ones(T2,1); tauk_vec] );
tauc_vec2=([ones(T2,1); tauc_vec/tauc]-1 )*100;
taul_vec2=([taul*ones(T2,1); taul_vec] );
Gov_vec2=([ones(T2,1); Gov_vec/Gss]-1 )*100;

else
years=T;

output=(results(:,1)./yss-1)*100;

if DELTA>0
investment=(results(:,2)./(DELTA*kss)-1)*100;
else
   investment=results(:,2);
end


labor=  (results(:,3)./lss-1)*100 ;
consumption_w= ( results(:,4)./cwss-1)*100 ;
consumption_k= ( results(:,11)./ckss-1)*100 ;

consumption= ((results(:,4)+results(:,11))./(ckss+cwss) -1)*100 ;
capital= (results(:,5)./kss -1)*100;
MPK=(results(:,6)./rss-1 )*100;
wages=(results(:,8)./wss-1 )*100;
InterestRate=(results(:,9)/Rkss-1)*100;
%Transfers=(results(:,7)/Tss-1 )*100;
tauk_vec2=(tauk_vec/tauk-1 )*100;
tauc_vec2=(tauc_vec/tauc-1 )*100;
taul_vec2=(taul_vec/taul-1 )*100;
Gov_vec2=(Gov_vec/Gss-1 )*100;
end

Gov_vec./results(:,1)

Transfers=zeros(length(Gov_vec2),1);

%plot
save("../Fig7Data.mat","years","capital", "labor", "consumption", "output","Gov_vec2","tauk_vec2","taul_vec2")
createfigure_temp(1:years, capital, labor, consumption, output)
%createfigure_temp_prices(1:years, wages, labor, InterestRate, investment)

createfigure_temp_tax(1:years, Gov_vec2, tauk_vec2, taul_vec2)

%createfigure_temp_tax(1:years, consumption_k, consumption_w, consumption)

return
welfare=log(results(:,4)-results(:,3).^(1+1/THETA)./(1+1/THETA));
welfare_old=log(css-lss.^(1+1/THETA)./(1+1/THETA));

welfare_gain=[zeros(T2,1); (welfare-welfare_old)./abs(welfare_old)*100];
plot(1:years, welfare_gain)

%checkss

%check errors in FOC
error=max((results(:,4)+results(:,11)).*(1+tauc_vec)-(1-taul_vec).*results(:,8).*results(:,3)+results(:,2)-(results(:,9)-(1-DELTA)).*results(:,5)-results(:,7))

error2= max(results(:,4)+results(:,11)+Gov_vec+results(:,2)-results(:,1))
Rv=results(:,9);
ck=results(:,4);
cw=results(:,11);
FOCk=max((ck(2:T,1)./(ck(1:T-1,1))).*(1+tauc_vec(2:T,1))./(1+tauc_vec(1:T-1,1)) -  BETA.*Rv(2:T,1))


%check labor
L=results(:,3);
Lcheck=((1-taul_vec)./(1+tauc_vec).*(z.*(1-ALPHA).*results(:,5).^ALPHA)).^(THETA/(1+ALPHA*THETA));

%check steady state values: code vs algebra in the initial and final SS
yss_new=((1-taul_new)./(1+tauc)*(1-ALPHA))^THETA*(ALPHA*(1-tauk_new)/(rho...
    +DELTA*(1-tauk_new)))^(ALPHA*(1+THETA)/(1-ALPHA));

yss_new_code=results(T,1);

yss_old=((1-taul)./(1+tauc)*(1-ALPHA))^THETA*(ALPHA*(1-tauk)/(rho...
   +DELTA*(1-tauk)))^(ALPHA*(1+THETA)/(1-ALPHA));

yss_old_code=yss;



return

%