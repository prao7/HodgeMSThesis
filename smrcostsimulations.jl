using DataFrames
using Statistics

@info("Importing in the functions needed to run simulation")
include("smrsimulationfunctions.jl")

@info("Importing the data needed for the functions")
include("data.jl")


##### run simulation #####
texas_payout, texas_output = smr_dispatch_iteration_one(texas_input_data,0.96,0.92,77,1.3,4)
println(smr_infodf)
npvtest, breakeventest = npv_calc(texas_payout,4,)

##### run simulation #####