module GAP_col_gen

using GLPK
using JuMP

struct Pattern
    # vector of 0/1 values indicating which jobs are included in the pattern.
    # has as many elements as the number of jobs
    jobs::Vector{Int}
    profit::Float64
end

function setup_master(patterns, nJobs, nMachines)
    myModel = Model(GLPK.Optimizer)
    @variable(myModel, lambda[i=1:nMachines, 1:length(patterns[i])] >= 0)
    @objective(myModel, Max, sum(patterns[i][s].profit * lambda[i,s] for i=1:nMachines for s=1:length(patterns[i])))
    @constraint(myModel, job_served[j=1:nJobs], sum(patterns[i][s].jobs[j] * lambda[i,s] for i=1:nMachines for s=1:length(patterns[i])) == 1)
    @constraint(myModel, convexity_cons[i=1:nMachines], sum(lambda[i,s] for s=1:length(patterns[i])) == 1)
    return myModel, job_served, convexity_cons
end

function solve_subproblem(i, w, p, c, duals_job_served, dual_convexity_cons)
    nJobs = size(w, 2)
    subModel = Model(GLPK.Optimizer)
    @variable(subModel, 0 <= y[j=1:nJobs] <= 1)
    @objective(subModel, Max, sum((p[i,j] - duals_job_served[j]) * y[j] for j=1:nJobs) - dual_convexity_cons)
    @constraint(subModel, sum(w[i,j] * y[j] for j=1:nJobs) <= c[i])
    for (a, b) in K
        @constraint(subModel, y[a]+y[b] <= 1)
    end
    optimize!(subModel)

    if termination_status(subModel) == MOI.OPTIMAL
        new_pattern_jobs = value.(y)
        reduced_cost = objective_value(subModel)
        if reduced_cost > 1e-6 # some small threshold to avoid numerical issues
            println("New pattern for machine $i with reduced cost $reduced_cost: ", new_pattern_jobs)
            return true, Pattern(new_pattern_jobs, sum(p[i,j] * new_pattern_jobs[j] for j=1:nJobs))
        else
            return false, Pattern(zeros(nJobs), 0)
        end
    else
        error("Subproblem for machine $i not optimal")
    end
end

function colgen(w, p, c)
    nJobs = size(w, 2)
    nMachines = size(w, 1)

    patterns = Vector{Vector{Pattern}}(undef, nMachines)
    for i in 1:nMachines
        if i == 1
            # dummy pattern to ensure the master problem is feasible at the start
            patterns[i] = [Pattern(ones(nJobs), -1000)]
        else
            # empty pattern for all the other machines
            patterns[i] = [Pattern(zeros(nJobs), 0)]
        end
    end

    master, job_served, convexity_cons = setup_master(patterns, nJobs, nMachines)

    iter = 0
    done = false
    while !done
        iter += 1
        #println(master)
        if iter > 100
            error("Too many iterations, something might be wrong")
        end
        optimize!(master)
        println("Iteration $iter: Master objective value = ", objective_value(master))
        if termination_status(master) != MOI.OPTIMAL
            error("Master problem not optimal")
        end

        # get duals
        duals_job_served = -dual.(job_served)
        duals_convexity_cons = -dual.(convexity_cons)

        # solve subproblems and add new patterns to the master problem
        done = true
        for i in 1:nMachines
            # solve subproblem for machine i using the duals as input
            col_found, pattern = solve_subproblem(i, w, p, c, duals_job_served, duals_convexity_cons[i])
            if col_found
                push!(patterns[i], pattern)
                done = false
            end
        end
        if !done
            # inefficient way to rebuild the master problem, but it keeps the code simple for this example
            master, job_served, convexity_cons = setup_master(patterns, nJobs, nMachines)
        else
            println("No more columns with positive reduced cost found, optimal solution reached.")
        end
    end   
end

function example()
    # Use data from the supplied data file:
    include("../exercise2_data - Copy.jl")
    colgen(w, p, cap)
end

example()

end