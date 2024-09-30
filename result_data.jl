using HTTP
using CSV
using DataFrames
using Dates
using CategoricalArrays
using Plots

@info("Loading in the functions file for data processing")
include("dataprocessingfunctions.jl")

@info("Loading in data for the results data")
include("data.jl")

"""
The following function returns all the scenarios used as price arrays for the SMR dispatch
"""
function get_all_scenario_prices_smr()::Vector{Dict{String, Any}}
    scenario_price_data_all = []

    scenario_price_data_temp = []

    for (index2, cost_array) in enumerate(smr_cost_vals)
        if index2 < 20
            smr_lifetime = Int64(cost_array[2])
            construction_duration = cost_array[7]
        else
            smr_lifetime = Int64(cost_array[2])
            construction_duration = cost_array[8]
        end

        start_reactor = Int(ceil((construction_duration)/12))

        for (index3, scenario) in enumerate(scenario_data_all)
            if index3 == 1 || index3 == 2 || index3 == 3
                scenario_dict = Dict(
                    "smr" =>  "$(smr_names[index2])",
                    "scenario" => "$(scenario_names_combined[index3])",
                    "data" => create_scenario_array(scenario, scenario, scenario, scenario, scenario, scenario, scenario, scenario, (smr_lifetime + start_reactor))
                )

                push!(scenario_price_data_all, scenario_dict)
                continue
            end

            if length(scenario_price_data_temp) == 8
                scen_names_combined_index = Int((index3 - 4)/8) + 3
                scenario_dict = Dict(
                    "smr" =>  "$(smr_names[index2])",
                    "scenario" => "$(scenario_names_combined[scen_names_combined_index])",
                    "data" => create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (smr_lifetime + start_reactor))
                )

                push!(scenario_price_data_all, scenario_dict)
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end

        scenario_dict = Dict(
            "smr" =>  "$(smr_names[index2])",
            "scenario" => "$(last(scenario_names_combined))",
            "data" => create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (smr_lifetime + start_reactor))
        )

        push!(scenario_price_data_all, scenario_dict)
        empty!(scenario_price_data_temp)

        for (index3, scenario) in enumerate(scenario_23_data_all)
            if length(scenario_price_data_temp) == 6
                scen_names_combined_index = Int((index3 - 1)/6)
                scenario_dict = Dict(
                    "smr" =>  "$(smr_names[index2])",
                    "scenario" => "$(scenario_names_23cambium[scen_names_combined_index])",
                    "data" => create_scenario_interpolated_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], (smr_lifetime + start_reactor))
                )

                push!(scenario_price_data_all, scenario_dict)
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end

        scenario_dict = Dict(
            "smr" =>  "$(smr_names[index2])",
            "scenario" => "$(last(scenario_names_23cambium))",
            "data" => create_scenario_interpolated_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], (smr_lifetime + start_reactor))
        )

        push!(scenario_price_data_all, scenario_dict)
        empty!(scenario_price_data_temp)
    end

    return scenario_price_data_all
end


