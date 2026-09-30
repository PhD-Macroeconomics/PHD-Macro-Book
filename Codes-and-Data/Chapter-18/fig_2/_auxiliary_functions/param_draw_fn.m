function param = param_draw_fn(vYT,mWT,mZp,iT,mK,crit_val);

accept = 0;

while accept == 0

    rand_x = 0 + rand * (1 - 0); % coefficient on forcing variable
    rand_y = 0 + rand * (1 - 0); % coefficient inflation expectations
    
    vU         = vYT - mWT * [rand_y rand_x]'; 
    mPz        = mZp * inv(mZp'*mZp) * mZp';
    mMz        = eye(iT) - mPz;
    mARres     = vU' * mPz * vU / (iT^-1 * vU' * mMz * mK * mMz * vU);
    
    if mARres < crit_val
        kappa = rand_x;
        gamma_f  = rand_y;
        gamma_b = 1 - gamma_f;
        accept = 1;
    end
    
end

param = [gamma_f,gamma_b,kappa];