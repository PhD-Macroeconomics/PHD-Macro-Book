

# initialize value function as (na x nd ) array and several other arrays
#guess steady state



function SolveEGM(grid,Va_0,β,r,Y,ytax,trans,taue,distshock)
    #loop until convergence
    tol = 1e-10
    test = true

    for it in 1:10000
        Va_1  = eulerBack(grid,Va_0,β,r,Y,ytax,trans,distshock,taue)[1];

        if (it-1) % 50 == 0
            test = maximum(abs.(Va_0 .- Va_1)./(abs.(Va_0) .+ abs.(Va_1) .+ tol))
            println("it = $it, test = $test")
            if test  < tol
                break
            end
        end

        Va_0 = Va_1;
    end

    return eulerBack(grid,Va_0,β,r,Y,ytax,trans,distshock,taue)

end



# iterate forward step to convergence
function steady_state_forward_step(ass,grid; tol=1E-12, maxit= 10000, inital_guess=[])


    # initialize
    # D = np.ones((nS,nA))/(nS*nA)
    if inital_guess == []
        D = initialize_distribution(grid.Pi,grid.na);
    else
        D = inital_guess;
    end

    # interpolate policy rule usin Young idea
    sspol_i, sspol_pi = interpolate_coord_robust(grid.a,ass);

    finished = false;
    for it in 1:maxit

        Dnew = forward_step_1d(D, grid.Pi, sspol_i, sspol_pi);

        # only check convergence every 10 iterations for efficiency
        if it % 10 == 0  && within_tolerance(D, Dnew, tol)
            finished = true;
            break
        end
        D = Dnew;
    end
    if ~finished
        error("No convergence after $maxit forward iterations!")
    end

    return D
end



function TestSteadyState!(β_guess,grid,ss,forward_maxit)
    println("beta = $β_guess")
    println("Solve EGM")
    ss["Va"], ss["a"], ss["c"] = SolveEGM(grid,ss["Va"],β_guess,ss["r"],ss["Y"],ss["ytax"],ss["trans"],ss["taue"],ss["distshock"]);

    println("Solve for steady state distribution")
    ss["D"] = steady_state_forward_step(ss["a"],grid,maxit=forward_maxit);
    resid = ss["D"] ⋅ ss["a"] - ss["A"];

    println("resid = $resid")
    return resid
end





function get_steady_state!(grid,ss;forward_maxit = 10000,βtol = 1e-6)
# Initial guess of V_a
    ss["Va"] = initialize_Va(ss,grid);


    β = find_zero(β_guess -> TestSteadyState!(β_guess,grid,ss,forward_maxit)[1],  β_bracket(grid), Bisection(), atol = βtol);
    _ = TestSteadyState!(β,grid,ss,forward_maxit); # call it one more time to make sure that ss gets updated with results corresponding to β
    ss["β"] = β;

    @assert isapprox(ss["C"] , ss["D"] ⋅ ss["c"], atol = 1e-6)  # check that agg C is the sum of the policy rules

    # get MPCs
    println("Getting MPCs")
    MPCs = zeros(size(ss["c"]));
    for i = 1:grid.nz
        spl = Spline1D(grid.a, ss["c"][:,i]);
        MPCs[:,i] = derivative(spl,grid.a)/(1+ss["r"]);
    end
    println("Average MPC (marginal) = $(ss["D"]⋅MPCs/(1+ss["r"]))") # Note MPCs are MPC out of *before-interest* savings so divide by $(1+ss["r"]) if you want MPC out of cash on hand.

    MPCs500 = zeros(size(ss["c"]));
    gift = 500.0/15000. * ss["Y"]; # quarterly GDP is 15,000, so need to give them 500/15,000 times Y_SS
    _, _, c500 = eulerBack(grid,ss["Va"],β,ss["r"],ss["Y"],ss["ytax"],ss["trans"]+gift,ss["distshock"],ss["taue"]);
    MPCs500 = (c500-ss["c"])/gift;

    println("Average MPC (\$500)     = $(ss["D"]⋅MPCs500)")

    return MPCs
end
