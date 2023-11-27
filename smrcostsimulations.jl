using DataFrames
using Statistics

@info("Importing in the functions needed to run simulation")
include("smrsimulationfunctions.jl")

@info("Importing the data needed for the functions")
include("data.jl")


##### run simulation #####
texas_payout, texas_output = smr_dispatch_iteration_one(texas_input_data,0.96,0.92,77,1.3,4)
#println(texas_payout)
npvtest, breakeventest, lifetimenpvtest = npv_calc(texas_payout,0.04,1122843260,60)

println(npvtest) 
println(breakeventest)
println(lifetimenpvtest)
##### run simulation #####