clear all; close all;
 

Pal =               [68,    119,    170;...                 % blue
                    102,    204,    238;...                 % cyan   
                     34,    136,     51;...                 % green
                    238,    102,    119;...                 % red
                    170,     51,    119]...                 % pink
                    / 255; 

color_s=Pal(1,:);
color_h=Pal(4,:);
color_s=[0 0.45 0.74]; % blue 
color_h=[80 33 0]/100; % burned orange
lighto=0.7*color_h; 

% Load in expenditures, quantity index and price index from NIPA

%---------------------------------------%
% Table 2.3.5, from 1929 - 2024
% personal consumption expenditures by major type of product
% in billion of dollars

indx = [25;                                   % nondurables
        47];                                  % services
table2_4_5=readmatrix('NIPATable2_4_5.xlsx'); % expenditures
table2_4_5=table2_4_5(:,3:end)';
exp_h= table2_4_5(:,50);                      % expenditures on housing services
exp_c= sum(table2_4_5(:,indx)')';             % expenditures on nondurables and services
exp_t= table2_4_5(:,1);

expenditures = [table2_4_5(:,indx)];  

table2_4_4=readmatrix('NIPATable2_4_4.xlsx');  % prices
table2_4_4=table2_4_4(:,3:end)';
p_h = [table2_4_4(:,50)];                      % rents

table2_4_3=readmatrix('NIPATable2_4_3.xlsx');  % quantities
table2_4_3=table2_4_3(:,3:end)';

% Price and quantity index -----------------

for i=1:length(indx);
    QI(:,i)=table2_4_3(:,indx(i));
    PI(:,i)=table2_4_4(:,indx(i));
    expend(:,i)=table2_4_5(:,indx(i));
    w(:,i)=mean(expend(:,i)./(PI(:,i).*QI(:,i)));  % weights PoQo
end

T=length(PI);

priceindex(1)=1;
qtyindex(1)=1;

for i=2:T  
    priceindex(i)=priceindex(i-1)*sqrt((sum(w.*PI(i,:).*QI(i-1,:))*sum(w.*PI(i,:).*QI(i,:)))/...
                  (sum(w.*PI(i-1,:).*QI(i-1,:))*sum(w.*PI(i-1,:).*QI(i,:))));
    qtyindex(i)=qtyindex(i-1)*sqrt((sum(w.*PI(i-1,:).*QI(i,:))*sum(w.*PI(i,:).*QI(i,:)))/...
                  (sum(w.*PI(i-1,:).*QI(i-1,:))*sum(w.*PI(i,:).*QI(i-1,:))));
end

% constructed price and quantity index series, releveled to 1996=100.       
p_c=(100/(mean(priceindex(68))))*priceindex';   % price index of nondurables & services
q_c=(100/(mean(qtyindex(68))))*qtyindex';       % quantity index of nondurables & services

pi_c=diff(log(p_c));                            % log inflation 1930-2024
p_h=(100/p_h(68))*p_h;                          % rent (price)
Pi = p_c(2:end)./p_c(1:end-1);                  % level inflation 
pgrowth = log(Pi);

% get population numbers
table2_1=readmatrix('NIPATable2_1.xlsx');
table2_1=(table2_1(:,3:end))';
pop = table2_1(:,43)/1000;

year=(1929:2024)';
yearD = year(2:end);

% check out weird behavior of population growth in immediate postwar period
figure;
subplot(2,1,1);
plot(year, pop); title('U.S. Population (in Millions)');
axis([year(1) year(end) 120 320]);
subplot(2,1,2);
popgrowth = diff(log(pop));
plot(yearD, popgrowth); title('Growth Rate of U.S. Population');
axis([year(1) year(end) 0 0.025]);

% per capita consumption growth
cgrowth = diff(log(q_c)) - popgrowth;


% check out how smooth consumption growth is, except for Great Depression
% deflation in Great Depression, not in Great Recession

month=12*ones(length(year),1);
day=31*ones(length(year),1);
dates=[year month day];

figure;
plot(datetime(dates), zeros(length(year),1), 'k', datetime(dates(2:end,:)), cgrowth,'b','Linewidth',2); title('Aggregate Per Capita Real Consumption Growth');
% recessionplot;
axis tight;
print -dpdf annualcgrowth.pdf;

figure;
subplot(2,1,1);
plot(year, zeros(length(year),1), 'k', year(2:end), cgrowth,'b'); title('Per Capita Consumption Growth');
axis([1928 2022 -0.08 0.08]);
subplot(2,1,2);
plot(year, zeros(length(year),1),'k', year(2:end), pgrowth,'b'); title('Inflation');
axis([1928 2022 -0.1 0.15]);


% Load GDP and its price deflator
table1_1_4=readmatrix('NIPATable1_1_4.xlsx');
table1_1_4=table1_1_4(:,3:end)';
GDPdefl=table1_1_4(:,1);
pgrowth_GDP = diff(log(GDPdefl));

figure;
subplot(2,1,1);
plot(year, zeros(length(year),1), 'k', year(2:end), pgrowth_GDP,'b'); title('GDP inflation');
axis([1928 2022 -0.1 0.15]);
subplot(2,1,2);
plot(year, zeros(length(year),1),'k', year(2:end), pgrowth,'b'); title('Inflation');
axis([1928 2022 -0.1 0.15]);

% [acf,lags]=autocorr(cgrowth);

disp('----------------TABLE 1 ------------------------')
disp('consumption growth')
disp('long sample stats: mean, std, autocorrelation');
disp([mean(cgrowth) std(cgrowth)  ]);

disp('postwar sample stats: mean, std, autocorrelation');
cgrowth_post= cgrowth(20:end);
% [acf,lags]=autocorr(cgrowth_post);

disp([mean(cgrowth_post) std(cgrowth_post) ]);


% %---------------risk free rate from Shiller -------------------------------------------------%
data = readmatrix('chapt26.xlsx', "Sheet" ,'Data');
rf = data(59+7:end,5); % nominal one year rate starting in 1929
yL = data(59+7:end,6); % nominal 10 year rate starting in 1929

% 1 year Treasury rate from FRED
rf_postwar = readmatrix('DGS1.xlsx',"Sheet",'Annual'); rf_postwar=rf_postwar(:,2); % end of year value
yL_postwar = readmatrix('DGS10.xlsx',"Sheet",'Annual'); yL_postwar = yL_postwar(:,2);

% combine with shiller's earlier series
rf = [rf(1:33);rf_postwar];  % 1929 - 2024
yL = [yL(1:33);yL_postwar];

Rf = rf/100+1;  % gross nominal short rate 
YL = yL/100+1;  % gross nominal long rate
Rf_real = Rf(2:end)./Pi; % gross real rate 1930-2024
% [acf,lags]=autocorr(Rf_real-1);

disp('real rate');
disp([mean(Rf_real-1) std(Rf_real-1) ])

PL = exp(-10*log(YL));  % takes RL nominal gross rate

RL = PL(2:end)./PL(1:end-1); % nominal return on long bond
RL_real=RL./Pi; % real return on nominal bond

% RL_real_10year = (((yL(1:end-10)/100+1).^10).*(p_c(1:end-10)./p_c(11:end))).^(1/10)-1;
% 
% RL_real_10year=RL_real_10year(2:end);

% Rf = Rf(2:end); % gross nominal rate 1930-2024
% YL = YL(2:end); % gross nominal rate on long bond



% -----------------------------------------------------------------------------%
ie_data=readmatrix('ie_data.xls',"Sheet",'Data');
ie_data=ie_data(5:end,:);

T=floor(length(ie_data)/12);
Ds=zeros(T,1);
Ps=Ds;PDratios=Ds; 

% average dividends/earnings over the past year
for j=1:T
    Ds(j)=sum(ie_data((j-1)*12+(1:12)',3))/12;
    y(j)=ie_data(j*12,1);
    Ps(j)=ie_data(j*12,2); % use quarter-end
    PDratios(j)=Ps(j)/Ds(j);  % divide by annualized dividends    
end

Ds=Ds(59:end);  % 1929-2024
Ps=Ps(59:end); 
PDratios=PDratios(59:end); 

Rs=(Ds(2:end)+Ps(2:end))./Ps(1:end-1); % gross nominal stock returns 1930-2024
Rs_real=Rs./Pi;                        % gross real stock returns 1930-2024
Dsgrowth=(Ds(2:end)./Ds(1:end-1))./Pi; % real dividend growth 
% [acf,lags]=autocorr(Rs_real);

disp('stock returns');

disp([mean(Rs_real-1) std(Rs_real) ])

disp('----------------------------');
% run regression starting in 1947

Rs_post = Rs(17:end); 
Rf_post = Rf(17:end-1); 
x = (1./PDratios(17:end-1));


disp('------------- Table 2: stock return forecasting regressions-----------')
for i = 1:10
Rsmulti = multiyear(Rs_post,i);
Rfmulti = multiyear(Rf_post,i);
exr =Rsmulti - Rfmulti;
[b,se_b, R2] =olsgmm(exr,[ones(length(exr),1) x(1:end-i+1)],i, 0);
disp([b(2) b(2)/se_b(2) R2]);
end


i = 10;
Rsmulti = multiyear_a(Rs_post,i);
Rfmulti = multiyear_a(Rf_post,i);
exr = Rsmulti - Rfmulti;

figure;
plot(yearD(17+i-1:end)-i,exr,'k','Linewidth',2); hold on;
plot(year(17:end),4./PDratios(17:end),'color',[0.5 0.5 0.5], 'Linewidth',2); hold on;
axis([1947 2024 -.10 .30]);
text(1959,0.15,'4 D/P','Color',[0.5 0.5 0.5],'Fontsize',11);
text(1959,0.07,'excess return','Color', [0 0 0],'Fontsize',11);
print('-dpdf','predict.pdf');

%write to csv
T = array2table([yearD(17+i-1:end)-i,exr], 'VariableNames', {'Year', 'exr'});
writetable(T, 'Fig_5_data_excessreturn.csv');

T = array2table([year(17:end),4./PDratios(17:end)], 'VariableNames', {'Year', 'PDratiosX4'});
writetable(T, 'Fig_5_data_4DP.csv');



%---------------------- valuation ratios -------------------------------
% NIPA Fixed asset tables  (year-end values)
% 1925 - 2023 annual data, in millions of dollars

% table gets updated in november every year!!!
data=readmatrix('SFFixed2_1.xlsx');
data = data(:,3:end)';

Ph=data(5:end,8);    % 1925-2023 so start with 5th row, line 67 residential structures 
Ph=Ph*(1/(1-0.36));  % adjustment for the value of the land in the housing stock
Ph=[Ph;Ph(end)];     % repeat 2023 to get a value for 2024

ad= 0.016  + (1-0.33)*0.01;       % flow cost of owning: maintenance (assume equal to depreciation) and property taxes
Dh= exp_h  - ad*Ph ;              % 1929-2023
PDratioh=Ph./Dh;                  % 1929-2023


figure;
baxis=[5 90];
plot(year,PDratios, 'color', [0 0 0], 'Linewidth',2); 
hold on;
plot(year,PDratioh, 'color',[.5 .5 .5], 'Linewidth',2);
% title('Price-dividend ratios for housing and stocks');
text(1953,50,'Housing'); 
text(1953, 15,'Stocks'); 
axis([year(1) year(end) baxis]);
print -dpdf price_cashflows.pdf;

% Convert to table and write to csv
colNames = {'Year', 'PDratios', 'PDratioh'};
T = array2table([year PDratios PDratioh], 'VariableNames', colNames);
writetable(T, 'Fig_1_data.csv');
