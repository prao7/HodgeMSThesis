using DataFrames
using Statistics
using Distributions
using LineSearches
using Gurobi
using Optim
using Plots
using JuMP
using Roots
using LinearAlgebra
using StatsPlots
gr()

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
function smr_dispatch_iteration_three(price_data, module_size::Float64, number_of_modules::Int, fuel_cost::Float64, vom_cost::Float64, production_credit::Float64, 
    construction_end::Int, production_credit_duration::Int, refuel_time_upper::Int, refuel_time_lower::Int, lifetime::Int)
    # Assumption: Startup cost is based on moderate scenario from source: https://inldigitallibrary.inl.gov/sites/sti/sti/Sort_107010.pdf, pg. 82
    startup_cost_kW = 60
    refuel_time = 24*10 # Refuel time is 10 days as per the paper https://www.sciencedirect.com/science/article/pii/S0360544223015013

    # Assumption: Startup cost is for one module at a time, as only one module refueling at a time
    startup_cost_mW = (startup_cost_kW*module_size*1000)/refuel_time


    # Start year of all scenarios is 2040
    start_year = 2024
    
    # Calculating the year of the start and end of the construction and production credit
    construction_start_index = construction_end
    production_credit_start_index = construction_end
    production_credit_end_index = production_credit_start_index + production_credit_duration

    # Calculating the actual index of the start and end of the construction and production credit
    construction_start_index = construction_start_index*8760
    production_credit_start_index = production_credit_start_index*8760
    production_credit_end_index = production_credit_end_index*8760

    # Defining low power operation range # Changing LPO to 0.0 from 0.4*module_size*number_of_modules
    # Reference: https://www.sciencedirect.com/science/article/pii/S0360544223015013
    lpo_smr = 0.4*module_size*number_of_modules
    # Has removed 0.6*module_size*(number_of_modules-1)
    lpo_smr_refueling = 0.6*module_size*(number_of_modules-1)

    # Returned array with generator hourly payout
    generator_payout = []

    # Returned array with generator energy output
    generator_output = []

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
            if elec_hourly_price >= (fuel_cost + vom_cost)

                # If the production credit is valid add the production credit, otherwise don't add it
                if hour >= production_credit_start_index && hour <= production_credit_end_index
                    # If the price is higher than the fuel cost, the generator will dispatch to the energy market
                    if operating_status[hour] == 1
                        # If the SMR is not refueling, the operating status is 1. In this case, all modules are operational.
                        push!(generator_payout, (elec_hourly_price*module_size*number_of_modules + production_credit*module_size*number_of_modules - fuel_cost*module_size*number_of_modules - vom_cost*module_size*number_of_modules))
                        push!(generator_output, module_size*number_of_modules)
                    else
                        # If the SMR is refueling, the operating status is 0. In this case, there is a single module shut down.
                        push!(generator_payout, (elec_hourly_price*module_size*(number_of_modules - 1) + production_credit*module_size*(number_of_modules-1) - fuel_cost*module_size*(number_of_modules-1) - startup_cost_mW*(number_of_modules-1) - vom_cost*module_size*(number_of_modules-1)))
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
                        push!(generator_payout, (elec_hourly_price*module_size*(number_of_modules - 1) - fuel_cost*module_size*(number_of_modules-1) - startup_cost_mW*(number_of_modules-1) - vom_cost*module_size*(number_of_modules-1)))
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
                        push!(generator_payout, (elec_hourly_price*lpo_smr_refueling + production_credit*lpo_smr_refueling - fuel_cost*lpo_smr_refueling - startup_cost_mW*lpo_smr_refueling - vom_cost*lpo_smr_refueling))
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
                        push!(generator_payout, (elec_hourly_price*lpo_smr_refueling - fuel_cost*lpo_smr_refueling - startup_cost_mW*lpo_smr_refueling - vom_cost*lpo_smr_refueling))
                        push!(generator_output, lpo_smr_refueling)
                    end
                end
            end
        end
    end

    return generator_payout, generator_output
end


