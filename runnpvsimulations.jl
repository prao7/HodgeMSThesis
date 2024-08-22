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

# ##### Baseline Analysis #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# baseline_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "baseline_breakeven")
# baseline_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "baseline_npv_final")
# baseline_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "baseline_irr")
# ##### Baseline Analysis #####

# ##### Analysis adding in multi-modular SMR learning benefits #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, true, false, "", false)
# mmlearning_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "mmlearning_breakeven")
# mmlearning_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "mmlearning_npv_final")
# mmlearning_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "mmlearning_irr")
# ##### Analysis adding in multi-modular SMR learning benefits #####

# ##### Analysis for Coal2Nuclear plants #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, true, false, "", true)
# c2n_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "c2n_breakeven")
# c2n_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "c2n_npv_final")
# c2n_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "c2n_irr")
# ##### Analysis adding in multi-modular SMR learning benefits #####


# ##### Analysis taking in locations with ITC credits - 6% #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, true, "6%", false)
# itc6_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc_breakeven")
# itc6_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc_npv_final")
# itc6_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc_irr")
# ##### Analysis taking in locations with ITC credits - 6% #####

# ##### Analysis taking in locations with ITC credits - 30% #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, true, "30%", false)
# itc30_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc30_breakeven")
# itc30_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc30_npv_final")
# itc30_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc30_irr")
# ##### Analysis taking in locations with ITC credits - 30% #####

# ##### Analysis taking in locations with ITC credits - 40% #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, true, "40%", false)
# itc40_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc40_breakeven")
# itc40_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc40_npv_final")
# itc40_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc40_irr")
# ##### Analysis taking in locations with ITC credits - 40% #####

# ##### Analysis taking in locations with ITC credits - 50% #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, true, "50%", false)
# itc50_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc50_breakeven")
# itc50_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc50_npv_final")
# itc50_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc50_irr")
# ##### Analysis taking in locations with ITC credits - 50% #####





# ##### PTC of $11/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 11.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc11_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc11_breakeven")
# ptc11_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc11_npv_final")
# ptc11_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc11_irr")
# ##### PTC of $11/MWh for 10 years #####

# ##### PTC of $12/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 12.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc12_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc12_breakeven")
# ptc12_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc12_npv_final")
# ptc12_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc12_irr")
# ##### PTC of $12/MWh for 10 years #####

# ##### PTC of $13/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 13.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc13_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc13_breakeven")
# ptc13_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc13_npv_final")
# ptc13_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc13_irr")
# ##### PTC of $13/MWh for 10 years #####

# ##### PTC of $14/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 14.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc14_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc14_breakeven")
# ptc14_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc14_npv_final")
# ptc14_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc14_irr")
# ##### PTC of $14/MWh for 10 years #####

# ##### PTC of $15/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc15_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc15_breakeven")
# ptc15_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc15_npv_final")
# ptc15_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc15_irr")
# ##### PTC of $14/MWh for 10 years #####

# ##### PTC of $16/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 16.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc16_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc16_breakeven")
# ptc16_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc16_npv_final")
# ptc16_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc16_irr")
# ##### PTC of $16/MWh for 10 years #####

# ##### PTC of $17/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 17.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc17_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc17_breakeven")
# ptc17_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc17_npv_final")
# ptc17_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc17_irr")
# ##### PTC of $17/MWh for 10 years #####

# ##### PTC of $18/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 18.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc18_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc18_breakeven")
# ptc18_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc18_npv_final")
# ptc18_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc18_irr")
# ##### PTC of $18/MWh for 10 years #####

# ##### PTC of $19/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 19.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc19_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc19_breakeven")
# ptc19_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc19_npv_final")
# ptc19_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc19_irr")
# ##### PTC of $19/MWh for 10 years #####

# ##### PTC of $20/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 20.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc20_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc20_breakeven")
# ptc20_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc20_npv_final")
# ptc20_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc20_irr")
# ##### PTC of $20/MWh for 10 years #####

# ##### PTC of $21/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 21.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc21_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc21_breakeven")
# ptc21_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc21_npv_final")
# ptc21_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc21_irr")
# ##### PTC of $21/MWh for 10 years #####

