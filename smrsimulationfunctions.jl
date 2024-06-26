using DataFrames
using Statistics
using Distributions
using Gurobi
using Plots
using JuMP

# For testing, including Data.jl and dataprocessingfunctions.jl
include("data.jl")
include("dataprocessingfunctions.jl")

"""
This function details how a basic dispatch and payout of an SMR would be in response to prices. This function
needs to be further evaluated for a more realistic approach to SMR dispatch.
"""
function smr_dispatch_iteration_one(price_data, no_ramping_cf::Float64, ramping_cf::Float64, module_size::Float64, price_multiplication_factor::Float64, number_of_modules::Int)
    # Returned array with generator hourly payout
    generator_payout = []

    # Returned array with generator energy output
    generator_output = []

    # An assumption made here is a flat value where ramping is acceptable TODO: Assumption to be explored
    ramping_price = price_multiplication_factor*mean(price_data)

    # This loop will calculate the generator output and payout
    for (index, value) in enumerate(price_data)
        if value >= ramping_price
            # Adding to the array the payout from ramped generation
            push!(generator_payout, value*ramping_cf*module_size*number_of_modules)

            # Generation hourly added to the array
            push!(generator_output, ramping_cf*module_size*number_of_modules)
        elseif value <= 0
            # If prices are negative, and the previous hour the generator had been ramped, come back to normal gen
            if (price_data[index-1]>=ramping_price)
                #  Rather than 0 output, more realistic ramping capabilities TODO: Check assumption
                push!(generator_payout, value*module_size*number_of_modules*no_ramping_cf)
                push!(generator_output, no_ramping_cf*module_size*number_of_modules)
            else
                # If the generator previously had been running normally, reduce output by 4% to minimize negative price impact
                # TODO: Check this assumption of ramping down 4%
                push!(generator_payout,value*module_size*number_of_modules*(no_ramping_cf-0.04))
                push!(generator_output,module_size*number_of_modules*(no_ramping_cf-0.04))
            end
            #push!(generator_output,value*module_size*number_of_modules*(price_data[]))
        else
            # Adding the payout from the non ramped generation
            push!(generator_payout, value*no_ramping_cf*module_size*number_of_modules)

            # Generation output from the non ramped generation
            push!(generator_output, no_ramping_cf*module_size*number_of_modules)
        end
    end

    return generator_payout, generator_output
end

