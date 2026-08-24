
clear;
format longg;


alpha = 0.33;

beta = 0.97;
rho = (1/beta)-1;

delta = 0.07;
phi = 1;

tauc = 0;
g = 0.2;

klz = ( alpha/(rho+delta) )^(1/(1-alpha));
lz = ( (1-alpha)*klz^alpha  )^phi;
yz = klz^alpha*lz;
cwz = (1-alpha)*yz;
ckz = rho*( alpha/(rho+delta) )*yz;
ceqwz = (1/(1+phi))*cwz;

for j=1:101;

    tauk(j)=(j-1)/100;
    kl(j) = ( alpha*(1-tauk(j))/(rho+delta*(1-tauk(j))) )^(1/(1-alpha));
    taul(j) = (1/(1-alpha))*(g - tauk(j)*rho*(alpha/(rho+(1-tauk(j))*delta)));
    l(j) = ( ((1-taul(j))/(1+tauc))*(1-alpha)*kl(j)^alpha  )^phi;
    y(j) = kl(j)^alpha*l(j);
    cw(j) = ((1-taul(j))/(1+tauc))*(1-alpha)*y(j);
    ck(j) = (rho/(1+tauc))*( alpha*(1-tauk(j))/(rho+(1-tauk(j))*delta) )*y(j);
    gc(j) = g*y(j);
    k(j) = kl(j)*l(j);
    ceqw(j) = (1/(1+phi))*cw(j);

    costw(j) = ( ceqw(j)-ceqwz )/ceqwz;
    costk(j) = ( ck(j)-ckz )/ckz;
    exc(j) = ( ceqwz-ceqw(j)+ckz-ck(j)-g*y(j) )/(g*y(j));

end;

figure(1);
orient(1,'landscape');

subplot(2,2,1);
plot(tauk,taul,'Linewidth',2);
grid on;
set(gca,'FontSize',14)
title('A: $\tau^{\ell}$', 'fontsize', 14,'Interpreter', 'latex');
xlabel('$\tau^k$','Interpreter', 'latex');
ylim([-0.2,0.4]);

subplot(2,2,2);
plot(tauk,cw,tauk,tauk*0+cwz,'Linewidth',2);
grid on;
set(gca,'FontSize',14)
title('B: Worker Consumption', 'fontsize', 14,'Interpreter', 'latex');
legend('Taxes','No Taxes','Location','southwest','Interpreter', 'latex');
xlabel('$\tau^k$','Interpreter', 'latex');
ylim([0,2]);

subplot(2,2,3);
plot(tauk,ck,tauk,tauk*0+ckz,'Linewidth',2);
grid on;
set(gca,'FontSize',14)
title('C: Capitalist Consumption', 'fontsize', 14,'Interpreter', 'latex');
legend('Taxes','No Taxes','Location','northeast','Interpreter', 'latex');
xlabel('$\tau^k$','Interpreter', 'latex');
xlim([0,1]);
ylim([0,0.5]);


subplot(2,2,4);
plot(tauk,100*exc,'Linewidth',2);
grid on;
set(gca,'FontSize',14)
title('D: Excess Cost of Taxation', 'fontsize', 14,'Interpreter', 'latex');
%legend('Workers','Capitalists','Location','southeast');
xlabel('$\tau^k$','Interpreter', 'latex');
ylabel('cents per \$ of $G$','Interpreter', 'latex');
xlim([0,1]);
ylim([0,200]);

print('tauk','-dpdf','-bestfit');


for j=1:101;

    tauk=0;
    taul(j)=(j-1)/100;
    kl(j) = ( alpha*(1-tauk)/(rho+delta*(1-tauk)) )^(1/(1-alpha));
    l(j) = ( ((1-taul(j))/(1+tauc))*(1-alpha)*kl(j)^alpha  )^phi;
    y(j) = kl(j)^alpha*l(j);
    rev(j) = taul(j)*(1-alpha)*y(j);

end;


figure(2);
orient(2,'landscape');

plot(taul,rev,'Linewidth',2);
grid on;
set(gca,'FontSize',14)
title('Tax Revenue', 'fontsize', 14,'Interpreter', 'latex');
xlabel('$\tau^{\ell}$','Interpreter', 'latex');
xlim([0,1]);

print('Laffer','-dpdf','-bestfit');