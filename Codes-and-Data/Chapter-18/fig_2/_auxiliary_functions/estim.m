function [Bcomp, cvec, dvec, Bpl_ev, VC_eps, Residmat] = ...
                                    estim(Y, vlag, iscon, istr)

                                
%--------------------------------------------------------------------------
%
% DESCRIPTION:
%
% This routine estimates the residuals and companion matrix 
% of reduced form VAR
%
%--------------------------------------------------------------------------
%
% INPUTS:
%
% Y:     matrix of data series, m x n
%
% vlag:  lag length   
%
% iscon: a value '1' introduces a constant in the conditional mean 
%
% istr:  a value '1' introduces a determistic trend in the conditional mean
%
%--------------------------------------------------------------------------
%
% OUTPUT:
%
% Bcomp:   matrix with structure of estimated reduced-form coefficients in 
%           companion form excluding all the deterministic terms. 
%           This includes the estimated parameters in the partition 
%           n x (n x (n x vlag)). The remaining partition is made up of a 
%           diagonalic identity matrix that pins down the lead-lag relation 
%           between variables. The size is (n x vlag) x (n x vlag).  
%
% cvec:    matrix with estimated constants; this returns the scalar 0 
%           if no constant is included in the model; 
%           otherwise, this is a matrix of size n x 1
%
% dvec:    matrix with estimated parameters on the deterministic trends;
%           this returns the scalar 0 if no constant is included 
%           otherwise, this is a matrix of size n x 1
%
% Bpl_ev:  'full' companion matrix with parameter estimates; 
%          with both constant and deterministic trend. 
%          The content is arranged as follows:
%          [ partition of size (n x vlag) x n with estimated parameters on lagged data series;
%            partition of size (1 x n) with estimated coefficients on constant terms;
%            partition of size (1 x n) with estimated coefficients on deterministic trends ]
%           The overall size is (n*vlag+1+1) x (n*vlag+1+1)
%
% VC_eps:  covariance matrix of reduced-form residuals, size n x n
%
%--------------------------------------------------------------------------
%
% Author:  Paolo Z., September 2011
%
%--------------------------------------------------------------------------


%-------------------------
cvec    = 0;
dvec    = 0;

[Tbig0,Nbig] = size(Y);
Tbig         = Tbig0-vlag;
%-------------------------


%--------------------------------------------------------------------------
allY  = zeros(Tbig, (vlag+1)*Nbig);

uplcc = 1; 

for ii=0:vlag;
    allY(:,uplcc:uplcc+Nbig-1) = Y(1+vlag-ii:Tbig0-ii, 1:Nbig);
    uplcc = uplcc+Nbig;
end

allYlag = allY(:, Nbig+1:end);
Y       = allY(:, 1:Nbig);

Xmat    = allYlag;

if iscon==1;
    Xmat = [Xmat ones(Tbig, 1)];
    cvec = zeros(Nbig, 1);
end

if istr==1;
    trend = 1:Tbig;
    Xmat  = [Xmat trend'];
    dvec  = zeros(Nbig, 1);
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
Residmat = zeros(Tbig, Nbig);
Bcompsm  = zeros(Nbig, Nbig*vlag);

for ii=1:Nbig;
    yloc = Y(:, ii);
    [beta_loc, betaint_loc, resid_loc, rint_loc, stats_loc] = regress(yloc, Xmat);
    Bcompsm(ii, :)  = beta_loc(1:vlag*Nbig)';
    Residmat(:, ii) = resid_loc;

    if iscon==1;
        cvec(ii) = beta_loc(vlag*Nbig+1);
    end
    
    if istr==1;
        dvec(ii) = beta_loc(end);
    end
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
Bcomp   = [Bcompsm; kron(eye(vlag-1), eye(Nbig)), ... 
                                        zeros((vlag-1)*Nbig, Nbig)];

VC_eps  = cov(Residmat);
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
roBplev = Nbig*vlag;    
Bpl_ev  = zeros(roBplev, Nbig);

for jj=1:Nbig;
    colloc = Bcompsm(jj, :)';
    matloc = reshape(colloc, Nbig, vlag);
    colloc = reshape(matloc', vlag*Nbig, 1);
    Bpl_ev(:,jj) = colloc;
end

if iscon==1;
    Bpl_ev = [Bpl_ev; cvec'];
end

if istr==1;
    Bpl_ev = [Bpl_ev; dvec'];
end
%--------------------------------------------------------------------------