"""
The following code corrects the dispatch of the SMR to be more realistic.
It does an approximation of the operational dispatch of the paper below.

Paper used: https://www.sciencedirect.com/science/article/pii/S0360544223015013
"""
function smr_dispatch_iteration_three(price_data, module_size::Float64, number_of_modules::Int, fuel_cost::Float64, production_credit::Float64, 
    construction_end::Int, production_credit_start::Int, production_credit_end::Int, refuel_time_upper::Int, refuel_time_lower::Int, lifetime::Int)
    # Assumption: Startup cost is based on moderate scenario from source: https://inldigitallibrary.inl.gov/sites/sti/sti/Sort_107010.pdf, pg. 82
    startup_cost_kW = 60
    refuel_time = 24*10 # Refuel time is 10 days as per the paper https://www.sciencedirect.com/science/article/pii/S0360544223015013

    # Assumption: Startup cost is for one module at a time, as only one module refueling at a time
    startup_cost_mW = (startup_cost_kW*module_size*1000)/refuel_time


    # Start year of all scenarios is 2040
    start_year = 2024
    
    # Calculating the year of the start and end of the construction and production credit
    construction_start_index = construction_end
    production_credit_start_index = production_credit_start - start_year
    production_credit_end_index = production_credit_end - start_year

    # Calculating the actual index of the start and end of the construction and production credit
    construction_start_index = construction_start_index*8760
    production_credit_start_index = production_credit_start_index*8760
    production_credit_end_index = production_credit_end_index*8760

    # Defining low power operation range
    lpo_smr = 0.6*module_size*number_of_modules
    lpo_smr_refueling = 0.6*module_size*(number_of_modules-1)

    # Returned array with generator hourly payout
    generator_payout = []

    # Returned array with generator energy output
    generator_output = []

    """
    Curating the fuel cost array. This is done by taking the fuel cost input and perturbing it by the standard deviation to create hourly fuel costs.
    The fuel cost is uniform across a day.
    """
    #fuel_cost_array = fuel_cost_array_calc(length(price_data), fuel_cost)

    """
    Curating the operating status array. This is done by randomly choosing a refueling time between the range of refueling times.
    """

    operating_status = operating_status_array_calc(price_data, number_of_modules, refuel_time_upper, refuel_time_lower)

    """
    Running dispatch formulation of the SMR to calculate the payout array.
    """

    # This loop is the primary dispatch calculation loop, hourly prices are assumed as fixed throughout the hour
    for (hour, elec_hourly_price) in enumerate(price_data)


        # If the SMR hasn't been constructed yet, the payout and dispatch is 0
        if hour < construction_start_index
            push!(generator_payout, 0)
            push!(generator_output, 0)
            continue
        else
            # This is if no ancillary services are included in the dispatch
            if elec_hourly_price >= fuel_cost

                # If the production credit is valid add the production credit, otherwise don't add it
                if hour >= production_credit_start_index && hour <= production_credit_end_index
                    # If the price is higher than the fuel cost, the generator will dispatch to the energy market
                    if operating_status[hour] == 1
                        # If the SMR is not refueling, the operating status is 1. In this case, all modules are operational.
                        push!(generator_payout, (elec_hourly_price*module_size*number_of_modules + production_credit*module_size*number_of_modules - fuel_cost*module_size*number_of_modules))
                        push!(generator_output, module_size*number_of_modules)
                    else
                        # If the SMR is refueling, the operating status is 0. In this case, there is a single module shut down.
                        push!(generator_payout, (elec_hourly_price*module_size*(number_of_modules - 1) + production_credit*module_size*(number_of_modules-1) - fuel_cost*module_size*(number_of_modules-1) - startup_cost_mW*(number_of_modules-1)))
                        push!(generator_output, module_size*number_of_modules)
                    end
                else
                    # If the price is higher than the fuel cost, the generator will dispatch to the energy market, and this is a condition that doesn't have production credit
                    if operating_status[hour] == 1
                        # If the SMR is not refueling, the operating status is 1. In this case, all modules are operational.
                        push!(generator_payout, (elec_hourly_price*module_size*number_of_modules - fuel_cost*module_size*number_of_modules))
                        push!(generator_output, module_size*number_of_modules)
                    else
                        # If the SMR is refueling, the operating status is 0. In this case, there is a single module shut down.
                        push!(generator_payout, (elec_hourly_price*module_size*(number_of_modules - 1) - fuel_cost*module_size*(number_of_modules-1) - startup_cost_mW*(number_of_modules-1)))
                        push!(generator_output, module_size*number_of_modules)
                    end
                end
                
            else

                # If the production credit is valid add the production credit, otherwise don't add it
                if hour >= production_credit_start_index && hour <= production_credit_end_index
                    # If the price is lower than the fuel cost, the generator will ramp down to the low power operation range
                    if operating_status[hour] == 1
                        # If the SMR is not refueling, the operating status is 1. In this case, all modules are operational.
                        push!(generator_payout, (elec_hourly_price*lpo_smr + production_credit*lpo_smr - fuel_cost*lpo_smr))
                        push!(generator_output, lpo_smr)
                    else
                        # If the SMR is refueling, the operating status is 0. In this case, there is a single module shut down.
                        push!(generator_payout, (elec_hourly_price*lpo_smr_refueling + production_credit*lpo_smr_refueling - fuel_cost*lpo_smr_refueling - startup_cost_mW*lpo_smr_refueling))
                        push!(generator_output, lpo_smr_refueling)
                    end
                else
                    # If the production cost is not valid, then the dispatch is the same as above, but without the production credit
                    if operating_status[hour] == 1
                        # If the SMR is not refueling, the operating status is 1. In this case, all modules are operational.
                        push!(generator_payout, (elec_hourly_price*lpo_smr - fuel_cost*lpo_smr))
                        push!(generator_output, lpo_smr)
                    else
                        # If the SMR is refueling, the operating status is 0. In this case, there is a single module shut down.
                        push!(generator_payout, (elec_hourly_price*lpo_smr_refueling - fuel_cost*lpo_smr_refueling - startup_cost_mW*lpo_smr_refueling))
                        push!(generator_output, lpo_smr_refueling)
                    end
                end
            end
        end
    end
    
    return generator_payout, generator_output
end


