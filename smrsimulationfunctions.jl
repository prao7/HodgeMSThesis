using DataFrames
using Statistics

# Importing data from data.jl
@info("Bringing in data for simulations")
include("data.jl")

# Importing the dataprocessingfunctions.jl TODO: Perhaps delete if unneccesary
@info("Importing the functions necessary for the simulation")
include("dataprocessingfunctions.jl")

"""
This function details how a basic dispatch and payout of a generator would be 
"""
function smr_dispatch_iteration_one(price_data::Vector{Float64}, no_ramping_cf::Float64, ramping_cf::Float64, module_size::Int, price_multiplication_factor::Float64, number_of_modules::Int)
    # Returned array with generator hourly payout
    generator_payout = []

    # Returned array with generator energy output
    generator_output = []

    # An assumption made here is a flat value where ramping is acceptable
    ramping_price = price_multiplication_factor*mean(price_data)

    # This loop will calculate the 
    for value in price_data
        # Add in calculation of hourly payout and generator dispatch

        if value >= ramping_price
            # Adding to the array the payout from ramped generation
            push!(generator_payout, value*ramping_cf*module_size*number_of_modules)

            # Generation hourly added to the array
            push!(generator_output, ramping_cf*module_size*number_of_modules)
        else
            # Adding the payout from the non ramped generation
            push!(generator_payout, value*no_ramping_cf*module_size*number_of_modules)

            # Generation output from the non ramped generation
            push!(generator_output, no_ramping_cf*module_size*number_of_modules)
        end
    end

    return generator_payout, generator_output
end