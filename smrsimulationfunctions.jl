using DataFrames
using Statistics
using Distributions
using Gurobi
using Plots
using JuMP
using Roots
using LinearAlgebra
using StatsPlots

# For testing, including Data.jl and dataprocessingfunctions.jl
include("data.jl")
#include("dataprocessingfunctions.jl")

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
    refuel_time = 24*17 # Refuel time is 17 days as per the paper https://www.sciencedirect.com/science/article/pii/S0360544223015013

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

    # Defining low power operation range - reference: SNETP, Nuclear Energy Factsheets - Load following
    # capabilities of Nuclear Power Plants. TODO: Change this to link.
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
The following function calculates the dispatch formulation for an AP1000 reactor
"""
function smr_dispatch_iteration_three_withATB(price_data, module_size::Int, number_of_modules::Int, fuel_cost::Float64, vom_cost::Float64, production_credit::Float64, 
    construction_end::Int, production_credit_duration::Int, refuel_time_upper::Int, refuel_time_lower::Int, lifetime::Int)
    # Assumption: Startup cost [$/kWh] is based on moderate scenario from source: https://inldigitallibrary.inl.gov/sites/sti/sti/Sort_107010.pdf, pg. 82
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
This function takes a scenario as an input, and calculates the NPV lifetime of the scenario as a whole
"""
function npv_calc_scenario(payout_array, interest_rate::Float64, initial_investment::Float64, lifetime::Int)
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
        generator_payout_var = 0.0
        
        # This loop will calculate the yearly payout of the scenario
        for i in 1:8760
            # Summing the yearly payout
            generator_payout_var += payout_array[current_hour]
            
            # Incrementing the current hour analyzed
            current_hour += 1
        end
        
        # If this is a year of construction, continue to the next year.
        if generator_payout_var == 0.0
            continue
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

"""
The following function returns all the scenarios used as price arrays for the SMR dispatch
"""
function all_scenario_prices()::Vector{Dict{String, Any}}
    scenario_price_data_all = []

    scenario_price_data_temp = []

    for (index2, cost_array) in enumerate(smr_cost_vals)
        if index2 < 20
            smr_lifetime = Int64(cost_array[2])
            construction_duration = cost_array[7]
        else
            smr_lifetime = Int64(cost_array[2])
            construction_duration = cost_array[8]
        end

        start_reactor = Int(ceil((construction_duration)/12))

        for (index3, scenario) in enumerate(scenario_data_all)
            if index3 == 1 || index3 == 2 || index3 == 3
                scenario_dict = Dict(
                    "smr" =>  "$(smr_names[index2])",
                    "scenario" => "$(scenario_names_combined[index3])",
                    "data" => create_scenario_array(scenario, scenario, scenario, scenario, scenario, scenario, scenario, scenario, (smr_lifetime + start_reactor))
                )

                push!(scenario_price_data_all, scenario_dict)
                continue
            end

            if length(scenario_price_data_temp) == 8
                scen_names_combined_index = Int((index3 - 4)/8)
                scenario_dict = Dict(
                    "smr" =>  "$(smr_names[index2])",
                    "scenario" => "$(scenario_names_combined[scen_names_combined_index])",
                    "data" => create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (smr_lifetime + start_reactor))
                )

                push!(scenario_price_data_all, scenario_dict)
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end

        scenario_dict = Dict(
            "smr" =>  "$(smr_names[index2])",
            "scenario" => "$(last(scenario_names_combined))",
            "data" => create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (smr_lifetime + start_reactor))
        )

        push!(scenario_price_data_all, scenario_dict)
        empty!(scenario_price_data_temp)
    end

    return scenario_price_data_all
end

