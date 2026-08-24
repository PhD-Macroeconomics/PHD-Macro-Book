%clear all
%Compute Table 24.3
%Need to run first the Fortran code code_sovereign_default.f90 and then the code
% simulate_sovereign_default.f90 before running this file. 

clear all
    load data_sim.txt
    load def_per.txt
    load param.txt
    load delta.txt
r = 0.01;
coupon = (r+delta)/(1+r);

data_sim = data_sim;
per_num = param(1);  %HOW MANY PERIODS IN EACH SAMPLE
n =  round (length(data_sim)/per_num) % param(2);        %HOW MANY SAMPLES

y = zeros(per_num, n);
b = zeros(per_num, n);
q = zeros(per_num, n);
c = zeros(per_num, n);
tb = zeros(per_num, n);
d = zeros(per_num, n);
q_rn = zeros(per_num, n);
b_next = zeros(per_num-1, n);
duration = zeros(per_num,n);
recovery = zeros(per_num, n);
for i=1:n
   y(:,i) = data_sim((i-1)*per_num+1:i*per_num,1); 
   b(:,i) = -0.25*data_sim((i-1)*per_num+1:i*per_num,2)*coupon*exp(-r)/(1-(1-delta)*exp(-r)); 
   q(:,i) = data_sim((i-1)*per_num+1:i*per_num,3); 
   c(:,i) = data_sim((i-1)*per_num+1:i*per_num,4); 
   tb(:,i) = data_sim((i-1)*per_num+1:i*per_num,5);
   d(:,i) = data_sim((i-1)*per_num+1:i*per_num,6)-1;
   q_rn(:,i) = data_sim((i-1)*per_num+1:i*per_num,7);
   duration(:,i) = (((1-delta).*q(:,i) +coupon)./(q(:,i)))./(((1-delta).*q(:,i) +coupon)./(q(:,i))-1+delta);
  
   duration(:,i) = (((1-delta).*q(:,i) +coupon)./(q(:,i)))./(((1-delta).*q(:,i) +coupon)./(q(:,i))-1+delta);
end

b_next = b(2:per_num,:);
%g = zeros(per_num, n);
%g(1,:) = 1+y(1,:);
%g(2:per_num,:) = 1+(y(2:per_num,:)-y(1:per_num-1,:));

%CREATE OUTPUT SERIES
num = 500; %HOW MANY PERIODS IN EACH SUBSAMPLE
%b1 = zeros(per_num, n);
%for j=1:n
%    y(1,j) = 1;
 %   for i=2:per_num
 %      y(i,j) = y(i-1,j)*g(i,j);
 %      b1(i,j) = y(i-1,j)*b(i,j);
 %   end
%end

%CREATE OUTPUT SERIES
num = 100; %HOW MANY PERIODS IN EACH SUBSAMPLE
indices = find(sum(d(per_num - num - 25 +1:per_num,:))<1); %LAST DEFAULT: 20 PERIODS BEFORE THE BEGINNING OF EACH SAMPLE.
[i n_samples] = size(indices);

last_y = y(per_num - num+1:per_num,indices);  %TRIM THE FIRST 9500 OBSERVATIONS
last_c = c(per_num - num+1:per_num,indices);  %TRIM THE FIRST 9500 OBSERVATIONS
last_tb = tb(per_num - num+1:per_num,indices);  
last_d = d(per_num - num+1:per_num,indices);
last_b = b(per_num - num+1:per_num,indices);

%last_spreadannual = (((1-delta)./q(per_num - num+1:per_num,:) +1-delta)/1.01).^4 - 1;
last_spreadannual = (log(coupon./q(per_num - num+1:per_num,indices) - delta + 1) - r)*4;
%last_spread = ((1./q(per_num - num+1:per_num,indices))/1.01) - 1;
last_spread = log(coupon./q(per_num - num+1:per_num,indices) - delta + 1) - r;

last_duration = duration(per_num - num+1:per_num,indices);
last_spreadannual_rn = log(coupon./q_rn(per_num - num+1:per_num,indices) - delta + 1) - r;

