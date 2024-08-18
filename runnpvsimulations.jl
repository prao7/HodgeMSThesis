using DataFrames
using Statistics
using CSV
using HTTP

include("smrcostsimulations.jl")
include("dataprocessingfunctions.jl")

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
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
baseline_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "baseline_breakeven")
baseline_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "baseline_npv_final")
baseline_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "baseline_irr")
##### Baseline Analysis #####

##### Analysis adding in multi-modular SMR learning benefits #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, true, false, "", false)
mmlearning_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "mmlearning_breakeven")
mmlearning_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "mmlearning_npv_final")
mmlearning_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "mmlearning_irr")
##### Analysis adding in multi-modular SMR learning benefits #####

##### Analysis for Coal2Nuclear plants #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, true, false, "", true)
c2n_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "c2n_breakeven")
c2n_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "c2n_npv_final")
c2n_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "c2n_irr")
##### Analysis adding in multi-modular SMR learning benefits #####


##### Analysis taking in locations with ITC credits - 6% #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, true, "6%", false)
itc6_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc_breakeven")
itc6_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc_npv_final")
itc6_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc_irr")
##### Analysis taking in locations with ITC credits - 6% #####

##### Analysis taking in locations with ITC credits - 30% #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, true, "30%", false)
itc30_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc30_breakeven")
itc30_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc30_npv_final")
itc30_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc30_irr")
##### Analysis taking in locations with ITC credits - 30% #####

##### Analysis taking in locations with ITC credits - 40% #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, true, "40%", false)
itc40_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc40_breakeven")
itc40_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc40_npv_final")
itc40_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc40_irr")
##### Analysis taking in locations with ITC credits - 40% #####

##### Analysis taking in locations with ITC credits - 50% #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, true, "50%", false)
itc50_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc50_breakeven")
itc50_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc50_npv_final")
itc50_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc50_irr")
##### Analysis taking in locations with ITC credits - 50% #####





##### PTC of $11/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 11.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc11_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc11_breakeven")
ptc11_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc11_npv_final")
ptc11_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc11_irr")
##### PTC of $11/MWh for 10 years #####

##### PTC of $12/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 12.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc12_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc12_breakeven")
ptc12_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc12_npv_final")
ptc12_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc12_irr")
##### PTC of $12/MWh for 10 years #####

##### PTC of $13/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 13.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc13_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc13_breakeven")
ptc13_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc13_npv_final")
ptc13_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc13_irr")
##### PTC of $13/MWh for 10 years #####

##### PTC of $14/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 14.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc14_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc14_breakeven")
ptc14_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc14_npv_final")
ptc14_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc14_irr")
##### PTC of $14/MWh for 10 years #####

##### PTC of $15/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc15_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc15_breakeven")
ptc15_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc15_npv_final")
ptc15_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc15_irr")
##### PTC of $14/MWh for 10 years #####

##### PTC of $16/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 16.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc16_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc16_breakeven")
ptc16_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc16_npv_final")
ptc16_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc16_irr")
##### PTC of $16/MWh for 10 years #####

##### PTC of $17/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 17.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc17_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc17_breakeven")
ptc17_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc17_npv_final")
ptc17_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc17_irr")
##### PTC of $17/MWh for 10 years #####

##### PTC of $18/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 18.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc18_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc18_breakeven")
ptc18_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc18_npv_final")
ptc18_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc18_irr")
##### PTC of $18/MWh for 10 years #####

##### PTC of $19/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 19.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc19_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc19_breakeven")
ptc19_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc19_npv_final")
ptc19_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc19_irr")
##### PTC of $19/MWh for 10 years #####

##### PTC of $20/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 20.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc20_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc20_breakeven")
ptc20_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc20_npv_final")
ptc20_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc20_irr")
##### PTC of $20/MWh for 10 years #####

##### PTC of $21/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 21.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc21_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc21_breakeven")
ptc21_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc21_npv_final")
ptc21_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc21_irr")
##### PTC of $21/MWh for 10 years #####

##### PTC of $22/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 22.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc22_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc22_breakeven")
ptc22_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc22_npv_final")
ptc22_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc22_irr")
##### PTC of $22/MWh for 10 years #####

##### PTC of $23/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 23.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc23_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc23_breakeven")
ptc23_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc23_npv_final")
ptc23_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc23_irr")
##### PTC of $23/MWh for 10 years #####

##### PTC of $24/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 24.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc24_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc24_breakeven")
ptc24_npv_final = export_npv_final_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc24_npv_final")
ptc24_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc24_irr")
##### PTC of $24/MWh for 10 years #####