"""
The following code corrects the dispatch of the SMR to be more realistic.
It does an approximation of the operational dispatch of the paper below.

Paper used: https://www.sciencedirect.com/science/article/pii/S0360544223015013
"""
function smr_dispatch_iteration_three_withATB(price_data::Vector{Float64}, module_size::Float64, number_of_modules::Int, fuel_cost::Float64, vom_cost::Float64, production_credit::Float64, 
    construction_end::Int, production_credit_start::Int, production_credit_end::Int, refuel_time_upper::Int, refuel_time_lower::Int, lifetime::Int)
    # Assumption: Startup cost [$/kWh] is based on moderate scenario from source: https://inldigitallibrary.inl.gov/sites/sti/sti/Sort_107010.pdf, pg. 82
    startup_cost_kW = 60
    refuel_time = 24*10 # Refuel time is 10 days as per the paper https://www.sciencedirect.com/science/article/pii/S0360544223015013

    # Assumption: Startup cost is for one module at a time, as only one module refueling at a time
    startup_cost_mW = (startup_cost_kW*module_size*1000)/refuel_time


    # Start year of all scenarios is 2040
    start_year = 2024
    
    # Calculating the year of the start and end of the construction and production credit
    construction_start_index = construction_end
    production_credit_start_index = production_credit_start - start_year
    production_credit_end_index = production_credit_end - start_year

    # Calculating the actual index of the start and end of the construction and production credit
    construction_start_index = construction_start_index*8760
    production_credit_start_index = production_credit_start_index*8760
    production_credit_end_index = production_credit_end_index*8760

    # Defining low power operation range
    lpo_smr = 0.6*module_size*number_of_modules
    lpo_smr_refueling = 0.6*module_size*(number_of_modules-1)

    # Returned array with generator hourly payout
    generator_payout = []

    # Returned array with generator energy output
    generator_output = []

    """
    Curating the fuel cost array. This is done by taking the fuel cost input and perturbing it by the standard deviation to create hourly fuel costs.
    The fuel cost is uniform across a day.
    """
    #fuel_cost_array = fuel_cost_array_calc(length(price_data), fuel_cost)

    """
    Curating the operating status array. This is done by randomly choosing a refueling time between the range of refueling times.
    """

    # If the refuel time is not the same as the lifetime of the SMR, then the SMR will refuel
    operating_status = operating_status_array_calc(price_data, number_of_modules, refuel_time_upper, refuel_time_lower)

    """
    Running dispatch formulation of the SMR to calculate the payout array.
    """

    # This loop is the primary dispatch calculation loop, hourly prices are assumed as fixed throughout the hour
    for (hour, elec_hourly_price) in enumerate(price_data)


        # If the SMR hasn't been constructed yet, the payout and dispatch is 0
        if hour < construction_start_index
            push!(generator_payout, 0)
            push!(generator_output, 0)
            continue
        else
            # This is if only bidding into the energy market
            if elec_hourly_price >= fuel_cost

                # If the production credit is valid add the production credit, otherwise don't add it
                if hour >= production_credit_start_index && hour <= production_credit_end_index
                    # If the price is higher than the fuel cost, the generator will dispatch to the energy market
                    if operating_status[hour] == 1
                        # If the SMR is not refueling, the operating status is 1. In this case, all modules are operational.
                        push!(generator_payout, (elec_hourly_price*module_size*number_of_modules + production_credit*module_size*number_of_modules - fuel_cost*module_size*number_of_modules - vom_cost*module_size*number_of_modules))
                        push!(generator_output, module_size*number_of_modules)
                    else
                        # If the SMR is refueling, the operating status is 0. In this case, there is a single module shut down.
                        push!(generator_payout, (elec_hourly_price*module_size*(number_of_modules - 1) + production_credit*module_size*(number_of_modules-1) - fuel_cost*module_size*(number_of_modules-1) - startup_cost_mW - vom_cost*module_size*(number_of_modules-1)))
                        push!(generator_output, module_size*number_of_modules)
                    end
                else
                    # If the price is higher than the fuel cost, the generator will dispatch to the energy market, and this is a condition that doesn't have production credit
                    if operating_status[hour] == 1
                        # If the SMR is not refueling, the operating status is 1. In this case, all modules are operational.
                        push!(generator_payout, (elec_hourly_price*module_size*number_of_modules - fuel_cost*module_size*number_of_modules - vom_cost*module_size*number_of_modules))
                        push!(generator_output, module_size*number_of_modules)
                    else
                        # If the SMR is refueling, the operating status is 0. In this case, there is a single module shut down.
                        push!(generator_payout, (elec_hourly_price*module_size*(number_of_modules - 1) - fuel_cost*module_size*(number_of_modules-1) - startup_cost_mW - vom_cost*module_size*(number_of_modules-1)))
                        push!(generator_output, module_size*number_of_modules)
                    end
                end
                
            else

                # If the production credit is valid add the production credit, otherwise don't add it
                if hour >= production_credit_start_index && hour <= production_credit_end_index
                    # If the price is lower than the fuel cost, the generator will ramp down to the low power operation range
                    if operating_status[hour] == 1
                        # If the SMR is not refueling, the operating status is 1. In this case, all modules are operational.
                        push!(generator_payout, (elec_hourly_price*lpo_smr + production_credit*lpo_smr - fuel_cost*lpo_smr - vom_cost*lpo_smr))
                        push!(generator_output, lpo_smr)
                    else
                        # If the SMR is refueling, the operating status is 0. In this case, there is a single module shut down.
                        push!(generator_payout, (elec_hourly_price*lpo_smr_refueling + production_credit*lpo_smr_refueling - fuel_cost*lpo_smr_refueling - startup_cost_mW - vom_cost*lpo_smr_refueling))
                        push!(generator_output, lpo_smr_refueling)
                    end
                else
                    # If the production cost is not valid, then the dispatch is the same as above, but without the production credit
                    if operating_status[hour] == 1
                        # If the SMR is not refueling, the operating status is 1. In this case, all modules are operational.
                        push!(generator_payout, (elec_hourly_price*lpo_smr - fuel_cost*lpo_smr - vom_cost*lpo_smr))
                        push!(generator_output, lpo_smr)
                    else
                        # If the SMR is refueling, the operating status is 0. In this case, there is a single module shut down.
                        push!(generator_payout, (elec_hourly_price*lpo_smr_refueling - fuel_cost*lpo_smr_refueling - startup_cost_mW - vom_cost*lpo_smr_refueling))
                        push!(generator_output, lpo_smr_refueling)
                    end
                end
            end
        end
    end
    
    return generator_payout, generator_output
