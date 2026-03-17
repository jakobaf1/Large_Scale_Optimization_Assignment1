# Benders template (no rays)

#-------------------------------------------------------------------
# Intro definitions
using JuMP
using HiGHS
#-------------------------------------------------------------------
include("assignment_1_data.jl")

I = 1:nS
J = 1:nC
S = 1:nSc

#-------------------------------------------------------------------
# Master problem
mas=Model(HiGHS.Optimizer)
set_silent(mas)
# Variables
@variable(mas, theta[S])
@variable(mas, y[I], Bin)

@objective(mas, Min, sum(F[i]*y[i] for i in I) + sum(theta[s] for s in S))
@constraint(mas, sum(y[i] for i in I) <= n)

function solve_master( u_dual )
    
    # Add Constraints
    for s in S
        u = u_dual[s]
        u1 = u[1]
        u2 = u[2]
        @constraint(mas, sum(u1[j]*D[j,s] for j in J) + sum(u2[i]*B[i]*y[i] for i in I) <= theta[s])
    end

    optimize!(mas)
    
    return objective_value(mas)
    
end
#-------------------------------------------------------------------


#-------------------------------------------------------------------
# Subproblem
function solve_sub( y_bar, s )
    
    sub=Model(HiGHS.Optimizer)
    set_silent(sub)

    # Variables
    @variable(sub, u1[J] >= 0)
    @variable(sub, u2[I] <= 0)
    @variable(sub, u3[I] <= 0)
    
    # Objective
    @objective(sub, Max, sum(u1[j]*D[j,s] for j in J) + sum(u2[i]*B[i]*y_bar[i] for i in I) )

    # Constraints
    @constraint(sub, [i=I] , u2[i] - u3[i] <= C[i])
    @constraint(sub, [i=I, j=J], u1[j] + u3[i] <= P*T[i,j])
    @constraint(sub, [j=J], u1[j] <=P*u)

    optimize!(sub)

    return (objective_value(sub), [value.(u1), value.(u2), value.(u3)] )
end    
#-------------------------------------------------------------------




#-------------------------------------------------------------------
# main code
let
    UB=Inf
    LB=-Inf
    Delta=0
    y_bar= ones(Int64, length(I))
    it=1
    while (round(UB-LB, digits=3)>Delta)
        
        sub_total = 0.0
        u_duals = []

        for s in S
            sub_obj_s, u_dual_s = solve_sub(y_bar, s)
            sub_total += sub_obj_s
            push!(u_duals, u_dual_s)
        end
        
        UB=min(UB,sub_total + sum(F[i]*y_bar[i] for i in I) )


        mas_obj=solve_master(u_duals)
        
        y_bar=value.(y)
        LB=mas_obj
        
        println("It: $(it) UB: $(UB) LB: $(LB)  Sub: $(sub_total)")
        it+=1
    end
end
println("Correct Ending")