##### PTC of $25/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 25.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc25_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc25_breakeven")
ptc25_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc25_npv_final")
ptc25_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc25_irr")
##### PTC of $25/MWh for 10 years #####

##### PTC of $26/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 26.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc26_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc26_breakeven")
ptc26_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc26_npv_final")
ptc26_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc26_irr")
##### PTC of $26/MWh for 10 years #####

##### PTC of $27.5/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 27.5, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc275_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc27.5_breakeven")
ptc275_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc27.5_npv_final")
ptc275_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc27.5_irr")
##### PTC of $27.5/MWh for 10 years #####

##### PTC of $28.05/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 28.05, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc2805_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc28.05_breakeven")
ptc2805_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc28.05_npv_final")
ptc2805_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc28.05_irr")
##### PTC of $28.05/MWh for 10 years #####

##### PTC of $30.05/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 30.05, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc3005_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc30.05_breakeven")
ptc3005_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc30.05_npv_final")
ptc3005_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc30.05_irr")
##### PTC of $30.05/MWh for 10 years #####

##### PTC of $33.0/MWh for 10 years #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 33.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
ptc33_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc33_breakeven")
ptc33_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc33_npv_final")
ptc33_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc33_irr")
##### PTC of $33.0/MWh for 10 years #####




##### Capacity Market of $1.0/kW-month #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 1.0, false, false, false, "", false)
cm1_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm1_breakeven")
cm1_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm1_npv_final")
cm1_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm1_irr")
##### Capacity Market of $1.0/kW-month #####

##### Capacity Market of $2.0/kW-month #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 2.0, false, false, false, "", false)
cm2 = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm2_breakeven")
cm2_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm2_npv_final")
cm2_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm2_irr")
##### Capacity Market of $2.0/kW-month #####

##### Capacity Market of $3.0/kW-month #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 3.0, false, false, false, "", false)
cm3_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm3_breakeven")
cm3_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm3_npv_final")
cm3_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm3_irr")
##### Capacity Market of $3.0/kW-month #####

##### Capacity Market of $4.0/kW-month #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 4.0, false, false, false, "", false)
cm4_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm4_breakeven")
cm4_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm4_npv_final")
cm4_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm4_irr")
##### Capacity Market of $4.0/kW-month #####

##### Capacity Market of $5.0/kW-month #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, false, false, false, "", false)
cm5_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm5_breakeven")
cm5_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm5_npv_final")
cm5_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm5_irr")
##### Capacity Market of $5.0/kW-month #####

##### Capacity Market of $6.0/kW-month #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 6.0, false, false, false, "", false)
cm6_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm6_breakeven")
cm6_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm6_npv_final")
cm6_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm6_irr")
##### Capacity Market of $6.0/kW-month #####

##### Capacity Market of $7.0/kW-month #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 7.0, false, false, false, "", false)
cm7_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm7_breakeven")
cm7_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm7_npv_final")
cm7_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm7_irr")
##### Capacity Market of $7.0/kW-month #####

##### Capacity Market of $8.0/kW-month #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 8.0, false, false, false, "", false)
cm8_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm8_breakeven")
cm8_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm8_npv_final")
cm8_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm8_irr")
##### Capacity Market of $8.0/kW-month #####

##### Capacity Market of $15.0/kW-month #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 15.0, false, false, false, "", false)
cm15_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm15_breakeven")
cm15_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm15_npv_final")
cm15_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm15_irr")
##### Capacity Market of $15.0/kW-month #####

##### Capacity Market of $16.0/kW-month #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 16.0, false, false, false, "", false)
cm16_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm16_breakeven")
cm16_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm16_npv_final")
cm16_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm16_irr")
##### Capacity Market of $16.0/kW-month #####

##### Capacity Market of $21.0/kW-month #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 21.0, false, false, false, "", false)
cm21_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm21_breakeven")
cm21_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm21_npv_final")
cm21_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm21_irr")
##### Capacity Market of $21.0/kW-month #####

##### Capacity Market of $22.0/kW-month #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 22.0, false, false, false, "", false)
cm22_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm22_breakeven")
cm22_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm22_npv_final")
cm22_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm22_irr")
##### Capacity Market of $22.0/kW-month #####

##### Multi-modular, C2N, PTC $15/MWh and Capacity Market of $5.0/kW-month #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, false, true, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case1")
synthetic_case1_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case1_breakeven")
synthetic_case1_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case1_npv_final")
synthetic_case1_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case1_irr")
##### Multi-modular, C2N, PTC $15/MWh and Capacity Market of $5.0/kW-month #####

# println("NPV Final All: ", npv_final_all)
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