end

"""
This function calculates the dispatch behavior of an SMR and storage device.
Paper used: https://www.mdpi.com/1996-1073/15/10/3599
"""
function smr_plus_storage_dispatch()
    # Code here
end

"""
This function returns the real time NPV, lifetime NPV and break even for a generator based on the payout, interest rate input
and capital and O&M cost calulation. 
"""
function npv_calc(generator_payout::Vector{Any}, interest_rate::Float64, initial_investment::Float64, lifetime::Int)
    # First, create an empty array for the real time NPV
    npv_tracker = []

    # Creating another empty array to calculate the NPV payoff per year
    npv_payoff = []

    # Empty break even tracker
    break_even = 0

    for index in 1:lifetime 
        # This array will show the value of the cashflow per year
        push!(npv_payoff, sum(generator_payout)/((1+interest_rate)^index))

        # Which we will use to calculate the real time NPV
        push!(npv_tracker, (sum(npv_payoff) - initial_investment))
    end

    # This is the break even calculator
    for (index, value) in enumerate(npv_tracker)
        
        # Break out of the loop when NPV first turns positive
        if value >=0
            break_even = index
            break
        end
    end
    
    return npv_tracker, break_even, npv_payoff
end

"""
This function calculates the capital cost/initial investment of an SMR prototype
"""
function initial_investment_calculation(capacity::Float64, construction_cost::Float64, o_and_m_cost::Float64, number_of_modules::Int)
    return (((construction_cost*capacity) + (o_and_m_cost*capacity))*number_of_modules)
end

"""
This function calculates the total investment cost of an SMR prototype including delays

Paper used: https://www.sciencedirect.com/science/article/pii/S0301421518303446

From the paper, the discount rate used was 10%
"""
function calculate_total_investment_with_cost_of_delay(interest_rate::Float64, capacity::Float64, construction_cost::Float64, o_and_m_cost::Float64, 
    number_of_modules::Int, standard_construction_time::Int, lead_time::Int)
    # Calculate the total construction cost
    total_construction_cost = construction_cost*capacity*number_of_modules

    # Calculate the total O&M cost
    total_o_and_m_cost = o_and_m_cost*capacity*number_of_modules
    
    # Log-normal distribution parameters
    mu = log(total_construction_cost / standard_construction_time)  # Mean of the log-normal distribution
    sigma = 0.5  # Standard deviation of the log-normal distribution (can adjust as needed)

    # Generate annual construction costs for standard construction time
    dist = LogNormal(mu, sigma)
    construction_cost_standard = rand(dist, standard_construction_time)
    construction_cost_standard *= total_construction_cost / sum(construction_cost_standard)  # Scale to total cost

    # Generate annual construction costs for lead time (including delays)
    construction_cost_lead = rand(dist, lead_time)
    construction_cost_lead *= total_construction_cost / sum(construction_cost_lead)  # Scale to total cost

    # Calculate SOCC (Standard Operation Capital Cost)
    SOCC = sum(construction_cost_standard[t] * (1 + interest_rate)^(standard_construction_time - t) for t in 1:standard_construction_time)

    # Calculate TOCC (Total Operation Capital Cost)
    TOCC = sum(construction_cost_lead[t] * (1 + interest_rate)^(lead_time - t) for t in 1:lead_time)

    # Calculate CoD (Cost of Delay)
    CoD = TOCC - SOCC

    # Calculate total initial investment
    total_investment_cost = total_construction_cost + total_o_and_m_cost + CoD

    # This return function is just for testing. The actual function will return total_investment_cost
    return total_investment_cost
