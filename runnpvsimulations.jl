using DataFrames
using Statistics
using CSV
using HTTP

include("smrcostsimulations.jl")
# include("dataprocessingfunctions.jl")

##### run simulation #####

"""
The first simulation runs all the SMR prototypes for their NPV's in all scenarios.
Comment out the below line if this particular analysis is not to be run. If the data 
needs to be inspected, paste the below line before analysis_npv_all_scenarios().

payouts_all_, generationOutput_all_, npv_tracker_all_, break_even_all_, npv_payoff_all_ =
"""
# payouts_all_test, generationOutput_all_test, npv_tracker_all_test, npv_payoff_all_test = analysis_npv_all_scenarios_iteration_one()
# payouts_all_test, generationOutput_all_test, npv_tracker_all_test, npv_payoff_all_test = analysis_npv_all_scenarios_iteration_two(0.04, 0.96, 0.92, true, false)


##### All cases described inside this method #####
analysis_sensitivity_npv_breakeven()
##### All cases described inside this method #####

##### Running the Heatmaps #####
# analysis_construction_cost_vs_breakeven()
##### Running the Heatmaps #####

# ##### run simulation #####


# # Project   Type     Capacity [MWel]  Lifetime [years]  Construction Cost [USD2020/MWel]  Fuel cost [USD2020/MWh]  O&M cost [USD2020/MWel]