"""
The following function imports in the results from the case analysis, and stores them in a dictionary.
Returned is an array of dictionaries of all the cases
"""
function get_results_all_cases()
    # Creating an array to hold dictionaries for all cases
    all_cases = []

    # Baseline
    baseline_dict = Dict(
        "Scenario" => "Baseline", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/baseline/baseline_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/baseline/baseline_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/baseline/baseline_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/baseline/baseline_npv_final.csv"))
    )
    push!(all_cases, baseline_dict)

    # Coal2Nuclear
    c2n_dict = Dict(
        "Scenario" => "C2N", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline/c2n_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline/c2n_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline/c2n_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline/c2n_npv_final.csv"))
    )
    push!(all_cases, c2n_dict)

    # Multi-Module Learning
    multi_module_dict = Dict(
        "Scenario" => "Multi-Module Learning", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/mmlearning_baseline/mmlearning_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/mmlearning_baseline/mmlearning_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/mmlearning_baseline/mmlearning_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/mmlearning_baseline/mmlearning_npv_final.csv"))
    )
    push!(all_cases, multi_module_dict)

    # ITC 6%
    itc_6_dict = Dict(
        "Scenario" => "ITC 6%", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline/itc_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline/itc_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline/itc_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline/itc_npv_final.csv"))
    )
    push!(all_cases, itc_6_dict)

    # ITC 30%
    itc_30_dict = Dict(
        "Scenario" => "ITC 30%", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline/itc30_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline/itc30_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline/itc30_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline/itc30_npv_final.csv"))
    )
    push!(all_cases, itc_30_dict)

    # ITC 40%
    itc_40_dict = Dict(
        "Scenario" => "ITC 40%", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc40_baseline/itc40_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc40_baseline/itc40_breakeven.csv"))
    )
    push!(all_cases, itc_40_dict)

    # ITC 50%
    itc_50_dict = Dict(
        "Scenario" => "ITC 50%", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc50_baseline/itc50_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc50_baseline/itc50_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc50_baseline/itc50_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc50_baseline/itc50_npv_final.csv"))
    )
    push!(all_cases, itc_50_dict)

    # PTC $11/MWh
    ptc_11_dict = Dict(
        "Scenario" => "PTC \$11/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline/ptc11_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline/ptc11_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline/ptc11_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline/ptc11_npv_final.csv"))
    )
    push!(all_cases, ptc_11_dict)

    # PTC $12/MWh
    ptc_12_dict = Dict(
        "Scenario" => "PTC \$12/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc12_baseline/ptc12_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc12_baseline/ptc12_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc12_baseline/ptc12_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc12_baseline/ptc12_npv_final.csv"))
    )
    push!(all_cases, ptc_12_dict)

    # PTC $13/MWh
    ptc_13_dict = Dict(
        "Scenario" => "PTC \$13/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc13_baseline/ptc13_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc13_baseline/ptc13_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc13_baseline/ptc13_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc13_baseline/ptc13_npv_final.csv"))
    )
    push!(all_cases, ptc_13_dict)

    # PTC $14/MWh
    ptc_14_dict = Dict(
        "Scenario" => "PTC \$14/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc14_baseline/ptc14_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc14_baseline/ptc14_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc14_baseline/ptc14_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc14_baseline/ptc14_npv_final.csv"))
    )
    push!(all_cases, ptc_14_dict)

    # PTC $15/MWh
    ptc_15_dict = Dict(
        "Scenario" => "PTC \$15/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc15_baseline/ptc15_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc15_baseline/ptc15_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc15_baseline/ptc15_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc15_baseline/ptc15_npv_final.csv"))
    )
    push!(all_cases, ptc_15_dict)

    # PTC $16/MWh
    ptc_16_dict = Dict(
        "Scenario" => "PTC \$16/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc16_baseline/ptc16_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc16_baseline/ptc16_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc16_baseline/ptc16_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc16_baseline/ptc16_npv_final.csv"))
    )
    push!(all_cases, ptc_16_dict)

    # PTC $17/MWh
    ptc_17_dict = Dict(
        "Scenario" => "PTC \$17/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc17_baseline/ptc17_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc17_baseline/ptc17_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc17_baseline/ptc17_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc17_baseline/ptc17_npv_final.csv"))
    )
    push!(all_cases, ptc_17_dict)

    # PTC $18/MWh
    ptc_18_dict = Dict(
        "Scenario" => "PTC \$18/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc18_baseline/ptc18_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc18_baseline/ptc18_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc18_baseline/ptc18_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc18_baseline/ptc18_npv_final.csv"))
    )
    push!(all_cases, ptc_18_dict)

    # PTC $19/MWh
    ptc_19_dict = Dict(
        "Scenario" => "PTC \$19/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc19_baseline/ptc19_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc19_baseline/ptc19_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc19_baseline/ptc19_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc19_baseline/ptc19_npv_final.csv"))
    )
    push!(all_cases, ptc_19_dict)

    # PTC $20/MWh
    ptc_20_dict = Dict(
        "Scenario" => "PTC \$20/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc20_baseline/ptc20_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc20_baseline/ptc20_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc20_baseline/ptc20_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc20_baseline/ptc20_npv_final.csv"))
    )
    push!(all_cases, ptc_20_dict)

    # PTC $21/MWh
    ptc_21_dict = Dict(
        "Scenario" => "PTC \$21/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc21_baseline/ptc21_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc21_baseline/ptc21_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc21_baseline/ptc21_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc21_baseline/ptc21_npv_final.csv"))
    )
    push!(all_cases, ptc_21_dict)

    # PTC $22/MWh
    ptc_22_dict = Dict(
        "Scenario" => "PTC \$22/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc22_baseline/ptc22_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc22_baseline/ptc22_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc22_baseline/ptc22_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc22_baseline/ptc22_npv_final.csv"))
    )
    push!(all_cases, ptc_22_dict)

    # PTC $23/MWh
    ptc_23_dict = Dict(
        "Scenario" => "PTC \$23/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc23_baseline/ptc23_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc23_baseline/ptc23_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc23_baseline/ptc23_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc23_baseline/ptc23_npv_final.csv"))
    )
    push!(all_cases, ptc_23_dict)

    # PTC $24/MWh
    ptc_24_dict = Dict(
        "Scenario" => "PTC \$24/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc24_baseline/ptc24_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc24_baseline/ptc24_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc24_baseline/ptc24_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc24_baseline/ptc24_npv_final.csv"))
    )
    push!(all_cases, ptc_24_dict)

    # PTC $25/MWh
    ptc_25_dict = Dict(
        "Scenario" => "PTC \$25/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc25_baseline/ptc25_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc25_baseline/ptc25_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc25_baseline/ptc25_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc25_baseline/ptc25_npv_final.csv"))
    )
    push!(all_cases, ptc_25_dict)

    # PTC $26/MWh
    ptc_26_dict = Dict(
        "Scenario" => "PTC \$26/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc26_baseline/ptc26_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc26_baseline/ptc26_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc26_baseline/ptc26_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc26_baseline/ptc26_npv_final.csv"))
    )
    push!(all_cases, ptc_26_dict)

    # PTC $27.5/MWh
    ptc_27_5_dict = Dict(
        "Scenario" => "PTC \$27.5/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc27.5_baseline/ptc27.5_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc27.5_baseline/ptc27.5_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc27.5_baseline/ptc27.5_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc27.5_baseline/ptc27.5_npv_final.csv"))
    )
    push!(all_cases, ptc_27_5_dict)

    # PTC $28.05/MWh
    ptc_28_05_dict = Dict(
        "Scenario" => "PTC \$28.05/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc28.05_baseline/ptc2805_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc28.05_baseline/ptc28.05_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc28.05_baseline/ptc28.05_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc28.05_baseline/ptc28.05_npv_final.csv"))
    )
    push!(all_cases, ptc_28_05_dict)

    # PTC $30.05/MWh
    ptc_30_05_dict = Dict(
        "Scenario" => "PTC \$30.05/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc30.05_baseline/ptc3005_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc30.05_baseline/ptc30.05_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc30.05_baseline/ptc30.05_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc30.05_baseline/ptc30.05_npv_final.csv"))
    )
    push!(all_cases, ptc_30_05_dict)

    # PTC $33/MWh
    ptc_33_dict = Dict(
        "Scenario" => "PTC \$33/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc33_baseline/ptc33_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc33_baseline/ptc33_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc33_baseline/ptc33_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc33_baseline/ptc33_npv_final.csv"))
    )
    push!(all_cases, ptc_33_dict)

    # Capacity Market $1/kW-month
    cm_1_dict = Dict(
        "Scenario" => "Capacity Market \$1/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm1_baseline/cm1_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm1_baseline/cm1_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm1_baseline/cm1_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm1_baseline/cm1_npv_final.csv"))
    )
    push!(all_cases, cm_1_dict)

    # Capacity Market $2/kW-month
    cm_2_dict = Dict(
        "Scenario" => "Capacity Market \$2/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm2_baseline/cm2_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm2_baseline/cm2_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm2_baseline/cm2_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm2_baseline/cm2_npv_final.csv"))
    )
    push!(all_cases, cm_2_dict)

    # Capacity Market $3/kW-month
    cm_3_dict = Dict(
        "Scenario" => "Capacity Market \$3/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm3_baseline/cm3_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm3_baseline/cm3_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm3_baseline/cm3_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm3_baseline/cm3_npv_final.csv"))
    )
    push!(all_cases, cm_3_dict)

    # Capacity Market $4/kW-month
    cm_4_dict = Dict(
        "Scenario" => "Capacity Market \$4/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm4_baseline/cm4_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm4_baseline/cm4_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm4_baseline/cm4_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm4_baseline/cm4_npv_final.csv"))
    )
    push!(all_cases, cm_4_dict)

    # Capacity Market $5/kW-month
    cm_5_dict = Dict(
        "Scenario" => "Capacity Market \$5/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm5_baseline/cm5_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm5_baseline/cm5_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm5_baseline/cm5_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm5_baseline/cm5_npv_final.csv"))
    )
    push!(all_cases, cm_5_dict)

    # Capacity Market $6/kW-month
    cm_6_dict = Dict(
        "Scenario" => "Capacity Market \$6/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm6_baseline/cm6_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm6_baseline/cm6_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm6_baseline/cm6_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm6_baseline/cm6_npv_final.csv"))
    )
    push!(all_cases, cm_6_dict)

    # Capacity Market $7/kW-month
    cm_7_dict = Dict(
        "Scenario" => "Capacity Market \$7/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm7_baseline/cm7_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm7_baseline/cm7_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm7_baseline/cm7_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm7_baseline/cm7_npv_final.csv"))
    )
    push!(all_cases, cm_7_dict)

    # Capacity Market $8/kW-month
    cm_8_dict = Dict(
        "Scenario" => "Capacity Market \$8/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm8_baseline/cm8_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm8_baseline/cm8_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm8_baseline/cm8_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm8_baseline/cm8_npv_final.csv"))
    )
    push!(all_cases, cm_8_dict)

    # Capacity Market $15/kW-month
    cm_15_dict = Dict(
        "Scenario" => "Capacity Market \$15/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm15_baseline/cm15_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm15_baseline/cm15_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm15_baseline/cm15_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm15_baseline/cm15_npv_final.csv"))
    )
    push!(all_cases, cm_15_dict)

    # Capacity Market $16/kW-month
    cm_16_dict = Dict(
        "Scenario" => "Capacity Market \$16/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm16_baseline/cm16_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm16_baseline/cm16_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm16_baseline/cm16_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm16_baseline/cm16_npv_final.csv"))
    )
    push!(all_cases, cm_16_dict)

    # Capacity Market $17/kW-month
    cm_17_dict = Dict(
        "Scenario" => "Capacity Market \$17/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm17_baseline/cm17_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm17_baseline/cm17_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm17_baseline/cm17_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm17_baseline/cm17_npv_final.csv"))
    )
    push!(all_cases, cm_17_dict)

    # Capacity Market $18/kW-month
    cm_18_dict = Dict(
        "Scenario" => "Capacity Market \$18/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm18_baseline/cm18_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm18_baseline/cm18_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm18_baseline/cm18_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm18_baseline/cm18_npv_final.csv"))
    )
    push!(all_cases, cm_18_dict)

    # Capacity Market $19/kW-month
    cm_19_dict = Dict(
        "Scenario" => "Capacity Market \$19/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm19_baseline/cm19_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm19_baseline/cm19_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm19_baseline/cm19_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm19_baseline/cm19_npv_final.csv"))
    )
    push!(all_cases, cm_19_dict)

    # Capacity Market $20/kW-month
    cm_20_dict = Dict(
        "Scenario" => "Capacity Market \$20/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm20_baseline/cm20_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm20_baseline/cm20_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm20_baseline/cm20_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm20_baseline/cm20_npv_final.csv"))
    )
    push!(all_cases, cm_20_dict)

    # Capacity Market $21/kW-month
    cm_21_dict = Dict(
        "Scenario" => "Capacity Market \$21/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm21_baseline/cm21_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm21_baseline/cm21_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm21_baseline/cm21_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm21_baseline/cm21_npv_final.csv"))
    )
    push!(all_cases, cm_21_dict)

    # Capacity Market $22/kW-month
    cm_22_dict = Dict(
        "Scenario" => "Capacity Market \$22/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm22_baseline/cm22_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm22_baseline/cm22_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm22_baseline/cm22_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm22_baseline/cm22_npv_final.csv"))
    )
    push!(all_cases, cm_22_dict)

    # Capacity Market $23/kW-month
    cm_23_dict = Dict(
        "Scenario" => "Capacity Market \$23/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm23_baseline/cm23_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm23_baseline/cm23_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm23_baseline/cm23_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm23_baseline/cm23_npv_final.csv"))
    )
    push!(all_cases, cm_23_dict)

    # Capacity Market $25/kW-month
    cm_25_dict = Dict(
        "Scenario" => "Capacity Market \$25/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm25_baseline/cm25_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm25_baseline/cm25_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm25_baseline/cm25_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm25_baseline/cm25_npv_final.csv"))
    )
    push!(all_cases, cm_25_dict)

    # Capacity Market $30/kW-month
    cm_30_dict = Dict(
        "Scenario" => "Capacity Market \$30/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm30_baseline/cm30_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm30_baseline/cm30_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm30_baseline/cm30_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm30_baseline/cm30_npv_final.csv"))
    )
    push!(all_cases, cm_30_dict)

    # Capacity Market $35/kW-month
    cm_35_dict = Dict(
        "Scenario" => "Capacity Market \$35/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm35_baseline/cm35_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm35_baseline/cm35_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm35_baseline/cm35_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm35_baseline/cm35_npv_final.csv"))
    )
    push!(all_cases, cm_35_dict)

    # Capacity Market $40/kW-month
    cm_40_dict = Dict(
        "Scenario" => "Capacity Market \$40/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm40_baseline/cm40_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm40_baseline/cm40_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm40_baseline/cm40_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm40_baseline/cm40_npv_final.csv"))
    )
    push!(all_cases, cm_40_dict)

    # Capacity Market $45/kW-month
    cm_45_dict = Dict(
        "Scenario" => "Capacity Market \$45/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm45_baseline/cm45_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm45_baseline/cm45_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm45_baseline/cm45_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm45_baseline/cm45_npv_final.csv"))
    )
    push!(all_cases, cm_45_dict)

    # Capacity Market $50/kW-month
    cm_50_dict = Dict(
        "Scenario" => "Capacity Market \$50/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm50_baseline/cm50_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm50_baseline/cm50_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm50_baseline/cm50_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm50_baseline/cm50_npv_final.csv"))
    )
    push!(all_cases, cm_50_dict)

    # Capacity Market $55/kW-month
    cm_55_dict = Dict(
        "Scenario" => "Capacity Market \$55/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm55_baseline/cm55_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm55_baseline/cm55_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm55_baseline/cm55_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm55_baseline/cm55_npv_final.csv"))
    )
    push!(all_cases, cm_55_dict)

    # Capacity Market $60/kW-month
    cm_60_dict = Dict(
        "Scenario" => "Capacity Market \$60/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm60_baseline/cm60_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm60_baseline/cm60_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm60_baseline/cm60_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm60_baseline/cm60_npv_final.csv"))
    )
    push!(all_cases, cm_60_dict)

    # Capacity Market $65/kW-month
    cm_65_dict = Dict(
        "Scenario" => "Capacity Market \$65/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm65_baseline/cm65_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm65_baseline/cm65_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm65_baseline/cm65_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm65_baseline/cm65_npv_final.csv"))
    )
    push!(all_cases, cm_65_dict)

    # Capacity Market $70/kW-month
    cm_70_dict = Dict(
        "Scenario" => "Capacity Market \$70/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm70_baseline/cm70_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm70_baseline/cm70_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm70_baseline/cm70_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm70_baseline/cm70_npv_final.csv"))
    )
    push!(all_cases, cm_70_dict)

    # Capacity Market $75/kW-month
    cm_75_dict = Dict(
        "Scenario" => "Capacity Market \$75/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm75_baseline/cm75_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm75_baseline/cm75_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm75_baseline/cm75_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm75_baseline/cm75_npv_final.csv"))
    )
    push!(all_cases, cm_75_dict)

    # Capacity Market $80/kW-month
    cm_80_dict = Dict(
        "Scenario" => "Capacity Market \$80/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm80_baseline/cm80_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm80_baseline/cm80_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm80_baseline/cm80_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm80_baseline/cm80_npv_final.csv"))
    )
    push!(all_cases, cm_80_dict)

    # Capacity Market $85/kW-month
    cm_85_dict = Dict(
        "Scenario" => "Capacity Market \$85/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm85_baseline/cm85_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm85_baseline/cm85_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm85_baseline/cm85_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm85_baseline/cm85_npv_final.csv"))
    )
    push!(all_cases, cm_85_dict)

    # Capacity Market $90/kW-month
    cm_90_dict = Dict(
        "Scenario" => "Capacity Market \$90/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm90_baseline/cm90_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm90_baseline/cm90_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm90_baseline/cm90_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm90_baseline/cm90_npv_final.csv"))
    )
    push!(all_cases, cm_90_dict)

    # Capacity Market $95/kW-month
    cm_95_dict = Dict(
        "Scenario" => "Capacity Market \$95/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm95_baseline/cm95_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm95_baseline/cm95_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm95_baseline/cm95_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm95_baseline/cm95_npv_final.csv"))
    )
    push!(all_cases, cm_95_dict)

    # Capacity Market $100/kW-month
    cm_100_dict = Dict(
        "Scenario" => "Capacity Market \$100/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm100_baseline/cm100_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm100_baseline/cm100_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm100_baseline/cm100_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm100_baseline/cm100_npv_final.csv"))
    )
    push!(all_cases, cm_100_dict)

    # Capacity Market $105/kW-month
    cm_105_dict = Dict(
        "Scenario" => "Capacity Market \$105/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm105_baseline/cm105_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm105_baseline/cm105_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm105_baseline/cm105_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm105_baseline/cm105_npv_final.csv"))
    )
    push!(all_cases, cm_105_dict)

    # Capacity Market $110/kW-month
    cm_110_dict = Dict(
        "Scenario" => "Capacity Market \$110/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm110_baseline/cm110_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm110_baseline/cm110_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm110_baseline/cm110_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm110_baseline/cm110_npv_final.csv"))
    )
    push!(all_cases, cm_110_dict)

    # Capacity Market $115/kW-month
    cm_115_dict = Dict(
        "Scenario" => "Capacity Market \$115/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm115_baseline/cm115_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm115_baseline/cm115_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm115_baseline/cm115_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm115_baseline/cm115_npv_final.csv"))
    )
    push!(all_cases, cm_115_dict)

    # Capacity Market $120/kW-month
    cm_120_dict = Dict(
        "Scenario" => "Capacity Market \$120/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm120_baseline/cm120_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm120_baseline/cm120_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm120_baseline/cm120_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm120_baseline/cm120_npv_final.csv"))
    )
    push!(all_cases, cm_120_dict)

    # Capacity Market $125/kW-month
    cm_125_dict = Dict(
        "Scenario" => "Capacity Market \$125/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm125_baseline/cm125_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm125_baseline/cm125_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm125_baseline/cm125_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm125_baseline/cm125_npv_final.csv"))
    )
    push!(all_cases, cm_125_dict)

    # Capacity Market $130/kW-month
    cm_130_dict = Dict(
        "Scenario" => "Capacity Market \$130/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm130_baseline/cm130_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm130_baseline/cm130_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm130_baseline/cm130_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm130_baseline/cm130_npv_final.csv"))
    )
    push!(all_cases, cm_130_dict)

    # Synthetic Case 1: Multi-modular, PTC $15/MWh and Capacity Market of $5.0/kW-month
    synthetic_case1_dict = Dict(
        "Scenario" => "Synthetic Case 1: Multi-modular, PTC \$15/MWh and Capacity Market of \$5.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case1/synthetic_case1_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case1/synthetic_case1_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case1/synthetic_case1_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case1/synthetic_case1_npv_final.csv"))
    )
    push!(all_cases, synthetic_case1_dict)

    # Synthetic Case 2: Multi-modular, C2N, PTC $15/MWh and Capacity Market of $5.0/kW-month
    synthetic_case2_dict = Dict(
        "Scenario" => "Synthetic Case 2: Multi-modular, C2N, PTC \$15/MWh and Capacity Market of \$5.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case2/synthetic_case2_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case2/synthetic_case2_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case2/synthetic_case2_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case2/synthetic_case2_npv_final.csv"))
    )
    push!(all_cases, synthetic_case2_dict)

    # Synthetic Case 3: Multi-modular, C2N, ITC 6%, PTC $15/MWh and Capacity Market of $5.0/kW-month
    synthetic_case3_dict = Dict(
        "Scenario" => "Synthetic Case 3: Multi-modular, C2N, ITC 6%, PTC \$15/MWh and Capacity Market of \$5.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case3/synthetic_case3_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case3/synthetic_case3_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case3/synthetic_case3_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case3/synthetic_case3_npv_final.csv"))
    )
    push!(all_cases, synthetic_case3_dict)

    # Synthetic Case 4: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $5.0/kW-month
    synthetic_case4_dict = Dict(
        "Scenario" => "Synthetic Case 4: Multi-modular, C2N, ITC 30%, PTC \$15/MWh and Capacity Market of \$5.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case4/synthetic_case4_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case4/synthetic_case4_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case4/synthetic_case4_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case4/synthetic_case4_npv_final.csv"))
    )
    push!(all_cases, synthetic_case4_dict)

    # Synthetic Case 5: Multi-modular, C2N, ITC 40%, PTC $15/MWh and Capacity Market of $5.0/kW-month
    synthetic_case5_dict = Dict(
        "Scenario" => "Synthetic Case 5: Multi-modular, C2N, ITC 40%, PTC \$15/MWh and Capacity Market of \$5.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case5/synthetic_case5_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case5/synthetic_case5_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case5/synthetic_case5_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case5/synthetic_case5_npv_final.csv"))
    )
    push!(all_cases, synthetic_case5_dict)

    # Synthetic Case 6:  Multi-modular, C2N, ITC 50%, PTC $15/MWh and Capacity Market of $5.0/kW-month 
    synthetic_case6_dict = Dict(
        "Scenario" => "Synthetic Case 6: Multi-modular, C2N, ITC 50%, PTC \$15/MWh and Capacity Market of \$5.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case6/synthetic_case6_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case6/synthetic_case6_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case6/synthetic_case6_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case6/synthetic_case6_npv_final.csv"))
    )
    push!(all_cases, synthetic_case6_dict)

    # Synthetic Case 7: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $15.0/kW-month
    synthetic_case7_dict = Dict(
        "Scenario" => "Synthetic Case 7: Multi-modular, C2N, ITC 30%, PTC \$15/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case7/synthetic_case7_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case7/synthetic_case7_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case7/synthetic_case7_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case7/synthetic_case7_npv_final.csv"))
    
    )
    push!(all_cases, synthetic_case7_dict)

    # Synthetic Case 8: Multi-modular, C2N, ITC 30%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month
    synthetic_case8_dict = Dict(
        "Scenario" => "Synthetic Case 8: Multi-modular, C2N, ITC 30%, PTC \$27.5/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case8/synthetic_case8_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case8/synthetic_case8_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case8/synthetic_case8_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case8/synthetic_case8_npv_final.csv"))
    )
    push!(all_cases, synthetic_case8_dict)

    # Synthetic Case 9: Multi-modular, C2N, ITC 40%, PTC $15/MWh and Capacity Market of $15.0/kW-month
    synthetic_case9_dict = Dict(
        "Scenario" => "Synthetic Case 9: Multi-modular, C2N, ITC 40%, PTC \$15/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case9/synthetic_case9_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case9/synthetic_case9_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case9/synthetic_case9_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case9/synthetic_case9_npv_final.csv"))
    )
    push!(all_cases, synthetic_case9_dict)

    # Synthetic Case 10: Multi-modular, C2N, ITC 50%, PTC $15/MWh and Capacity Market of $15.0/kW-month
    synthetic_case10_dict = Dict(
        "Scenario" => "Synthetic Case 10: Multi-modular, C2N, ITC 50%, PTC \$15/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case10/synthetic_case10_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case10/synthetic_case10_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case10/synthetic_case10_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case10/synthetic_case10_npv_final.csv"))
    )
    push!(all_cases, synthetic_case10_dict)

    # Synthetic Case 11: Multi-modular, C2N, ITC 6%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month
    synthetic_case11_dict = Dict(
        "Scenario" => "Synthetic Case 11: Multi-modular, C2N, ITC 6%, PTC \$27.5/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case11/synthetic_case11_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case11/synthetic_case11_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case11/synthetic_case11_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case11/synthetic_case11_npv_final.csv"))
    )
    push!(all_cases, synthetic_case11_dict)

    # Synthetic Case 12: Multi-modular, C2N, ITC 40%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month
    synthetic_case12_dict = Dict(
        "Scenario" => "Synthetic Case 12: Multi-modular, C2N, ITC 40%, PTC \$27.5/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case12/synthetic_case12_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case12/synthetic_case12_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case12/synthetic_case12_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case12/synthetic_case12_npv_final.csv"))
    )
    push!(all_cases, synthetic_case12_dict)

    # Synthetic Case 13: Multi-modular, C2N, ITC 50%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month
    synthetic_case13_dict = Dict(
        "Scenario" => "Synthetic Case 13: Multi-modular, C2N, ITC 50%, PTC \$27.5/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case13/synthetic_case13_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case13/synthetic_case13_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case13/synthetic_case13_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case13/synthetic_case13_npv_final.csv"))
    )
    push!(all_cases, synthetic_case13_dict)

    # Synthetic Case 14: Multi-modular, C2N, ITC 6%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month
    synthetic_case14_dict = Dict(
        "Scenario" => "Synthetic Case 14: Multi-modular, C2N, ITC 6%, PTC \$30.05/MWh and Capacity Market of \$25.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case14/synthetic_case14_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case14/synthetic_case14_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case14/synthetic_case14_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case14/synthetic_case14_npv_final.csv"))
    )
    push!(all_cases, synthetic_case14_dict)

    # Synthetic Case 15: Multi-modular, C2N, ITC 30%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month
    synthetic_case15_dict = Dict(
        "Scenario" => "Synthetic Case 15: Multi-modular, C2N, ITC 30%, PTC \$30.05/MWh and Capacity Market of \$25.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case15/synthetic_case15_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case15/synthetic_case15_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case15/synthetic_case15_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case15/synthetic_case15_npv_final.csv"))
    )
    push!(all_cases, synthetic_case15_dict)

    # Synthetic Case 16: Multi-modular, C2N, ITC 40%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month
    synthetic_case16_dict = Dict(
        "Scenario" => "Synthetic Case 16: Multi-modular, C2N, ITC 40%, PTC \$30.05/MWh and Capacity Market of \$25.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case16/synthetic_case16_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case16/synthetic_case16_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case16/synthetic_case16_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case16/synthetic_case16_npv_final.csv"))
    )
    push!(all_cases, synthetic_case16_dict)

    # Synthetic Case 17: Multi-modular, C2N, ITC 50%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month
    synthetic_case17_dict = Dict(
        "Scenario" => "Synthetic Case 17: Multi-modular, C2N, ITC 50%, PTC \$30.05/MWh and Capacity Market of \$25.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case17/synthetic_case17_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case17/synthetic_case17_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case17/synthetic_case17_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case17/synthetic_case17_npv_final.csv"))
    )
    push!(all_cases, synthetic_case17_dict)

    # Synthetic Case 18: Multi-modular, C2N, ITC 50%, PTC $33.0/MWh and Capacity Market of $25.0/kW-month
    synthetic_case18_dict = Dict(
        "Scenario" => "Synthetic Case 18: Multi-modular, C2N, ITC 50%, PTC \$33.0/MWh and Capacity Market of \$25.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case18/synthetic_case18_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case18/synthetic_case18_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case18/synthetic_case18_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case18/synthetic_case18_npv_final.csv"))
    )
    push!(all_cases, synthetic_case18_dict)

    # Synthetic Learning Rate 1: 65% construction cost reduction and 5% FOM cost reduction
    syntheticll_1_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 1: 65% construction cost reduction and 5% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case1/syntheticll_case1_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case1/syntheticll_case1_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case1/syntheticll_case1_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case1/syntheticll_case1_npv_final.csv"))
    )
    push!(all_cases, syntheticll_1_dict)

    # Synthetic Learning Rate 2: 65% construction cost reduction and 10% FOM cost reduction
    syntheticll_2_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 2: 65% construction cost reduction and 10% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case2/syntheticll_case2_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case2/syntheticll_case2_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case2/syntheticll_case2_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case2/syntheticll_case2_npv_final.csv"))
    )
    push!(all_cases, syntheticll_2_dict)

    # Synthetic Learning Rate 3: 65% construction cost reduction and 15% FOM cost reduction
    syntheticll_3_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 3: 65% construction cost reduction and 15% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case3/syntheticll_case3_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case3/syntheticll_case3_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case3/syntheticll_case3_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case3/syntheticll_case3_npv_final.csv"))
    )
    push!(all_cases, syntheticll_3_dict)

    # Synthetic Learning Rate 4: 65% construction cost reduction and 20% FOM cost reduction
    syntheticll_4_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 4: 65% construction cost reduction and 20% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case4/syntheticll_case4_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case4/syntheticll_case4_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case4/syntheticll_case4_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case4/syntheticll_case4_npv_final.csv"))
    )
    push!(all_cases, syntheticll_4_dict)

    # Synthetic Learning Rate 5: 65% construction cost reduction and 25% FOM cost reduction
    syntheticll_5_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 5: 65% construction cost reduction and 25% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case5/syntheticll_case5_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case5/syntheticll_case5_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case5/syntheticll_case5_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case5/syntheticll_case5_npv_final.csv"))
    )
    push!(all_cases, syntheticll_5_dict)

    # Synthetic Learning Rate 6: 65% construction cost reduction and 30% FOM cost reduction
    syntheticll_6_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 6: 65% construction cost reduction and 30% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case6/syntheticll_case6_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case6/syntheticll_case6_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case6/syntheticll_case6_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case6/syntheticll_case6_npv_final.csv"))
    )
    push!(all_cases, syntheticll_6_dict)

    # Synthetic Learning Rate 7: 65% construction cost reduction and 35% FOM cost reduction
    syntheticll_7_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 7: 65% construction cost reduction and 35% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case7/syntheticll_case7_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case7/syntheticll_case7_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case7/syntheticll_case7_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case7/syntheticll_case7_npv_final.csv"))
    )
    push!(all_cases, syntheticll_7_dict)

    # Synthetic Learning Rate 8: 65% construction cost reduction and 40% FOM cost reduction
    syntheticll_8_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 8: 65% construction cost reduction and 40% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case8/syntheticll_case8_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case8/syntheticll_case8_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case8/syntheticll_case8_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case8/syntheticll_case8_npv_final.csv"))
    )
    push!(all_cases, syntheticll_8_dict)

    # Synthetic Learning Rate 9: 65% construction cost reduction and 45% FOM cost reduction
    syntheticll_9_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 9: 65% construction cost reduction and 45% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case9/syntheticll_case9_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case9/syntheticll_case9_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case9/syntheticll_case9_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case9/syntheticll_case9_npv_final.csv"))
    )
    push!(all_cases, syntheticll_9_dict)

    # Synthetic Learning Rate 10: 65% construction cost reduction and 50% FOM cost reduction
    syntheticll_10_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 10: 65% construction cost reduction and 50% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case10/syntheticll_case10_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case10/syntheticll_case10_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case10/syntheticll_case10_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case10/syntheticll_case10_npv_final.csv"))
    )
    push!(all_cases, syntheticll_10_dict)

    # Synthetic Learning Rate 11: 65% construction cost reduction and 55% FOM cost reduction
    syntheticll_11_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 11: 65% construction cost reduction and 55% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case11/syntheticll_case11_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case11/syntheticll_case11_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case11/syntheticll_case11_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case11/syntheticll_case11_npv_final.csv"))
    )
    push!(all_cases, syntheticll_11_dict)

    # Synthetic Learning Rate 12: 65% construction cost reduction and 60% FOM cost reduction
    syntheticll_12_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 12: 65% construction cost reduction and 60% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case12/syntheticll_case12_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case12/syntheticll_case12_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case12/syntheticll_case12_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case12/syntheticll_case12_npv_final.csv"))
    )
    push!(all_cases, syntheticll_12_dict)
    

    return all_cases
