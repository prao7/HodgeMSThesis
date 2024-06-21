using JuMP
using Gurobi
using DataFrames
using CSV

# Load data from CSV files
cambium_df = CSV.read("/Users/pradyrao/VSCode/HodgeMSThesis/test_dispatch/Cambium22_Electrification_hourly_usa_2024.csv", DataFrame)
reserve_sr_df = CSV.read("/Users/pradyrao/VSCode/HodgeMSThesis/test_dispatch/reserve_market_resultsSR.csv", DataFrame)
reserve_reg_df = CSV.read("/Users/pradyrao/VSCode/HodgeMSThesis/test_dispatch/reserve_market_resultsREG.csv", DataFrame)
reserve_pr_df = CSV.read("/Users/pradyrao/VSCode/HodgeMSThesis/test_dispatch/reserve_market_resultsPR.csv", DataFrame)
reserve_30min_df = CSV.read("/Users/pradyrao/VSCode/HodgeMSThesis/test_dispatch/reserve_market_results30min.csv", DataFrame)

# Convert hourly data to five-minute data by repeating each value 12 times
function hourly_to_five_minute(data)
    repeat(data, inner=12)
end

energy_prices_5min = hourly_to_five_minute(cambium_df[:, "total_cost_busbar"])

# Truncate the five-minute data to match the length of the reserve market data
T = min(length(energy_prices_5min), length(reserve_sr_df[:, "mcp"]))

energy_prices_5min = energy_prices_5min[1:T]
reserve_sr_prices = reserve_sr_df[:, "mcp"][1:T]
reserve_reg_prices = reserve_reg_df[:, "mcp"][1:T]
reserve_pr_prices = reserve_pr_df[:, "mcp"][1:T]
reserve_30min_prices = reserve_30min_df[:, "mcp"][1:T]

reserve_sr_demand = reserve_sr_df[:, "as_req_mw"][1:T]
reserve_reg_demand = reserve_reg_df[:, "as_req_mw"][1:T]
reserve_pr_demand = reserve_pr_df[:, "as_req_mw"][1:T]
reserve_30min_demand = reserve_30min_df[:, "as_req_mw"][1:T]

# Load data from CSV files
cambium_df = CSV.read("/Users/pradyrao/VSCode/HodgeMSThesis/test_dispatch/Cambium22_Electrification_hourly_usa_2024.csv", DataFrame)
reserve_sr_df = CSV.read("/Users/pradyrao/VSCode/HodgeMSThesis/test_dispatch/reserve_market_resultsSR.csv", DataFrame)
reserve_reg_df = CSV.read("/Users/pradyrao/VSCode/HodgeMSThesis/test_dispatch/reserve_market_resultsREG.csv", DataFrame)
reserve_pr_df = CSV.read("/Users/pradyrao/VSCode/HodgeMSThesis/test_dispatch/reserve_market_resultsPR.csv", DataFrame)
reserve_30min_df = CSV.read("/Users/pradyrao/VSCode/HodgeMSThesis/test_dispatch/reserve_market_results30min.csv", DataFrame)