%CREATE VECTORS OF STD OF RETURNS AND CORRELATION BETWEEN RETURNS, OUTPUT
%AND TB. NEED TO TRIM OBSERVATIONS WHILE THE COUNTRY IS IN DEFAULT.
y_trend = zeros(num, n_samples);
c_trend = zeros(num, n_samples);
tb_trend = zeros(num, n_samples);
spread_trend = zeros(num, n_samples);
spreadannual_trend = zeros(num, n_samples);

lambda = 1600;
for i=1:n_samples
  y_trend(:,i)= hpfilter(last_y(:,i),lambda);            %FILTER log(output)
  c_trend(:,i) = hpfilter(last_c(:,i), lambda);           %FILTER log(consumption)
  tb_trend(:,i) = hpfilter(last_tb(:,i), lambda);         %FILTER tb/output
end

% spread_trend = hpfilter(last_spread, lambda);  %FILTER quaterly spread
% spreadannual_trend = hpfilter(last_spreadannual, lambda); %FILTER annualized spread
%COMPUTE DEVIATIONS FROM TREND  
y_dev = last_y - y_trend;
c_dev = last_c - c_trend;
tb_dev = last_tb - tb_trend;
spread_dev = last_spread - spread_trend;
spreadannual_dev = last_spreadannual - spreadannual_trend;
 
fprintf('Statistics when all sample periods are considered \n')
fprintf('std of output = %f5 \n',100*mean(std(y_dev)))
fprintf('std of cons   = %f5 \n',100*mean(std(c_dev)))
fprintf('std of TB/Y   = %f5 \n',100*mean(std(tb_dev)))
fprintf('std of R_s   = %f5 \n',100*mean(std(spreadannual_dev)))

matrix_corr = zeros(n_samples,3);
matrix_corr1 = zeros(n_samples,1);

for i=1:n_samples
    matrix = corrcoef([y_dev(:,i) c_dev(:,i) tb_dev(:,i) spreadannual_dev(:,i)]);
    matrix_corr(i,:) = matrix(1,2:4);

    %COMPUTE CORRELATION BETWEEN FILTERED SPREAD AND TRADE BALANCE
    matrix1 = corrcoef([spreadannual_dev(:,i) tb_dev(:,i)]);
    matrix_corr1(i) = matrix1(1,2);
end
fprintf('corr(c, y)   = %f5 \n',mean(matrix_corr(:,1)))
fprintf('corr(tb,y)   = %f5 \n',mean(matrix_corr(:,2)))
fprintf('corr(R_s,y)  = %f5 \n',mean(matrix_corr(:,3)))
fprintf('corr(R_s,tb) = %f5 \n',mean(matrix_corr1))
fprintf('Annual mean default rate = %f5 \n', 400*mean(sum(d)/per_num))
fprintf('Mean debt    = %f5 \n',mean(mean(last_b./exp(last_y))))
fprintf('E(R_s)       = %f5 \n',100*mean(mean(last_spreadannual)))
fprintf('Max R_s      = %f5 \n',100*max(max(last_spreadannual)))
fprintf('Duration     = %f5 \n',mean(mean(last_duration))/4)

fprintf('%6.2f \n',25*mean(mean(last_b./exp(last_y))))
fprintf('%6.2f \n',100*mean(mean(last_spreadannual)))



statistics = [mean(std(c_dev))/mean(std(y_dev)) ...
    100*mean(mean(last_b)) ...
    100*mean(mean(last_spreadannual)) ... 
    100*mean(std(last_spreadannual))];


