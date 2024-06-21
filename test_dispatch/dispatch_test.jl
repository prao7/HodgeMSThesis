using CSV
using DataFrames
using JuMP
using Gurobi
using Plots
gr() 

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

# Print lengths to verify
#println("Length of energy_prices_5min: ", length(energy_prices_5min))
#println("Length of reserve_sr_prices: ", length(reserve_sr_prices))
#println("Length of reserve_reg_prices: ", length(reserve_reg_prices))
#println("Length of reserve_pr_prices: ", length(reserve_pr_prices))
#println("Length of reserve_30min_prices: ", length(reserve_30min_prices))
#println("Length of reserve_sr_demand: ", length(reserve_sr_demand))
#println("Length of reserve_reg_demand: ", length(reserve_reg_demand))
#println("Length of reserve_pr_demand: ", length(reserve_pr_demand))
#println("Length of reserve_30min_demand: ", length(reserve_30min_demand))

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

# Define the STP model
function solve_STP(params, fuel_cost, OM_cost, start_up_cost, shut_down_cost, FPO_cost, P_min, P_max, ramp_rate, energy_prices, reserve_sr_prices, reserve_reg_prices, reserve_pr_prices, reserve_30min_prices, reserve_sr_demand, reserve_reg_demand, reserve_pr_demand, reserve_30min_demand)
    model = Model(Gurobi.Optimizer)
    set_optimizer_attribute(model, "OutputFlag", 1)  # Enable solver output

    N_units = length(P_min)  # Number of units
    T = length(energy_prices)  # Number of time periods

    # Decision variables
    @variable(model, 0 <= P[u=1:N_units, t=1:T] <= P_max[u])
    @variable(model, U[u=1:N_units, t=1:T], Bin)
    @variable(model, SU[u=1:N_units, t=1:T], Bin)
    @variable(model, SD[u=1:N_units, t=1:T], Bin)
    @variable(model, 0 <= R_sr[u=1:N_units, t=1:T] <= reserve_sr_demand[t])  # Spinning Reserve
    @variable(model, 0 <= R_reg[u=1:N_units, t=1:T] <= reserve_reg_demand[t])  # Regulation Reserve
    @variable(model, 0 <= R_pr[u=1:N_units, t=1:T] <= reserve_pr_demand[t])  # Primary Reserve
    @variable(model, 0 <= R_30min[u=1:N_units, t=1:T] <= reserve_30min_demand[t])  # 30-minute Reserve

    # Objective function: Maximize total revenue (energy market + reserve markets) minus costs
    @objective(model, Max, 
        sum(energy_prices[t] * P[u, t] + reserve_sr_prices[t] * R_sr[u, t] + reserve_reg_prices[t] * R_reg[u, t] + reserve_pr_prices[t] * R_pr[u, t] + reserve_30min_prices[t] * R_30min[u, t] for u in 1:N_units, t in 1:T) -
        sum(fuel_cost[u] * P[u, t] + OM_cost[u] * P[u, t] + FPO_cost[u] * P[u, t] + start_up_cost[u] * SU[u, t] + shut_down_cost[u] * SD[u, t] for u in 1:N_units, t in 1:T)
    )

    # Constraints
    # Minimum and maximum power output constraints
    @constraint(model, [u=1:N_units, t=1:T], P_min[u] * U[u, t] <= P[u, t])
    @constraint(model, [u=1:N_units, t=1:T], P[u, t] <= P_max[u] * U[u, t])

    # Ramp rate constraints
    @constraint(model, [u=1:N_units, t=2:T], P[u, t] - P[u, t-1] <= ramp_rate[u])
    @constraint(model, [u=1:N_units, t=2:T], P[u, t-1] - P[u, t] <= ramp_rate[u])

    # Start-up and shut-down constraints
    @constraint(model, [u=1:N_units, t=2:T], SU[u, t] >= U[u, t] - U[u, t-1])
    @constraint(model, [u=1:N_units, t=2:T], SD[u, t] >= U[u, t-1] - U[u, t])

    # Initial conditions (assume all units are off at the beginning)
    @constraint(model, [u=1:N_units], U[u, 1] == 0)

    # Solve the model
    optimize!(model)

    # Check the status of the solution
    if termination_status(model) == MOI.OPTIMAL
        println("Optimal solution found for STP!")
        profit = [sum(energy_prices[t] * value(P[u, t]) + reserve_sr_prices[t] * value(R_sr[u, t]) + reserve_reg_prices[t] * value(R_reg[u, t]) + reserve_pr_prices[t] * value(R_pr[u, t]) + reserve_30min_prices[t] * value(R_30min[u, t]) - fuel_cost[u] * value(P[u, t]) - OM_cost[u] * value(P[u, t]) - FPO_cost[u] * value(P[u, t]) - start_up_cost[u] * value(SU[u, t]) - shut_down_cost[u] * value(SD[u, t]) for u in 1:N_units) for t in 1:T]
        return Dict(
            "P" => [value(P[u, t]) for u in 1:N_units, t in 1:T],
            "U" => [value(U[u, t]) for u in 1:N_units, t in 1:T],
            "SU" => [value(SU[u, t]) for u in 1:N_units, t in 1:T],
            "SD" => [value(SD[u, t]) for u in 1:N_units, t in 1:T],
            "profit" => profit
        )
    else
        println("No optimal solution found for STP. Status: ", termination_status(model))
        return nothing
    end
