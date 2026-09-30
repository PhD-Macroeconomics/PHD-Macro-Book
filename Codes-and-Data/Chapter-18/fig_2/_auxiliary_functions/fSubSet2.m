function [AR] = fSubSet2(vP_fixed, vY, mV, mX, mZp, iT, mK)  

% input :
% vP_fixed: fixed parameters under H_0 
% vY dependent variables 
% mV endogenous variables corresponding to H_0
% mX endogenous variables corresponding to nuisance parameters 
% mZp polynomial instruments 
% iT effective sample size 
% mK quadratic spectral kernel matrix 

% output: 
% AR_{a,s} statistic 

mPz     = mZp * inv(mZp'*mZp) * mZp';    
mMz     = eye(iT) - mPz;                
mYstar  = [(vY - mV * vP_fixed)  mX];    
mRz    = mYstar' * mMz * mK * mMz * mYstar / iT;   
vVal   =  sort(eig( inv(chol(mRz))' * mYstar' * mPz * mYstar * inv(chol(mRz))));
AR = vVal(1);

end