# ##### PTC of $22/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 22.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc22_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc22_breakeven")
# ptc22_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc22_npv_final")
# ptc22_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc22_irr")
# ##### PTC of $22/MWh for 10 years #####

# ##### PTC of $23/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 23.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc23_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc23_breakeven")
# ptc23_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc23_npv_final")
# ptc23_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc23_irr")
# ##### PTC of $23/MWh for 10 years #####

# ##### PTC of $24/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 24.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc24_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc24_breakeven")
# ptc24_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc24_npv_final")
# ptc24_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc24_irr")
# ##### PTC of $24/MWh for 10 years #####

# ##### PTC of $25/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 25.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc25_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc25_breakeven")
# ptc25_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc25_npv_final")
# ptc25_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc25_irr")
# ##### PTC of $25/MWh for 10 years #####

# ##### PTC of $26/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 26.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc26_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc26_breakeven")
# ptc26_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc26_npv_final")
# ptc26_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc26_irr")
# ##### PTC of $26/MWh for 10 years #####

# ##### PTC of $27.5/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 27.5, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc275_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc27.5_breakeven")
# ptc275_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc27.5_npv_final")
# ptc275_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc27.5_irr")
# ##### PTC of $27.5/MWh for 10 years #####

# ##### PTC of $28.05/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 28.05, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc2805_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc28.05_breakeven")
# ptc2805_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc28.05_npv_final")
# ptc2805_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc28.05_irr")
# ##### PTC of $28.05/MWh for 10 years #####

# ##### PTC of $30.05/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 30.05, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc3005_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc30.05_breakeven")
# ptc3005_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc30.05_npv_final")
# ptc3005_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc30.05_irr")
# ##### PTC of $30.05/MWh for 10 years #####

# ##### PTC of $33.0/MWh for 10 years #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 33.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
# ptc33_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc33_breakeven")
# ptc33_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc33_npv_final")
# ptc33_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc33_irr")
# ##### PTC of $33.0/MWh for 10 years #####




# ##### Capacity Market of $1.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 1.0, false, false, false, "", false)
# cm1_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm1_breakeven")
# cm1_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm1_npv_final")
# cm1_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm1_irr")
# ##### Capacity Market of $1.0/kW-month #####

# ##### Capacity Market of $2.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 2.0, false, false, false, "", false)
# cm2 = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm2_breakeven")
# cm2_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm2_npv_final")
# cm2_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm2_irr")
# ##### Capacity Market of $2.0/kW-month #####

# ##### Capacity Market of $3.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 3.0, false, false, false, "", false)
# cm3_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm3_breakeven")
# cm3_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm3_npv_final")
# cm3_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm3_irr")
# ##### Capacity Market of $3.0/kW-month #####

# ##### Capacity Market of $4.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 4.0, false, false, false, "", false)
# cm4_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm4_breakeven")
# cm4_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm4_npv_final")
# cm4_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm4_irr")
# ##### Capacity Market of $4.0/kW-month #####

# ##### Capacity Market of $5.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, false, false, false, "", false)
# cm5_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm5_breakeven")
# cm5_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm5_npv_final")
# cm5_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm5_irr")
# ##### Capacity Market of $5.0/kW-month #####

# ##### Capacity Market of $6.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 6.0, false, false, false, "", false)
# cm6_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm6_breakeven")
# cm6_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm6_npv_final")
# cm6_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm6_irr")
# ##### Capacity Market of $6.0/kW-month #####

# ##### Capacity Market of $7.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 7.0, false, false, false, "", false)
# cm7_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm7_breakeven")
# cm7_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm7_npv_final")
# cm7_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm7_irr")
# ##### Capacity Market of $7.0/kW-month #####

# ##### Capacity Market of $8.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 8.0, false, false, false, "", false)
# cm8_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm8_breakeven")
# cm8_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm8_npv_final")
# cm8_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm8_irr")
# ##### Capacity Market of $8.0/kW-month #####

