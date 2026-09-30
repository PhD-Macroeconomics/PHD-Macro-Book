function [x,AR] = fCUErestricted(vPar, vYT, mWT, mZp, iT, mK) 

options = optimset('Display','none');
[x,AR]  = fminsearch(@ARsubset,vPar,options);

% Nested function that computes the AR objective function     
    function AR = ARsubset(vPar)
        vU = vYT - mWT * vPar; 
        mPz = mZp * inv(mZp'*mZp) * mZp';
        mMz = eye(iT) - mPz;
        dSu = vU' * mMz * mK * mMz * vU;
        AR  = vU' * mPz * vU / (iT^-1 * dSu);         
    end
end