using DataFrames
using Statistics
using CSV
using HTTP

include("smrcostsimulations.jl")

##### run simulation #####

"""
The first simulation runs all the SMR prototypes for their NPV's in all scenarios.
Comment out the below line if this particular analysis is not to be run. If the data 
needs to be inspected, paste the below line before analysis_npv_all_scenarios().

payouts_all_, generationOutput_all_, npv_tracker_all_, break_even_all_, npv_payoff_all_ =
"""
# payouts_all_test, generationOutput_all_test, npv_tracker_all_test, npv_payoff_all_test = analysis_npv_all_scenarios_iteration_one()
# payouts_all_test, generationOutput_all_test, npv_tracker_all_test, npv_payoff_all_test = analysis_npv_all_scenarios_iteration_two(0.04, 0.96, 0.92, true, false)

##### Baseline Analysis #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, true, false, "", false)
##### Baseline Analysis #####

##### Analysis adding in multi-modular SMR learning benefits #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, true, false, "", false)
##### Analysis adding in multi-modular SMR learning benefits #####

##### Analysis taking in locations with ITC credits - 6% #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, true, "6%", false)
##### Analysis taking in locations with ITC credits - 6% #####

##### Analysis taking in locations with ITC credits - 30% #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, true, "30%", false)
##### Analysis taking in locations with ITC credits - 30% #####


# println("NPV Tracker All: ", npv_tracker_all)
# println("NPV Payoff All: ", npv_payoff_all)
# println("Payouts All: ", length(payouts_all))
# println("Generation Output All: ", length(generationOutput_all))

##### Baseline Analysis #####

##### Sensitivity Analysis #####
#analysis_sensitivity_npv_breakeven()
##### Sensitivity Analysis #####

##### run simulation #####


# Project   Type     Capacity [MWel]  Lifetime [years]  Construction Cost [USD2020/MWel]  Fuel cost [USD2020/MWh]  O&M cost [USD2020/MWel]