% sample_size = 32;
% max_num_def = max(sum(d));
% num_observations_vector = zeros(n,1); %NUMBER OF OBSERVATIONS PER SAMPLE (AN OBSERVATION
%                                % IS A DEFAULT EPISODE WITH SUFFICIENT
%                                % PERIODS BEFORE THE DEFAULT AND NO
%                                % EXCLUSION IN BETWEEN
% def_per_matrix = zeros(max_num_def,n); %MATRIX OF DEFAULT PERIODS SATISFYING THE ABOVE RESTRICTION
% 
% index_acum = 0; %INDEX OF ACUMULATED NUMBER OF DEFAULT EPISODES
% for i = 1:n
%     def_num = sum(d(:,i));
%     if def_num>0
%        def_periods = def_per(index_acum+1:index_acum+def_num);  %VECTOR OF DEFAULT PERIODS
%        interperiods = zeros(def_num,1);
%        interperiods(1) = def_periods(1);             %SEPARATION BETWEEN DEFAULT PERIODS
%        interperiods(2:def_num)= diff(def_periods);   %SEPARATION BETWEEN DEFAULT PERIODS
%        index_acum = index_acum + def_num;            %COUNT DEFAULT PERIODS IN i SAMPLE.
%                                          %NEEDED TO KEEP TRACK OF SAMPLE
%                                          %CHANGES IN def_per
%        %FIND SAMPLES CONTAINING AT LEAST sample_size PERIODS BEFORE THE
%        %DEFAULT AND THAT THE LAST EXCLUSION PERIOD HAPPENED sample_size + 2
%        %PERIODS AGO (NEEDED TO CLEAR THE SAMPLE FROM OUTLIERS)
%        indices = find(interperiods>sample_size+2);  
%        
%        num_observations_vector(i) = length(indices);        %STORE THE NUMBER OF SUCH SAMPLES
%        if length(indices)>0
%            %ONLY STORE RESULTS IF THERE ARE A POSITIVE NUMBER OF
%            %OBSERVATIONS.
%            def_per_matrix(1:length(indices),i) = def_periods(indices);  
%        end
%     end
% end
% 
% 
% %load data1;
% %y_matrix1 = y_matrix;
% %ra_matrix1 = ra_matrix;
% 
% 
% num_observations = sum(num_observations_vector);
% 
% std_y_vector = zeros(num_observations,1);
% std_c_vector = zeros(num_observations,1);
% std_tb_vector = zeros(num_observations,1);
% std_ra_vector = zeros(num_observations,1);
% std_ra_vector_rn = zeros(num_observations,1);
% mean_b_vector = zeros(num_observations,1);
% mean_b_market_vector = zeros(num_observations,1);
% mean_ra_vector = zeros(num_observations,1);
% mean_duration_vector = zeros(num_observations,1);
% mean_ra_vector_rn = zeros(num_observations,1);
% default_b_vector = zeros(num_observations,1);
% default_rec_vector = zeros(num_observations,1);
% 
% corr_ra_y_vector = zeros(num_observations,1);
% corr_y_c_vector = zeros(num_observations,1);
% corr_ra_tb_vector = zeros(num_observations,1);
% corr_ra_ra_rn_vector = zeros(num_observations,1);
% 
% corr_y_tb_vector = zeros(num_observations,1);
% 
% b_next_before1 = zeros(5,num_observations);
% ra_before1     = zeros(5,num_observations);
% b_next_after1  = zeros(4,num_observations);
% ra_after1      = zeros(4,num_observations);
% new_issuance_before = zeros(5,num_observations);
% new_issuance_after  = zeros(4,num_observations);
% 
% ra_matrix = zeros(sample_size, num_observations);
% y_matrix = zeros(sample_size, num_observations);
% c_matrix = zeros(sample_size, num_observations);
% tb_matrix = zeros(sample_size, num_observations);
% borrowing_matrix = zeros(sample_size, num_observations);
% 
% 
% index_observation = 1;
% for i=1:n
%        for j=1:num_observations_vector(i)
% %            ra_vector = (((1-delta)./q(def_per_matrix(j,i) - sample_size:def_per_matrix(j,i) - 1,i) +1-delta)/1.01).^4 - 1;
%          ra_vector = (log(coupon./q(def_per_matrix(j,i) - sample_size:def_per_matrix(j,i) - 1,i) - delta + 1) - r)*4;
%             
%          ra_vector_rn = (log(coupon./q_rn(def_per_matrix(j,i) - sample_size:def_per_matrix(j,i) - 1,i) - delta + 1) - r)*4;
% 
%          
%             y_vector = y(def_per_matrix(j,i) - sample_size:def_per_matrix(j,i) - 1,i);
%             tb_vector = tb(def_per_matrix(j,i) - sample_size:def_per_matrix(j,i) - 1,i);
%             c_vector = c(def_per_matrix(j,i) - sample_size:def_per_matrix(j,i) - 1,i);
%             b_vector = b(def_per_matrix(j,i) - sample_size:def_per_matrix(j,i) - 1,i);
%             q_vector = q(def_per_matrix(j,i) - sample_size:def_per_matrix(j,i) - 1,i);
%             
%             ra_matrix(:, index_observation) = ra_vector;
%             y_matrix(:, index_observation) = exp(y_vector);
%             c_matrix(:, index_observation) = exp(c_vector);
%             tb_matrix(:, index_observation) = tb_vector;
%             borrowing_matrix(:, index_observation) = b(def_per_matrix(j,i) - sample_size+1:def_per_matrix(j,i),i) - (1-delta)*b_vector;
% 
%                         
%             lambda=1600;
%             hp_y = hpfilter(y_vector,lambda);    %FILTER log 
%             hp_tb = hpfilter(tb_vector,lambda);    %FILTER log 
%             hp_ra = hpfilter(ra_vector,lambda);    %FILTER log 
%             hp_ra_rn = hpfilter(ra_vector_rn,lambda);    %FILTER log 
%             hp_c = hpfilter(c_vector,lambda);    %FILTER log 
%     
%             dev_y = y_vector - hp_y;
%             dev_tb = tb_vector - hp_tb;
%             dev_ra = ra_vector - hp_ra;
%             dev_ra_rn = ra_vector_rn - hp_ra_rn;
%             dev_c = c_vector - hp_c;
%     
%             default_b_vector(index_observation) = b(def_per_matrix(j,i),i)/(exp(y(def_per_matrix(j,i),i))/0.5);
%             default_rec_vector(index_observation) = recovery(def_per_matrix(j,i),i);
% %            fprintf('%8.3f %8.3f %8.3f \n',[ b(def_per_matrix(j,i),i) exp(y(def_per_matrix(j,i),i)) b(def_per_matrix(j,i),i)/exp(y(def_per_matrix(j,i),i))])
%             std_ra_vector(index_observation) = std(dev_ra);
%             std_ra_vector_rn(index_observation) = std(dev_ra_rn);
%             std_c_vector(index_observation) = std(dev_c);
%             std_y_vector(index_observation) = std(dev_y);
%             std_tb_vector(index_observation) = std(dev_tb);
% 
%             matrix = corrcoef(dev_y, dev_c);
%             corr_y_c_vector(index_observation) = matrix(1,2);
% 
%             matrix = corrcoef(dev_y, dev_tb);
%             corr_y_tb_vector(index_observation) = matrix(1,2);
% 
%             matrix = corrcoef(dev_ra, dev_y);
%             corr_ra_y_vector(index_observation) = matrix(1,2);
%     
%             matrix = corrcoef(dev_ra, dev_ra_rn);
%             corr_ra_ra_rn_vector(index_observation) = matrix(1,2);
% 
%             matrix = corrcoef(dev_ra, dev_tb);
%             corr_ra_tb_vector(index_observation) = matrix(1,2);
%     
%             mean_ra_vector(index_observation) = mean(ra_vector);
%             mean_ra_vector_rn(index_observation) = mean(ra_vector_rn);
%             mean_b_vector(index_observation) = mean(b_vector); %b_vector(sample_size);
%             mean_b_market_vector(index_observation) = mean(b_vector.*q_vector);%b_vector(sample_size)*q(def_per_matrix(j,i) - 1,i) ;
%             max_ra_vector(index_observation) = max(ra_vector);
%             mean_duration_vector(index_observation) = mean(duration(def_per_matrix(j,i) - sample_size:def_per_matrix(j,i) - 1,i));
% 
%            if def_per_matrix(j,i)+4 < per_num
%                 b_next_before1(:,index_observation) = b(def_per_matrix(j,i) - 3: def_per_matrix(j,i) + 1,i)*1.01/(delta+.01);
%                 new_issuance_before(:,index_observation) = (b(def_per_matrix(j,i) - 3: def_per_matrix(j,i) + 1,i) - (1-delta)*(1-d(def_per_matrix(j,i) - 4: def_per_matrix(j,i) ,i)).*b(def_per_matrix(j,i) - 4: def_per_matrix(j,i) ,i))*(1-delta)*1.01/(delta+.01);
%                 %ra_before1(:,index_observation)     = (((1-delta)./q(def_per_matrix(j,i) - 4: def_per_matrix(j,i),i) +1-delta)/1.01).^4 - 1;
%                 ra_before1(:,index_observation) = (((1-delta).*q(def_per_matrix(j,i) - 4: def_per_matrix(j,i),i) +1)./(1.01*q(def_per_matrix(j,i) - 4: def_per_matrix(j,i),i))).^4 - 1;
%                              
%                 b_next_after1(:,index_observation)  = b(def_per_matrix(j,i) + 2: def_per_matrix(j,i) + 5,i)*1.01/(delta+.01);
% %                ra_after1(:,index_observation)      = (((1-delta)./q(def_per_matrix(j,i) + 1: def_per_matrix(j,i) + 4,i) +1-delta)/1.01).^4 - 1;
%                 ra_after1(:,index_observation) = (((1-delta).*q(def_per_matrix(j,i) +1: def_per_matrix(j,i)+4,i) +1)./...
%                                                  (1.01*q(def_per_matrix(j,i) +1: def_per_matrix(j,i)+4,i)) ).^4 - 1;
%                 new_issuance_after(:,index_observation)  = (b(def_per_matrix(j,i) + 2: def_per_matrix(j,i) + 5,i) - (1-delta)*b(def_per_matrix(j,i) + 1: def_per_matrix(j,i) + 4,i) ) *(1-delta)*1.01/(delta+.01);
%             end 
% 
%             index_observation = index_observation+1;
%     end
% end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% num_simulations = min(1000,num_observations);
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % fprintf(' \n')
% % fprintf(['Compute statistics of ',num2str(num_simulations),' samples of ',num2str(sample_size),' observations before a default and without outliers. \n'])
% % fprintf('std(y)               = %f5 \n',100*mean(std_y_vector(1:num_simulations)))
% % fprintf('std(c)               = %f5 \n',100*mean(std_c_vector(1:num_simulations)))
% % fprintf('std(tb)              = %f5 \n',100*mean(std_tb_vector(1:num_simulations)))
% % fprintf('std(R_s)             = %f5 \n',100*mean(std_ra_vector(1:num_simulations)))
% % fprintf('std(R_s risk neutral)= %f5 \n',100*mean(std_ra_vector_rn(1:num_simulations)))
% % fprintf('corr(y,c)            = %f5 \n',mean(corr_y_c_vector(1:num_simulations)))
% % fprintf('corr(y,tb)           = %f5 \n',mean(corr_y_tb_vector(1:num_simulations)))
% % fprintf('corr(y,R_s)          = %f5 \n',mean(corr_ra_y_vector(1:num_simulations)))
% % fprintf('corr(R_s,tb)         = %f5 \n',mean(corr_ra_tb_vector(1:num_simulations)))
% % fprintf('corr(R_s,R_s r.neutr) = %f5 \n',mean(corr_ra_ra_rn_vector(1:num_simulations)))
% % fprintf('Mean debt            = %f5 \n',100*mean(mean_b_vector(1:num_simulations)))
% % fprintf('Mean debt mkt value  = %f5 \n',100*mean(mean_b_market_vector(1:num_simulations)))
% % fprintf('debt/y at def.       = %f5 \n',100*mean(default_b_vector(1:num_simulations)))
% % fprintf('recovery at def.     = %f5 \n',100*mean(default_rec_vector(1:num_simulations)))
% % fprintf('E(R_s)               = %f5 \n',100*mean(mean_ra_vector(1:num_simulations)))
% % fprintf('E(R_s) risk neutral  = %f5 \n',100*mean(mean_ra_vector_rn(1:num_simulations)))
% % fprintf('Max R_s              = %f5 \n',100*max(max_ra_vector(1:num_simulations)))
% % fprintf('Mean duration        = %f5 \n',mean(mean_duration_vector(1:num_simulations))/4)