end

"""
This function takes a scenario as an input, and calculates the NPV lifetime of the scenario as a whole
"""
function npv_calc_scenario(payout_array, interest_rate::Float64, initial_investment::Float64, lifetime::Float64)
   # First, create an empty array for the real time NPV
   npv_tracker = []

   # Creating another empty array to calculate the NPV payoff per year
   npv_payoff = []

   # Empty break even tracker
   break_even = lifetime

   # Create an empty variable to hold the current hour being analyzed
   current_hour = 1

   for index in 1:lifetime
    # Empty variable to hold the yearly payout
    generator_payout_var = 0

    # This loop will calculate the yearly payout of the scenario
    for i in 1:8760
        # Summing the yearly payout
        generator_payout_var += payout_array[current_hour]

        # Incrementing the current hour analyzed
        current_hour += 1
    end

    # This array will show the value of the cashflow per year
    push!(npv_payoff, generator_payout_var/((1+interest_rate)^index))

    # Which we will use to calculate the real time NPV
    push!(npv_tracker, (sum(npv_payoff) - initial_investment))
   end

   # This is the break even calculator
   for (index, value) in enumerate(npv_tracker)
     # Break out of the loop when NPV first turns positive
     if value >=0
        break_even = index
        break
     end
   end

   return npv_tracker, break_even, npv_payoff
end


"""
This function calculates the fuel cost array based on the average fuel cost of the reactor 
given by each reactor type. The fuel cost is perturbed by a standard deviation range to create
hourly prices for an entire scenario.
"""
function fuel_cost_array_calc(len::Int, fuel_cost::Float64)
    # Array to contain the fuel cost
    fuel_cost_array = ones(len)

    # Array containing standard deviation range of fuel cost. Need to use this to calculate the fuel cost per day
    # Using this paper to define the fuel cost max and min standard deviation: https://www.scirp.org/html/2-6201621_45669.htm
    fuel_cost_sd_range = [0.091, 0.236]

    # Initialising the current hour of the day
    current_hour_of_day = 1

    # Initialising the current fuel cost input
    current_fuel_cost = fuel_cost

    # This loop creates the fuel cost array
    for i in 1:length(fuel_cost_array)
        if current_hour_of_day == 1
            # Random standard deviation between fuel cost standard dev
            deviation = rand(fuel_cost_sd_range[1]:fuel_cost_sd_range[2])
            
            # Randomly choose whether to add or subtract the deviation
            sign = rand([-1, 1])

            # Calculating the current fuel cost
            current_fuel_cost = fuel_cost + sign * deviation

            # Adding in the current fuel cost to the fuel cost array
            push!(fuel_cost_array, current_fuel_cost)

            # Increment the current hour of the day
            current_hour_of_day += 1
        elseif current_hour_of_day == 24
            # Adding in the current fuel cost to the fuel cost array
            push!(fuel_cost_array, current_fuel_cost)

            # Resetting the current hour of the day
            current_hour_of_day = 1
        else
            # Adding in the current fuel cost to the fuel cost array
            push!(fuel_cost_array, current_fuel_cost)

            # Increment the current hour of the day
            current_hour_of_day += 1
        end
    end

    return fuel_cost_array

end