"""
The following code uses the SMR dispatch and just changes the startup cost to be
reflective of the Westinghouse AP1000 dispatch
It does an approximation of the operational dispatch of the paper below. We assume the 
dispatch does not change for the LR due to FPO.

Paper used: https://www.sciencedirect.com/science/article/pii/S0360544223015013
"""
function ap1000_dispatch_iteration_one(price_data, module_size::Int, number_of_modules::Int, fuel_cost::Float64, vom_cost::Float64, production_credit::Float64, 
    construction_end::Int, production_credit_duration::Int, refuel_time_upper::Int, refuel_time_lower::Int, lifetime::Int)
    # Assumption: Startup cost [$/kWh] is based on moderate scenario from source: https://inldigitallibrary.inl.gov/sites/sti/sti/Sort_107010.pdf, pg. 82
    startup_cost_kW = 33
    refuel_time = 24*17 # Refuel time is 17 days as per the paper https://aris.iaea.org/PDF/AP1000.pdf

    # Assumption: Startup cost is for one module at a time, as only one module refueling at a time
    startup_cost_mW = (startup_cost_kW*module_size*1000)/refuel_time


    # Start year of all scenarios is 2040
    start_year = 2024
    
    # Calculating the year of the start and end of the construction and production credit
    construction_start_index = construction_end
    production_credit_start_index = construction_end
    production_credit_end_index = production_credit_start_index + production_credit_duration

    # Calculating the actual index of the start and end of the construction and production credit
    construction_start_index = construction_start_index*8760
    production_credit_start_index = production_credit_start_index*8760
    production_credit_end_index = production_credit_end_index*8760

    # Defining low power operation range
    # Reference: https://snetp.eu/wp-content/uploads/2020/05/SNETP-Factsheet-7-Load-following-capabilities-of-nuclear-power-plants.pdf
    lpo_smr = 0.5*module_size*number_of_modules
    lpo_smr_refueling = 0.5*module_size*(number_of_modules-1)

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
    if construction_cost == 0.0
        return o_and_m_cost*capacity*number_of_modules
    end
    
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
Function version for learning rates calculation
"""
function calculate_total_investment_with_cost_of_delay_learning_rates(
    interest_rate::Float64, capacity::Float64, construction_cost::Float64, o_and_m_cost::Float64, 
    number_of_modules::Int, standard_construction_time::Int, lead_time::Int
)
    # Ensure construction_cost is positive to avoid log of a non-positive number
    adjusted_construction_cost = max(construction_cost, 1e-6)  # Small positive minimum

    # Calculate the total construction cost
    total_construction_cost = adjusted_construction_cost * capacity * number_of_modules

    # Calculate the total O&M cost
    total_o_and_m_cost = o_and_m_cost * capacity * number_of_modules
    
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

    return total_investment_cost
end


"""
This function takes a scenario as an input, and calculates the NPV lifetime of the scenario as a whole
"""
function npv_calc_scenario(payout_array, interest_rate::Float64, initial_investment::Float64, lifetime::Int)
    npv_tracker = Float64[]
    npv_payoff = Float64[]
    current_hour = 1
    
    for year in 1:lifetime
        # Calculate the yearly payout by summing up the hourly payouts
        yearly_payout = sum(payout_array[current_hour : current_hour + 8759])
        current_hour += 8760
        
        # Skip years with no payout (construction years)
        if yearly_payout == 0.0
            continue
        end
        
        # Calculate the discounted cash flow for the year
        discounted_payout = yearly_payout / (1 + interest_rate)^year
        push!(npv_payoff, discounted_payout)
        
        # Calculate the cumulative NPV
        push!(npv_tracker, sum(npv_payoff) - initial_investment)
    end
    
    # Determine the break-even year
    break_even = findfirst(x -> x >= 0, npv_tracker)
    break_even = break_even === nothing ? lifetime : break_even
    
    return npv_tracker, break_even, npv_payoff
end


"""
This function calculates the payout for a situation for when generators can bid into the capacity market
in addition to the energy market. This function assumes that the capacity market rate is normalized to 
\$/kW-month.
"""
function capacity_market_analysis(capacity_market_rate::Float64, payout_run::Vector{Any}, number_of_modules::Int, module_size)
    # Do not proceed if the capacity market is not being explored
    if capacity_market_rate <= 0.0
        return payout_run
    end

    # Find the first non-zero element in payout_run
    first_nonzero_index = findfirst(!iszero, payout_run)

    # If all elements are zero, return the original payout_run
    if first_nonzero_index === nothing
        return payout_run
    end

    # Note: The capacity market rate units can be assumed as $/kW-month

    # Start processing from the first non-zero element
    for i in first_nonzero_index:length(payout_run)
        if (i - first_nonzero_index + 1) % 8760 == 0
            # If the current hour is the start of the year, then calculate the capacity market payout
            payout_run[i] += capacity_market_rate * module_size * number_of_modules * 12 * 1000  # Capacity Market rate is in $/kW-month, so need to convert to MW
        end
    end

    return payout_run
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
    calculate_irr(hourly_payout_data::Vector{Float64}, initial_investment::Float64) -> Float64

Calculate the internal rate of return (IRR) given hourly payout data and an initial investment cost.

# Arguments
- `hourly_payout_data::Vector{Float64}`: A vector of hourly payouts.
- `initial_investment::Float64`: The initial investment cost.

# Returns
- `Float64`: The internal rate of return (IRR).
"""
function calculate_irr(hourly_payout_data::Vector{Any}, initial_investment::Float64) :: Float64
    # Find the first non-zero element in hourly_payout_data
    first_nonzero_index = findfirst(!iszero, hourly_payout_data)

    # Slice the hourly_payout_data from the first non-zero index
    trimmed_hourly_payout_data = hourly_payout_data[first_nonzero_index:end]

    # Determine the lifetime from the length of the trimmed payout data
    total_hours = length(trimmed_hourly_payout_data)
    lifetime = total_hours ÷ 8760  # Number of years

    # Aggregate hourly data to annual data
    annual_payouts = [sum(trimmed_hourly_payout_data[(8760 * (i - 1) + 1):min(8760 * i, total_hours)]) for i in 1:lifetime]

    # Add the initial investment as a negative payout at year 0
    annual_payouts = [-initial_investment; annual_payouts]

    # Define the NPV function
    function npv(irr)
        sum([payout / (1 + irr)^(year - 1) for (year, payout) in enumerate(annual_payouts)])
    end

    # Try different initial guesses or methods
    irr_value = try
        find_zero(irr -> npv(irr), 0.1, Order1(), verbose=false)
    catch e
        #println("First attempt failed: $e")
        # More granular search if the first attempt fails
        #println("Starting granular search...")

        guesses = [0.01, 0.02, 0.05, 0.08, 0.1, 0.15]
        orders = [Order0(), Order1(), Order2()]

        for guess in guesses
            for order in orders
                try
                    irr_value = find_zero(irr -> npv(irr), guess, order, verbose=false)
                    return irr_value
                catch e
                    #println("Attempt with guess $guess and order $order failed: $e")
                end
            end
        end

        println("Granular search failed. Returning default IRR of 0.0")
        return 0.0
    end

    return irr_value
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

    for (index, value) in enumerate(smr_cost_vals)
        if index >= 20
            result = calculate_total_investment_with_cost_of_delay(0.1, value[1], value[3], value[5], Int(value[7]), Int(ceil(value[8]/12)), Int(ceil(value[8]/12)))
            println(result)
        else
            result = calculate_total_investment_with_cost_of_delay(0.1, value[1], value[3], value[5], Int(value[6]), Int(ceil(value[7]/12)), Int(ceil(value[8]/12)))
            println(result)
        end
    end


    # Generate random hourly payout data for 60 years
    hourly_payout_data = rand(Float64, 8760 * 60)  # Random hourly payout data for 60 years as an array
    initial_investment = 1000000.0  # Example initial investment cost

    irr = calculate_irr(hourly_payout_data, initial_investment)
    println("The calculated IRR is: ", irr)

    # # Simple test data
    # hourly_payout_data = repeat([100.0], 8760 * 60)  # 60 years of hourly payouts of 100
    # initial_investment = 500000.0

    # irr_value = calculate_irr(hourly_payout_data, initial_investment)
    # println("The calculated IRR for test data is: ", irr_value)

    # # Aggregate hourly data to annual data for plotting
    # annual_payouts = [sum(hourly_payout_data[(8760 * (i - 1) + 1):min(8760 * i, length(hourly_payout_data))]) for i in 1:(length(hourly_payout_data) ÷ 8760)]

    # # Add the initial investment as a negative payout at year 0 for plotting
    # annual_payouts_with_investment = [-initial_investment; annual_payouts]

    # Simple test data for multiple scenarios
    num_scenarios = 3
    num_years = 60
    hourly_payout_data = [repeat([100.0 + i], 8760 * num_years) for i in 1:num_scenarios]
    hourly_payout_data = hcat(hourly_payout_data...)'  # Convert to a 2D array

    initial_investment = 500000.0

    irr_values = calculate_irr(hourly_payout_data, initial_investment)
    println("The calculated IRR values for test data are: ", irr_values)

    payout_test = [zeros(8760*60) for _ in 1:12]

    payout_test = capacity_market_analysis(1.0, payout_test, 4, 77)
    npv_calc_scenario(payout_test[2], 0.1, 1000000.0, 60)




    scenario_prices = all_scenario_prices()

    println("Length of all_cases: ", length(scenario_prices))

    println("Length of scenario ", scenario_prices[1]["name"], " prices: ", length(scenario_prices[1]["scenario"]))
end

# TODO: Test this method to ensure it works as expected
function smr_dispatch_iteration_three_optimized(price_data::Vector{Float64}, module_size::Float64, number_of_modules::Int, fuel_cost::Float64, vom_cost::Float64, production_credit::Float64, 
    construction_end::Int, production_credit_duration::Int, refuel_time_upper::Int, refuel_time_lower::Int, lifetime::Int)

    startup_cost_kW = 60
    refuel_time = 24 * 10
    startup_cost_mW = (startup_cost_kW * module_size * 1000) / refuel_time

    construction_start_index = construction_end * 8760
    production_credit_start_index = construction_start_index
    production_credit_end_index = production_credit_start_index + production_credit_duration * 8760

    lpo_smr = 0.4 * module_size * number_of_modules
    lpo_smr_refueling = 0.6 * module_size * (number_of_modules - 1)

    generator_payout = Vector{Float64}(undef, length(price_data))
    generator_output = Vector{Float64}(undef, length(price_data))

    operating_status = operating_status_array_calc_optimized(price_data, number_of_modules, refuel_time_upper, refuel_time_lower)

    function compute_dispatch(elec_hourly_price, production_credit_active, refueling)
        modules = refueling ? (number_of_modules - 1) : number_of_modules
        lpo = refueling ? lpo_smr_refueling : lpo_smr
        full_output = module_size * modules
        full_payout = elec_hourly_price * full_output - fuel_cost * full_output - vom_cost * full_output
        if production_credit_active
            full_payout += production_credit * full_output
        end
        lpo_payout = elec_hourly_price * lpo - fuel_cost * lpo - vom_cost * lpo
        if production_credit_active
            lpo_payout += production_credit * lpo
        end
        if refueling
            full_payout -= startup_cost_mW * modules
            lpo_payout -= startup_cost_mW * lpo
        end
        return full_output, full_payout, lpo_payout
    end

    for hour in 1:length(price_data)
        if hour < construction_start_index
            generator_payout[hour] = 0
            generator_output[hour] = 0
        else
            elec_hourly_price = price_data[hour]
            production_credit_active = hour >= production_credit_start_index && hour <= production_credit_end_index
            refueling = operating_status[hour] == 0

            if elec_hourly_price >= fuel_cost
                output, payout, _ = compute_dispatch(elec_hourly_price, production_credit_active, refueling)
                generator_payout[hour] = payout
                generator_output[hour] = output
            else
                _, _, lpo_payout = compute_dispatch(elec_hourly_price, production_credit_active, refueling)
                generator_payout[hour] = lpo_payout
                generator_output[hour] = refueling ? lpo_smr_refueling : lpo_smr
            end
        end
    end

    return generator_payout, generator_output
