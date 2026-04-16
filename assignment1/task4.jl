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
@variable(mas, theta)
@variable(mas, y[I], Bin)

@objective(mas, Min, sum(F[i]*y[i] for i in I) + theta)
@constraint(mas, sum(y[i] for i in I) <= n)

function solve_master( u_dual )
    u1 = u_dual[1]
    u2 = u_dual[2]
    # u3 = u_dual[3]
    
    # Add Constraints
    @constraint(mas, sum(u1[j,s]*D[j,s] for j in J, s in S) + sum(u2[i]*B[i]*y[i] for i in I) <= theta)

    optimize!(mas)
    
    return objective_value(mas)
    
end
#-------------------------------------------------------------------


#-------------------------------------------------------------------
# Subproblem
function solve_sub( y_bar )
    
    sub=Model(HiGHS.Optimizer)
    set_silent(sub)

    # Variables
    @variable(sub, u1[J,S] >= 0)
    @variable(sub, u2[I] <= 0)
    @variable(sub, u3[I,S] <= 0)
    
    # Objective
    @objective(sub, Max, sum(u1[j,s]*D[j,s] for j in J, s in S) + sum(u2[i]*B[i]*y_bar[i] for i in I) )

    # Constraints
    @constraint(sub, [i=I] , u2[i] - sum(u3[i,s] for s in S) <= C[i])
    @constraint(sub, [i=I, j=J, s=S], u1[j,s] + u3[i,s] <= P*T[i,j])
    @constraint(sub, [j=J, s=S], u1[j,s] <=P*u)

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
        
        (sub_obj, u_dual )=solve_sub(y_bar)
        
        UB=min(UB,sub_obj + sum(F[i]*y_bar[i] for i in I) )
        
        mas_obj=solve_master(u_dual)
        
        y_bar=value.(y)
        LB=mas_obj
        
        println("It: $(it) UB: $(UB) LB: $(LB)  Sub: $(sub_obj)")
        it+=1
    end
end
println("Correct Ending")