"""
The following function imports in the results from the case analysis, and stores them in a dictionary.
Returned is an array of dictionaries of all the cases
"""
function results_cases()
    # Creating an array to hold dictionaries for all cases
    all_cases = []

    # Baseline
    baseline_dict = Dict(
        "Scenario" => "Baseline", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/baseline/baseline_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/baseline/baseline_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/baseline/baseline_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/baseline/baseline_npv_final.csv"))
    )
    push!(all_cases, baseline_dict)

    # Coal2Nuclear
    c2n_dict = Dict(
        "Scenario" => "C2N", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline/c2n_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline/c2n_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline/c2n_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline/c2n_npv_final.csv"))
    )
    push!(all_cases, c2n_dict)

    # Multi-Module Learning
    multi_module_dict = Dict(
        "Scenario" => "Multi-Module Learning", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/mmlearning_baseline/mmlearning_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/mmlearning_baseline/mmlearning_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/mmlearning_baseline/mmlearning_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/mmlearning_baseline/mmlearning_npv_final.csv"))
    )
    push!(all_cases, multi_module_dict)

    # ITC 6%
    itc_6_dict = Dict(
        "Scenario" => "ITC 6%", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline/itc_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline/itc_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline/itc_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline/itc_npv_final.csv"))
    )
    push!(all_cases, itc_6_dict)

    # ITC 30%
    itc_30_dict = Dict(
        "Scenario" => "ITC 30%", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline/itc30_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline/itc30_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline/itc30_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline/itc30_npv_final.csv"))
    )
    push!(all_cases, itc_30_dict)

    # ITC 40%
    itc_40_dict = Dict(
        "Scenario" => "ITC 40%", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc40_baseline/itc40_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc40_baseline/itc40_breakeven.csv"))
    )
    push!(all_cases, itc_40_dict)

    # ITC 50%
    itc_50_dict = Dict(
        "Scenario" => "ITC 50%", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc50_baseline/itc50_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc50_baseline/itc50_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc50_baseline/itc50_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc50_baseline/itc50_npv_final.csv"))
    )
    push!(all_cases, itc_50_dict)

    # PTC $11/MWh
    ptc_11_dict = Dict(
        "Scenario" => "PTC \$11/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline/ptc11_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline/ptc11_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline/ptc11_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline/ptc11_npv_final.csv"))
    )
    push!(all_cases, ptc_11_dict)

    # PTC $12/MWh
    ptc_12_dict = Dict(
        "Scenario" => "PTC \$12/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc12_baseline/ptc12_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc12_baseline/ptc12_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc12_baseline/ptc12_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc12_baseline/ptc12_npv_final.csv"))
    )
    push!(all_cases, ptc_12_dict)

    # PTC $13/MWh
    ptc_13_dict = Dict(
        "Scenario" => "PTC \$13/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc13_baseline/ptc13_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc13_baseline/ptc13_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc13_baseline/ptc13_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc13_baseline/ptc13_npv_final.csv"))
    )
    push!(all_cases, ptc_13_dict)

    # PTC $14/MWh
    ptc_14_dict = Dict(
        "Scenario" => "PTC \$14/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc14_baseline/ptc14_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc14_baseline/ptc14_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc14_baseline/ptc14_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc14_baseline/ptc14_npv_final.csv"))
    )
    push!(all_cases, ptc_14_dict)

    # PTC $15/MWh
    ptc_15_dict = Dict(
        "Scenario" => "PTC \$15/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc15_baseline/ptc15_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc15_baseline/ptc15_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc15_baseline/ptc15_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc15_baseline/ptc15_npv_final.csv"))
    )
    push!(all_cases, ptc_15_dict)

    # PTC $16/MWh
    ptc_16_dict = Dict(
        "Scenario" => "PTC \$16/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc16_baseline/ptc16_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc16_baseline/ptc16_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc16_baseline/ptc16_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc16_baseline/ptc16_npv_final.csv"))
    )
    push!(all_cases, ptc_16_dict)

    # PTC $17/MWh
    ptc_17_dict = Dict(
        "Scenario" => "PTC \$17/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc17_baseline/ptc17_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc17_baseline/ptc17_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc17_baseline/ptc17_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc17_baseline/ptc17_npv_final.csv"))
    )
    push!(all_cases, ptc_17_dict)

    # PTC $18/MWh
    ptc_18_dict = Dict(
        "Scenario" => "PTC \$18/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc18_baseline/ptc18_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc18_baseline/ptc18_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc18_baseline/ptc18_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc18_baseline/ptc18_npv_final.csv"))
    )
    push!(all_cases, ptc_18_dict)

    # PTC $19/MWh
    ptc_19_dict = Dict(
        "Scenario" => "PTC \$19/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc19_baseline/ptc19_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc19_baseline/ptc19_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc19_baseline/ptc19_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc19_baseline/ptc19_npv_final.csv"))
    )
    push!(all_cases, ptc_19_dict)

    # PTC $20/MWh
    ptc_20_dict = Dict(
        "Scenario" => "PTC \$20/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc20_baseline/ptc20_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc20_baseline/ptc20_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc20_baseline/ptc20_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc20_baseline/ptc20_npv_final.csv"))
    )
    push!(all_cases, ptc_20_dict)

    # PTC $21/MWh
    ptc_21_dict = Dict(
        "Scenario" => "PTC \$21/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc21_baseline/ptc21_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc21_baseline/ptc21_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc21_baseline/ptc21_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc21_baseline/ptc21_npv_final.csv"))
    )
    push!(all_cases, ptc_21_dict)

    # PTC $22/MWh
    ptc_22_dict = Dict(
        "Scenario" => "PTC \$22/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc22_baseline/ptc22_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc22_baseline/ptc22_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc22_baseline/ptc22_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc22_baseline/ptc22_npv_final.csv"))
    )
    push!(all_cases, ptc_22_dict)

    # PTC $23/MWh
    ptc_23_dict = Dict(
        "Scenario" => "PTC \$23/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc23_baseline/ptc23_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc23_baseline/ptc23_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc23_baseline/ptc23_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc23_baseline/ptc23_npv_final.csv"))
    )
    push!(all_cases, ptc_23_dict)

    # PTC $24/MWh
    ptc_24_dict = Dict(
        "Scenario" => "PTC \$24/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc24_baseline/ptc24_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc24_baseline/ptc24_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc24_baseline/ptc24_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc24_baseline/ptc24_npv_final.csv"))
    )
    push!(all_cases, ptc_24_dict)

    # PTC $25/MWh
    ptc_25_dict = Dict(
        "Scenario" => "PTC \$25/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc25_baseline/ptc25_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc25_baseline/ptc25_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc25_baseline/ptc25_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc25_baseline/ptc25_npv_final.csv"))
    )
    push!(all_cases, ptc_25_dict)

    # PTC $26/MWh
    ptc_26_dict = Dict(
        "Scenario" => "PTC \$26/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc26_baseline/ptc26_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc26_baseline/ptc26_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc26_baseline/ptc26_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc26_baseline/ptc26_npv_final.csv"))
    )
    push!(all_cases, ptc_26_dict)

    # PTC $27.5/MWh
    ptc_27_5_dict = Dict(
        "Scenario" => "PTC \$27.5/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc27.5_baseline/ptc27.5_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc27.5_baseline/ptc27.5_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc27.5_baseline/ptc27.5_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc27.5_baseline/ptc27.5_npv_final.csv"))
    )
    push!(all_cases, ptc_27_5_dict)

    # PTC $28.05/MWh
    ptc_28_05_dict = Dict(
        "Scenario" => "PTC \$28.05/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc28.05_baseline/ptc2805_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc28.05_baseline/ptc28.05_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc28.05_baseline/ptc28.05_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc28.05_baseline/ptc28.05_npv_final.csv"))
    )
    push!(all_cases, ptc_28_05_dict)

    # PTC $30.05/MWh
    ptc_30_05_dict = Dict(
        "Scenario" => "PTC \$30.05/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc30.05_baseline/ptc3005_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc30.05_baseline/ptc30.05_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc30.05_baseline/ptc30.05_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc30.05_baseline/ptc30.05_npv_final.csv"))
    )
    push!(all_cases, ptc_30_05_dict)

    # PTC $33/MWh
    ptc_33_dict = Dict(
        "Scenario" => "PTC \$33/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc33_baseline/ptc33_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc33_baseline/ptc33_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc33_baseline/ptc33_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc33_baseline/ptc33_npv_final.csv"))
    )
    push!(all_cases, ptc_33_dict)

    # Capacity Market $1/kW-month
    cm_1_dict = Dict(
        "Scenario" => "Capacity Market \$1/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm1_baseline/cm1_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm1_baseline/cm1_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm1_baseline/cm1_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm1_baseline/cm1_npv_final.csv"))
    )
    push!(all_cases, cm_1_dict)

    # Capacity Market $2/kW-month
    cm_2_dict = Dict(
        "Scenario" => "Capacity Market \$2/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm2_baseline/cm2_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm2_baseline/cm2_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm2_baseline/cm2_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm2_baseline/cm2_npv_final.csv"))
    )
    push!(all_cases, cm_2_dict)

    # Capacity Market $3/kW-month
    cm_3_dict = Dict(
        "Scenario" => "Capacity Market \$3/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm3_baseline/cm3_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm3_baseline/cm3_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm3_baseline/cm3_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm3_baseline/cm3_npv_final.csv"))
    )
    push!(all_cases, cm_3_dict)

    # Capacity Market $4/kW-month
    cm_4_dict = Dict(
        "Scenario" => "Capacity Market \$4/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm4_baseline/cm4_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm4_baseline/cm4_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm4_baseline/cm4_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm4_baseline/cm4_npv_final.csv"))
    )
    push!(all_cases, cm_4_dict)

    # Capacity Market $5/kW-month
    cm_5_dict = Dict(
        "Scenario" => "Capacity Market \$5/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm5_baseline/cm5_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm5_baseline/cm5_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm5_baseline/cm5_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm5_baseline/cm5_npv_final.csv"))
    )
    push!(all_cases, cm_5_dict)

    # Capacity Market $6/kW-month
    cm_6_dict = Dict(
        "Scenario" => "Capacity Market \$6/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm6_baseline/cm6_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm6_baseline/cm6_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm6_baseline/cm6_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm6_baseline/cm6_npv_final.csv"))
    )
    push!(all_cases, cm_6_dict)

    # Capacity Market $7/kW-month
    cm_7_dict = Dict(
        "Scenario" => "Capacity Market \$7/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm7_baseline/cm7_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm7_baseline/cm7_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm7_baseline/cm7_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm7_baseline/cm7_npv_final.csv"))
    )
    push!(all_cases, cm_7_dict)

    # Capacity Market $8/kW-month
    cm_8_dict = Dict(
        "Scenario" => "Capacity Market \$8/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm8_baseline/cm8_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm8_baseline/cm8_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm8_baseline/cm8_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm8_baseline/cm8_npv_final.csv"))
    )
    push!(all_cases, cm_8_dict)

    # Capacity Market $15/kW-month
    cm_15_dict = Dict(
        "Scenario" => "Capacity Market \$15/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm15_baseline/cm15_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm15_baseline/cm15_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm15_baseline/cm15_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm15_baseline/cm15_npv_final.csv"))
    )
    push!(all_cases, cm_15_dict)

    # Capacity Market $16/kW-month
    cm_16_dict = Dict(
        "Scenario" => "Capacity Market \$16/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm16_baseline/cm16_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm16_baseline/cm16_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm16_baseline/cm16_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm16_baseline/cm16_npv_final.csv"))
    )
    push!(all_cases, cm_16_dict)

    # Capacity Market $17/kW-month
    cm_17_dict = Dict(
        "Scenario" => "Capacity Market \$17/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm17_baseline/cm17_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm17_baseline/cm17_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm17_baseline/cm17_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm17_baseline/cm17_npv_final.csv"))
    )
    push!(all_cases, cm_17_dict)

    # Capacity Market $18/kW-month
    cm_18_dict = Dict(
        "Scenario" => "Capacity Market \$18/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm18_baseline/cm18_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm18_baseline/cm18_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm18_baseline/cm18_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm18_baseline/cm18_npv_final.csv"))
    )
    push!(all_cases, cm_18_dict)

    # Capacity Market $19/kW-month
    cm_19_dict = Dict(
        "Scenario" => "Capacity Market \$19/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm19_baseline/cm19_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm19_baseline/cm19_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm19_baseline/cm19_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm19_baseline/cm19_npv_final.csv"))
    )
    push!(all_cases, cm_19_dict)

    # Capacity Market $20/kW-month
    cm_20_dict = Dict(
        "Scenario" => "Capacity Market \$20/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm20_baseline/cm20_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm20_baseline/cm20_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm20_baseline/cm20_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm20_baseline/cm20_npv_final.csv"))
    )
    push!(all_cases, cm_20_dict)

    # Capacity Market $21/kW-month
    cm_21_dict = Dict(
        "Scenario" => "Capacity Market \$21/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm21_baseline/cm21_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm21_baseline/cm21_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm21_baseline/cm21_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm21_baseline/cm21_npv_final.csv"))
    )
    push!(all_cases, cm_21_dict)

    # Capacity Market $22/kW-month
    cm_22_dict = Dict(
        "Scenario" => "Capacity Market \$22/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm22_baseline/cm22_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm22_baseline/cm22_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm22_baseline/cm22_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm22_baseline/cm22_npv_final.csv"))
    )
    push!(all_cases, cm_22_dict)

    # Capacity Market $23/kW-month
    cm_23_dict = Dict(
        "Scenario" => "Capacity Market \$23/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm23_baseline/cm23_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm23_baseline/cm23_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm23_baseline/cm23_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm23_baseline/cm23_npv_final.csv"))
    )
    push!(all_cases, cm_23_dict)

    # Capacity Market $25/kW-month
    cm_25_dict = Dict(
        "Scenario" => "Capacity Market \$25/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm25_baseline/cm25_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm25_baseline/cm25_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm25_baseline/cm25_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm25_baseline/cm25_npv_final.csv"))
    )
    push!(all_cases, cm_25_dict)

    # Capacity Market $30/kW-month
    cm_30_dict = Dict(
        "Scenario" => "Capacity Market \$30/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm30_baseline/cm30_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm30_baseline/cm30_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm30_baseline/cm30_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm30_baseline/cm30_npv_final.csv"))
    )
    push!(all_cases, cm_30_dict)

    # Capacity Market $35/kW-month
    cm_35_dict = Dict(
        "Scenario" => "Capacity Market \$35/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm35_baseline/cm35_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm35_baseline/cm35_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm35_baseline/cm35_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm35_baseline/cm35_npv_final.csv"))
    )
    push!(all_cases, cm_35_dict)

    # Capacity Market $40/kW-month
    cm_40_dict = Dict(
        "Scenario" => "Capacity Market \$40/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm40_baseline/cm40_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm40_baseline/cm40_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm40_baseline/cm40_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm40_baseline/cm40_npv_final.csv"))
    )
    push!(all_cases, cm_40_dict)

    # Capacity Market $45/kW-month
    cm_45_dict = Dict(
        "Scenario" => "Capacity Market \$45/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm45_baseline/cm45_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm45_baseline/cm45_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm45_baseline/cm45_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm45_baseline/cm45_npv_final.csv"))
    )
    push!(all_cases, cm_45_dict)

    # Capacity Market $50/kW-month
    cm_50_dict = Dict(
        "Scenario" => "Capacity Market \$50/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm50_baseline/cm50_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm50_baseline/cm50_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm50_baseline/cm50_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm50_baseline/cm50_npv_final.csv"))
    )
    push!(all_cases, cm_50_dict)

    # Capacity Market $55/kW-month
    cm_55_dict = Dict(
        "Scenario" => "Capacity Market \$55/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm55_baseline/cm55_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm55_baseline/cm55_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm55_baseline/cm55_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm55_baseline/cm55_npv_final.csv"))
    )
    push!(all_cases, cm_55_dict)

    # Capacity Market $60/kW-month
    cm_60_dict = Dict(
        "Scenario" => "Capacity Market \$60/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm60_baseline/cm60_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm60_baseline/cm60_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm60_baseline/cm60_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm60_baseline/cm60_npv_final.csv"))
    )
    push!(all_cases, cm_60_dict)

    # Capacity Market $65/kW-month
    cm_65_dict = Dict(
        "Scenario" => "Capacity Market \$65/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm65_baseline/cm65_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm65_baseline/cm65_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm65_baseline/cm65_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm65_baseline/cm65_npv_final.csv"))
    )
    push!(all_cases, cm_65_dict)

    # Capacity Market $70/kW-month
    cm_70_dict = Dict(
        "Scenario" => "Capacity Market \$70/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm70_baseline/cm70_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm70_baseline/cm70_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm70_baseline/cm70_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm70_baseline/cm70_npv_final.csv"))
    )
    push!(all_cases, cm_70_dict)

    # Capacity Market $75/kW-month
    cm_75_dict = Dict(
        "Scenario" => "Capacity Market \$75/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm75_baseline/cm75_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm75_baseline/cm75_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm75_baseline/cm75_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm75_baseline/cm75_npv_final.csv"))
    )
    push!(all_cases, cm_75_dict)

    # Capacity Market $80/kW-month
    cm_80_dict = Dict(
        "Scenario" => "Capacity Market \$80/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm80_baseline/cm80_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm80_baseline/cm80_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm80_baseline/cm80_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm80_baseline/cm80_npv_final.csv"))
    )
    push!(all_cases, cm_80_dict)

    # Capacity Market $85/kW-month
    cm_85_dict = Dict(
        "Scenario" => "Capacity Market \$85/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm85_baseline/cm85_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm85_baseline/cm85_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm85_baseline/cm85_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm85_baseline/cm85_npv_final.csv"))
    )
    push!(all_cases, cm_85_dict)

    # Capacity Market $90/kW-month
    cm_90_dict = Dict(
        "Scenario" => "Capacity Market \$90/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm90_baseline/cm90_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm90_baseline/cm90_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm90_baseline/cm90_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm90_baseline/cm90_npv_final.csv"))
    )
    push!(all_cases, cm_90_dict)

    # Capacity Market $95/kW-month
    cm_95_dict = Dict(
        "Scenario" => "Capacity Market \$95/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm95_baseline/cm95_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm95_baseline/cm95_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm95_baseline/cm95_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm95_baseline/cm95_npv_final.csv"))
    )
    push!(all_cases, cm_95_dict)

    # Capacity Market $100/kW-month
    cm_100_dict = Dict(
        "Scenario" => "Capacity Market \$100/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm100_baseline/cm100_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm100_baseline/cm100_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm100_baseline/cm100_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm100_baseline/cm100_npv_final.csv"))
    )
    push!(all_cases, cm_100_dict)

    # Capacity Market $105/kW-month
    cm_105_dict = Dict(
        "Scenario" => "Capacity Market \$105/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm105_baseline/cm105_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm105_baseline/cm105_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm105_baseline/cm105_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm105_baseline/cm105_npv_final.csv"))
    )
    push!(all_cases, cm_105_dict)

    # Capacity Market $110/kW-month
    cm_110_dict = Dict(
        "Scenario" => "Capacity Market \$110/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm110_baseline/cm110_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm110_baseline/cm110_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm110_baseline/cm110_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm110_baseline/cm110_npv_final.csv"))
    )
    push!(all_cases, cm_110_dict)

    # Capacity Market $115/kW-month
    cm_115_dict = Dict(
        "Scenario" => "Capacity Market \$115/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm115_baseline/cm115_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm115_baseline/cm115_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm115_baseline/cm115_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm115_baseline/cm115_npv_final.csv"))
    )
    push!(all_cases, cm_115_dict)

    # Capacity Market $120/kW-month
    cm_120_dict = Dict(
        "Scenario" => "Capacity Market \$120/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm120_baseline/cm120_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm120_baseline/cm120_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm120_baseline/cm120_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm120_baseline/cm120_npv_final.csv"))
    )
    push!(all_cases, cm_120_dict)

    # Capacity Market $125/kW-month
    cm_125_dict = Dict(
        "Scenario" => "Capacity Market \$125/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm125_baseline/cm125_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm125_baseline/cm125_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm125_baseline/cm125_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm125_baseline/cm125_npv_final.csv"))
    )
    push!(all_cases, cm_125_dict)

    # Capacity Market $130/kW-month
    cm_130_dict = Dict(
        "Scenario" => "Capacity Market \$130/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm130_baseline/cm130_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm130_baseline/cm130_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm130_baseline/cm130_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm130_baseline/cm130_npv_final.csv"))
    )
    push!(all_cases, cm_130_dict)

    # Synthetic Case 1: Multi-modular, PTC $15/MWh and Capacity Market of $5.0/kW-month
    synthetic_case1_dict = Dict(
        "Scenario" => "Synthetic Case 1: Multi-modular, PTC \$15/MWh and Capacity Market of \$5.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case1/synthetic_case1_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case1/synthetic_case1_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case1/synthetic_case1_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case1/synthetic_case1_npv_final.csv"))
    )
    push!(all_cases, synthetic_case1_dict)

    # Synthetic Case 2: Multi-modular, C2N, PTC $15/MWh and Capacity Market of $5.0/kW-month
    synthetic_case2_dict = Dict(
        "Scenario" => "Synthetic Case 2: Multi-modular, C2N, PTC \$15/MWh and Capacity Market of \$5.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case2/synthetic_case2_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case2/synthetic_case2_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case2/synthetic_case2_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case2/synthetic_case2_npv_final.csv"))
    )
    push!(all_cases, synthetic_case2_dict)

    # Synthetic Case 3: Multi-modular, C2N, ITC 6%, PTC $15/MWh and Capacity Market of $5.0/kW-month
    synthetic_case3_dict = Dict(
        "Scenario" => "Synthetic Case 3: Multi-modular, C2N, ITC 6%, PTC \$15/MWh and Capacity Market of \$5.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case3/synthetic_case3_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case3/synthetic_case3_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case3/synthetic_case3_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case3/synthetic_case3_npv_final.csv"))
    )
    push!(all_cases, synthetic_case3_dict)

    # Synthetic Case 4: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $5.0/kW-month
    synthetic_case4_dict = Dict(
        "Scenario" => "Synthetic Case 4: Multi-modular, C2N, ITC 30%, PTC \$15/MWh and Capacity Market of \$5.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case4/synthetic_case4_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case4/synthetic_case4_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case4/synthetic_case4_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case4/synthetic_case4_npv_final.csv"))
    )
    push!(all_cases, synthetic_case4_dict)

    # Synthetic Case 5: Multi-modular, C2N, ITC 40%, PTC $15/MWh and Capacity Market of $5.0/kW-month
    synthetic_case5_dict = Dict(
        "Scenario" => "Synthetic Case 5: Multi-modular, C2N, ITC 40%, PTC \$15/MWh and Capacity Market of \$5.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case5/synthetic_case5_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case5/synthetic_case5_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case5/synthetic_case5_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case5/synthetic_case5_npv_final.csv"))
    )
    push!(all_cases, synthetic_case5_dict)

    # Synthetic Case 6:  Multi-modular, C2N, ITC 50%, PTC $15/MWh and Capacity Market of $5.0/kW-month 
    synthetic_case6_dict = Dict(
        "Scenario" => "Synthetic Case 6: Multi-modular, C2N, ITC 50%, PTC \$15/MWh and Capacity Market of \$5.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case6/synthetic_case6_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case6/synthetic_case6_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case6/synthetic_case6_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case6/synthetic_case6_npv_final.csv"))
    )
    push!(all_cases, synthetic_case6_dict)

    # Synthetic Case 7: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $15.0/kW-month
    synthetic_case7_dict = Dict(
        "Scenario" => "Synthetic Case 7: Multi-modular, C2N, ITC 30%, PTC \$15/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case7/synthetic_case7_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case7/synthetic_case7_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case7/synthetic_case7_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case7/synthetic_case7_npv_final.csv"))
    
    )
    push!(all_cases, synthetic_case7_dict)

    # Synthetic Case 8: Multi-modular, C2N, ITC 30%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month
    synthetic_case8_dict = Dict(
        "Scenario" => "Synthetic Case 8: Multi-modular, C2N, ITC 30%, PTC \$27.5/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case8/synthetic_case8_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case8/synthetic_case8_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case8/synthetic_case8_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case8/synthetic_case8_npv_final.csv"))
    )
    push!(all_cases, synthetic_case8_dict)

    # Synthetic Case 9: Multi-modular, C2N, ITC 40%, PTC $15/MWh and Capacity Market of $15.0/kW-month
    synthetic_case9_dict = Dict(
        "Scenario" => "Synthetic Case 9: Multi-modular, C2N, ITC 40%, PTC \$15/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case9/synthetic_case9_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case9/synthetic_case9_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case9/synthetic_case9_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case9/synthetic_case9_npv_final.csv"))
    )
    push!(all_cases, synthetic_case9_dict)

    # Synthetic Case 10: Multi-modular, C2N, ITC 50%, PTC $15/MWh and Capacity Market of $15.0/kW-month
    synthetic_case10_dict = Dict(
        "Scenario" => "Synthetic Case 10: Multi-modular, C2N, ITC 50%, PTC \$15/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case10/synthetic_case10_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case10/synthetic_case10_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case10/synthetic_case10_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case10/synthetic_case10_npv_final.csv"))
    )
    push!(all_cases, synthetic_case10_dict)

    # Synthetic Case 11: Multi-modular, C2N, ITC 6%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month
    synthetic_case11_dict = Dict(
        "Scenario" => "Synthetic Case 11: Multi-modular, C2N, ITC 6%, PTC \$27.5/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case11/synthetic_case11_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case11/synthetic_case11_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case11/synthetic_case11_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case11/synthetic_case11_npv_final.csv"))
    )
    push!(all_cases, synthetic_case11_dict)

    # Synthetic Case 12: Multi-modular, C2N, ITC 40%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month
    synthetic_case12_dict = Dict(
        "Scenario" => "Synthetic Case 12: Multi-modular, C2N, ITC 40%, PTC \$27.5/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case12/synthetic_case12_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case12/synthetic_case12_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case12/synthetic_case12_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case12/synthetic_case12_npv_final.csv"))
    )
    push!(all_cases, synthetic_case12_dict)

    # Synthetic Case 13: Multi-modular, C2N, ITC 50%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month
    synthetic_case13_dict = Dict(
        "Scenario" => "Synthetic Case 13: Multi-modular, C2N, ITC 50%, PTC \$27.5/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case13/synthetic_case13_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case13/synthetic_case13_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case13/synthetic_case13_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case13/synthetic_case13_npv_final.csv"))
    )
    push!(all_cases, synthetic_case13_dict)

    # Synthetic Case 14: Multi-modular, C2N, ITC 6%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month
    synthetic_case14_dict = Dict(
        "Scenario" => "Synthetic Case 14: Multi-modular, C2N, ITC 6%, PTC \$30.05/MWh and Capacity Market of \$25.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case14/synthetic_case14_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case14/synthetic_case14_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case14/synthetic_case14_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case14/synthetic_case14_npv_final.csv"))
    )
    push!(all_cases, synthetic_case14_dict)

    # Synthetic Case 15: Multi-modular, C2N, ITC 30%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month
    synthetic_case15_dict = Dict(
        "Scenario" => "Synthetic Case 15: Multi-modular, C2N, ITC 30%, PTC \$30.05/MWh and Capacity Market of \$25.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case15/synthetic_case15_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case15/synthetic_case15_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case15/synthetic_case15_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case15/synthetic_case15_npv_final.csv"))
    )
    push!(all_cases, synthetic_case15_dict)

    # Synthetic Case 16: Multi-modular, C2N, ITC 40%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month
    synthetic_case16_dict = Dict(
        "Scenario" => "Synthetic Case 16: Multi-modular, C2N, ITC 40%, PTC \$30.05/MWh and Capacity Market of \$25.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case16/synthetic_case16_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case16/synthetic_case16_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case16/synthetic_case16_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case16/synthetic_case16_npv_final.csv"))
    )
    push!(all_cases, synthetic_case16_dict)

    # Synthetic Case 17: Multi-modular, C2N, ITC 50%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month
    synthetic_case17_dict = Dict(
        "Scenario" => "Synthetic Case 17: Multi-modular, C2N, ITC 50%, PTC \$30.05/MWh and Capacity Market of \$25.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case17/synthetic_case17_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case17/synthetic_case17_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case17/synthetic_case17_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case17/synthetic_case17_npv_final.csv"))
    )
    push!(all_cases, synthetic_case17_dict)

    # Synthetic Case 18: Multi-modular, C2N, ITC 50%, PTC $33.0/MWh and Capacity Market of $25.0/kW-month
    synthetic_case18_dict = Dict(
        "Scenario" => "Synthetic Case 18: Multi-modular, C2N, ITC 50%, PTC \$33.0/MWh and Capacity Market of \$25.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case18/synthetic_case18_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case18/synthetic_case18_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case18/synthetic_case18_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case18/synthetic_case18_npv_final.csv"))
    )
    push!(all_cases, synthetic_case18_dict)

    # Synthetic Learning Rate 1: 65% construction cost reduction and 5% FOM cost reduction
    syntheticll_1_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 1: 65% construction cost reduction and 5% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case1/syntheticll_case1_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case1/syntheticll_case1_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case1/syntheticll_case1_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case1/syntheticll_case1_npv_final.csv"))
    )
    push!(all_cases, syntheticll_1_dict)

    # Synthetic Learning Rate 2: 65% construction cost reduction and 10% FOM cost reduction
    syntheticll_2_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 2: 65% construction cost reduction and 10% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case2/syntheticll_case2_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case2/syntheticll_case2_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case2/syntheticll_case2_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case2/syntheticll_case2_npv_final.csv"))
    )
    push!(all_cases, syntheticll_2_dict)

    # Synthetic Learning Rate 3: 65% construction cost reduction and 15% FOM cost reduction
    syntheticll_3_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 3: 65% construction cost reduction and 15% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case3/syntheticll_case3_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case3/syntheticll_case3_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case3/syntheticll_case3_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case3/syntheticll_case3_npv_final.csv"))
    )
    push!(all_cases, syntheticll_3_dict)

    # Synthetic Learning Rate 4: 65% construction cost reduction and 20% FOM cost reduction
    syntheticll_4_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 4: 65% construction cost reduction and 20% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case4/syntheticll_case4_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case4/syntheticll_case4_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case4/syntheticll_case4_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case4/syntheticll_case4_npv_final.csv"))
    )
    push!(all_cases, syntheticll_4_dict)

    # Synthetic Learning Rate 5: 65% construction cost reduction and 25% FOM cost reduction
    syntheticll_5_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 5: 65% construction cost reduction and 25% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case5/syntheticll_case5_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case5/syntheticll_case5_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case5/syntheticll_case5_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case5/syntheticll_case5_npv_final.csv"))
    )
    push!(all_cases, syntheticll_5_dict)

    # Synthetic Learning Rate 6: 65% construction cost reduction and 30% FOM cost reduction
    syntheticll_6_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 6: 65% construction cost reduction and 30% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case6/syntheticll_case6_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case6/syntheticll_case6_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case6/syntheticll_case6_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case6/syntheticll_case6_npv_final.csv"))
    )
    push!(all_cases, syntheticll_6_dict)

    # Synthetic Learning Rate 7: 65% construction cost reduction and 35% FOM cost reduction
    syntheticll_7_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 7: 65% construction cost reduction and 35% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case7/syntheticll_case7_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case7/syntheticll_case7_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case7/syntheticll_case7_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case7/syntheticll_case7_npv_final.csv"))
    )
    push!(all_cases, syntheticll_7_dict)

    # Synthetic Learning Rate 8: 65% construction cost reduction and 40% FOM cost reduction
    syntheticll_8_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 8: 65% construction cost reduction and 40% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case8/syntheticll_case8_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case8/syntheticll_case8_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case8/syntheticll_case8_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case8/syntheticll_case8_npv_final.csv"))
    )
    push!(all_cases, syntheticll_8_dict)

    # Synthetic Learning Rate 9: 65% construction cost reduction and 45% FOM cost reduction
    syntheticll_9_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 9: 65% construction cost reduction and 45% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case9/syntheticll_case9_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case9/syntheticll_case9_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case9/syntheticll_case9_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case9/syntheticll_case9_npv_final.csv"))
    )
    push!(all_cases, syntheticll_9_dict)

    # Synthetic Learning Rate 10: 65% construction cost reduction and 50% FOM cost reduction
    syntheticll_10_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 10: 65% construction cost reduction and 50% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case10/syntheticll_case10_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case10/syntheticll_case10_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case10/syntheticll_case10_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case10/syntheticll_case10_npv_final.csv"))
    )
    push!(all_cases, syntheticll_10_dict)

    # Synthetic Learning Rate 11: 65% construction cost reduction and 55% FOM cost reduction
    syntheticll_11_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 11: 65% construction cost reduction and 55% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case11/syntheticll_case11_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case11/syntheticll_case11_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case11/syntheticll_case11_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case11/syntheticll_case11_npv_final.csv"))
    )
    push!(all_cases, syntheticll_11_dict)

    # Synthetic Learning Rate 12: 65% construction cost reduction and 60% FOM cost reduction
    syntheticll_12_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 12: 65% construction cost reduction and 60% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case12/syntheticll_case12_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case12/syntheticll_case12_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case12/syntheticll_case12_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case12/syntheticll_case12_npv_final.csv"))
    )
    push!(all_cases, syntheticll_12_dict)
    

    return all_cases