end

#TODO: Test this method to ensure it works as expected
function operating_status_array_calc_optimized(price_array::Vector{Float64}, number_of_modules::Int, refuel_time_lower::Int, refuel_time_upper::Int)
    len = length(price_array)
    months_to_hours = 730.485
    refueling_time_min = round(Int, refuel_time_lower * months_to_hours)
    refueling_time_max = round(Int, refuel_time_upper * months_to_hours)
    refuel_time = 24

    # Average cycle length between refuel time min and max
    cycle_length = (refueling_time_min + refueling_time_max) ÷ 2
    num_cycles = len ÷ cycle_length

    # Initialize the operating status array with ones (all modules operating)
    operating_status = ones(Int, len)

    # Allocate memory for refuel_slots outside the loop
    refuel_slots = Vector{Int}(undef, number_of_modules)

    # Loop through each cycle and assign refueling slots
    for cycle in 0:num_cycles-1
        start_t = cycle * cycle_length + 1
        end_t = min((cycle + 1) * cycle_length, len)

        # Sort the refueling slots by price to prioritize lower prices
        sortperm!(refuel_slots, price_array[start_t:end_t])

        # Assign refueling slots to each module, ensuring no overlap
        for m in 1:number_of_modules
            refuel_start = start_t + refuel_slots[m] - 1
            refuel_end = min(refuel_start + refuel_time - 1, len)

            # Update the operating status array
            operating_status[refuel_start:refuel_end] .= 0
        end
    end

    return operating_status
end


function calculate_total_investment_with_cost_of_delay_plotting(interest_rate::Float64, capacity::Float64, construction_cost::Float64, o_and_m_cost::Float64, 
    number_of_modules::Int, standard_construction_time::Int, lead_time::Int)

    if construction_cost == 0.0
        return o_and_m_cost * capacity * number_of_modules
    end
    
    # Calculate the total construction cost
    total_construction_cost = construction_cost * capacity * number_of_modules

    # Calculate the total O&M cost
    total_o_and_m_cost = o_and_m_cost * capacity * number_of_modules
    
    # Log-normal distribution parameters
    mu = log(total_construction_cost / standard_construction_time)  # Mean of the log-normal distribution
    sigma = 0.5  # Standard deviation of the log-normal distribution

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

    # Return yearly construction costs along with other values
    return construction_cost_standard, construction_cost_lead, SOCC, TOCC, CoD, total_construction_cost
end


function plot_effect_of_delay(interest_rate::Float64, capacity::Float64, construction_cost::Float64, o_and_m_cost::Float64, 
                              number_of_modules::Int, standard_construction_time::Int, max_lead_time::Int, output_dir::String)
    
    lead_times = collect(standard_construction_time:max_lead_time)
    total_investment_costs = []
    cod_values = []  # Cost of delay for visualization

    for lead_time in lead_times
        _, _, CoD, total_investment_cost = calculate_total_investment_with_cost_of_delay_plotting(interest_rate, capacity, construction_cost, o_and_m_cost, 
                                                                                        number_of_modules, standard_construction_time, lead_time)
        push!(total_investment_costs, total_investment_cost)
        push!(cod_values, CoD)
    end

    # Create the plot with two lines: Total Investment Cost and Cost of Delay
    p = plot(lead_times, total_investment_costs, label="Total Investment Cost", xlabel="Lead Time (Years)", ylabel="Cost [Million \$]", 
             title="Effect of Lead Time on Total Investment Cost", legend=:topright, lw=2)
    
    plot!(lead_times, cod_values, label="Cost of Delay (CoD)", lw=2, linestyle=:dash, color=:red)

    # Ensure output directory path ends with a "/"
    if !endswith(output_dir, "/")
        output_dir *= "/"
    end

    # Define output file name
    output_file = output_dir * "effect_of_delay_plot.png"
    
    # Save the plot to the specified directory
    savefig(p, output_file)
    
    println("Plot saved to $output_file")

    return nothing
end



function plot_construction_cost_distribution(interest_rate::Float64, capacity::Float64, construction_cost::Float64, o_and_m_cost::Float64, 
                                             number_of_modules::Int, standard_construction_time::Int, lead_time::Int, output_dir::String,
                                             smr_name::String)
    
    # Get the construction cost distribution for both standard and lead time cases
    construction_cost_standard, construction_cost_lead, _, _, _, _ = calculate_total_investment_with_cost_of_delay_plotting(interest_rate, capacity, construction_cost, o_and_m_cost, 
                                                                                                                            number_of_modules, standard_construction_time, lead_time)

    # Create a plot showing the cost distributions over time
    p = bar(1:lead_time, construction_cost_lead, label="With Delay (Lead Time)", xlabel="Year", ylabel="Construction Cost [\$]", 
            title="Construction Cost Distribution for $smr_name", bar_width=0.5, color=:blue)
    
    # Overlay the standard construction cost as a line
    plot!(1:standard_construction_time, construction_cost_standard, label="Without Delay (Standard)", lw=2, color=:red, linestyle=:solid)
    
    # Ensure output directory path ends with a "/"
    if !endswith(output_dir, "/")
        output_dir *= "/"
    end

    # Define output file name
    output_file = output_dir * "$(smr_name)_construction_cost_distribution.png"
    
    # Save the plot to the specified directory
    savefig(p, output_file)
    
    println("Plot saved to $output_file")

    return nothing
end