end

#=
# Define the LTP model
function solve_LTP(params, STP_results, operational_costs)
    model = Model(Gurobi.Optimizer)
    set_optimizer_attribute(model, "OutputFlag", 1)  # Enable solver output

    N_units = length(operational_costs)  # Number of units
    T = length(STP_results["profit"])  # Number of time periods

    # Decision variables
    @variable(model, 0 <= P_LTP[u=1:N_units, t=1:T])
    @variable(model, U_LTP[u=1:N_units, t=1:T], Bin)

    # Objective function: Maximize total profit (from STP results) minus operational costs
    @objective(model, Max,
        sum(STP_results["profit"][t] for t in 1:T) -
        sum(operational_costs[u] * P_LTP[u, t] for u in 1:N_units, t in 1:T)
    )

    # Constraints
    # Ensure power output does not exceed maximum power output from STP results
    @constraint(model, [u=1:N_units, t=1:T], P_LTP[u, t] <= STP_results["P"][u, t])

    # Link operation state with power output
    @constraint(model, [u=1:N_units, t=1:T], P_LTP[u, t] <= STP_results["P"][u, t] * U_LTP[u, t])

    # Ensure U_LTP is consistent with STP results (if needed)
    @constraint(model, [u=1:N_units, t=1:T], U_LTP[u, t] == STP_results["U"][u, t])

    # Ensure power output is within operational limits
    P_min = [minimum(STP_results["P"][u, :]) for u in 1:N_units]
    P_max = [maximum(STP_results["P"][u, :]) for u in 1:N_units]
    @constraint(model, [u=1:N_units, t=1:T], P_min[u] <= P_LTP[u, t] <= P_max[u])

    # Solve the model
    optimize!(model)

    # Check the status of the solution
    if termination_status(model) == MOI.OPTIMAL
        println("Optimal solution found for LTP!")
        # Calculate the finalized profit array
        finalized_profit = [sum(STP_results["profit"][t] - operational_costs[u] * value(P_LTP[u, t]) for u in 1:N_units) for t in 1:T]

        return Dict(
            "P_LTP" => [value(P_LTP[u, t]) for u in 1:N_units, t in 1:T],
            "U_LTP" => [value(U_LTP[u, t]) for u in 1:N_units, t in 1:T],
            "finalized_profit" => finalized_profit
        )
    else
        println("No optimal solution found for LTP. Status: ", termination_status(model))
        return nothing
    end
end
=#