end

function filter_and_extract_cases(all_cases::Vector{Any})::Vector{Dict{String, Any}}  # Changed type to Vector{Any}
    # Define a regular expression to match "Capacity Market \$<price>/kW-month"
    capacity_market_regex = r"^Capacity Market \$\d+(\.\d+)?/kW-month$"
    
    # Initialize an array to hold the filtered and extracted dictionaries
    filtered_cases = []

    # Iterate through the cases and filter based on the scenario
    for case in all_cases
        if isa(case, Dict{String, Any}) && occursin(capacity_market_regex, case["Scenario"])
            # Create a new dictionary with only the "Scenario" and "Breakeven DataFrame" keys
            new_case = Dict(
                "Scenario" => case["Scenario"],
                "Breakeven DataFrame" => case["Breakeven DataFrame"]
            )
            # Add the new dictionary to the filtered cases array
            push!(filtered_cases, new_case)
        end
    end

    return filtered_cases
end


# Function to calculate average energy prices from scenario data
function calculate_avg_energy_prices(scenario_data)
    return mean(scenario_data)  # Adjust as needed based on how your data is structured
end

# Function to generate heatmaps
function generate_heatmaps(filtered_cases::Vector{Dict{String, Any}}, scenario_prices::Vector{Dict{String, Any}})
    heatmaps = []

    # Loop over each filtered case
    for case in filtered_cases
        scenario_name = case["Scenario"]
        breakeven_df = case["Breakeven DataFrame"]
        
        # Find corresponding scenario prices
        scenario_price_data = filter(scenario -> scenario["scenario"] == scenario_name, scenario_prices)
        
        if length(scenario_price_data) > 0
            avg_energy_prices = calculate_avg_energy_prices(scenario_price_data[1]["data"])
            capacity_prices = breakeven_df[!, "Capacity Price"]
            breakeven_times = breakeven_df[!, "Breakeven Time"]

            # Generate heatmap
            hm = heatmap(capacity_prices, avg_energy_prices, breakeven_times,
                         xlabel="Capacity Price (\$/kW-month)",
                         ylabel="Average Energy Price (\$/MWh)",
                         title=scenario_name,
                         color=:viridis)
                         
            push!(heatmaps, hm)
        end
    end

    # Check if heatmaps are generated
    if length(heatmaps) > 0
        plot_layout = layoutgrid(length(heatmaps), 1)  # Create a layout grid
        plot(heatmaps..., layout=plot_layout, size=(800, 600 * length(heatmaps)))
    else
        println("No heatmaps were generated.")
    end