function breakeven_objective(learning_rates, smr_prototype::String, production_credit, capacity_market_rate, breakeven_standard, is_favorable::Bool, itc_case::String="")

    # First, get the index of the prototype based on the smr_name
    smr_index = findfirst(x -> x == smr_prototype, smr_names)

    # Setting the cost values for the prototype
    cost_array = smr_cost_vals[smr_index]

    production_duration = 10

    if smr_index < 20
        ## If it's the SMRs that are not in the ATB
                
        # Module size
        module_size = cost_array[1]
    
        # Number of modules
        numberof_modules = Int(cost_array[6])
    
        # Fuel cost
        fuel_cost = cost_array[4]
    
        # Lifetime of the SMR
        smr_lifetime = Int64(cost_array[2])
    
        # Construction cost of the SMR
        construction_cost = cost_array[3]
    
        # O&M cost of the SMR
        om_cost = cost_array[5]

        # VOM Cost is zero is not ATB as the O&M cost is assumed to be included in fom
        vom_cost = 0.0
    
        # Construction duration of the SMR
        construction_duration = cost_array[7]
    
        # Refueling min time
        refueling_min_time = Int64(cost_array[8])
    
        # Refueling max time
        refueling_max_time = Int64(cost_array[9])

        # Scenario
        scenario = cost_array[10]

        construction_interest_rate = 0.1

        production_duration = 10

        interest_rate_wacc = 0.04
    else
        ## If it's the SMRs that are in the ATB
    
        # Module size
        module_size = cost_array[1]
    
        # Number of modules
        numberof_modules = Int(cost_array[7])
    
        # Fuel cost
        fuel_cost = cost_array[4]
    
        # Lifetime of the SMR
        smr_lifetime = Int64(cost_array[2])
    
        # Construction cost of the SMR
        construction_cost = cost_array[3]
    
        # Fixed O&M cost of the SMR
        fom_cost = cost_array[5]

        # O&M cost of the SMR
        om_cost = fom_cost*smr_lifetime
    
        # Variable O&M cost of the SMR
        vom_cost = cost_array[6]
                
        # Construction duration of the SMR
        construction_duration = cost_array[8]
    
        # Refueling min time
        refueling_min_time = Int64(cost_array[9])
    
        # Refueling max time
        refueling_max_time = Int64(cost_array[10])

        # Scenario
        scenario = cost_array[11]

        construction_interest_rate = 0.1

        production_duration = 10

        interest_rate_wacc = 0.04
    end

    construction_start = 2024
    construction_delay = 0
    start_reactor = Int(ceil(((construction_start - 2024)*12 + construction_duration + (construction_delay*12))/12))

    ### Curating the scenarios to run the SMRs through ###
    if is_favorable
        # Favorable scenarios are Texas 2022, High NG ’23, High RE Cost, Mid Case 95 ’23, Mid Case 100 ‘23
        scenarios_to_run = []

        # Texas 2022
        texas_2022_scen = fifteen_minutes_to_hourly(texasdf,"Settlement Point Price", 4)
        push!(scenarios_to_run, create_scenario_interpolated_array_cambium2022(texas_2022_scen, texas_2022_scen, texas_2022_scen, texas_2022_scen, texas_2022_scen, texas_2022_scen, texas_2022_scen, texas_2022_scen, (smr_lifetime + start_reactor)))

        # High NG '23
        push!(scenarios_to_run, create_scenario_interpolated_array(array_from_dataframe(c23_highNGPrices2025df, column_name_cambium),
        array_from_dataframe(c23_highNGPrices2030df, column_name_cambium),
        array_from_dataframe(c23_highNGPrices2035df, column_name_cambium),
        array_from_dataframe(c23_highNGPrices2040df, column_name_cambium),
        array_from_dataframe(c23_highNGPrices2045df, column_name_cambium),
        array_from_dataframe(c23_highNGPrices2050df, column_name_cambium),
        (smr_lifetime + start_reactor)))

        # High RE Cost
        push!(scenarios_to_run, create_scenario_interpolated_array(array_from_dataframe(c23_highRenewableCost2025df, column_name_cambium),
        array_from_dataframe(c23_highRenewableCost2030df, column_name_cambium),
        array_from_dataframe(c23_highRenewableCost2035df, column_name_cambium),
        array_from_dataframe(c23_highRenewableCost2040df, column_name_cambium),
        array_from_dataframe(c23_highRenewableCost2045df, column_name_cambium),
        array_from_dataframe(c23_highRenewableCost2050df, column_name_cambium),
        (smr_lifetime + start_reactor)))

        # Mid Case 95 '23
        push!(scenarios_to_run, create_scenario_interpolated_array(array_from_dataframe(c23_midcase952025df, column_name_cambium),
        array_from_dataframe(c23_midcase952030df, column_name_cambium),
        array_from_dataframe(c23_midcase952035df, column_name_cambium),
        array_from_dataframe(c23_midcase952040df, column_name_cambium),
        array_from_dataframe(c23_midcase952045df, column_name_cambium),
        array_from_dataframe(c23_midcase952050df, column_name_cambium),
        (smr_lifetime + start_reactor)))

        # Mid Case 100 '23
        push!(scenarios_to_run, create_scenario_interpolated_array(array_from_dataframe(c23_midcase1002025df, column_name_cambium),
        array_from_dataframe(c23_midcase1002030df, column_name_cambium),
        array_from_dataframe(c23_midcase1002035df, column_name_cambium),
        array_from_dataframe(c23_midcase1002040df, column_name_cambium),
        array_from_dataframe(c23_midcase1002045df, column_name_cambium),
        array_from_dataframe(c23_midcase1002050df, column_name_cambium),
        (smr_lifetime + start_reactor)))

    else
        # Favorable scenarios are Low RE Cost, Mid Case, Low RE Cost TC Expire, High Demand Growth
        scenarios_to_run = []

        # Low RE Cost
        push!(scenarios_to_run, create_scenario_interpolated_array(array_from_dataframe(c23_lowRECost2025df, column_name_cambium),
        array_from_dataframe(c23_lowRECost2030df, column_name_cambium),
        array_from_dataframe(c23_lowRECost2035df, column_name_cambium),
        array_from_dataframe(c23_lowRECost2040df, column_name_cambium),
        array_from_dataframe(c23_lowRECost2045df, column_name_cambium),
        array_from_dataframe(c23_lowRECost2050df, column_name_cambium),
        (smr_lifetime + start_reactor)))

        # Mid Case
        push!(scenarios_to_run, create_scenario_interpolated_array(array_from_dataframe(c23_midcase2025df, column_name_cambium),
        array_from_dataframe(c23_midcase2030df, column_name_cambium),
        array_from_dataframe(c23_midcase2035df, column_name_cambium),
        array_from_dataframe(c23_midcase2040df, column_name_cambium),
        array_from_dataframe(c23_midcase2045df, column_name_cambium),
        array_from_dataframe(c23_midcase2050df, column_name_cambium),
        (smr_lifetime + start_reactor)))

        # Low RE Cost TC Expire
        push!(scenarios_to_run, create_scenario_interpolated_array_cambium2022(array_from_dataframe(lowRECostTCE_2024df, column_name_cambium),
        array_from_dataframe(lowRECostTCE_2026df, column_name_cambium),
        array_from_dataframe(lowRECostTCE_2028df, column_name_cambium),
        array_from_dataframe(lowRECostTCE_2030df, column_name_cambium),
        array_from_dataframe(lowRECostTCE_2035df, column_name_cambium),
        array_from_dataframe(lowRECostTCE_2040df, column_name_cambium),
        array_from_dataframe(lowRECostTCE_2045df, column_name_cambium),
        array_from_dataframe(lowRECostTCE_2050df, column_name_cambium),
        (smr_lifetime + start_reactor)))

        # High Demand Growth
        push!(scenarios_to_run, create_scenario_interpolated_array(array_from_dataframe(highDemandGrowth_2025df, column_name_cambium),
        array_from_dataframe(highDemandGrowth_2030df, column_name_cambium),
        array_from_dataframe(highDemandGrowth_2035df, column_name_cambium),
        array_from_dataframe(highDemandGrowth_2040df, column_name_cambium),
        array_from_dataframe(highDemandGrowth_2045df, column_name_cambium),
        array_from_dataframe(highDemandGrowth_2050df, column_name_cambium),
        (smr_lifetime + start_reactor)))

    end

    if itc_case != ""
        if scenario == "Advanced"
            # Adjusting the construction costs
            construction_cost = construction_cost * itc_cost_reduction[itc_cost_reduction.Category .== itc_case, :Advanced][1]
        elseif scenario == "Moderate"
            # Adjusting the construction costs
            construction_cost = construction_cost * itc_cost_reduction[itc_cost_reduction.Category .== itc_case, :Moderate][1]
        elseif scenario == "Conservative"
            # Adjusting the construction costs
            construction_cost = construction_cost * itc_cost_reduction[itc_cost_reduction.Category .== itc_case, :Conservative][1]
        end
    end
    occ_learning_rate = learning_rates[1]
    om_learning_rate = learning_rates[2]
    fuel_learning_rate = learning_rates[3]

    ### Use updated learning rates in the existing calculations
    construction_cost_ll = max(construction_cost * (1 - occ_learning_rate), 1e-8)
    om_cost_ll = max(om_cost * (1 - om_learning_rate), 1e-8)
    vom_cost_ll = max(vom_cost * (1 - om_learning_rate), 1e-8)
    fuel_cost_ll = max(fuel_cost * (1 - fuel_learning_rate), 1e-8)


    max_breakeven = 60.0  # Start with a large breakeven and reduce iteratively

    breakevenvals_array = []

    # Iterate over all the scenarios and calculate breakeven time
    for (_, scenario_array) in enumerate(scenarios_to_run)
        payout_run, _ = smr_dispatch_iteration_three(scenario_array, Float64(module_size), numberof_modules, fuel_cost_ll, vom_cost_ll, production_credit, start_reactor, production_duration, refueling_max_time, refueling_min_time, smr_lifetime)
        
        payout_run = capacity_market_analysis(capacity_market_rate, payout_run, numberof_modules, module_size)
        
        # Calculate breakeven
        _, break_even_run, _ = npv_calc_scenario(payout_run, interest_rate_wacc, calculate_total_investment_with_cost_of_delay_learning_rates(construction_interest_rate, Float64(module_size), Float64(construction_cost_ll), Float64(om_cost_ll), numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))), (smr_lifetime + start_reactor))
        # Track breakeven for all scenarios
        push!(breakevenvals_array, break_even_run)
    end

    # Calculate maximum breakeven across scenarios
    max_breakeven = maximum(breakevenvals_array)

    println("Construction Learning Rate: ", occ_learning_rate)
    println("O&M Learning Rate: ", om_learning_rate)
    println("Fuel Learning Rate: ", fuel_learning_rate)
    println("Max Breakeven: ", max_breakeven)
    println("")
    # The objective is to minimize learning rates, while ensuring the breakeven is below the standard.
    return (max_breakeven - breakeven_standard)^2
