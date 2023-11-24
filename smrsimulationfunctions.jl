using DataFrames
using Statistics


"""
# Importing data from data.jl TODO: Delete if unneccesary
@info("Bringing in data for simulations")
include("data.jl")

# Importing the dataprocessingfunctions.jl TODO: Perhaps delete if unneccesary
@info("Importing the functions necessary for the simulation")
include("dataprocessingfunctions.jl")
"""


"""
This function details how a basic dispatch and payout of an SMR would be in response to prices. This function
needs to be further evaluated for a more realistic approach to SMR dispatch.
"""
function smr_dispatch_iteration_one(price_data::Vector{Float64}, no_ramping_cf::Float64, ramping_cf::Float64, module_size::Int, price_multiplication_factor::Float64, number_of_modules::Int)
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
This function returns the NPV and break even for a generator based on the payout, interest rate input
and capital and O&M cost calulation. 
"""
function npv_calc(generator_payout::Vector{Any}, interest_rate::Int, initial_investment::Int, lifetime::Int)
    # First, create an empty array for the NPV per year tracker
    npv_tracker = []

    # Empty break even tracker
    break_even = 0

    # This is the cost of the initial investment that the payoff will need to recoup
    lifetime_npv = initial_investment*(-1)
    for index in 1:lifetime # need to change that in range to lifetime
        # TODO: Need to check if this equation will yield a correct NPV
        push!(npv_tracker, (sum(generator_payout)/((1+interest_rate)^index))-initial_investment)
        
        # This will show the lifetime npv 
        lifetime_npv+=(sum(generator_payout)/((1+interest_rate)^index))
    end

    # This is the break even calculator
    for (index, value) in enumerate(npv_tracker)
        if value >=0
            break_even = index
            break
        end
    end
    
    return npv_tracker, break_even, lifetime_npv
end