end

"""
This function returns the 2023 Cambium price profiles for the AP1000
reactor
"""
function get_ap1000_scenario_prices()
    scenario_price_data_all = []

    scenario_price_data_temp = []

    for (index2, cost_array) in enumerate(ap1000_cost_vals)
        if index2 < 20
            smr_lifetime = Int64(cost_array[2])
            construction_duration = cost_array[7]
        else
            smr_lifetime = Int64(cost_array[2])
            construction_duration = cost_array[8]
        end

        start_reactor = Int(ceil((construction_duration)/12))

        for (index3, scenario) in enumerate(scenario_data_all)
            if index3 == 1 || index3 == 2 || index3 == 3
                scenario_dict = Dict(
                    "smr" =>  "$(ap1000_scenario_names[index2])",
                    "scenario" => "$(scenario_names_combined[index3])",
                    "data" => create_scenario_array(scenario, scenario, scenario, scenario, scenario, scenario, scenario, scenario, (smr_lifetime + start_reactor))
                )

                push!(scenario_price_data_all, scenario_dict)
                continue
            end

            if length(scenario_price_data_temp) == 8
                scen_names_combined_index = Int((index3 - 4)/8) + 3
                scenario_dict = Dict(
                    "smr" =>  "$(ap1000_scenario_names[index2])",
                    "scenario" => "$(scenario_names_combined[scen_names_combined_index])",
                    "data" => create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (smr_lifetime + start_reactor))
                )

                push!(scenario_price_data_all, scenario_dict)
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end

        scenario_dict = Dict(
            "smr" =>  "$(ap1000_scenario_names[index2])",
            "scenario" => "$(last(scenario_names_combined))",
            "data" => create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (smr_lifetime + start_reactor))
        )

        push!(scenario_price_data_all, scenario_dict)
        empty!(scenario_price_data_temp)

        for (index3, scenario) in enumerate(scenario_23_data_all)
            if length(scenario_price_data_temp) == 6
                scen_names_combined_index = Int((index3 - 1)/6)
                # Remove after testing
                scenario_dict = Dict(
                    "smr" =>  "$(ap1000_scenario_names[index2])",
                    "scenario" => "$(scenario_names_23cambium[scen_names_combined_index])",
                    "data" => create_scenario_interpolated_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], (smr_lifetime + start_reactor))
                )

                push!(scenario_price_data_all, scenario_dict)
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end
        
        scenario_dict = Dict(
            "smr" =>  "$(ap1000_scenario_names[index2])",
            "scenario" => "$(last(scenario_names_23cambium))",
            "data" => create_scenario_interpolated_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], (smr_lifetime + start_reactor))
        )

        push!(scenario_price_data_all, scenario_dict)
        empty!(scenario_price_data_temp)
    end

    return scenario_price_data_all