end

"""
Gradient-based optimization of learning rates for SMR breakeven analysis
"""
function optimize_learning_rates_gradient(smr_prototype::String, production_credit, capacity_market_rate, breakeven_standard, is_favorable::Bool=true, itc_case::String="", initial_learning_rates=[0.9302115, 0.9002115, 0.9105115])
    # Set up tighter optimization options to avoid boundary drift
    options = Optim.Options(f_tol = 1e-8, g_tol = 1e-8, iterations = 100000, f_calls_limit = 100000)

    # Set up bounds for the optimization
    lower_bounds = [0.0, 0.0, 0.0]
    upper_bounds = [1.0, 1.0, 1.0]

    # Run the optimization using Nelder-Mead within Fminbox for constrained optimization
    result = optimize(
        learning_rates -> breakeven_objective(learning_rates, smr_prototype, production_credit, capacity_market_rate, breakeven_standard, is_favorable, itc_case), 
        lower_bounds, upper_bounds, initial_learning_rates, Fminbox(NelderMead()), options
    )

    # Extract and print the optimal learning rates
    optimal_learning_rates = result.minimizer
    println("Optimized Learning Rates:")
    println("OCC Learning Rate: ", optimal_learning_rates[1])
    println("O&M Learning Rate: ", optimal_learning_rates[2])
    println("Fuel Learning Rate: ", optimal_learning_rates[3])

    return optimal_learning_rates
end





# Exponential temperature schedule for simulated annealing
function exp_temp_schedule(iter, initial_temp, final_temp, max_iter)
    # Adjust the schedule to cool slower, if needed
    return initial_temp * (final_temp / initial_temp)^(iter / (max_iter * 1.2))
end


# Wrapper for the objective function to respect bounds
function wrapped_breakeven_objective(
    learning_rates::Vector{Float64}, smr_prototype::String,
    production_credit::Float64, capacity_market_rate::Float64,
    breakeven_standard::Float64, is_favorable::Bool, itc_case::String
)
    # Enforce bounds: return `Inf` if any learning rate is out of bounds [0, 1]
    if any(learning_rate -> learning_rate < 0.0 || learning_rate > 1.0, learning_rates)
        return Inf  # Penalize out-of-bounds solutions
    end
    return breakeven_objective(
        learning_rates, smr_prototype, production_credit,
        capacity_market_rate, breakeven_standard, is_favorable, itc_case
    )
end

function optimize_learning_rates(
    smr_prototype::String, production_credit::Float64,
    capacity_market_rate::Float64, breakeven_standard::Float64,
    is_favorable::Bool = true, itc_case::String = "", 
    initial_learning_rates = [0.5, 0.5, 0.5]
)
    # Define bounds for each learning rate dimension
    lower_bounds = [0.0, 0.0, 0.0]
    upper_bounds = [1.0, 1.0, 1.0]

    # Define the objective function with bounds handling
    objective_function = x -> wrapped_breakeven_objective(
        x, smr_prototype, production_credit, capacity_market_rate,
        breakeven_standard, is_favorable, itc_case
    )

    # Set up the options for SAMIN (Simulated Annealing Minimizer with bounds)
    options = Optim.Options(f_tol=1e-5, iterations=10000, store_trace=true)


    # Run the Simulated Annealing optimization with SAMIN for bounds
    result = optimize(
        objective_function,
        lower_bounds, upper_bounds,
        initial_learning_rates,
        SAMIN(),
        options
    )

    # Extract and print the optimal learning rates
    optimal_learning_rates = Optim.minimizer(result)
    println("Optimized Learning Rates (Simulated Annealing with SAMIN in Optim.jl):")
    println("OCC Learning Rate: ", optimal_learning_rates[1])
    println("O&M Learning Rate: ", optimal_learning_rates[2])
    println("Fuel Learning Rate: ", optimal_learning_rates[3])

    return optimal_learning_rates
end


function optimize_learning_rates_manual(smr_prototype::String, production_credit, capacity_market_rate, breakeven_standard, is_favorable::Bool=true, itc_case::String="")
    step_size = 0.001
    min_breakeven_difference = 1e-2  # Tolerance for breakeven difference

    # Initial learning rates
    best_learning_rates = [0.0, 0.0, 0.0]
    best_breakeven = 60.0  # Start with an arbitrarily high breakeven
    all_learning_rates = []

    # Iterate over possible learning rates with step size
    for occ_lr in 0.0:step_size:1.0
        for om_lr in 0.0:step_size:1.0
            for fuel_lr in 0.0:step_size:1.0
                current_learning_rates = [occ_lr, om_lr, fuel_lr]
                max_breakeven = breakeven_objective(current_learning_rates, smr_prototype, production_credit, capacity_market_rate, breakeven_standard, is_favorable, itc_case)

                # If the current breakeven is closer to the standard, update the best result
                if abs(max_breakeven - breakeven_standard) < min_breakeven_difference
                    best_learning_rates = current_learning_rates
                    best_breakeven = max_breakeven
                    push!(all_learning_rates, current_learning_rates)
                end
            end
        end
    end

    println("Optimized Learning Rates:")
    println("Learning Rate: ", all_learning_rates)
    println("Best Breakeven: ", best_breakeven)

    return best_learning_rates, all_learning_rates