end

"""
This function returns the 2023 Cambium price profiles for the SMRs
"""
function cambium23_prices()
    scenario_price_data_all = []
    scenario_price_data_temp = []

    for (index2, cost_array) in enumerate(smr_cost_vals)
        if index2 < 20
            smr_lifetime = Int64(cost_array[2])
            construction_duration = cost_array[7]
        else
            smr_lifetime = Int64(cost_array[2])
            construction_duration = cost_array[8]
        end

        start_reactor = Int(ceil((construction_duration)/12))

        for (index3, scenario) in enumerate(scenario_23_data_all)
            if length(scenario_price_data_temp) == 6
                scen_names_combined_index = Int((index3 - 1)/6)
                println(scen_names_combined_index)
                println("Scenario of $(scenario_names_23cambium[scen_names_combined_index]) for $(smr_names[index2]) is done")
                scenario_dict = Dict(
                    "smr" =>  "$(smr_names[index2])",
                    "scenario" => "$(scenario_names_23cambium[scen_names_combined_index])",
                    "data" => create_scenario_interpolated_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], (smr_lifetime + start_reactor))
                )

                push!(scenario_price_data_all, scenario_dict)
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end
        
        println("Scenario of $(last(scenario_names_23cambium)) for $(smr_names[index2]) is done")
        scenario_dict = Dict(
            "smr" =>  "$(smr_names[index2])",
            "scenario" => "$(last(scenario_names_23cambium))",
            "data" => create_scenario_interpolated_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], (smr_lifetime + start_reactor))
        )

        push!(scenario_price_data_all, scenario_dict)
        empty!(scenario_price_data_temp)
        
    end

    return scenario_price_data_all
end


# # Example usage:
# # Load your scenario prices and filtered cases
# filtered_cases = filter_and_extract_cases(results_cases())
# scenario_prices = all_scenario_prices()

# # Generate the heatmaps
# generate_heatmaps(filtered_cases, scenario_prices)
