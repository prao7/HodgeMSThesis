using DataFrames
using Statistics

# For testing, including Data.jl and dataprocessingfunctions.jl
include("data.jl")
include("dataprocessingfunctions.jl")

"""
This function details how a basic dispatch and payout of an SMR would be in response to prices. This function
needs to be further evaluated for a more realistic approach to SMR dispatch.
"""
function smr_dispatch_iteration_one(price_data::Vector{Any}, no_ramping_cf::Float64, ramping_cf::Float64, module_size::Float64, price_multiplication_factor::Float64, number_of_modules::Int)
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

"""
Testing npv_calc_scenario
"""
"""
# Name of column extracted
column_name_cambium = "total_cost_busbar"

# payout scenario array 
full_scenario_dispatch = []

# Creating a combined scenario array
test_scenario_array = create_scenario_array(array_from_dataframe(elec_2024df, column_name_cambium), array_from_dataframe(elec_2026df, column_name_cambium), array_from_dataframe(elec_2028df, column_name_cambium), array_from_dataframe(elec_2030df, column_name_cambium), array_from_dataframe(elec_2035df, column_name_cambium), array_from_dataframe(elec_2040df, column_name_cambium), array_from_dataframe(elec_2045df, column_name_cambium), array_from_dataframe(elec_2050df, column_name_cambium), 60)

# SMR dispatch
payout_array_test, generation_output_array_test = smr_dispatch_iteration_one(test_scenario_array, 0.92, 0.96, 443.0, 1.3, 1)

# Testing with UK SMR
npv_tracker_test, break_even_test, npv_payoff_test = npv_calc_scenario(test_scenario_array, 0.05, initial_investment_calculation(443.0, 5215937.0, 518242.0, 1), 60.0)

println("NPV Tracker: ", npv_tracker_test)
println("Break Even: ", break_even_test)
println("NPV Payoff: ", sum(npv_payoff_test))
"""