# ##### Capacity Market of $15.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 15.0, false, false, false, "", false)
# cm15_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm15_breakeven")
# cm15_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm15_npv_final")
# cm15_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm15_irr")
# ##### Capacity Market of $15.0/kW-month #####

# ##### Capacity Market of $16.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 16.0, false, false, false, "", false)
# cm16_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm16_breakeven")
# cm16_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm16_npv_final")
# cm16_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm16_irr")
# ##### Capacity Market of $16.0/kW-month #####

# ##### Capacity Market of $17.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 17.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd17kW_month")
# cm17_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm17_breakeven")
# cm17_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm17_npv_final")
# cm17_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm17_irr")
# ##### Capacity Market of $17.0/kW-month #####

# ##### Capacity Market of $18.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 18.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd18kW_month")
# cm18_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm18_breakeven")
# cm18_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm18_npv_final")
# cm18_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm18_irr")
# ##### Capacity Market of $18.0/kW-month #####

# ##### Capacity Market of $19.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 19.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd19kW_month")
# cm19_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm19_breakeven")
# cm19_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm19_npv_final")
# cm19_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm19_irr")
# ##### Capacity Market of $19.0/kW-month #####

# ##### Capacity Market of $20.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 20.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd20kW_month")
# cm20_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm20_breakeven")
# cm20_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm20_npv_final")
# cm20_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm20_irr")
# ##### Capacity Market of $20.0/kW-month #####

# ##### Capacity Market of $21.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 21.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd21kW_month")
# cm21_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm21_breakeven")
# cm21_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm21_npv_final")
# cm21_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm21_irr")
# ##### Capacity Market of $21.0/kW-month #####

# ##### Capacity Market of $22.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 22.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd22kW_month")
# cm22_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm22_breakeven")
# cm22_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm22_npv_final")
# cm22_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm22_irr")
# ##### Capacity Market of $22.0/kW-month #####

# ##### Capacity Market of $23.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd23kW_month")
# cm23_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm23_breakeven")
# cm23_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm23_npv_final")
# cm23_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm23_irr")
# ##### Capacity Market of $23.0/kW-month #####

# ##### Capacity Market of $25.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd25kW_month")
# cm25_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm25_breakeven")
# cm25_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm25_npv_final")
# cm25_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm25_irr")
# ##### Capacity Market of $25.0/kW-month #####

# ##### Learning Rates reducing construction costs by 5% #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.95, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll5_case")
# ll5_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll5_breakeven")
# ll5_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll5_npv_final")
# ll5_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll5_irr")
# ##### Learning Rates reducing construction costs by 5% #####

# ##### Learning Rates reducing construction costs by 10% #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.90, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll10_case")
# ll10_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll10_breakeven")
# ll10_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll10_npv_final")
# ll10_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll10_irr")
# ##### Learning Rates reducing construction costs by 10% #####

# ##### Learning Rates reducing construction costs by 15% #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.85, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll15_case")
# ll15_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll15_breakeven")
# ll15_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll15_npv_final")
# ll15_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll15_irr")
# ##### Learning Rates reducing construction costs by 15% #####

# ##### Learning Rates reducing construction costs by 20% #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.80, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll20_case")
# ll20_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll20_breakeven")
# ll20_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll20_npv_final")
# ll20_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll20_irr")
# ##### Learning Rates reducing construction costs by 20% #####

# ##### Learning Rates reducing construction costs by 25% #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.75, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll25_case")
# ll25_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll25_breakeven")
# ll25_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll25_npv_final")
# ll25_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll25_irr")
# ##### Learning Rates reducing construction costs by 25% #####

# ##### Learning Rates reducing construction costs by 30% #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.70, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll30_case")
# ll30_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll30_breakeven")
# ll30_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll30_npv_final")
# ll30_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll30_irr")
# ##### Learning Rates reducing construction costs by 30% #####

# ##### Learning Rates reducing construction costs by 35% #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.65, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll35_case")
# ll35_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll35_breakeven")
# ll35_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll35_npv_final")
# ll35_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll35_irr")
# ##### Learning Rates reducing construction costs by 35% #####