function solve_LTP(params, STP_results, operational_costs, filename="LTP_results.csv")
    model = Model(Gurobi.Optimizer)
    set_optimizer_attribute(model, "OutputFlag", 1)  # Enable solver output

    N_units = length(operational_costs)  # Number of units
    T = length(STP_results["profit"])  # Number of time periods

    # Decision variables
    @variable(model, 0 <= P_LTP[u=1:N_units, t=1:T])
    @variable(model, U_LTP[u=1:N_units, t=1:T], Bin)

    # Objective function: Maximize total profit (from STP results) minus operational costs
    @objective(model, Max,
        sum(STP_results["profit"][t] for t in 1:T) -
        sum(operational_costs[u] * P_LTP[u, t] for u in 1:N_units, t in 1:T)
    )

    # Constraints
    # Ensure power output does not exceed maximum power output from STP results
    @constraint(model, [u=1:N_units, t=1:T], P_LTP[u, t] <= STP_results["P"][u, t])

    # Link operation state with power output
    @constraint(model, [u=1:N_units, t=1:T], P_LTP[u, t] <= STP_results["P"][u, t] * U_LTP[u, t])

    # Ensure U_LTP is consistent with STP results (if needed)
    @constraint(model, [u=1:N_units, t=1:T], U_LTP[u, t] == STP_results["U"][u, t])

    # Ensure power output is within operational limits
    P_min = [minimum(STP_results["P"][u, :]) for u in 1:N_units]
    P_max = [maximum(STP_results["P"][u, :]) for u in 1:N_units]
    @constraint(model, [u=1:N_units, t=1:T], P_min[u] <= P_LTP[u, t] <= P_max[u])

    # Solve the model
    optimize!(model)

    # Check the status of the solution
    if termination_status(model) == MOI.OPTIMAL
        println("Optimal solution found for LTP!")
        # Calculate the finalized profit array
        finalized_profit = [sum(STP_results["profit"][t] - operational_costs[u] * value(P_LTP[u, t]) for u in 1:N_units) for t in 1:T]

        LTP_results = Dict(
            "P_LTP" => [value(P_LTP[u, t]) for u in 1:N_units, t in 1:T],
            "U_LTP" => [value(U_LTP[u, t]) for u in 1:N_units, t in 1:T],
            "finalized_profit" => finalized_profit
        )

        # Write the results to CSV
        write_LTP_results_to_csv(LTP_results, filename)

        return LTP_results
    else
        println("No optimal solution found for LTP. Status: ", termination_status(model))
        return nothing
    end
end

function plot_results(LTP_results, T)
    # Extract the power output and profit results
    P_LTP = LTP_results["P_LTP"]
    finalized_profit = LTP_results["finalized_profit"]

    # Create a time vector
    time_vector = 1:T

    # Plot the power output for each unit
    plot(title="Power Output Over Time", xlabel="Time (5-minute intervals)", ylabel="Power Output (MW)")
    for u in 1:size(P_LTP, 1)
        plot!(time_vector, P_LTP[u, :], label="Unit $u")
    end
    plot!()  # This ensures the plot is finalized and displayed

    # Plot the finalized profit over time
    plot(time_vector, finalized_profit, title="Finalized Profit Over Time", xlabel="Time (5-minute intervals)", ylabel="Profit (\$)", label="Profit")
end

# Function to write STP results to CSV
function write_STP_results_to_csv(STP_results, filename="STP_results.csv")
    if STP_results == nothing
        println("No STP results to write.")
        return
    end
    
    N_units = length(STP_results["P"])  # Number of units
    T = length(STP_results["P"][1])  # Number of time periods

    # Create a DataFrame for STP results
    df_stp = DataFrame()

    # Add columns for each unit's power output, status, start-up, and shut-down indicators
    for u in 1:N_units
        df_stp[!, "P_unit_$u"] = [STP_results["P"][u][t] for t in 1:T]
        df_stp[!, "U_unit_$u"] = [STP_results["U"][u][t] for t in 1:T]
        df_stp[!, "SU_unit_$u"] = [STP_results["SU"][u][t] for t in 1:T]
        df_stp[!, "SD_unit_$u"] = [STP_results["SD"][u][t] for t in 1:T]
    end

    # Add a column for profit per time period
    df_stp[!, "profit"] = STP_results["profit"]

    # Write the DataFrame to CSV
    CSV.write(filename, df_stp)
    println("STP results written to $filename")
