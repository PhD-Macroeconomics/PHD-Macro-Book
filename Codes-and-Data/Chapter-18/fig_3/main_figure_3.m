clc; clear all; close all; 

[DATASET.NUM,DATASET.TEXT]  = xlsread('inflation_data.xlsx','DATA');
DATASET.LABEL               = DATASET.TEXT(1,2:3);
DATASET.date                = DATASET.NUM(1:end,1);
DATASET.TSERIES             = DATASET.NUM(1:end,2:3);

Data = DATASET.TSERIES;
Dats = DATASET.date;
LData = Data;
[Nobs,Nvar] = size(LData);

lambda = 1600;

% choose sample
pars.samplestart = 1;
pars.sampleend = 243; % this ends the sample 2019:4 Nobs;
% Nobs1 = pars.sampleend - pars.samplestart + 1;
y=LData(pars.samplestart:pars.sampleend,:);
Cycle = y - [hpfilter(y(:,1),lambda) hpfilter(y(:,2),lambda)];

% compute cross-correlation functions
window = 8;
Correl = zeros(2*window+1,3);

data1 = Cycle(4:243,:);
data1a = Cycle(4:155,:);
data1b = Cycle(156:243,:);

for i=-window:window

    data2(:,1) = lagmatrix(data1(:,1),-i);
    data2(:,2) = data1(:,2);
    data3 = rmmissing(data2);
    correl(window+1+i,1) = corr(data3(:,1),data3(:,2));
    
    data2a(:,1) = lagmatrix(data1a(:,1),-i);
    data2a(:,2) = data1a(:,2);
    data3a = rmmissing(data2a);
    correl(window+1+i,2) = corr(data3a(:,1),data3a(:,2));

    data2b(:,1) = lagmatrix(data1b(:,1),-i);
    data2b(:,2) = data1b(:,2);
    data3b = rmmissing(data2b);
    correl(window+1+i,3) = corr(data3b(:,1),data3b(:,2));

end

index1 = -8:1:8;

plot(index1,correl(:,2),'b--o',index1,correl(:,3),'r--x',index1,correl(:,1),'k--*',index1,zeros(2*window+1,1),'-','LineWidth',2.5);
title('Correlation between Labor Share(t) and Inflation(t+i)');
legend('1960:1-1997:4','1998:1-2019:4','Full sample');
xlabel('i');
ylabel('Correlation');
% printpdf(gcf,'Figure_Morten');

