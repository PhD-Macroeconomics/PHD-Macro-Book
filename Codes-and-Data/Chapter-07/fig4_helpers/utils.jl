module utils

using LinearAlgebra: ⋅, Diagonal, eigen

export interpolate_y, setmin!
export interpolate_coord_robust, forward_step_1d, forward_step_shock_1d
export initialize_distribution, within_tolerance, GetStationaryDist
export forward_step_transpose_1d,TransMat,forward_step_2d, mask_col, mask_row
export collapse_by_z






function setmin!(x, xmin)
    # Set 2-dimensional array x where each col is ascending equal to equal to max(x, xmin).
    ni, nj = size(x)
    for j = 1:nj
        for i = 1:ni
            if x[i, j] < xmin
                x[i, j] = xmin
            else
                break
            end
        end
    end
end

function interpolate_y(x::Array{Float64,1},y::Array{Float64,1},xq::Array{Float64,1})
    # Parameters
    #     ----------
    #     x  : array (nx), ascending data points
    #     y  : array (nx), data points
    #     xq : array (nxq), ascending query points

    nx, = size(x);
    nxq, = size(xq);

    @assert all(diff(x) .> 0)
    @assert all(diff(xq) .> 0)

    yq = zeros(nxq);

    xi = 1;
    x_low = x[1];
    x_high = x[2];
    for xqi_cur = 1:nxq
        xq_cur = xq[xqi_cur];
        while xi < nx - 1
            if x_high >= xq_cur
                break
            end
            xi += 1
            x_low = x_high
            x_high = x[xi + 1]
        end

        xqpi_cur = (x_high - xq_cur) / (x_high - x_low);
        yq[xqi_cur] = xqpi_cur * y[xi] + (1 - xqpi_cur) * y[xi + 1];
    end

    return yq;

end



"Linear interpolation exploiting monotonicity only in data x, not in query points xq.
Simple binary search, less efficient but more robust.
xq = xqpi * x[xqi] + (1-xqpi) * x[xqi+1]

Main application intended to be universally-valid interpolation of policy rules.
Dimension k is optional.

Parameters
----------
x    : array (n), ascending data points
xq   : array (nq, k), query points (in any order)

Returns
----------
xqi  : array (nq, k), indices of lower bracketing gridpoints
xqpi : array (nq, k), weights on lower bracketing gridpoints
"
function interpolate_coord_robust(x, xq)

    if ndims(x) != 1
        error("Data input to interpolate_coord_robust must have exactly one dimension")
    end

    if ndims(xq) == 1
        return interpolate_coord_robust_vector(x, xq)
    else
        i, pi = interpolate_coord_robust_vector(x, xq[:])
        return reshape(i,size(xq)), reshape(pi,size(xq))
    end
end

"""Does interpolate_coord_robust where xq must be a vector, more general function is wrapper"""
function interpolate_coord_robust_vector(x, xq)

    n = length(x);
    nq = length(xq);
    xqi =  Array{UInt32}(undef, nq);
    xqpi = Array{Float64}(undef, nq);

    for iq in 1:nq
        if xq[iq] < x[1]
            ilow = 1;
        elseif xq[iq] > x[end-1]
            ilow = n-1;
        else
            # start binary search
            # should end with ilow and ihigh exactly 1 apart, bracketing variable
            ihigh = n;
            ilow = 1;
            while ihigh - ilow > 1
                imid = floor( UInt32, (ihigh + ilow) / 2);
                if xq[iq] > x[imid]
                    ilow = imid
                else
                    ihigh = imid
                end
            end
        end
        xqi[iq] = ilow;
        xqpi[iq] = (x[ilow+1] - xq[iq]) / (x[ilow+1] - x[ilow]);
    end

    return xqi, xqpi
end

"Single forward step to update distribution using exogenous Markov transition Pi and
policy x_i and x_pi for one-dimensional endogenous state.

Efficient implementation of D_t = Lam_{t-1}' * D_{t-1} using sparsity of the endogenous
part of Lam_{t-1}'.

