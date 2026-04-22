using JuMP
using HiGHS

include("../exercise2_data - Copy.jl")
N, M = size(w)
I = 1:N
J = 1:M


# solves the subproblem of a certain machine i, resulting in a new pattern (or optimal solution found)
function solve_subproblem(i, job_dual, conv_dual)
    sub = Model(HiGHS.Optimizer)
    set_silent(sub)

    @variable(sub, 0 <= new_pattern[J] <= 1.0)
    @objective(sub, Max, sum(p[i,j]*new_pattern[j] - job_dual[j]*new_pattern[j] for j in J) - conv_dual[i])
    @constraint(sub, sum(w[i,j] * new_pattern[j] for j in J) <= cap[i])
    for (a, b) in K
        @constraint(sub, new_pattern[a]+new_pattern[b] <= 1)
    end
    optimize!(sub)

    if termination_status(sub) == OPTIMAL
        if -objective_value(sub) < -1e-6
            return true, value.(new_pattern), sum(p[i,j] * value.(new_pattern)[j] for j in J)
        else
            return false, zeros(M), -1000
        end
    else
        println("subproblem infeasible")
    end
end

function solve()
    jp = [Matrix{Float64}(undef, 0, M) for _ in I]
    profit = [Vector{Float64}() for _ in I]

    for i in I
        if i == 1
            jp[i]   = ones(1, M)    # dummy pattern: all jobs assigned
            profit[i] = [-1000]    
        else
            jp[i]   = zeros(1, M)   # empty pattern: no jobs assigned
            profit[i] = [0.0]
        end
    end

    pattern_found = true
    iteration = 0
    while pattern_found
        pattern_found = false
        iteration += 1
        mas = Model(HiGHS.Optimizer)
        set_silent(mas)
        # Job patterns are refered to as jp[machine, pattern, job]. 
        # profit[i,s] is the profit of machine i with pattern s
        @variable(mas, 0 <= lambda[i=I,1:size(jp[i],1)])
        @objective(mas, Max, sum(profit[i][s]*lambda[i,s] for i in I, s in 1:size(jp[i],1)))
        @constraint(mas, job[j=J], sum(jp[i][s,j]*lambda[i,s] for i in I, s in 1:size(jp[i],1)) == 1)
        @constraint(mas, conv[i=I], sum(lambda[i,s] for s in 1:size(jp[i],1)) == 1)

        optimize!(mas)
        println("Iteration $iteration: Objective value = ", objective_value(mas))

        job_dual = -dual.(job)
        conv_dual = -dual.(conv)

        for i in I
            new_pattern_found, new_pattern, new_profit = solve_subproblem(i,job_dual,conv_dual)
            if new_pattern_found
                pattern_found = true
                jp[i] = vcat(jp[i], new_pattern') # as new_pattern is a matrix, we can't use push!
                push!(profit[i], new_profit)
            end
        end
        if !pattern_found 
            println("Final objective value: $(objective_value(mas))")
            patterns_used = []
            for i in I
                for s in 1:size(jp[i],1)
                    if value(lambda[i,s]) > 1e-6
                        # println("lambda[$i,$s]: $(value(lambda[i,s]))")
                        push!(patterns_used, (i,s))
                    end
                end
            end
            for (mach_idx, jp_idx) in patterns_used
                println("Used pattern for machine $mach_idx: $(jp[mach_idx][jp_idx,:])")
            end
        end
    end
end

solve()