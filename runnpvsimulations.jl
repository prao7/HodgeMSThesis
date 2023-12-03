using DataFrames
using Statistics
using CSV
using HTTP

include("data.jl")
include("smrcostsimulations.jl")

##### run simulation #####

"""
The first simulation runs all the SMR prototypes for their NPV's in all scenarios.
Comment out the below line if this particular analysis is not to be run. If the data 
needs to be inspected, paste the below line before analysis_npv_all_scenarios().

payouts_all_test, generationOutput_all_test, npv_tracker_all_test, break_even_all_test, npv_payoff_all_test =
"""
payouts_all_test, generationOutput_all_test, npv_tracker_all_test, break_even_all_test, npv_payoff_all_test = analysis_npv_all_scenarios()

##### run simulation #####


# Project   Type     Capacity [MWel]  Lifetime [years]  Construction Cost [USD2020/MWel]  Fuel cost [USD2020/MWh]  O&M cost [USD2020/MWel] 