end

"""
This function finds the first week with mixed prices and ramping in two dispatch dataframes.
"""
function find_first_common_week_with_mixed_prices_and_ramping(
    dispatch_df1::DataFrame, dispatch_df2::DataFrame, 
    payout_df1::DataFrame, payout_df2::DataFrame, 
    prices1::Vector{Float64}, prices2::Vector{Float64}, 
    module_size::Float64, number_of_modules::Int, 
    column_name::String)
    
    # Function to classify the ramping for the first dataframe
    function classify_ramping_df1(module_size, number_of_modules)
        lpo_smr = 0.4 * module_size * number_of_modules
        lpo_smr_refueling = 0.6 * module_size * (number_of_modules - 1)
        return lpo_smr, lpo_smr_refueling
    end

    # Function to classify the ramping for the second dataframe
    function classify_ramping_df2(module_size, number_of_modules)
        lpo_smr = 0.0
        lpo_smr_refueling = module_size * number_of_modules
        return lpo_smr, lpo_smr_refueling
    end

    # Helper function to find a common week with mixed prices and ramping in both dataframes
    function find_common_mixed_prices_and_ramping(dispatch_df1, dispatch_df2, prices1, prices2, module_size, number_of_modules, column_name)
        column_data1 = dispatch_df1[!, column_name]  # Pull out the relevant column from the first dataframe
        column_data2 = dispatch_df2[!, column_name]  # Pull out the relevant column from the second dataframe
        
        # Define the ramping criteria for both dataframes
        lpo_smr_1, lpo_smr_refueling_1 = classify_ramping_df1(module_size, number_of_modules)
        lpo_smr_2, lpo_smr_refueling_2 = classify_ramping_df2(module_size, number_of_modules)
        
        # Ensure the loop doesn't go beyond the length of the data
        max_index = min(length(column_data1), length(column_data2), length(prices1), length(prices2)) - 167
        
        # Loop through 7-day periods (7 * 24 = 168 hours)
        for i in 1:168:max_index
            current_period_1 = column_data1[i:i+167]
            current_period_2 = column_data2[i:i+167]
            current_prices_1 = prices1[i:i+167]
            current_prices_2 = prices2[i:i+167]
        
            # Check for both negative and positive prices in both dataframes
            has_negative_prices_1 = any(current_prices_1 .< 0)
            has_positive_prices_1 = any(current_prices_1 .> 0)
            has_negative_prices_2 = any(current_prices_2 .< 0)
            has_positive_prices_2 = any(current_prices_2 .> 0)
        
            # Check if both dataframes have mixed prices
            mixed_prices_1 = has_negative_prices_1 && has_positive_prices_1
            mixed_prices_2 = has_negative_prices_2 && has_positive_prices_2
        
            if mixed_prices_1 && mixed_prices_2
                return (i, i+167)  # Return the start and end indices for the 7-day period
            end
        end
        
        return nothing  # Return nothing if no such period is found
    end

    # Find the first common week with mixed prices and ramping for both dispatch dataframes
    week_indices = find_common_mixed_prices_and_ramping(dispatch_df1, dispatch_df2, prices1, prices2, module_size, number_of_modules, column_name)

    # If no period is found, return empty DataFrames and empty price vectors
    if isnothing(week_indices)
        return DataFrame(), DataFrame(), DataFrame(), DataFrame(), [], []
    end

    # Retrieve the actual 7-day data (168 hours) for the significant periods in both dataframes
    start_index, end_index = week_indices
    significant_dispatch_df1 = dispatch_df1[start_index:end_index, :]
    significant_dispatch_df2 = dispatch_df2[start_index:end_index, :]
    
    # Retrieve corresponding payout data for the significant periods
    significant_payout_df1 = payout_df1[start_index:end_index, :]
    significant_payout_df2 = payout_df2[start_index:end_index, :]

    # Retrieve the corresponding price data for the significant periods
    significant_prices1 = prices1[start_index:end_index]
    significant_prices2 = prices2[start_index:end_index]

    # Return the significant dispatch, payout periods, and corresponding prices
    return significant_dispatch_df1, significant_dispatch_df2, significant_payout_df1, significant_payout_df2, significant_prices1, significant_prices2
end


"""
Building a function to calculate the heatmap data and output to a directory
"""
function calculate_smr_heatmap_data(output_dir::String)
    for (index, cost_array) in enumerate(smr_cost_vals)
        # X Values is an array from 0 to 100
        x_values = collect(0.0:1.0:100.0)

        # Y Values is an array from 0 to 100
        y_values = collect(0.0:1.0:100.0)

        # Creating an empty matrix to hold heatmap data
        heatmap_data = Matrix{Float64}(undef, length(x_values), length(y_values))


        ### Creating the variables for the SMR dispatch ###
        if index < 20
            ## If it's the SMRs that are not in the ATB
            # Module size
            module_size = cost_array[1]
        
            # Number of modules
            numberof_modules = Int(cost_array[6])
        
            # Fuel cost
            fuel_cost = cost_array[4]
        
            # Lifetime of the SMR
            smr_lifetime = Int64(cost_array[2])
        
            # Construction cost of the SMR
            construction_cost = cost_array[3]
        
            # O&M cost of the SMR
            om_cost = cost_array[5]

            # VOM Cost is zero is not ATB as the O&M cost is assumed to be included in fom
            vom_cost = 0.0
        
            # Construction duration of the SMR
            construction_duration = cost_array[7]

            # Refueling min time
            refueling_min_time = Int64(cost_array[8])

            # Refueling max time
            refueling_max_time = Int64(cost_array[9])

            # Scenario
            scenario = cost_array[10]
        else
            ## If it's the SMRs that are in the ATB
        
            # Module size
            module_size = cost_array[1]
        
            # Number of modules
            numberof_modules = Int(cost_array[7])
        
            # Fuel cost
            fuel_cost = cost_array[4]
        
            # Lifetime of the SMR
            smr_lifetime = Int64(cost_array[2])
        
            # Construction cost of the SMR
            construction_cost = cost_array[3]
        
            # Fixed O&M cost of the SMR
            fom_cost = cost_array[5]

            # O&M cost of the SMR
            om_cost = fom_cost*smr_lifetime
        
            # Variable O&M cost of the SMR
            vom_cost = cost_array[6]
                    
            # Construction duration of the SMR
            construction_duration = cost_array[8]
        
            # Refueling min time
            refueling_min_time = Int64(cost_array[9])
        
            # Refueling max time
            refueling_max_time = Int64(cost_array[10])

            # Scenario
            scenario = cost_array[11]
        end

        # Calculating the lead time
        start_reactor = Int(ceil(construction_duration/12))
        interest_rate_wacc = 0.04
        construction_interest_rate = 0.1

        max_energy_price = 100.0
        max_capacity_price = 100.0
        production_credit = 0.0
        production_duration = 10
    
        for energy_market_price in 0.0:1.0:max_energy_price
            for capacity_market_price in 0.0:1.0:max_capacity_price
                # Creating an energy market scenario on a flat price
                energy_market_scenario = create_constant_price_scenario(energy_market_price, (smr_lifetime + start_reactor))

                # Running the dispatch
                payout_run, _ = smr_dispatch_iteration_three(energy_market_scenario, Float64(module_size), numberof_modules, fuel_cost, vom_cost, production_credit, start_reactor, production_duration, refueling_max_time, refueling_min_time, smr_lifetime)
                
                # Running the capacity market analysis
                payout_run = capacity_market_analysis(capacity_market_price, payout_run, numberof_modules, module_size)
                
                # Calculating the NPV
                _, break_even_run, _ = npv_calc_scenario(payout_run, interest_rate_wacc, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), Float64(construction_cost), Float64(om_cost), numberof_modules, Int(ceil(construction_duration/12)), Int(ceil(construction_duration/12))), (smr_lifetime + start_reactor))
                
                # Pushing the breakeven value
                heatmap_data[Int(capacity_market_price)+1, Int(energy_market_price)+1] = Float64(break_even_run)
            end
        end

        # Saving the heatmap data to a CSV file
        CSV.write("$output_dir/$(smr_names[index])_breakeven.csv", DataFrame(heatmap_data, :auto), writeheader=false)
        println("$(smr_names[index]) done")
    end
