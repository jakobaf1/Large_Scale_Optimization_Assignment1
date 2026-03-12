include("assignment_1_data.jl")

I = 1:nS
J = 1:nC
S = 1:nSc

using JuMP
using Gurobi

const GRB_ENV = Gurobi.Env()
Gurobi_constructor = ()->Gurobi.Optimizer(GRB_ENV)

m = Model(Gurobi_constructor)
set_silent(m)

@variable(m, x[I,J,S] >= 0)
@variable(m, r[I] >= 0)
@variable(m, z[J,S] >= 0)
@variable(m, y[I], Bin)

@objective(m, Min, sum(P*(sum(y[i]*F[i] + sum(x[i,j,s]*(C[i]+T[i,j]) for j in J) for i in I)) + sum(z[j,s]*u for j in J) for s in S))

@constraint(m, [s=S,j=J], sum(x[i,j,s] for i in I) + z[j,s] >= D[j,s])
@constraint(m, sum(y[i] for i in I) <= n)
@constraint(m, [i=I], r[i] <= y[i]*B[i])
@constraint(m, [i=I, s=S], sum(x[i,j,s] for j in J) <= r[i])

optimize!(m)
println("Termination status: $(termination_status(m))")

if termination_status(m) == OPTIMAL
    println("\nOptimal objective value: $(objective_value(m))\n")
    print("Suppliers selected:")
    for i in I
        if value(y[i]) == 1
            print(" $i")
        end
    end
    println("\nCapacity reserved from each supplier:")
    for i in I 
        println("Supplier $i: $(value(r[i]))")
    end

else
    println("No optimal solution found")
end