# ##### Learning Rates reducing construction costs by 40% #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.60, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll40_case")
# ll40_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll40_breakeven")
# ll40_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll40_npv_final")
# ll40_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll40_irr")
# ##### Learning Rates reducing construction costs by 40% #####

# ##### Learning Rates reducing construction costs by 45% #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.55, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll45_case")
# ll45_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll45_breakeven")
# ll45_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll45_npv_final")
# ll45_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll45_irr")
# ##### Learning Rates reducing construction costs by 45% #####

# ##### Learning Rates reducing construction costs by 50% #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.50, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll50_case")
# ll50_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll50_breakeven")
# ll50_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll50_npv_final")
# ll50_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll50_irr")
# ##### Learning Rates reducing construction costs by 50% #####

# ##### Learning Rates reducing construction costs by 55% #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.45, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll55_case")
# ll55_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll55_breakeven")
# ll55_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll55_npv_final")
# ll55_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll55_irr")
# ##### Learning Rates reducing construction costs by 55% #####

# ##### Learning Rates reducing construction costs by 60% #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.40, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll60_case")
# ll60_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll60_breakeven")
# ll60_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll60_npv_final")
# ll60_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll60_irr")
# ##### Learning Rates reducing construction costs by 60% #####

# ##### Learning Rates reducing construction costs by 65% #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.35, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll65_case")
# ll65_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll65_breakeven")
# ll65_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll65_npv_final")
# ll65_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll65_irr")
# ##### Learning Rates reducing construction costs by 65% #####

# ##### Learning Rates reducing construction costs by 70% #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.30, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll70_case")
# ll70_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll70_breakeven")
# ll70_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll70_npv_final")
# ll70_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll70_irr")
# ##### Learning Rates reducing construction costs by 70% #####

# ##### Learning Rates reducing construction costs by 75% #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.25, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll75_case")
# ll75_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll75_breakeven")
# ll75_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll75_npv_final")
# ll75_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll75_irr")
# ##### Learning Rates reducing construction costs by 75% #####

# ############### Synthetic Cases ################


# ##### Synthetic Case 1: Multi-modular, PTC $15/MWh and Capacity Market of $5.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, true, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case1")
# synthetic_case1_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case1_breakeven")
# synthetic_case1_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case1_npv_final")
# synthetic_case1_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case1_irr")
# ##### Synthetic Case 1: Multi-modular, C2N, PTC $15/MWh and Capacity Market of $5.0/kW-month #####

# ##### Synthetic Case 2: Multi-modular, C2N, PTC $15/MWh and Capacity Market of $5.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, true, true, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case2")
# synthetic_case2_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case2_breakeven")
# synthetic_case2_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case2_npv_final")
# synthetic_case2_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case2_irr")
# ##### Synthetic Case 2: Multi-modular, C2N, PTC $15/MWh and Capacity Market of $5.0/kW-month #####

# ##### Synthetic Case 3: Multi-modular, C2N, ITC 6%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, true, true, true, "6%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case3")
# synthetic_case3_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case3_breakeven")
# synthetic_case3_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case3_npv_final")
# synthetic_case3_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case3_irr")
# ##### Synthetic Case 3: Multi-modular, C2N, ITC 6%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####

# ##### Synthetic Case 4: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, true, true, true, "30%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case4")
# synthetic_case4_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case4_breakeven")
# synthetic_case4_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case4_npv_final")
# synthetic_case4_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case4_irr")
# ##### Synthetic Case 4: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####

# ##### Synthetic Case 5: Multi-modular, C2N, ITC 40%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, true, true, true, "40%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case5")
# synthetic_case5_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case5_breakeven")
# synthetic_case5_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case5_npv_final")
# synthetic_case5_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case5_irr")
# ##### Synthetic Case 5: Multi-modular, C2N, ITC 40%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####

