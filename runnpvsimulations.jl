using DataFrame
using Statistics
using CSV
using HTTP

include("data.jl")
include("smrcostsimulations.jl")

##### run simulation #####
texas_payout, texas_output = smr_dispatch_iteration_one(texas_input_data,0.96,0.92,77,1.3,4)
#println(texas_payout)
npvtest, breakeventest, lifetimenpvtest = npv_calc(texas_payout,0.04,1122843260,60)

println(npvtest) 
println(breakeventest)
println(lifetimenpvtest)
##### run simulation #####


# Project   Type     Capacity [MWel]  Lifetime [years]  Construction Cost [USD2020/MWel]  Fuel cost [USD2020/MWh]  O&M cost [USD2020/MWel] 