end

function write_LTP_results_to_csv(LTP_results, filename="LTP_results.csv")
    if LTP_results == nothing
        println("No LTP results to write.")
        return
    end
    
    N_units = length(LTP_results["P_LTP"])  # Number of units
    T = length(LTP_results["P_LTP"][1])  # Number of time periods

    println("N_units: $N_units")
    println("T: $T")

    # Create a DataFrame for LTP results
    df_ltp = DataFrame()

    # Add columns for each unit's power output and status
    for u in 1:N_units
        P_length = length(LTP_results["P_LTP"][u])
        U_length = length(LTP_results["U_LTP"][u])
        println("Length of P_LTP_unit_$u: $P_length")
        println("Length of U_LTP_unit_$u: $U_length")

        if P_length != T || U_length != T
            println("Error: Length mismatch for unit $u. P_LTP_length: $P_length, U_LTP_length: $U_length, Expected length: $T")
            return
        end

        df_ltp[!, "P_LTP_unit_$u"] = [LTP_results["P_LTP"][u][t] for t in 1:T]
        df_ltp[!, "U_LTP_unit_$u"] = [LTP_results["U_LTP"][u][t] for t in 1:T]
    end

    # Add a column for profit per time period
    finalized_profit_length = length(LTP_results["finalized_profit"])
    println("Length of finalized_profit: $finalized_profit_length")

    if finalized_profit_length != T
        println("Error: Length mismatch for finalized_profit. Length: $finalized_profit_length, Expected length: $T")
        return
    end

    df_ltp[!, "finalized_profit"] = LTP_results["finalized_profit"]

    # Write the DataFrame to CSV
    CSV.write(filename, df_ltp)
    println("LTP results written to $filename")
end


# Example usage with your results
# STP_results = solve_STP(...)  # Assuming STP_results is obtained from the solve_STP function
# LTP_results = solve_LTP(...)  # Assuming LTP_results is obtained from the solve_LTP function

# Write results to CSV
# write_STP_results_to_csv(STP_results, "STP_results.csv")
# write_LTP_results_to_csv(LTP_results, "LTP_results.csv")

# Example usage with real data
params = Dict("some_param" => 1)
fuel_cost = [20, 18, 22]
OM_cost = [5, 4, 6]
start_up_cost = [1000, 1200, 1500]
shut_down_cost = [500, 600, 800]
FPO_cost = [2, 2, 2]
P_min = [100, 150, 200]
P_max = [500, 600, 700]
ramp_rate = [50, 60, 70]

# Solve STP
STP_results = solve_STP(params, fuel_cost, OM_cost, start_up_cost, shut_down_cost, FPO_cost, P_min, P_max, ramp_rate, energy_prices_5min, reserve_sr_prices, reserve_reg_prices, reserve_pr_prices, reserve_30min_prices, reserve_sr_demand, reserve_reg_demand, reserve_pr_demand, reserve_30min_demand)

# Check if STP results are valid before solving LTP
if STP_results != nothing
    operational_costs = [10, 12, 15]  # Example operational costs
    LTP_results = solve_LTP(params, STP_results, operational_costs)
    if LTP_results != nothing
        T = length(STP_results["profit"])  # Number of time periods
    end
end

# Example usage with real data for writing results to CSV
if STP_results != nothing
    write_STP_results_to_csv(STP_results, "STP_results.csv")
end

if LTP_results != nothing
    write_LTP_results_to_csv(LTP_results, "LTP_results.csv")
end