# ##### Synthetic Case 6: Multi-modular, C2N, ITC 50%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, true, true, true, "40%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case6")
# synthetic_case6_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case6_breakeven")
# synthetic_case6_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case6_npv_final")
# synthetic_case6_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case6_irr")
# ##### Synthetic Case 6: Multi-modular, C2N, ITC 50%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####

##### Synthetic Case 7: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $15.0/kW-month #####
payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 15.0, true, true, true, "30%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case7")
synthetic_case7_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case7_breakeven")
synthetic_case7_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case7_npv_final")
synthetic_case7_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case7_irr")
##### Synthetic Case 7: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $15.0/kW-month #####

# ##### Synthetic Case 8: Multi-modular, C2N, ITC 30%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 27.5, true, true, true, "30%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case8")
# synthetic_case8_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case8_breakeven")
# synthetic_case8_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case8_npv_final")
# synthetic_case8_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case8_irr")
# ##### Synthetic Case 8: Multi-modular, C2N, ITC 30%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####

# ##### Synthetic Case 9: Multi-modular, C2N, ITC 40%, PTC $15/MWh and Capacity Market of $15.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 15.0, true, true, true, "40%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case9")
# synthetic_case9_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case9_breakeven")
# synthetic_case9_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case9_npv_final")
# synthetic_case9_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case9_irr")
# ##### Synthetic Case 9: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $15.0/kW-month #####

# ##### Synthetic Case 10: Multi-modular, C2N, ITC 50%, PTC $15/MWh and Capacity Market of $15.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 15.0, true, true, true, "50%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case10")
# synthetic_case10_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case10_breakeven")
# synthetic_case10_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case10_npv_final")
# synthetic_case10_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case10_irr")
# ##### Synthetic Case 10: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $15.0/kW-month #####

# ##### Synthetic Case 11: Multi-modular, C2N, ITC 6%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 27.5, 10, 1.0, 1.0, 1.0, 1.0, 15.0, true, true, true, "6%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case11")
# synthetic_case11_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case11_breakeven")
# synthetic_case11_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case11_npv_final")
# synthetic_case11_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case11_irr")
# ##### Synthetic Case 11: Multi-modular, C2N, ITC 6%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####

# ##### Synthetic Case 12: Multi-modular, C2N, ITC 40%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 27.5, 10, 1.0, 1.0, 1.0, 1.0, 15.0, true, true, true, "40%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case12")
# synthetic_case12_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case12_breakeven")
# synthetic_case12_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case12_npv_final")
# synthetic_case12_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case12_irr")
# ##### Synthetic Case 12: Multi-modular, C2N, ITC 40%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####

# ##### Synthetic Case 13: Multi-modular, C2N, ITC 50%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 27.5, 10, 1.0, 1.0, 1.0, 1.0, 15.0, true, true, true, "50%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case13")
# synthetic_case13_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case13_breakeven")
# synthetic_case13_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case13_npv_final")
# synthetic_case13_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case13_irr")
# ##### Synthetic Case 13: Multi-modular, C2N, ITC 50%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####

# ##### Synthetic Case 14: Multi-modular, C2N, ITC 50%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####
# payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 27.5, 10, 1.0, 1.0, 1.0, 1.0, 15.0, true, true, true, "50%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case13")
# synthetic_case14_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case13_breakeven")
# synthetic_case14_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case13_npv_final")
# synthetic_case14_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case13_irr")
# ##### Synthetic Case 14: Multi-modular, C2N, ITC 50%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####

# # println("NPV Final All: ", npv_final_all)
# # println("NPV Tracker All: ", npv_tracker_all)
# # println("NPV Payoff All: ", npv_payoff_all)
# # println("Payouts All: ", length(payouts_all))
# # println("Generation Output All: ", length(generationOutput_all))

# ##### Baseline Analysis #####

# ##### Sensitivity Analysis #####
# #analysis_sensitivity_npv_breakeven()
# ##### Sensitivity Analysis #####

# ##### run simulation #####


# # Project   Type     Capacity [MWel]  Lifetime [years]  Construction Cost [USD2020/MWel]  Fuel cost [USD2020/MWh]  O&M cost [USD2020/MWel]