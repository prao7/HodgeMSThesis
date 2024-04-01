using DataFrames
using Statistics
using Gurobi
using Plots

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
function smr_dispatch_iteration_two(price_data::Vector{Any}, module_size::Float64, number_of_modules::Int, fuel_cost::Float64, ancillary_services_included::Bool, production_credit::Float64)
    # Array to model when the SMR is operating vs. refueling
    operating_status = ones(length(price_data))
    
    # Array to contain the modules refueling times
    refueling_times_modules = zeros(number_of_modules)

    # Array for fuel prices
    fuel_cost_array = ones(length(price_data))

    # Array containing standard deviation range of fuel cost. Need to use this to calculate the fuel cost per day
    # Using this paper to define the fuel cost max and min standard deviation: https://www.scirp.org/html/2-6201621_45669.htm
    fuel_cost_sd_range = [0.091, 0.236]

    # Months to hours conversion
    months_to_hours = 730.485

    # Defining the ramp up or ramp down speed of the SMR - technically a multiplier
    #ru_cr = 502

    # Defining low power operation range
    lpo_smr = 0.6*module_size*number_of_modules

    # Array holding max and min refueling time. Based on the paper: https://www.sciencedirect.com/science/article/pii/S0360544223015013
    refueling_time_range = [15*months_to_hours, 18*months_to_hours]

    # Returned array with generator hourly payout
    generator_payout = []

    # Returned array with generator energy output
    generator_output = []

    # Creation of ancillary services array to be used in the dispatch
    if ancillary_services_included
        ancillary_services_payout = zeros(length(price_data))
        ancillary_services_output = zeros(length(price_data))
    end

    """
    Curating the fuel cost array. This is done by taking the fuel cost input and perturbing it by the standard deviation to create hourly fuel costs.
    The fuel cost is uniform across a day.
    """

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

    """
    Curating the operating status array. This is done by randomly choosing a refueling time between the range of refueling times.
    """
    # Calculating the lower quartile of the price data for comparison. The refueling should be done when the price is in the lower quartile
    q1 = quantile(price_data, 0.25)

    # Setting a variable denoting the hours to refuel
    refuel_time = 24

    for i in eachindex(refueling_times_modules)
        while true
            random_time = rand(refueling_time_range[1]:refueling_time_range[2])
            # Check if the corresponding price is lower than the lower quartile and the refueling time is not already in the refueling times array
            if price_data[random_time] < q1 && !(refueling_times_modules[i] + random_time in refueling_times_modules)
                # Adding refueling times to each module
                if refueling_times_modules[i] + random_time <= length(operating_status)
                    refueling_times_modules[i] += random_time
                    # TODO: Add in a block here to extend the refueling time for a day 
                    if refueling_times_modules[i] + refuel_time <= length(operating_status)
                        operating_status[refueling_times_modules[i]:(refueling_times_modules[i]+refuel_time)] = 0
                    else
                        operating_status[refueling_times_modules[i]:length(operating_status)] = 0
                    end 
                    continue
                else
                    break
                end
            end
        end
    end

    """
    Running dispatch formulation of the SMR to calculate the payout array.
    """

    # Index to track ancillary services for the conversion from 5 minutes to hourly data
    ancillaryservices_index = 1

    # This is the primary dispatch calculation loop
    for (index, value) in enumerate(price_data)
        # If the SMR is refueling, the operating status is 0. In this case, there is a single module shut down.
        if operating_status[index] == 1
            if ancillary_services_included
                # This will give a proportion of the energy generated to ancillary services
                if value >= fuel_cost_array[index] && value >= 
                    push!(generator_payout, (value*module_size*number_of_modules + production_credit*module_size*number_of_modules - fuel_cost_array[index]*module_size*number_of_modules))
                    push!(generator_output, module_size*number_of_modules)
                else
                    # If the price is lower than the fuel cost, the generator will ramp down to the low power operation range
                    push!(generator_payout, (value*lpo_smr + production_credit*lpo_smr - fuel_cost_array[index]*lpo_smr))
                    push!(generator_output, lpo_smr)
                end
            else
                # If the ancillary services are not included, normal dispatch
                if value >= fuel_cost_array[index]
                    push!(generator_payout, (value*module_size*number_of_modules + production_credit*module_size*number_of_modules - fuel_cost_array[index]*module_size*number_of_modules))
                    push!(generator_output, module_size*number_of_modules)
                else
                    # If the price is lower than the fuel cost, the generator will ramp down to the low power operation range
                    push!(generator_payout, (value*lpo_smr + production_credit*lpo_smr - fuel_cost_array[index]*lpo_smr))
                    push!(generator_output, lpo_smr)
                end

                # Need to add production credit according to dispatch
            end
        else
            if ancillary_services_included
                # This will give a proportion of the energy generated to ancillary services

            else
                # If the ancillary services are not included, normal dispatch minus one unit that is refueling
                if value >= fuel_cost_array[index]
                    push!(generator_payout, (value*module_size*(number_of_modules - 1) + production_credit*module_size*(number_of_modules-1) - fuel_cost_array[index]*module_size*(number_of_modules-1)))
                    push!(generator_output, module_size*number_of_modules)
                else
                    # If the price is lower than the fuel cost, the generator will ramp down to the low power operation range
                    #TODO: Amend LPO for one less module. Also, figure out how to push the same value for the next few loops.
                    push!(generator_payout, (value*lpo_smr + production_credit*lpo_smr - fuel_cost_array[index]*lpo_smr))
                    push!(generator_output, lpo_smr)
                end
                # Need to add production credit according to dispatch
            end
        end
    end
end

"""
The following function is a test of a optimization model for the dispatch of an SMR.
"""
function smr_dispatch_iteration_three()
    # This method will probably not be used as the approximation in the previous function is more realistic
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
function npv_calc(generator_payout::Vector{Any}, interest_rate::Float64, initial_investment::Float64, lifetime::Float64)
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


#= 
Need to build test cases for smr_dispatch_iteration_two
=#
