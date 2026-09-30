



function generate_sample!(y::Matrix{Float64},As::Array{Float64,3},T::Int64)

    e =randn(n,T);
    
    
    # Ainv = inv(A0);
    
    y[:,1] = As[:,:,1] * e[:,1];
    y[:,2] = As[:,:,1] * e[:,2] + As[:,:,2] * y[:,1];
    for t = 3:T
        y[:,t] = As[:,:,1] * e[:,t] + As[:,:,2] * y[:,t-1] + As[:,:,3] * y[:,t-2];
    end
    
end


function lagmat(y::AbstractArray{Float64,2},n::Int)
    T,m = size(y)
    l = zeros(T,m*n);
    for i = 1:n
        l[:,(i-1)*m+1:i*m] = [repeat([NaN],i,m);y[1:T-i,:]];
    end
    return l
end
function lagmat(y::Vector{Float64},n::Int)
    return lagmat(reshape(y,:,1),n)
end
function lead(y::Vector{Float64},n::Int)
    return [y[1+n:end]; repeat([NaN],n)];
end
function lead(y::Array{Float64,2},n::Int)
    return [y[1+n:end,:];repeat([NaN],n,size(y,2))]
end

function localprojection(y,x,maxhorizon,ylags,xlags)
    T = size(y,1);
    nlags = ylags + xlags;
    
    lhs = zeros(T,maxhorizon+1);
    for h = 0:maxhorizon
        lhs[:,h+1] = lead(y,h);
    end
    rhs = zeros(T,2+nlags);
    rhs[:,1] = x;
    rhs[:,2:xlags+1] = lagmat(x,xlags);
    rhs[:,xlags+2:nlags+1] = lagmat(y,ylags);
    rhs[:,2+nlags] = ones(T);

    maxlag = max(xlags,ylags);
    IRF = zeros(maxhorizon+1);
    for h = 0:maxhorizon
        I = .!isnan.(lhs[:,h+1]);
        I[1:maxlag] .= false;
        β = rhs[I,:] \ lhs[I,h+1];
        IRF[h+1] = β[1];
    end 

    return IRF
end


function var(y,nlags;constant=true)
    T,n = size(y);
    Y = y;
    X = lagmat(y,nlags);
    if constant
        X = [X ones(T)];
    end

    keep = (nlags+1):T;

    Aprime = X[keep,:] \ Y[keep,:];
    res = Y[keep,:] .- X[keep,:] * Aprime;
    Σ = cov(res,dims=1);
    return Aprime, Σ

end

function getvarirfs(A,nlags,IRF_hor;constant=true)
    n = size(A,1);
    AA = zeros(n*nlags,n*nlags);
    if constant
        AA[1:n,:] = A[:,1:end-1];
    else
        AA[1:n,:] = A;
    end

    
    for j = 1:nlags-1
        AA[j*n+1:(j+1)*n,(j-1)*n+1:j*n] = I(n);
    end

    irfs = zeros(n,n,IRF_hor+1);
    for h = 0:IRF_hor
        tmp = AA^h;
        irfs[:,:,h+1] = tmp[1:n,1:n];
    end

    return irfs

end


function var_lp_irfs(y;maxh = 20,nlags = 1)
    
    Aprime, Σ = var(y',nlags,constant=false);
    irfs1 = getvarirfs(Aprime',nlags,maxh,constant=false);

    chol = cholesky(Symmetric(Σ));
    L = chol.L;

    E = L[:,1] / L[1,1];

    irfs2 = zeros(maxh+1,2);
    for h = 0:maxh
        irfs2[h+1,:] = irfs1[:,:,h+1] * E;
    end
    return irfs2
end