function solve_optimized_STP(params, fuel_cost, P_min, P_max, ramp_rate, energy_prices, reserve_sr_prices, reserve_reg_prices, reserve_pr_prices, reserve_30min_prices, reserve_sr_demand, reserve_reg_demand, reserve_pr_demand, reserve_30min_demand, refuel_time, OM_cost, capital_cost, lifetime_years)
    model = Model(Gurobi.Optimizer)
    set_optimizer_attribute(model, "OutputFlag", 1)  # Enable solver output

    N_units = length(P_min)  # Number of units
    T = length(energy_prices)  # Number of time periods

    # Calculate 5-minute O&M and capital costs
    total_5min_periods = 365 * 24 * 12 * lifetime_years
    OM_cost_5min = OM_cost / total_5min_periods
    capital_cost_5min = capital_cost / total_5min_periods

    # Decision variables
    @variable(model, 0 <= P[u=1:N_units, t=1:T] <= P_max[u])
    @variable(model, U[u=1:N_units, t=1:T], Bin)
    @variable(model, refuel[u=1:N_units, t=1:T], Bin)  # Refuel decision
    @variable(model, 0 <= R_sr[u=1:N_units, t=1:T])
    @variable(model, 0 <= R_reg[u=1:N_units, t=1:T])
    @variable(model, 0 <= R_pr[u=1:N_units, t=1:T])
    @variable(model, 0 <= R_30min[u=1:N_units, t=1:T])

    # Objective function: Maximize total revenue (energy market + reserve markets) minus costs
    max_energy_price = maximum(energy_prices)
    @objective(model, Max,
        (1/12) * sum(energy_prices[t] * P[u, t] + reserve_sr_prices[t] * R_sr[u, t] + reserve_reg_prices[t] * R_reg[u, t] + reserve_pr_prices[t] * R_pr[u, t] + reserve_30min_prices[t] * R_30min[u, t] for u in 1:N_units, t in 1:T) -
        (1/12) * sum(fuel_cost[u] * P[u, t] for u in 1:N_units, t in 1:T) -
        sum(OM_cost_5min[u] * P[u, t] + capital_cost_5min[u] * P[u, t] for u in 1:N_units, t in 1:T) +
        sum((1 - refuel[u, t]) * (max_energy_price - energy_prices[t]) for u in 1:N_units, t in 1:T)
    )

    # Constraints
    # Minimum and maximum power output constraints
    @constraint(model, [u=1:N_units, t=1:T], P_min[u] * U[u, t] <= P[u, t])
    @constraint(model, [u=1:N_units, t=1:T], P[u, t] <= P_max[u] * U[u, t])

    # Ramp rate constraints
    @constraint(model, [u=1:N_units, t=2:T], P[u, t] - P[u, t-1] <= ramp_rate[u])
    @constraint(model, [u=1:N_units, t=2:T], P[u, t-1] - P[u, t] <= ramp_rate[u])

    # Initial conditions (assume all units are off at the beginning)
    @constraint(model, [u=1:N_units], U[u, 1] == 0)

    # Refueling constraints: Only one unit can refuel at a time
    @constraint(model, [t=1:T], sum(refuel[u, t] for u in 1:N_units) <= 1)
    
    # Refueling time constraints: Ensure a unit refuels for `refuel_time` consecutive time periods
    @constraint(model, [u=1:N_units, t=1:T-refuel_time+1], sum(refuel[u, t:t+refuel_time-1]) <= 1)

    # Ensure unit is off during refueling
    @constraint(model, [u=1:N_units, t=1:T], U[u, t] <= 1 - refuel[u, t])

    # Refueling interval constraints: Force refueling every 15 to 18 months
    min_refuel_periods = 5 * 30 * 24 * 12
    max_refuel_periods = 8 * 30 * 24 * 12
    for u in 1:N_units
        for t in 1:T-max_refuel_periods+1
            @constraint(model, sum(refuel[u, t1] for t1 in t:min(t+max_refuel_periods-1, T)) >= min_refuel_periods)
        end
    end

    # Constraints for maximum supplied power to reserve markets
    @constraint(model, [u=1:N_units, t=1:T], R_sr[u, t] <= 0.1 * reserve_sr_demand[t])
    @constraint(model, [u=1:N_units, t=1:T], R_reg[u, t] <= 0.1 * reserve_reg_demand[t])
    @constraint(model, [u=1:N_units, t=1:T], R_pr[u, t] <= 0.1 * reserve_pr_demand[t])
    @constraint(model, [u=1:N_units, t=1:T], R_30min[u, t] <= 0.1 * reserve_30min_demand[t])

    # Solve the model
    optimize!(model)

    # Check the status of the solution
    if termination_status(model) == MOI.OPTIMAL
        println("Optimal solution found for STP!")
        profit = (1/12) * [sum(energy_prices[t] * value(P[u, t]) + reserve_sr_prices[t] * value(R_sr[u, t]) + reserve_reg_prices[t] * value(R_reg[u, t]) + reserve_pr_prices[t] * value(R_pr[u, t]) + reserve_30min_prices[t] * value(R_30min[u, t]) - fuel_cost[u] * value(P[u, t]) - OM_cost_5min[u] * value(P[u, t]) - capital_cost_5min[u] * value(P[u, t]) for u in 1:N_units) for t in 1:T]
        return Dict(
            "P" => [value(P[u, t]) for u in 1:N_units, t in 1:T],
            "U" => [value(U[u, t]) for u in 1:N_units, t in 1:T],
            "refuel" => [value(refuel[u, t]) for u in 1:N_units, t in 1:T],
            "R_sr" => [value(R_sr[u, t]) for u in 1:N_units, t in 1:T],
            "R_reg" => [value(R_reg[u, t]) for u in 1:N_units, t in 1:T],
            "R_pr" => [value(R_pr[u, t]) for u in 1:N_units, t in 1:T],
            "R_30min" => [value(R_30min[u, t]) for u in 1:N_units, t in 1:T],
            "profit" => profit
        )
    else
        println("No optimal solution found for STP. Status: ", termination_status(model))
        return nothing
    end
end


# Example usage with real data from NuScale
params = Dict("some_param" => 1)
fuel_cost = [7.15, 7.15, 7.15]
#start_up_cost = [500000, 500000, 500000]
#shut_down_cost = [500000, 500000, 500000]
P_min = [(0.4*77), (0.4*77), (0.4*77)]
P_max = [77, 77, 77]
ramp_rate = [50, 50, 50]
refuel_time = 48*12  # Number of consecutive time periods for refueling

OM_cost = [179595, 179595, 179595]  # Example O&M costs for each unit ($/MWh)
capital_cost = [3466000, 3466000, 3466000]  # Example capital costs for each unit ($/MWh over lifetime)
lifetime_years = 60  # Plant lifetime in years

# Assuming you have already defined and loaded your data
# For example, let's assume `energy_prices`, `reserve_sr_prices`, `reserve_reg_prices`, `reserve_pr_prices`, `reserve_30min_prices`, `reserve_sr_demand`, `reserve_reg_demand`, `reserve_pr_demand`, `reserve_30min_demand` are defined

# Example usage
STP_results = solve_optimized_STP(params, fuel_cost, P_min, P_max, ramp_rate, energy_prices_5min, reserve_sr_prices, reserve_reg_prices, reserve_pr_prices, reserve_30min_prices, reserve_sr_demand, reserve_reg_demand, reserve_pr_demand, reserve_30min_demand, refuel_time, OM_cost, capital_cost, lifetime_years)

println(maximum(STP_results["P"]))
println(minimum(STP_results["P"]))
println(sum(STP_results["profit"]))
println(minimum(STP_results["SD"]))

# # Write results to CSV
# if STP_results != nothing
#     write_STP_results_to_csv(STP_results, "STP_results.csv")
# end
