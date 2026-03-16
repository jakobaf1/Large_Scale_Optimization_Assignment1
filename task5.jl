# Benders template with rays

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
@variable(mas, theta )

@variable(mas, y[I], Bin)
@objective(mas, Min,  sum(F[i]*y[i] for i in I) + theta)

@constraint(mas, sum(y[i] for i in I) <= n)

function solve_master( u_dual, opt_cut::Bool )
    
    u1 = u_dual[1]
    u2 = u_dual[2]

    # Add Constraints
    if opt_cut
        # Add opt cut Constraints
        @constraint(mas,
                    sum(u1[j,s]*D[j,s] for j in J, s in S) + sum(u2[i]*B[i]*y[i] for i in I)
                    <= theta)
    else
        # Add feas cut Constraints
        @constraint(mas,
                    sum(u1[j,s]*D[j,s] for j in J, s in S) + sum(u2[i]*B[i]*y[i] for i in I)
                    <= 0)
    end
    
    optimize!(mas)
    
    return objective_value(mas)
    
end
#-------------------------------------------------------------------

#-------------------------------------------------------------------
# Sub problem
function solve_sub( y_bar )
    
    sub=Model(HiGHS.Optimizer)
    set_silent(sub)
    
    # Variables
    @variable(sub, u1[J,S])
    @variable(sub, u2[I] <= 0)
    @variable(sub, u3[I,S] <= 0)

    # Objective
    @objective(sub, Max, sum(u1[j,s]*D[j,s] for j in J, s in S) + sum(u2[i]*B[i]*y_bar[i] for i in I) )

    # Constraints
    @constraint(sub, [i=I] , u2[i] - sum(u3[i,s] for s in S) <= C[i])
    @constraint(sub, [i=I, j=J, s=S], u1[j,s] + u3[i,s] <= P*T[i,j])
    @constraint(sub, [j=J, s=S], u1[j,s] <=P*u)

    optimize!(sub)

    if termination_status(sub)== MOI.OPTIMAL
        return (true, objective_value(sub), [value.(u1), value.(u2), value.(u3)] )
    else
    	#check termination_status is "DUAL_INFEASIBLE"
    	return (false, objective_value(sub), [value.(u1), value.(u2), value.(u3)])
    end

end    
#-------------------------------------------------------------------

#-------------------------------------------------------------------
# Ray problem
function solve_ray( y_bar )
    
    ray=Model(HiGHS)
    set_silent(ray)
    
    # Variables
    @variable(ray, r1[J,S])
    @variable(ray, r2[I] <= 0)
    @variable(ray, r3[I,S] <= 0)

    # Objective
    @objective(ray, Max, 1 )
    
    # Constraints
    @constraint(ray, sum(r1[j,s]*D[j,s] for j in J, s in S) + sum(r2[i]*B[i]*y_bar[i] for i in I) == 1)

    # Constraints
    @constraint(ray, [i=I] , r2[i] - sum(r3[i,s] for s in S) <= 0)
    @constraint(ray, [i=I, j=J, s=S], r1[j,s] + r3[i,s] <= P*T[i,j])
    @constraint(ray, [j=J, s=S], r1[j,s] <=P*u)

    optimize!(ray)
    
    return (objective_value(ray), [value.(r1), value.(r2), value.(r3)] )
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
    while (UB-LB>Delta)
        
        (sub_prob_solution, sub_obj, u_dual )=solve_sub(y_bar)
        
        if sub_prob_solution
            UB=min(UB,sub_obj + sum(F[i]*y_bar[i] for i in I) )
        else
            (ray_obj, u_dual )=solve_ray(y_bar)
        end
        
        mas_obj=solve_master( u_dual, sub_prob_solution)
        
        y_bar=value.(y)
        
        LB=mas_obj

        if sub_prob_solution
            println("SUB It: $(it) UB: $(UB) LB: $(LB)  Sub: $(sub_obj)")
        else
            println("RAY It: $(it) UB: $(UB) LB: $(LB)  Sub: $(ray_obj)")
        end
        it+=1
    end
end
#print(mas)
#-------------------------------------------------------------------
println("Correct Ending")