Parameters
----------
D : array (S,X), beginning-of-period distribution over s_t, x_(t-1)
Pi : array (S,S), Markov matrix that maps s_t to s_(t+1) (rows sum to 1)
x_i : int array (X,S), left gridpoint of endogenous policy
x_pi : array (X,S), weight on left gridpoint of endogenous policy

Returns
----------
Dnew : array (S*X), beginning-of-next-period dist s_(t+1), x_t
"
function forward_step_1d(D::Array{Float64,2}, Pi::Array{Float64,2}, x_i::Array{UInt32,2}, x_pi::Array{Float64,2})

    # first update using endogenous policy
    nX, nZ = size(D);
    Dnew = zeros(nX,nZ);
    for iz in 1:nZ
        for ix in 1:nX
            i = x_i[ix,iz]
            pi = x_pi[ix, iz]
            d = D[ix, iz]
            Dnew[i, iz] += d * pi
            Dnew[i+1, iz] += d * (1 - pi)
        end
    end
    # then using exogenous transition matrix
    return  Dnew * Pi
end

"""Transpose of forward_step_1d"""
function forward_step_transpose_1d(D, Pi_T, x_i, x_pi)

    # first update using exogenous transition matrix
    D =  D * Pi_T

    # then update using (transpose) endogenous policy
    nX, nZ = size(D);
    Dnew = zeros(nX,nZ);
    for iz = 1:nZ
        for ix = 1:nX
            i = x_i[ix, iz]
            pi = x_pi[ix, iz]
            Dnew[ix, iz] = pi * D[i, iz] + (1-pi) * D[i+1, iz]
        end
    end
    return Dnew
end


"""forward_step_1d linearized wrt x_pi"""
function forward_step_shock_1d(Dss::Array{Float64,2}, Pi::Array{Float64,2}, x_i_ss::Array{UInt32,2}, x_pi_shock::Array{Float64,2})
    # first find effect of shock to endogenous policy
    nX, nZ = size(Dss);
    Dshock = zeros(nX,nZ);

    for iz in 1:nZ
        for ix in 1:nX
            i = x_i_ss[ix, iz]
            dshock = x_pi_shock[ix, iz] * Dss[ix, iz];
            Dshock[i, iz] += dshock;
            Dshock[i+1, iz] -= dshock;
        end
    end

    # then apply exogenous transition matrix to update
    return Dshock * Pi

end

"Single forward step to update distribution using exogenous Markov transition Pi and
policies (x_i, x_pi) and (y_i, y_pi) for two-dimensional endogenous state.

Efficient implementation of D_t = Lam_{t-1}' * D_{t-1} using sparsity of the endogenous
part of Lam_{t-1}'.

Note that for our application we assume that x'[ix,iy,iz] is the same for all iy
    and that y'[ix,iy,iz] is the same for all ix.

Parameters
----------
D : array (nX,nY,nZ), beginning-of-period distribution over s_t, x_(t-1)
Pi : array (nZ,nZ), Markov matrix that maps s_t to s_(t+1) (rows sum to 1)
x_i : int array (nX,nY,nZ), left gridpoint of first endogenous policy
x_pi : array (nX,nY,nZ), weight on left gridpoint of first endogenous policy
y_i : int array (nY,nZ), left gridpoint of second endogenous policy
y_pi : array (nY,nZ), weight on left gridpoint of second endogenous policy

Returns
----------
Dnew : array (nX,nY,nZ), beginning-of-next-period dist
"
function forward_step_2d(D::Array{Float64,3}, Pi::Array{Float64,2},
                x_i::Array{UInt32,3}, x_pi::Array{Float64,3},y_i::Array{UInt32,2}, y_pi::Array{Float64,2})

    Dmid = forward_step_endo_2d(D,x_i,x_pi,y_i,y_pi);
    nX,nY,nZ = size(Dmid);
    return reshape(  reshape(Dmid,nX*nY,nZ) * Pi  , nX,nY,nZ);