end

# TODO: Replace with OneDrive links
"""
This function stores all the capacity market data for the AP1000
"""
function get_ap1000_cm_data()
    # Creating an array to hold dictionaries for all cases
    ap1000_cm_cases = []

    # Capacity Market Case 1: AP1000, $1.0/kW-month Capacity Market Price
    cm1_dict = Dict(
        "Scenario" => "AP1000, \$1.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 1.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm1_ap1000/cm1_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm1_ap1000/cm1_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm1_ap1000/cm1_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm1_ap1000/cm1_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm1_dict)

    # Capacity Market Case 2: AP1000, $2.0/kW-month Capacity Market Price
    cm2_dict = Dict(
        "Scenario" => "AP1000, \$2.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 2.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm2_ap1000/cm2_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm2_ap1000/cm2_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm2_ap1000/cm2_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm2_ap1000/cm2_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm2_dict)

    # Capacity Market Case 3: AP1000, $3.0/kW-month Capacity Market Price
    cm3_dict = Dict(
        "Scenario" => "AP1000, \$3.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 3.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm3_ap1000/cm3_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm3_ap1000/cm3_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm3_ap1000/cm3_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm3_ap1000/cm3_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm3_dict)

    # Capacity Market Case 4: AP1000, $4.0/kW-month Capacity Market Price
    cm4_dict = Dict(
        "Scenario" => "AP1000, \$4.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 4.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm4_ap1000/cm4_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm4_ap1000/cm4_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm4_ap1000/cm4_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm4_ap1000/cm4_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm4_dict)

    # Capacity Market Case 5: AP1000, $5.0/kW-month Capacity Market Price
    cm5_dict = Dict(
        "Scenario" => "AP1000, \$5.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 5.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm5_ap1000/cm5_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm5_ap1000/cm5_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm5_ap1000/cm5_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm5_ap1000/cm5_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm5_dict)

    # Capacity Market Case 6: AP1000, $6.0/kW-month Capacity Market Price
    cm6_dict = Dict(
        "Scenario" => "AP1000, \$6.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 6.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm6_ap1000/cm6_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm6_ap1000/cm6_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm6_ap1000/cm6_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm6_ap1000/cm6_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm6_dict)

    # Capacity Market Case 7: AP1000, $7.0/kW-month Capacity Market Price
    cm7_dict = Dict(
        "Scenario" => "AP1000, \$7.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 7.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm7_ap1000/cm7_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm7_ap1000/cm7_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm7_ap1000/cm7_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm7_ap1000/cm7_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm7_dict)

    # Capacity Market Case 8: AP1000, $8.0/kW-month Capacity Market Price
    cm8_dict = Dict(
        "Scenario" => "AP1000, \$8.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 8.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm8_ap1000/cm8_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm8_ap1000/cm8_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm8_ap1000/cm8_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm8_ap1000/cm8_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm8_dict)

    # Capacity Market Case 9: AP1000, $15.0/kW-month Capacity Market Price
    cm15_dict = Dict(
        "Scenario" => "AP1000, \$15.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 15.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm15_ap1000/cm15_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm15_ap1000/cm15_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm15_ap1000/cm15_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm15_ap1000/cm15_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm15_dict)

    # Capacity Market Case 10: AP1000, $16.0/kW-month Capacity Market Price
    cm16_dict = Dict(
        "Scenario" => "AP1000, \$16.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 16.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm16_ap1000/cm16_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm16_ap1000/cm16_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm16_ap1000/cm16_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm16_ap1000/cm16_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm16_dict)

    # Capacity Market Case 11: AP1000, $17.0/kW-month Capacity Market Price
    cm17_dict = Dict(
        "Scenario" => "AP1000, \$17.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 17.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm17_ap1000/cm17_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm17_ap1000/cm17_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm17_ap1000/cm17_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm17_ap1000/cm17_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm17_dict)

    # Capacity Market Case 12: AP1000, $18.0/kW-month Capacity Market Price
    cm18_dict = Dict(
        "Scenario" => "AP1000, \$18.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 18.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm18_ap1000/cm18_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm18_ap1000/cm18_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm18_ap1000/cm18_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm18_ap1000/cm18_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm18_dict)

    # Capacity Market Case 13: AP1000, $19.0/kW-month Capacity Market Price
    cm19_dict = Dict(
        "Scenario" => "AP1000, \$19.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 19.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm19_ap1000/cm19_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm19_ap1000/cm19_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm19_ap1000/cm19_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm19_ap1000/cm19_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm19_dict)

    # Capacity Market Case 14: AP1000, $20.0/kW-month Capacity Market Price
    cm20_dict = Dict(
        "Scenario" => "AP1000, \$20.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 20.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm20_ap1000/cm20_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm20_ap1000/cm20_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm20_ap1000/cm20_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm20_ap1000/cm20_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm20_dict)

    # Capacity Market Case 15: AP1000, $21.0/kW-month Capacity Market Price
    cm21_dict = Dict(
        "Scenario" => "AP1000, \$21.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 21.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm21_ap1000/cm21_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm21_ap1000/cm21_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm21_ap1000/cm21_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm21_ap1000/cm21_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm21_dict)

    # Capacity Market Case 16: AP1000, $22.0/kW-month Capacity Market Price
    cm22_dict = Dict(
        "Scenario" => "AP1000, \$22.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 22.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm22_ap1000/cm22_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm22_ap1000/cm22_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm22_ap1000/cm22_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm22_ap1000/cm22_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm22_dict)

    # Capacity Market Case 17: AP1000, $23.0/kW-month Capacity Market Price
    cm23_dict = Dict(
        "Scenario" => "AP1000, \$23.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 23.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm23_ap1000/cm23_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm23_ap1000/cm23_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm23_ap1000/cm23_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm23_ap1000/cm23_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm23_dict)

    # Capacity Market Case 18: AP1000, $25.0/kW-month Capacity Market Price
    cm25_dict = Dict(
        "Scenario" => "AP1000, \$25.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 25.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm25_ap1000/cm25_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm25_ap1000/cm25_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm25_ap1000/cm25_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm25_ap1000/cm25_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm25_dict)

    # Capacity Market Case 19: AP1000, $30.0/kW-month Capacity Market Price
    cm30_dict = Dict(
        "Scenario" => "AP1000, \$30.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 30.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm30_ap1000/cm30_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm30_ap1000/cm30_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm30_ap1000/cm30_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm30_ap1000/cm30_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm30_dict)

    # Capacity Market Case 20: AP1000, $35.0/kW-month Capacity Market Price
    cm35_dict = Dict(
        "Scenario" => "AP1000, \$35.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 35.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm35_ap1000/cm35_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm35_ap1000/cm35_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm35_ap1000/cm35_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm35_ap1000/cm35_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm35_dict)

    # Capacity Market Case 21: AP1000, $40.0/kW-month Capacity Market Price
    cm40_dict = Dict(
        "Scenario" => "AP1000, \$40.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 40.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm40_ap1000/cm40_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm40_ap1000/cm40_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm40_ap1000/cm40_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm40_ap1000/cm40_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm40_dict)

    # Capacity Market Case 22: AP1000, $45.0/kW-month Capacity Market Price
    cm45_dict = Dict(
        "Scenario" => "AP1000, \$45.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 45.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm45_ap1000/cm45_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm45_ap1000/cm45_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm45_ap1000/cm45_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm45_ap1000/cm45_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm45_dict)

    # Capacity Market Case 23: AP1000, $50.0/kW-month Capacity Market Price
    cm50_dict = Dict(
        "Scenario" => "AP1000, \$50.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 50.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm50_ap1000/cm50_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm50_ap1000/cm50_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm50_ap1000/cm50_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm50_ap1000/cm50_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm50_dict)

    # Capacity Market Case 24: AP1000, $55.0/kW-month Capacity Market Price
    cm55_dict = Dict(
        "Scenario" => "AP1000, \$55.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 55.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm55_ap1000/cm55_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm55_ap1000/cm55_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm55_ap1000/cm55_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm55_ap1000/cm55_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm55_dict)

    # Capacity Market Case 25: AP1000, $60.0/kW-month Capacity Market Price
    cm60_dict = Dict(
        "Scenario" => "AP1000, \$60.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 60.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm60_ap1000/cm60_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm60_ap1000/cm60_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm60_ap1000/cm60_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm60_ap1000/cm60_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm60_dict)

    # Capacity Market Case 26: AP1000, $65.0/kW-month Capacity Market Price
    cm65_dict = Dict(
        "Scenario" => "AP1000, \$65.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 65.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm65_ap1000/cm65_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm65_ap1000/cm65_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm65_ap1000/cm65_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm65_ap1000/cm65_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm65_dict)

    # Capacity Market Case 27: AP1000, $70.0/kW-month Capacity Market Price
    cm70_dict = Dict(
        "Scenario" => "AP1000, \$70.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 70.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm70_ap1000/cm70_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm70_ap1000/cm70_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm70_ap1000/cm70_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm70_ap1000/cm70_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm70_dict)

    # Capacity Market Case 28: AP1000, $75.0/kW-month Capacity Market Price
    cm75_dict = Dict(
        "Scenario" => "AP1000, \$75.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 75.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm75_ap1000/cm75_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm75_ap1000/cm75_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm75_ap1000/cm75_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm75_ap1000/cm75_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm75_dict)

    # Capacity Market Case 29: AP1000, $80.0/kW-month Capacity Market Price
    cm80_dict = Dict(
        "Scenario" => "AP1000, \$80.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 80.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm80_ap1000/cm80_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm80_ap1000/cm80_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm80_ap1000/cm80_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm80_ap1000/cm80_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm80_dict)

    # Capacity Market Case 30: AP1000, $85.0/kW-month Capacity Market Price
    cm85_dict = Dict(
        "Scenario" => "AP1000, \$85.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 85.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm85_ap1000/cm85_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm85_ap1000/cm85_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm85_ap1000/cm85_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm85_ap1000/cm85_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm85_dict)

    # Capacity Market Case 31: AP1000, $90.0/kW-month Capacity Market Price
    cm90_dict = Dict(
        "Scenario" => "AP1000, \$90.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 90.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm90_ap1000/cm90_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm90_ap1000/cm90_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm90_ap1000/cm90_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm90_ap1000/cm90_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm90_dict)

    # Capacity Market Case 32: AP1000, $95.0/kW-month Capacity Market Price
    cm95_dict = Dict(
        "Scenario" => "AP1000, \$95.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 95.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm95_ap1000/cm95_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm95_ap1000/cm95_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm95_ap1000/cm95_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm95_ap1000/cm95_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm95_dict)

    # Capacity Market Case 33: AP1000, $100.0/kW-month Capacity Market Price
    cm100_dict = Dict(
        "Scenario" => "AP1000, \$100.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 100.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm100_ap1000/cm100_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm100_ap1000/cm100_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm100_ap1000/cm100_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm100_ap1000/cm100_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm100_dict)

    # Capacity Market Case 34: AP1000, $105.0/kW-month Capacity Market Price
    cm105_dict = Dict(
        "Scenario" => "AP1000, \$105.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 105.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm105_ap1000/cm105_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm105_ap1000/cm105_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm105_ap1000/cm105_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm105_ap1000/cm105_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm105_dict)

    # Capacity Market Case 35: AP1000, $110.0/kW-month Capacity Market Price
    cm110_dict = Dict(
        "Scenario" => "AP1000, \$110.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 110.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm110_ap1000/cm110_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm110_ap1000/cm110_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm110_ap1000/cm110_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm110_ap1000/cm110_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm110_dict)

    # Capacity Market Case 36: AP1000, $115.0/kW-month Capacity Market Price
    cm115_dict = Dict(
        "Scenario" => "AP1000, \$115.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 115.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm115_ap1000/cm115_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm115_ap1000/cm115_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm115_ap1000/cm115_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm115_ap1000/cm115_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm115_dict)

    # Capacity Market Case 37: AP1000, $120.0/kW-month Capacity Market Price
    cm120_dict = Dict(
        "Scenario" => "AP1000, \$120.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 120.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm120_ap1000/cm120_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm120_ap1000/cm120_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm120_ap1000/cm120_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm120_ap1000/cm120_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm120_dict)

    # Capacity Market Case 38: AP1000, $125.0/kW-month Capacity Market Price
    cm125_dict = Dict(
        "Scenario" => "AP1000, \$125.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 125.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm125_ap1000/cm125_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm125_ap1000/cm125_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm125_ap1000/cm125_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm125_ap1000/cm125_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm125_dict)

    # Capacity Market Case 39: AP1000, $130.0/kW-month Capacity Market Price
    cm130_dict = Dict(
        "Scenario" => "AP1000, \$130.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 130.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm130_ap1000/cm130_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm130_ap1000/cm130_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm130_ap1000/cm130_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm130_ap1000/cm130_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm130_dict)

    # Capacity Market Case 40: AP1000, $135.0/kW-month Capacity Market Price
    cm135_dict = Dict(
        "Scenario" => "AP1000, \$135.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 135.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm135_ap1000/cm135_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm135_ap1000/cm135_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm135_ap1000/cm135_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm135_ap1000/cm135_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm135_dict)

    # Capacity Market Case 41: AP1000, $140.0/kW-month Capacity Market Price
    cm140_dict = Dict(
        "Scenario" => "AP1000, \$140.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 140.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm140_ap1000/cm140_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm140_ap1000/cm140_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm140_ap1000/cm140_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm140_ap1000/cm140_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm140_dict)

    # Capacity Market Case 42: AP1000, $145.0/kW-month Capacity Market Price
    cm145_dict = Dict(
        "Scenario" => "AP1000, \$145.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 145.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm145_ap1000/cm145_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm145_ap1000/cm145_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm145_ap1000/cm145_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm145_ap1000/cm145_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm145_dict)

    # Capacity Market Case 43: AP1000, $150.0/kW-month Capacity Market Price
    cm150_dict = Dict(
        "Scenario" => "AP1000, \$150.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 150.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm150_ap1000/cm150_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm150_ap1000/cm150_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm150_ap1000/cm150_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm150_ap1000/cm150_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm150_dict)

    # Capacity Market Case 44: AP1000, $155.0/kW-month Capacity Market Price
    cm155_dict = Dict(
        "Scenario" => "AP1000, \$155.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 155.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm155_ap1000/cm155_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm155_ap1000/cm155_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm155_ap1000/cm155_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm155_ap1000/cm155_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm155_dict)

    # Capacity Market Case 45: AP1000, $160.0/kW-month Capacity Market Price
    cm160_dict = Dict(
        "Scenario" => "AP1000, \$160.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 160.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm160_ap1000/cm160_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm160_ap1000/cm160_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm160_ap1000/cm160_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm160_ap1000/cm160_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm160_dict)

    # Capacity Market Case 46: AP1000, $165.0/kW-month Capacity Market Price
    cm165_dict = Dict(
        "Scenario" => "AP1000, \$165.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 165.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm165_ap1000/cm165_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm165_ap1000/cm165_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm165_ap1000/cm165_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm165_ap1000/cm165_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm165_dict)


    # Capacity Market Case 47: AP1000, $170.0/kW-month Capacity Market Price
    cm170_dict = Dict(
        "Scenario" => "AP1000, \$170.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 170.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm170_ap1000/cm170_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm170_ap1000/cm170_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm170_ap1000/cm170_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm170_ap1000/cm170_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm170_dict)

    # Capacity Market Case 48: AP1000, $175.0/kW-month Capacity Market Price
    cm175_dict = Dict(
        "Scenario" => "AP1000, \$175.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 175.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm175_ap1000/cm175_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm175_ap1000/cm175_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm175_ap1000/cm175_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm175_ap1000/cm175_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm175_dict)

    # Capacity Market Case 49: AP1000, $180.0/kW-month Capacity Market Price
    cm180_dict = Dict(
        "Scenario" => "AP1000, \$180.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 180.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm180_ap1000/cm180_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm180_ap1000/cm180_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm180_ap1000/cm180_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm180_ap1000/cm180_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm180_dict)

    # Capacity Market Case 50: AP1000, $185.0/kW-month Capacity Market Price
    cm185_dict = Dict(
        "Scenario" => "AP1000, \$185.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 185.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm185_ap1000/cm185_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm185_ap1000/cm185_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm185_ap1000/cm185_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm185_ap1000/cm185_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm185_dict)

    # Capacity Market Case 51: AP1000, $190.0/kW-month Capacity Market Price
    cm190_dict = Dict(
        "Scenario" => "AP1000, \$190.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 190.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm190_ap1000/cm190_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm190_ap1000/cm190_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm190_ap1000/cm190_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm190_ap1000/cm190_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm190_dict)

    # Capacity Market Case 52: AP1000, $195.0/kW-month Capacity Market Price
    cm195_dict = Dict(
        "Scenario" => "AP1000, \$195.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 195.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm195_ap1000/cm195_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm195_ap1000/cm195_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm195_ap1000/cm195_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm195_ap1000/cm195_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm195_dict)

    # Capacity Market Case 53: AP1000, $200.0/kW-month Capacity Market Price
    cm200_dict = Dict(
        "Scenario" => "AP1000, \$200.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 200.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm200_ap1000/cm200_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm200_ap1000/cm200_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm200_ap1000/cm200_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm200_ap1000/cm200_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm200_dict)


    return ap1000_cm_cases
end

"""
This function gets all capacity market data for SMR prototypes
"""
function get_smr_cm_data()
    # Start with an empty array that will store the dicts for capacity market data
    smr_cm_data = []

    # Capacity Market Case 1: SMR, $1.0/kW-month Capacity Market Price
    cm1_dict = Dict(
        "Scenario" => "SMR, \$1.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 1.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm1_baseline/cm1_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm1_baseline/cm1_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm1_baseline/cm1_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm1_baseline/cm1_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm1_dict)

    # Capacity Market Case 2: SMR, $2.0/kW-month Capacity Market Price
    cm2_dict = Dict(
        "Scenario" => "SMR, \$2.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 2.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm2_baseline/cm2_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm2_baseline/cm2_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm2_baseline/cm2_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm2_baseline/cm2_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm2_dict)

    # Capacity Market Case 3: SMR, $3.0/kW-month Capacity Market Price
    cm3_dict = Dict(
        "Scenario" => "SMR, \$3.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 3.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm3_baseline/cm3_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm3_baseline/cm3_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm3_baseline/cm3_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm3_baseline/cm3_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm3_dict)

    # Capacity Market Case 4: SMR, $4.0/kW-month Capacity Market Price
    cm4_dict = Dict(
        "Scenario" => "SMR, \$4.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 4.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm4_baseline/cm4_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm4_baseline/cm4_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm4_baseline/cm4_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm4_baseline/cm4_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm4_dict)

    # Capacity Market Case 5: SMR, $5.0/kW-month Capacity Market Price
    cm5_dict = Dict(
        "Scenario" => "SMR, \$5.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 5.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm5_baseline/cm5_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm5_baseline/cm5_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm5_baseline/cm5_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm5_baseline/cm5_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm5_dict)

    # Capacity Market Case 6: SMR, $6.0/kW-month Capacity Market Price
    cm6_dict = Dict(
        "Scenario" => "SMR, \$6.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 6.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm6_baseline/cm6_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm6_baseline/cm6_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm6_baseline/cm6_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm6_baseline/cm6_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm6_dict)

    # Capacity Market Case 7: SMR, $7.0/kW-month Capacity Market Price
    cm7_dict = Dict(
        "Scenario" => "SMR, \$7.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 7.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm7_baseline/cm7_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm7_baseline/cm7_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm7_baseline/cm7_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm7_baseline/cm7_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm7_dict)

    # Capacity Market Case 8: SMR, $8.0/kW-month Capacity Market Price
    cm8_dict = Dict(
        "Scenario" => "SMR, \$8.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 8.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm8_baseline/cm8_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm8_baseline/cm8_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm8_baseline/cm8_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm8_baseline/cm8_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm8_dict)

    # Capacity Market Case 9: SMR, $15.0/kW-month Capacity Market Price
    cm15_dict = Dict(
        "Scenario" => "SMR, \$15.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 15.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm15_baseline/cm15_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm15_baseline/cm15_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm15_baseline/cm15_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm15_baseline/cm15_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm15_dict)

    # Capacity Market Case 10: SMR, $16.0/kW-month Capacity Market Price
    cm16_dict = Dict(
        "Scenario" => "SMR, \$16.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 16.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm16_baseline/cm16_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm16_baseline/cm16_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm16_baseline/cm16_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm16_baseline/cm16_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm16_dict)

    # Capacity Market Case 11: SMR, $17.0/kW-month Capacity Market Price
    cm17_dict = Dict(
        "Scenario" => "SMR, \$17.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 17.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm17_baseline/cm17_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm17_baseline/cm17_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm17_baseline/cm17_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm17_baseline/cm17_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm17_dict)

    # Capacity Market Case 12: SMR, $18.0/kW-month Capacity Market Price
    cm18_dict = Dict(
        "Scenario" => "SMR, \$18.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 18.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm18_baseline/cm18_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm18_baseline/cm18_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm18_baseline/cm18_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm18_baseline/cm18_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm18_dict)

    # Capacity Market Case 13: SMR, $19.0/kW-month Capacity Market Price
    cm19_dict = Dict(
        "Scenario" => "SMR, \$19.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 19.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm19_baseline/cm19_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm19_baseline/cm19_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm19_baseline/cm19_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm19_baseline/cm19_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm19_dict)

    # Capacity Market Case 14: SMR, $20.0/kW-month Capacity Market Price
    cm20_dict = Dict(
        "Scenario" => "SMR, \$20.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 20.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm20_baseline/cm20_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm20_baseline/cm20_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm20_baseline/cm20_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm20_baseline/cm20_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm20_dict)

    # Capacity Market Case 15: SMR, $21.0/kW-month Capacity Market Price
    cm21_dict = Dict(
        "Scenario" => "SMR, \$21.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 21.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm21_baseline/cm21_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm21_baseline/cm21_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm21_baseline/cm21_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm21_baseline/cm21_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm21_dict)

    # Capacity Market Case 16: SMR, $22.0/kW-month Capacity Market Price
    cm22_dict = Dict(
        "Scenario" => "SMR, \$22.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 22.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm22_baseline/cm22_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm22_baseline/cm22_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm22_baseline/cm22_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm22_baseline/cm22_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm22_dict)

    # Capacity Market Case 17: SMR, $23.0/kW-month Capacity Market Price
    cm23_dict = Dict(
        "Scenario" => "SMR, \$23.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 23.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm23_baseline/cm23_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm23_baseline/cm23_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm23_baseline/cm23_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm23_baseline/cm23_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm23_dict)

    # Capacity Market Case 18: SMR, $25.0/kW-month Capacity Market Price
    cm25_dict = Dict(
        "Scenario" => "SMR, \$25.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 25.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm25_baseline/cm25_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm25_baseline/cm25_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm25_baseline/cm25_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm25_baseline/cm25_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm25_dict)

    # Capacity Market Case 19: SMR, $30.0/kW-month Capacity Market Price
    cm30_dict = Dict(
        "Scenario" => "SMR, \$30.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 30.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm30_baseline/cm30_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm30_baseline/cm30_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm30_baseline/cm30_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm30_baseline/cm30_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm30_dict)

    # Capacity Market Case 20: SMR, $35.0/kW-month Capacity Market Price
    cm35_dict = Dict(
        "Scenario" => "SMR, \$35.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 35.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm35_baseline/cm35_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm35_baseline/cm35_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm35_baseline/cm35_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm35_baseline/cm35_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm35_dict)

    # Capacity Market Case 21: SMR, $40.0/kW-month Capacity Market Price
    cm40_dict = Dict(
        "Scenario" => "SMR, \$40.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 40.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm40_baseline/cm40_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm40_baseline/cm40_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm40_baseline/cm40_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm40_baseline/cm40_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm40_dict)

    # Capacity Market Case 22: SMR, $45.0/kW-month Capacity Market Price
    cm45_dict = Dict(
        "Scenario" => "SMR, \$45.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 45.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm45_baseline/cm45_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm45_baseline/cm45_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm45_baseline/cm45_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm45_baseline/cm45_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm45_dict)

    # Capacity Market Case 23: SMR, $50.0/kW-month Capacity Market Price
    cm50_dict = Dict(
        "Scenario" => "SMR, \$50.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 50.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm50_baseline/cm50_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm50_baseline/cm50_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm50_baseline/cm50_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm50_baseline/cm50_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm50_dict)

    # Capacity Market Case 24: SMR, $55.0/kW-month Capacity Market Price
    cm55_dict = Dict(
        "Scenario" => "SMR, \$55.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 55.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm55_baseline/cm55_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm55_baseline/cm55_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm55_baseline/cm55_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm55_baseline/cm55_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm55_dict)

    # Capacity Market Case 25: SMR, $60.0/kW-month Capacity Market Price
    cm60_dict = Dict(
        "Scenario" => "SMR, \$60.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 60.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm60_baseline/cm60_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm60_baseline/cm60_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm60_baseline/cm60_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm60_baseline/cm60_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm60_dict)

    # Capacity Market Case 26: SMR, $65.0/kW-month Capacity Market Price
    cm65_dict = Dict(
        "Scenario" => "SMR, \$65.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 65.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm65_baseline/cm65_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm65_baseline/cm65_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm65_baseline/cm65_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm65_baseline/cm65_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm65_dict)

    # Capacity Market Case 27: SMR, $70.0/kW-month Capacity Market Price
    cm70_dict = Dict(
        "Scenario" => "SMR, \$70.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 70.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm70_baseline/cm70_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm70_baseline/cm70_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm70_baseline/cm70_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm70_baseline/cm70_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm70_dict)

    # Capacity Market Case 28: SMR, $75.0/kW-month Capacity Market Price
    cm75_dict = Dict(
        "Scenario" => "SMR, \$75.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 75.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm75_baseline/cm75_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm75_baseline/cm75_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm75_baseline/cm75_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm75_baseline/cm75_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm75_dict)

    # Capacity Market Case 29: SMR, $80.0/kW-month Capacity Market Price
    cm80_dict = Dict(
        "Scenario" => "SMR, \$80.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 80.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm80_baseline/cm80_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm80_baseline/cm80_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm80_baseline/cm80_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm80_baseline/cm80_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm80_dict)

    # Capacity Market Case 30: SMR, $85.0/kW-month Capacity Market Price
    cm85_dict = Dict(
        "Scenario" => "SMR, \$85.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 85.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm85_baseline/cm85_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm85_baseline/cm85_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm85_baseline/cm85_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm85_baseline/cm85_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm85_dict)

    # Capacity Market Case 31: SMR, $90.0/kW-month Capacity Market Price
    cm90_dict = Dict(
        "Scenario" => "SMR, \$90.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 90.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm90_baseline/cm90_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm90_baseline/cm90_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm90_baseline/cm90_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm90_baseline/cm90_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm90_dict)

    # Capacity Market Case 32: SMR, $95.0/kW-month Capacity Market Price
    cm95_dict = Dict(
        "Scenario" => "SMR, \$95.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 95.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm95_baseline/cm95_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm95_baseline/cm95_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm95_baseline/cm95_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm95_baseline/cm95_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm95_dict)

    # Capacity Market Case 33: SMR, $100.0/kW-month Capacity Market Price
    cm100_dict = Dict(
        "Scenario" => "SMR, \$100.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 100.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm100_baseline/cm100_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm100_baseline/cm100_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm100_baseline/cm100_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm100_baseline/cm100_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm100_dict)

    # Capacity Market Case 34: SMR, $105.0/kW-month Capacity Market Price
    cm105_dict = Dict(
        "Scenario" => "SMR, \$105.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 105.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm105_baseline/cm105_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm105_baseline/cm105_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm105_baseline/cm105_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm105_baseline/cm105_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm105_dict)

    # Capacity Market Case 35: SMR, $110.0/kW-month Capacity Market Price
    cm110_dict = Dict(
        "Scenario" => "SMR, \$110.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 110.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm110_baseline/cm110_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm110_baseline/cm110_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm110_baseline/cm110_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm110_baseline/cm110_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm110_dict)

    # Capacity Market Case 36: SMR, $115.0/kW-month Capacity Market Price
    cm115_dict = Dict(
        "Scenario" => "SMR, \$115.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 115.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm115_baseline/cm115_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm115_baseline/cm115_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm115_baseline/cm115_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm115_baseline/cm115_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm115_dict)

    # Capacity Market Case 37: SMR, $120.0/kW-month Capacity Market Price
    cm120_dict = Dict(
        "Scenario" => "SMR, \$120.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 120.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm120_baseline/cm120_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm120_baseline/cm120_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm120_baseline/cm120_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm120_baseline/cm120_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm120_dict)

    # Capacity Market Case 38: SMR, $125.0/kW-month Capacity Market Price
    cm125_dict = Dict(
        "Scenario" => "SMR, \$125.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 125.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm125_baseline/cm125_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm125_baseline/cm125_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm125_baseline/cm125_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm125_baseline/cm125_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm125_dict)

    # Capacity Market Case 39: SMR, $130.0/kW-month Capacity Market Price
    cm130_dict = Dict(
        "Scenario" => "SMR, \$130.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 130.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm130_baseline/cm130_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm130_baseline/cm130_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm130_baseline/cm130_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm130_baseline/cm130_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm130_dict)

    # Capacity Market Case 40: SMR, $135.0/kW-month Capacity Market Price
    cm135_dict = Dict(
        "Scenario" => "SMR, \$135.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 135.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm135_baseline/cm135_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm135_baseline/cm135_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm135_baseline/cm135_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm135_baseline/cm135_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm135_dict)

    # Capacity Market Case 41: SMR, $140.0/kW-month Capacity Market Price
    cm140_dict = Dict(
        "Scenario" => "SMR, \$140.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 140.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm140_baseline/cm140_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm140_baseline/cm140_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm140_baseline/cm140_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm140_baseline/cm140_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm140_dict)

    # Capacity Market Case 42: SMR, $145.0/kW-month Capacity Market Price
    cm145_dict = Dict(
        "Scenario" => "SMR, \$145.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 145.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm145_baseline/cm145_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm145_baseline/cm145_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm145_baseline/cm145_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm145_baseline/cm145_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm145_dict)

    # Capacity Market Case 43: SMR, $150.0/kW-month Capacity Market Price
    cm150_dict = Dict(
        "Scenario" => "SMR, \$150.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 150.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm150_baseline/cm150_cambium_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm150_baseline/cm150_cambium_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm150_baseline/cm150_cambium_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm150_baseline/cm150_cambium_npv_final.csv"))
    )
    push!(smr_cm_data, cm150_dict)

    return smr_cm_data
end

"""
This function stores all tests for the results_data.jl file
"""
function test_results_data()
    for scenario_dict in get_all_scenario_prices_smr()
        smr = scenario_dict["smr"]
        scenario = scenario_dict["scenario"]
        println("SMR: $smr, Scenario: $scenario")
    end
end

"""
This returns an array of dictionaries the generation output for the AP1000
"""
function get_ap1000_generation()
    return process_csv_to_dicts("/Users/pradyrao/Desktop/thesis_plots/output_files/dispatch_outputs/generation_ap1000_baseline.csv")
end

"""
This returns an array of dictionaries of the payout data for the AP1000
"""
function get_ap1000_payout()
    return process_csv_to_dicts("/Users/pradyrao/Desktop/thesis_plots/output_files/dispatch_outputs/payout_ap1000_baseline.csv")
end

"""
This returns an array of dictionaries of the generation output for the SMR
"""
function get_smr_generation()
    return process_csv_to_dicts("/Users/pradyrao/Desktop/thesis_plots/output_files/dispatch_outputs/generation_cambium23_baseline.csv")
end

"""
This returns an array of dictionaries of the payout data for the SMR
"""
function get_smr_payout()
    return process_csv_to_dicts("/Users/pradyrao/Desktop/thesis_plots/output_files/dispatch_outputs/payout_cambium23_baseline.csv")
end

get_ap1000_generation() 
println("Generation length: ", length(get_ap1000_generation()))

get_ap1000_payout()
println("Payout length: ", length(get_ap1000_payout()))