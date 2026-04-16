using JuMP
using HiGHS

include("exercise2_data - Copy.jl")

m = Model(HiGHS.Optimizer)
set_silent(m)

N, M = size(w)
I = 1:N
J = 1:M

@variable(m, x[I,J], Bin)

@objective(m, Max, sum(p[i,j]*x[i,j] for i in I, j in J))

@constraint(m, [j=J], sum(x[i,j] for i in I) == 1)
@constraint(m, [i=I], sum(w[i,j]*x[i,j] for j in J) <= cap[i])

for (a, b) in K
    @constraint(m,[i=I], x[i,a]+x[i,b] <= 1)
end

optimize!(m)
println("Termination status: $(termination_status(m))")

if termination_status(m) == OPTIMAL
    println("Optimal objective value: $(objective_value(m))")
else
    println("No optimal solution found")
end