end

function forward_step_endo_2d(D::Array{Float64,3},x_i::Array{UInt32,3}, x_pi::Array{Float64,3},y_i::Array{UInt32,2}, y_pi::Array{Float64,2})
    nX,nY,nZ = size(D);
    Dnew = zeros(nX,nY,nZ);
    for iz = 1:nZ
        for iy = 1:nY
            for ix = 1:nX
                ixp = x_i[ix, iy, iz]
                iyp = y_i[ iy, iz]
                beta = x_pi[ix, iy, iz]
                alpha = y_pi[iy, iz]

                Dnew[ixp, iyp, iz] += alpha * beta * D[ix, iy, iz]
                Dnew[ixp+1, iyp, iz] += alpha * (1 - beta) * D[ix, iy, iz]
                Dnew[ixp, iyp+1, iz] += (1 - alpha) * beta * D[ix, iy, iz]
                Dnew[ixp+1, iyp+1, iz] += (1 - alpha) * (1 - beta) * D[ix, iy, iz]
            end
        end
    end

    return Dnew
end


"Initialize a distribution of wealth: uniform on assets and stationary on income

Parameters
-----------

Pi : array (nz,nz), Markov matrix that maps z_t to z_(t+1) (rows sum to 1)
na :: Int, grid size in a dimension

returns D0 (na,nz) initial distribution of wealth

"
function initialize_distribution(Pi::Array{Float64,2},na::Int64)
    return repeat(GetStationaryDist(Pi)',na,1)./na
end


"Initialize a distribution of wealth: uniform on assets and history and stationary on income

Parameters
-----------

Pi : array (nz,nz), Markov matrix that maps z_t to z_(t+1) (rows sum to 1)
na :: Int, grid size in a dimension
nb :: Int, grid size in b dimension

returns D0 (na,nb,nz) initial distribution of wealth

"
function initialize_distribution(Pi::Array{Float64,2},na::Int64,nb::Int64)
    nZ = size(Pi)[1];
    return reshape(repeat(GetStationaryDist(Pi)',na*nb,1)./(na*nb),na,nb,nZ)
end



"
Return the stationary distribution of a markov chain.
Pi -- transtion matrix with rows that sum to 1
"
function GetStationaryDist(Pi)
    @assert within_tolerance(sum(Pi,dims=2),ones(size(Pi)[1]),1e-8)
    F = eigen(Pi',sortby=x->abs(x-1));
    d = real(F.vectors[:,1]); # the vector should be real, but if other eigenvalues are complex it returns this column as complex with 0 imag
    return d/sum(d)
end




"""Efficiently test max(abs(x1-x2)) <= tol for arrays of same dimensions x1, x2."""
function within_tolerance(x1, x2, tol)
    y1 = x1[:];
    y2 = x2[:];

    for i in 1:length(y1)
        if abs(y1[i] - y2[i]) > tol
            return false
        end
    end
    return true
end


"Create a mask matrix of shape shp and set the i column(s) to 1."
function mask_col(i,shp::Tuple{Int64,Int64})
    m = zeros(shp);
    m[:,i] .= 1.0;
    return m
end

"Create a mask matrix of shape shp and set the i row(s) to 1."
function mask_row(i,shp::Tuple{Int64,Int64})
    m = zeros(shp);
    m[i,:] .= 1.0;
    return m
end


"Compute sum of x by z group"
function collapse_by_z(x::Array{Float64,2},z::Array{Int8,1},nzgroups::Int)

    n = size(x)[2];
    sumx = zeros(nzgroups,n);

    for i = 1:size(x)[1]
        sumx[z[i],:] += x[i,:];
    end

    return sumx
end
function collapse_by_z(x::Array{Float64,1},z::Array{Int8,1},nzgroups::Int)

    sumx = zeros(nzgroups);

    for i = 1:length(x)
        sumx[z[i]] += x[i];
    end

    return sumx
end

end  # -------- End of Module------------
