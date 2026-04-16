include("ColGenGeneric.jl")
using GLPK, JuMP
using .DW_ColGen

function GAPMIP(w, p, c, K)
    (m,n) = size(w)
    myModel = Model(GLPK.Optimizer)
    @variable(myModel, x[1:m,1:n], Bin)
    @objective(myModel, Max, sum(p[i,j]*x[i,j] for i=1:m for j=1:n))
    # each job must be served
    @constraint(myModel, [j=1:n],sum(x[i,j] for i=1:m) == 1)
    @constraint(myModel, capacity[i=1:m],sum(w[i,j]*x[i,j] for j=1:n) <= c[i])
    for (a, b) in K
        @constraint(myModel,[i=I], x[i,a]+x[i,b] <= 1)
    end

    # define blocks (Each block becomes a sub-problem)
    blocks = [[capacity[i]] for i=1:m]
    # this ensures that <blocks> has the right type
    blocks = Vector{Vector{ConstraintRef}}(blocks)
    
    return myModel, blocks
end

# data
include("../exercise2_data - Copy.jl")

gapModel, blocks = GAPMIP(w, p, cap, K)
DW_ColGen.DWColGenEasy(gapModel, blocks)