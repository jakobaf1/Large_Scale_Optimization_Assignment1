# Benders template (no rays)

#-------------------------------------------------------------------
# Intro definitions
using JuMP
using HiGHS
#-------------------------------------------------------------------

#-------------------------------------------------------------------
# Master problem
mas=Model(HiGHS.Optimizer)

# Variables
@variable(mas, theta )

@variable(mas, (A) )
@objective(mas, Min, (B) + theta)

function solve_master( (D2) )
    
    # Add Constraints
    @constraint(mas, (D3) <= theta)

    optimize!(mas)
    
    return objective_value(mas)
    
end
#-------------------------------------------------------------------


#-------------------------------------------------------------------
# Subproblem
function solve_sub( (C4) )
    
    sub=Model(HiGHS.Optimizer)

    # Variables
    @variable(sub, (C1) )

    # Objective
    @objective(sub, Min/Max, (C2) )

    # Constraints
    @constraint(sub, (C3) )

    optimize!(sub)

    return (objective_value(sub), (D1) )
end    
#-------------------------------------------------------------------




#-------------------------------------------------------------------
# main code
let
    UB=Inf
    LB=-Inf
    Delta=0
    ybar= (F)
    it=1
    while (UB-LB>Delta)
        
        (sub_obj, (D1) )=solve_sub(ybar)
        
        UB=min(UB,sub_obj + (E) )
        
        mas_obj=solve_master((D2))
        
        ybar=(G)
        LB=mas_obj
        
        println("It: $(it) UB: $(UB) LB: $(LB)  Sub: $(sub_obj)")
        it+=1
    end
end
println("Correct Ending")