end

"""
Building a function to calculate the heatmap data for AP1000 and output to a directory
"""
function calculate_ap1000_heatmap_data(output_dir::String)
    for (index, cost_array) in enumerate(ap1000_cost_vals)
        ### Curating the scenarios to run the SMRs through ###
        # X Values is an array from 0 to 100
        x_values = collect(0.0:1.0:100.0)

        # Y Values is an array from 0 to 100
        y_values = collect(0.0:1.0:100.0)

        # Creating an empty matrix to hold heatmap data
        heatmap_data = Matrix{Float64}(undef, length(x_values), length(y_values))


        # Module size
        module_size = cost_array[1]
        
        # Number of modules
        numberof_modules = Int(cost_array[7])
                
        # Fuel cost
        fuel_cost = cost_array[4]
                
        # Lifetime of the SMR
        smr_lifetime = Int64(cost_array[2])
                
        # Construction cost of the SMR
        construction_cost = cost_array[3]
                
        # Fixed O&M cost of the SMR
        om_cost = cost_array[5]
                
        # Variable O&M cost of the SMR
        vom_cost = cost_array[6]
                            
        # Construction duration of the SMR
        construction_duration = cost_array[8]
                
        # Refueling min time
        refueling_min_time = Int64(cost_array[9])
                
        # Refueling max time
        refueling_max_time = Int64(cost_array[10])
        
        # Scenario
        scenario = cost_array[11]

        # Calculating the lead time
        start_reactor = Int(ceil(construction_duration/12))

        interest_rate_wacc = 0.04
        construction_interest_rate = 0.1

        max_energy_price = 100.0
        max_capacity_price = 100.0
        production_credit = 0.0
        production_duration = 10

        for energy_market_price in 0.0:1.0:max_energy_price
            for capacity_market_price in 0.0:1.0:max_capacity_price
                # Creating an energy market scenario on a flat price
                energy_market_scenario = create_constant_price_scenario(energy_market_price, (smr_lifetime + start_reactor))

                # Running the dispatch
                payout_run, _ = ap1000_dispatch_iteration_one(energy_market_scenario, module_size, numberof_modules, fuel_cost, vom_cost, production_credit, start_reactor, production_duration, refueling_max_time, refueling_min_time, smr_lifetime)
                
                # Running the capacity market analysis
                payout_run = capacity_market_analysis(capacity_market_price, payout_run, numberof_modules, module_size)
                
                # Calculating the NPV
                _, break_even_run, _ = npv_calc_scenario(payout_run, interest_rate_wacc, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), Float64(construction_cost), Float64(om_cost), numberof_modules, Int(ceil(construction_duration/12)), Int(ceil(construction_duration/12))), (smr_lifetime + start_reactor))
                
                # Pushing the breakeven value
                heatmap_data[Int(capacity_market_price)+1, Int(energy_market_price)+1] = Float64(break_even_run)
            end
        end

        # Saving the heatmap data to a CSV file
        CSV.write("$output_dir/$(ap1000_scenario_names[index])_breakeven.csv", DataFrame(heatmap_data, :auto), writeheader=false)
        println("$(ap1000_scenario_names[index]) done")
    end
end

"""
This function finds the first week with mixed prices and ramping in two dispatch dataframes.
"""
function find_first_common_week_with_mixed_prices_and_ramping(
    dispatch_df1::DataFrame, dispatch_df2::DataFrame, 
    payout_df1::DataFrame, payout_df2::DataFrame, 
    prices1::Vector{Float64}, prices2::Vector{Float64}, 
    module_size::Float64, number_of_modules::Int, 
    column_name::String)
    
    # Function to classify the ramping for the first dataframe
    function classify_ramping_df1(module_size, number_of_modules)
        lpo_smr = 0.4 * module_size * number_of_modules
        lpo_smr_refueling = 0.6 * module_size * (number_of_modules - 1)
        return lpo_smr, lpo_smr_refueling
    end

    # Function to classify the ramping for the second dataframe
    function classify_ramping_df2(module_size, number_of_modules)
        lpo_smr = 0.0
        lpo_smr_refueling = module_size * number_of_modules
        return lpo_smr, lpo_smr_refueling
    end

    # Helper function to find a common week with mixed prices and ramping in both dataframes
    function find_common_mixed_prices_and_ramping(dispatch_df1, dispatch_df2, prices1, prices2, module_size, number_of_modules, column_name)
        column_data1 = dispatch_df1[!, column_name]  # Pull out the relevant column from the first dataframe
        column_data2 = dispatch_df2[!, column_name]  # Pull out the relevant column from the second dataframe
        
        # Define the ramping criteria for both dataframes
        lpo_smr_1, lpo_smr_refueling_1 = classify_ramping_df1(module_size, number_of_modules)
        lpo_smr_2, lpo_smr_refueling_2 = classify_ramping_df2(module_size, number_of_modules)
        
        # Ensure the loop doesn't go beyond the length of the data
        max_index = min(length(column_data1), length(column_data2), length(prices1), length(prices2)) - 167
        
        # Loop through 7-day periods (7 * 24 = 168 hours)
        for i in 1:168:max_index
            current_period_1 = column_data1[i:i+167]
            current_period_2 = column_data2[i:i+167]
            current_prices_1 = prices1[i:i+167]
            current_prices_2 = prices2[i:i+167]
        
            # Check for both negative and positive prices in both dataframes
            has_negative_prices_1 = any(current_prices_1 .< 0)
            has_positive_prices_1 = any(current_prices_1 .> 0)
            has_negative_prices_2 = any(current_prices_2 .< 0)
            has_positive_prices_2 = any(current_prices_2 .> 0)
        
            # Check if both dataframes have mixed prices
            mixed_prices_1 = has_negative_prices_1 && has_positive_prices_1
            mixed_prices_2 = has_negative_prices_2 && has_positive_prices_2
        
            if mixed_prices_1 && mixed_prices_2
                return (i, i+167)  # Return the start and end indices for the 7-day period
            end
        end
        
        return nothing  # Return nothing if no such period is found
    end

    # Find the first common week with mixed prices and ramping for both dispatch dataframes
    week_indices = find_common_mixed_prices_and_ramping(dispatch_df1, dispatch_df2, prices1, prices2, module_size, number_of_modules, column_name)

    # If no period is found, return empty DataFrames and empty price vectors
    if isnothing(week_indices)
        return DataFrame(), DataFrame(), DataFrame(), DataFrame(), [], []
    end

    # Retrieve the actual 7-day data (168 hours) for the significant periods in both dataframes
    start_index, end_index = week_indices
    significant_dispatch_df1 = dispatch_df1[start_index:end_index, :]
    significant_dispatch_df2 = dispatch_df2[start_index:end_index, :]
    
    # Retrieve corresponding payout data for the significant periods
    significant_payout_df1 = payout_df1[start_index:end_index, :]
    significant_payout_df2 = payout_df2[start_index:end_index, :]

    # Retrieve the corresponding price data for the significant periods
    significant_prices1 = prices1[start_index:end_index]
    significant_prices2 = prices2[start_index:end_index]

    # Return the significant dispatch, payout periods, and corresponding prices
    return significant_dispatch_df1, significant_dispatch_df2, significant_payout_df1, significant_payout_df2, significant_prices1, significant_prices2
