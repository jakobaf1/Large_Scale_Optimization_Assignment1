using JuMP
using HiGHS

m = Model(HiGHS.Optimizer)
set_silent(m)

I = 1:4

@variable(m, lambda[I] >= 0)

@objective(m, Max, 
                    (lambda[1] + 2*lambda[2] + 2*lambda[3] + 3*lambda[4]) +
                    2*(lambda[1]+lambda[2] + 2*lambda[3] + 2*lambda[4])
)

@constraint(m, (lambda[1]+lambda[2] + 2*lambda[3] + 2*lambda[4]) <= 3)
@constraint(m, (lambda[1] + 2*lambda[2] + 2*lambda[3] + 3*lambda[4]) - (lambda[1]+lambda[2] + 2*lambda[3] + 2*lambda[4]) >= 1)
@constraint(m, (lambda[1] + 2*lambda[2] + 2*lambda[3] + 3*lambda[4]) <= 4)
@constraint(m, 1/3.0*(lambda[1] + 2*lambda[2] + 2*lambda[3] + 3*lambda[4]) + (lambda[1]+lambda[2] + 2*lambda[3] + 2*lambda[4]) >= 7/3.0)

@constraint(m, sum(lambda[i] for i in I) == 1)
@constraint(m, [i=I], lambda[i] >= 0)

optimize!(m)
println("Termination status: $(termination_status(m))")

if termination_status(m) == OPTIMAL
    println("Optimal objective value: $(objective_value(m))")
else
    println("No optimal solution found")
end