"""
This function curates the operating status of the SMR based on the refueling time.
The refueling time is chosen to be when the prices are in the lower quantile of a scenario, 
and within the range of refueling times extracted from the paper: https://www.sciencedirect.com/science/article/pii/S0360544223015013
"""
function operating_status_array_calc(price_array, number_of_modules::Int, refuel_time_lower::Int, refuel_time_upper::Int)
    len = length(price_array)
    months_to_hours = 730.485
    refueling_time_min = round(Int, refuel_time_lower * months_to_hours)
    refueling_time_max = round(Int, refuel_time_upper * months_to_hours)
    refuel_time = 24

    # Calculate the number of refueling cycles each module will undergo over the 60-year period
    cycle_length = div(refueling_time_min + refueling_time_max, 2)  # Use integer division to avoid floating-point issues
    num_cycles = div(len, cycle_length)  # Use integer division to get the number of complete cycles

    # Initialize the operating status array with ones (all modules operating)
    operating_status = ones(Int, len)

    # Track the next available refueling slot for each module
    next_refuel_slot = zeros(Int, number_of_modules)

    # Loop through each cycle and assign refueling slots
    for cycle in 0:num_cycles-1
        start_t = cycle * cycle_length + 1
        end_t = min((cycle + 1) * cycle_length, len)

        # Sort the refueling slots by price to prioritize lower prices
        refuel_slots = sortperm(price_array[start_t:end_t])

        # Assign refueling slots to each module, ensuring no overlap
        for m in 1:number_of_modules
            refuel_time_slot = refuel_slots[m]
            refuel_start = start_t + refuel_time_slot - 1
            refuel_end = min(refuel_start + refuel_time - 1, len)

            # Update the operating status array
            operating_status[refuel_start:refuel_end] .= 0

            # Update the next refuel slot for this module
            next_refuel_slot[m] = refuel_end + 1
        end
    end

    return operating_status
end

"""
Function to store tests 
"""
function test_simulation_functions()
    ######### Testing the operating status array calculation #########

    # Creating an empty array to store price date of all scenarios
    scenario_price_data_all = []
            
    # Creating a temporary array to store the price data of each scenario
    scenario_price_data_temp = []

    # Loop curating the scenarios each have to run through
    for (index3, scenario) in enumerate(scenario_data_all)
        if index3 == 1 || index3 == 2 || index3 == 3
            push!(scenario_price_data_all, scenario)
            continue
        end
        
        # If the length of the temporary array is 8, then push it into the main array
        if length(scenario_price_data_temp) == 8
            push!(scenario_price_data_all, create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], 60))
            empty!(scenario_price_data_temp)
            push!(scenario_price_data_temp, scenario)
        else
            # Otherwise, add to the array and continue
            push!(scenario_price_data_temp, scenario)
            continue
        end
    end

    # println(length(scenario_price_data_all))
    # println(length(scenario_price_data_all[4]))

    # Test 1
    gen_payout, gen_output = smr_dispatch_iteration_three(scenario_price_data_all[4], 77.0, 4, 7.14, 0.0, 2024, 2024, 2024, 60)
    println(maximum(gen_payout))
    println(maximum(gen_output))
    println(sum(gen_payout))
    println(minimum(gen_output))
    println("")
    println("")

    # Test 2
    gen_payout1, gen_output1 = smr_dispatch_iteration_three(scenario_price_data_all[4], 77.0, 4, 7.14, 15.0, 2024, 2025, 2026, 60)

    println(maximum(gen_payout1))
    println(maximum(gen_output1))
    println(sum(gen_payout1))
    println(minimum(gen_output1))
    println("")
    println("")

    # Test 3
    gen_payout2, gen_output2 = smr_dispatch_iteration_three(scenario_price_data_all[4], 77.0, 4, 7.14, 15.0, 2028, 2028, 2029, 60)

    println(maximum(gen_payout2))
    println(maximum(gen_output2))
    println(sum(gen_payout2))
    println(minimum(gen_output2))
    println("")
    println("")



    # Example usage
    price_array = rand(8760 * 60)  # Simulate a 60-year hourly price array
    number_of_modules = 4
    refuel_time_lower = 15  # Min refueling time in months
    refuel_time_upper = 18  # Max refueling time in months

    operating_status = operating_status_array_calc(price_array, number_of_modules, refuel_time_lower, refuel_time_upper)
    # Count the number of zeros in the array
    num_zeros = count(x -> x == 0, operating_status)

    number_refueling_times = 60 * 8760 // round(Int, 16 * 730.485)

    println(number_refueling_times)
    println("")
    println(num_zeros)


    # Testing the investment calculation functions
    println(calculate_total_investment_with_cost_of_delay(0.1, 300.0, 2250000.0, 144365.0, 1, 5, 5))
    println(calculate_total_investment_with_cost_of_delay(0.1, 300.0, 2250000.0, 144365.0, 1, 5, 6))
end