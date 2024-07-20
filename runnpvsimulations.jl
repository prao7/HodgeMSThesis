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
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, true, "6%", false)
##### Analysis taking in locations with ITC credits - 6% #####

##### Analysis taking in locations with ITC credits - 30% #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, true, "30%", false)
##### Analysis taking in locations with ITC credits - 30% #####

##### Analysis taking in locations with ITC credits - 40% #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, true, "40%", false)
##### Analysis taking in locations with ITC credits - 40% #####

##### Analysis taking in locations with ITC credits - 50% #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, true, "50%", false)
##### Analysis taking in locations with ITC credits - 50% #####



##### Analysis taking in if a Coal to Nuclear Plant is built #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", true)
##### Analysis taking in if a Coal to Nuclear Plant is built #####



##### PTC of $11/MWh for 10 years #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 11.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $11/MWh for 10 years #####

##### PTC of $12/MWh for 10 years #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 12.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $12/MWh for 10 years #####

##### PTC of $13/MWh for 10 years #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 13.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $13/MWh for 10 years #####

##### PTC of $14/MWh for 10 years #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 14.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $14/MWh for 10 years #####

##### PTC of $15/MWh for 10 years #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $14/MWh for 10 years #####

##### PTC of $16/MWh for 10 years #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 16.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $16/MWh for 10 years #####

##### PTC of $17/MWh for 10 years #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 17.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $17/MWh for 10 years #####

##### PTC of $18/MWh for 10 years #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 18.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $18/MWh for 10 years #####

##### PTC of $19/MWh for 10 years #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 19.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $19/MWh for 10 years #####

##### PTC of $20/MWh for 10 years #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 20.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $20/MWh for 10 years #####

##### PTC of $21/MWh for 10 years #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 21.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $21/MWh for 10 years #####

##### PTC of $22/MWh for 10 years #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 22.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $22/MWh for 10 years #####

##### PTC of $23/MWh for 10 years #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 23.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $23/MWh for 10 years #####

##### PTC of $24/MWh for 10 years #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 24.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $24/MWh for 10 years #####

##### PTC of $25/MWh for 10 years #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 25.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $25/MWh for 10 years #####

##### PTC of $26/MWh for 10 years #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 26.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $26/MWh for 10 years #####

##### PTC of $27.5/MWh for 10 years #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 27.5, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $27.5/MWh for 10 years #####

##### PTC of $28.05/MWh for 10 years #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 28.05, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $28.05/MWh for 10 years #####

##### PTC of $30.05/MWh for 10 years #####
#payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 30.05, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $30.05/MWh for 10 years #####

##### PTC of $33.0/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 33.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false)
##### PTC of $33.0/MWh for 10 years #####



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