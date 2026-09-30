module HouseholdAR1


using LinearAlgebra: ⋅, Diagonal, eigen
using utils: GetStationaryDist, interpolate_y, setmin!


export grid, σ, eulerBack, initialize_Va, β_bracket, get_e



σ = 1;
# function utility(c)
#     return (c.^(1-σ)  .- 1.)./(1-σ);
# end

function margutilc(c)
    return c.^(-σ);
end


function invmargutil(mu)
    # Solves for inverse of marginal utility via Newton method
    # mu   Array     marginal utility
    return mu.^(-1. /σ)
end

"One step back using the endogenous grid method.  The decision problem is
  V(a,z) =  u(c) + β E [ V(a',z')]
  s.t. c + a' = (1+r) a + (1-τ_y)Yz + τ.
The focs and envelope conditions are
  u_c(c) = λ
  λ = β E [V_a(a',z')]
  V_a(a,z,χ) = (1+r) λ.
Rearranging
  c = inv_u_c{ β E [V_a(a',z')] }
  V_a(a,z,) = (1+r)  u_c(c)
"
function eulerBack(grid,Va_p,β,r,Y)
    uc_nextgrid = β * Va_p * grid.Pi_T;  # marginal utility today given Va' on grid of a'  equation 0
    c_nextgrid = invmargutil(uc_nextgrid);   # convert to consumption
    e = grid.z;
    coh = (1 + r) * grid.a .+ Y*e';  # coh using grid on a
    a = zeros(size(coh));
    for j = 1:grid.nz
        a[:,j] = interpolate_y(c_nextgrid[:,j] .+ grid.a,  grid.a,  coh[:,j]);  # interpolate savings rule as function of coh onto the coh grid defined by a_grid in previous line
    end
    setmin!(a, grid.a[1])  # impose the borrowing constraint
    c = coh .- a;
    Va = (1 + r) * margutilc(c);
    return Va, a, c
end




struct GridFull

    amin::Float64
    amax::Float64
    na::Int64


    zmin::Float64
    zmax::Float64
    nz::Int64

    a::Vector{Float64}
    z::Vector{Float64}

    n::Int64

    Pi::Array{Float64,2}
    Pi_T::Array{Float64,2}

    z_dist::Vector{Float64}



end

function make_agrid(amax, n, amin=0)

    if amin <-1e-6
        error("Werning case requires amin = 0")
    end

    gridparam_a_pos = 0.3; #linear = 1, 1 L-shaped = 0;
    grid_a_pos = range(0.,1.,length=n);
    grid_a_pos = grid_a_pos.^(1. / gridparam_a_pos);
    grid_a_pos = amax .* grid_a_pos;
    grid_a = grid_a_pos;

    return grid_a

end


function getgrid()
    # outer constructor for CustomGrid
    # outer constructor for CustomGrid

    grid_y = [0.1, 1.0];
    n_y = length(grid_y);
    Pi_y = [0.9 0.1
            0.1 0.9];


    y_dist  = GetStationaryDist(Pi_y);

    mean_y_raw = grid_y ⋅ y_dist;
    grid_y     = grid_y/mean_y_raw;



    amax = 30 * maximum(grid_y);
    amin = 0.0;
    na = 250;
    a = make_agrid(amax,na,amin);




    z = grid_y;

    zmin = z[1];
    zmax = z[end];
    nz = n_y;




    return GridFull(amin,amax,na,
                      zmin,zmax,nz,
                      a,z,
                      na*nz,
                      Pi_y,copy(Pi_y'),y_dist[:])
end

function initialize_Va(r,Y,grid)
    c = r * grid.a .+ Y*grid.z';
    return (1+r)*margutilc(c);
end


function β_bracket(grid::GridFull)
    return 0.95 .+ [-0.05; 0.01]
end

## Construc the grids for the household problem


grid = getgrid();

end #-- end module
