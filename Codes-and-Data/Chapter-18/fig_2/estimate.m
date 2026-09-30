%% MONETARY POLICY SHOCK IRFs
% Alisdair McKay
% Jan 4, 2023
% 
% This script estimates a recursive VAR with the Romer-Romer shock ordered
% first. The shock therefore can 

clear;
clc;
close all;

warning('off','MATLAB:dispatcher:nameConflict')

addpath('_auxiliary_functions')


%%


load('Data/processeddata.mat','DT');

% dates

startdate = find(DT.quarter == 1969);
enddate = find(DT.quarter == 2007.75);


% collect VAR inputs
vardata = [DT.rrshock DT.lrgdp DT.infl DT.ffr DT.lpcom];
vardata = vardata(startdate:enddate,:);
vardata(isnan(vardata)) = 0;

% series names

series_names = {'RR Shock','Output','Inflation','Interest Rate', 'Commodity Price'};

%% SETTINGS

% VAR specification

n_lags     = 4;                    % number of lags
constant   = 2;                    % constant?
IRF_hor    = 100;
n_draws    = 1000;
n_y        = size(vardata,2);

% identification

IS.shock_pos = [1];
n_shocks     = length(IS.shock_pos);

% outcomes of interest

IS.y_pos = [2 3 4];

% placeholders

IS.IRF     = NaN(IRF_hor,n_y,n_shocks,n_draws);
IS.IRF_med = NaN(IRF_hor,n_y,n_shocks);
IS.IRF_lb  = NaN(IRF_hor,n_y,n_shocks);
IS.IRF_ub  = NaN(IRF_hor,n_y,n_shocks);
IS.IRF_OLS = NaN(IRF_hor,n_y,n_shocks);

%% VAR ESTIMATION

%----------------------------------------------------------------
% Estimate Reduced-Form VAR
%----------------------------------------------------------------

T = size(vardata,1) - n_lags;
[B_draws,Sigma_draws,B_OLS,Sigma_OLS] = bvar_fn(vardata,n_lags,constant,n_draws);

%----------------------------------------------------------------
% OLS IRFs
%----------------------------------------------------------------

% extract VAR inputs
    
Sigma_u   = Sigma_OLS;
B         = B_OLS;

% benchmark rotation

bench_rot = chol(Sigma_u,'lower');

% Wold IRFs

IRF_Wold = zeros(n_y,n_y,IRF_hor); % row is variable, column is shock
IRF_Wold(:,:,1) = eye(n_y);

for l = 1:IRF_hor
    
    if l < IRF_hor
        for j=1:min(l,n_lags)
            IRF_Wold(:,:,l+1) = IRF_Wold(:,:,l+1) + B(1+(j-1)*n_y:j*n_y,:)'*IRF_Wold(:,:,l-j+1);
        end
    end
    
end

W = bench_rot;

% get IRFs

IRF_OLS = NaN(n_y,n_y,IRF_hor);
for i_hor = 1:IRF_hor
    IRF_OLS(:,:,i_hor) = IRF_Wold(:,:,i_hor) * W;
end

% collect results

for i_shock = 1:length(IS.shock_pos)
    IS.IRF_OLS(:,:,i_shock) = squeeze(IRF_OLS(:,IS.shock_pos(i_shock),:))';
end

%----------------------------------------------------------------
% Identified Set
%----------------------------------------------------------------

for i_draw = 1:n_draws
    
% extract VAR inputs
    
Sigma_u   = Sigma_draws(:,:,i_draw);
B         = B_draws(:,:,i_draw);

% benchmark rotation

bench_rot = chol(Sigma_u,'lower');

% Wold IRFs

IRF_Wold = zeros(n_y,n_y,IRF_hor); % row is variable, column is shock
IRF_Wold(:,:,1) = eye(n_y);

for l = 1:IRF_hor
    
    if l < IRF_hor
        for j=1:min(l,n_lags)
            IRF_Wold(:,:,l+1) = IRF_Wold(:,:,l+1) + B(1+(j-1)*n_y:j*n_y,:)'*IRF_Wold(:,:,l-j+1);
        end
    end
    
end

W = bench_rot;

% get IRFs

IRF_draw = NaN(n_y,n_y,IRF_hor);
for i_hor = 1:IRF_hor
    IRF_draw(:,:,i_hor) = IRF_Wold(:,:,i_hor) * W;
end

% collect results

for i_shock = 1:length(IS.shock_pos)
    IS.IRF(:,:,i_shock,i_draw) = squeeze(IRF_draw(:,IS.shock_pos(i_shock),:))';
end

end

for ii=1:IRF_hor
    for jj=1:n_y
        for kk = 1:n_shocks
            IS.IRF_med(ii,jj,kk) = quantile(IS.IRF(ii,jj,kk,:),0.5);
            IS.IRF_lb(ii,jj,kk) = quantile(IS.IRF(ii,jj,kk,:),0.05);
            IS.IRF_ub(ii,jj,kk) = quantile(IS.IRF(ii,jj,kk,:),0.95);
        end
    end
end


%% SAVE RESULTS


RR.IRF     = squeeze(IS.IRF(:,IS.y_pos,1,:));
RR.IRF_lb  = squeeze(IS.IRF_lb(:,IS.y_pos,1));
RR.IRF_ub  = squeeze(IS.IRF_ub(:,IS.y_pos,1));
RR.IRF_med = squeeze(IS.IRF_med(:,IS.y_pos,1));


save('Results/RR_IRFs.mat','RR')