end


"""
Building a function to calculate the heatmap data and output to a directory
"""
function calculate_smr_heatmap_data(output_dir::String)
    for (index, cost_array) in enumerate(smr_cost_vals)
        # X Values is an array from 0 to 100
        x_values = collect(0.0:1.0:100.0)

        # Y Values is an array from 0 to 100
        y_values = collect(0.0:1.0:100.0)

        # Creating an empty matrix to hold heatmap data
        heatmap_data = Matrix{Float64}(undef, length(x_values), length(y_values))


        ### Creating the variables for the SMR dispatch ###
        if index < 20
            ## If it's the SMRs that are not in the ATB
            # Module size
            module_size = cost_array[1]
        
            # Number of modules
            numberof_modules = Int(cost_array[6])
        
            # Fuel cost
            fuel_cost = cost_array[4]
        
            # Lifetime of the SMR
            smr_lifetime = Int64(cost_array[2])
        
            # Construction cost of the SMR
            construction_cost = cost_array[3]
        
            # O&M cost of the SMR
            om_cost = cost_array[5]

            # VOM Cost is zero is not ATB as the O&M cost is assumed to be included in fom
            vom_cost = 0.0
        
            # Construction duration of the SMR
            construction_duration = cost_array[7]

            # Refueling min time
            refueling_min_time = Int64(cost_array[8])

            # Refueling max time
            refueling_max_time = Int64(cost_array[9])

            # Scenario
            scenario = cost_array[10]
        else
            ## If it's the SMRs that are in the ATB
        
            # Module size
            module_size = cost_array[1]
        
            # Number of modules
            numberof_modules = Int(cost_array[7])
        
            # Fuel cost
            fuel_cost = cost_array[4]
        
            # Lifetime of the SMR
            smr_lifetime = Int64(cost_array[2])
        
            # Construction cost of the SMR
            construction_cost = cost_array[3]
        
            # Fixed O&M cost of the SMR
            fom_cost = cost_array[5]

            # O&M cost of the SMR
            om_cost = fom_cost*smr_lifetime
        
            # Variable O&M cost of the SMR
            vom_cost = cost_array[6]
                    
            # Construction duration of the SMR
            construction_duration = cost_array[8]
        
            # Refueling min time
            refueling_min_time = Int64(cost_array[9])
        
            # Refueling max time
            refueling_max_time = Int64(cost_array[10])

            # Scenario
            scenario = cost_array[11]
        end

        # Calculating the lead time
        start_reactor = Int(ceil(construction_duration/12))
        interest_rate_wacc = 0.04
        construction_interest_rate = 0.1

        max_energy_price = 100.0
        max_capacity_price = 100.0
        production_credit = 0.0
        production_duration = 10
    
        for energy_market_price in 0.0:1.0:max_energy_price
            for capacity_market_price in 0.0:1.0:max_capacity_price
                # Creating an energy market scenario on a flat price
                energy_market_scenario = create_constant_price_scenario(energy_market_price, (smr_lifetime + start_reactor))

                # Running the dispatch
                payout_run, _ = smr_dispatch_iteration_three(energy_market_scenario, Float64(module_size), numberof_modules, fuel_cost, vom_cost, production_credit, start_reactor, production_duration, refueling_max_time, refueling_min_time, smr_lifetime)
                
                # Running the capacity market analysis
                payout_run = capacity_market_analysis(capacity_market_price, payout_run, numberof_modules, module_size)
                
                # Calculating the NPV
                _, break_even_run, _ = npv_calc_scenario(payout_run, interest_rate_wacc, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), Float64(construction_cost), Float64(om_cost), numberof_modules, Int(ceil(construction_duration/12)), Int(ceil(construction_duration/12))), (smr_lifetime + start_reactor))
                
                # Pushing the breakeven value
                heatmap_data[Int(capacity_market_price)+1, Int(energy_market_price)+1] = Float64(break_even_run)
            end
        end

        # Saving the heatmap data to a CSV file
        CSV.write("$output_dir/$(smr_names[index])_breakeven.csv", DataFrame(heatmap_data, :auto), writeheader=false)
        println("$(smr_names[index]) done")
    end
end

"""
Building a function to calculate the heatmap data for AP1000 and output to a directory
"""
function calculate_ap1000_heatmap_data(output_dir::String)
    for (index, cost_array) in enumerate(ap1000_cost_vals)
        ### Curating the scenarios to run the SMRs through ###
        # X Values is an array from 0 to 100
        x_values = collect(0.0:1.0:100.0)

        # Y Values is an array from 0 to 100
        y_values = collect(0.0:1.0:100.0)

        # Creating an empty matrix to hold heatmap data
        heatmap_data = Matrix{Float64}(undef, length(x_values), length(y_values))


        # Module size
        module_size = cost_array[1]
        
        # Number of modules
        numberof_modules = Int(cost_array[7])
                
        # Fuel cost
        fuel_cost = cost_array[4]
                
        # Lifetime of the SMR
        smr_lifetime = Int64(cost_array[2])
                
        # Construction cost of the SMR
        construction_cost = cost_array[3]
                
        # Fixed O&M cost of the SMR
        om_cost = cost_array[5]
                
        # Variable O&M cost of the SMR
        vom_cost = cost_array[6]
                            
        # Construction duration of the SMR
        construction_duration = cost_array[8]
                
        # Refueling min time
        refueling_min_time = Int64(cost_array[9])
                
        # Refueling max time
        refueling_max_time = Int64(cost_array[10])
        
        # Scenario
        scenario = cost_array[11]

        # Calculating the lead time
        start_reactor = Int(ceil(construction_duration/12))

        interest_rate_wacc = 0.04
        construction_interest_rate = 0.1

        max_energy_price = 100.0
        max_capacity_price = 100.0
        production_credit = 0.0
        production_duration = 10

        for energy_market_price in 0.0:1.0:max_energy_price
            for capacity_market_price in 0.0:1.0:max_capacity_price
                # Creating an energy market scenario on a flat price
                energy_market_scenario = create_constant_price_scenario(energy_market_price, (smr_lifetime + start_reactor))

                # Running the dispatch
                payout_run, _ = ap1000_dispatch_iteration_one(energy_market_scenario, module_size, numberof_modules, fuel_cost, vom_cost, production_credit, start_reactor, production_duration, refueling_max_time, refueling_min_time, smr_lifetime)
                
                # Running the capacity market analysis
                payout_run = capacity_market_analysis(capacity_market_price, payout_run, numberof_modules, module_size)
                
                # Calculating the NPV
                _, break_even_run, _ = npv_calc_scenario(payout_run, interest_rate_wacc, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), Float64(construction_cost), Float64(om_cost), numberof_modules, Int(ceil(construction_duration/12)), Int(ceil(construction_duration/12))), (smr_lifetime + start_reactor))
                
                # Pushing the breakeven value
                heatmap_data[Int(capacity_market_price)+1, Int(energy_market_price)+1] = Float64(break_even_run)
            end
        end

        # Saving the heatmap data to a CSV file
        CSV.write("$output_dir/$(ap1000_scenario_names[index])_breakeven.csv", DataFrame(heatmap_data, :auto), writeheader=false)
        println("$(ap1000_scenario_names[index]) done")
    end
end