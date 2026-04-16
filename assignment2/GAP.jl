include("ColGenGeneric.jl")
using GLPK, JuMP
using .DW_ColGen

function GAPMIP(w, p, c)
    (m,n) = size(w)
    myModel = Model(GLPK.Optimizer)
    @variable(myModel, x[1:m,1:n], Bin)
    @objective(myModel, Max, sum(p[i,j]*x[i,j] for i=1:m for j=1:n))
    # each job must be served
    @constraint(myModel, [j=1:n],sum(x[i,j] for i=1:m) == 1)
    @constraint(myModel, capacity[i=1:m],sum(w[i,j]*x[i,j] for j=1:n) <= c[i])

    # define blocks (Each block becomes a sub-problem)
    blocks = [[capacity[i]] for i=1:m]
    # this ensures that <blocks> has the right type
    blocks = Vector{Vector{ConstraintRef}}(blocks)
    
    return myModel, blocks
end


function exampleSlides()
    # w[i,j] = capacity used when assigning job j to machine i
    # p[i,j] = profit of assigning job j to machine i
    w = [
    7 2 8;
    8 7 6;
    9 1 9;
    ]
    p =[
    6 4 6
    1 3 4
    1 2 8
    ]
    cap = [9 7 10]

    gapModel, blocks = GAPMIP(w, p, cap)
    DWColGenEasy(gapModel, blocks)
end

exampleSlides()