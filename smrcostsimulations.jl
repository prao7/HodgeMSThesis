using DataFrames
using Statistics

@info("Importing in the functions needed to run simulation")
include("smrsimulationfunctions.jl")

@info("Importing the data needed for the functions")
include("data.jl")

@info("Bringing in functions for Plotting and Data processing")
include("dataprocessingfunctions.jl")

"""
The following function analyses the NPV and break even for an input prototype SMR for all scenarios
"""
function analysis_npv_all_scenarios_iteration_one()
    """
    NOTE - How the data is organized
    From the way that the below analysis is coded, the calculated data has been pushed to the above array as follows:
    All scenarios are calculated for an SMR, then pushed onto the array before moving onto the next SMR prototype.
    This is continued till all calculations have been completed for all SMR prototypes.
    """

    # Array for all payouts
    payouts_all = []

    # Array for all generation
    generationOutput_all = []

    # Array for all NPV's
    npv_tracker_all = []

    # Array for all break even times
    break_even_all = []

    # Array for all NPV per year info
    npv_payoff_all = []

    """
    The following constants were used 
    """
    # Interest Rate explored TODO: Try to make variable
    interest_rate_wacc = 0.04

    # Ramping CF used TODO: Try to make variable
    ramping_cf_constant = 0.96

    # Non-Ramping CF used TODO: Try to make variable
    non_ramping_cf_constant = 0.92

    # The price multiplication factor of the average that ramping begins TODO: Try to make variable
    price_multiplication_factor_constant = 1.3



    ### Running each SMR through each scenario ###
    for (index, cost_array) in enumerate(smr_cost_vals)
        for scenario_array in scenario_data_all
            if index == 5
                # If it's NuScale, there are 4 modules
                payout_run, generation_run = smr_dispatch_iteration_one(scenario_array, non_ramping_cf_constant, ramping_cf_constant, cost_array[1], price_multiplication_factor_constant, 4)
                npv_tracker_run, break_even_run, npv_payoff_run = npv_calc(payout_run, interest_rate_wacc, initial_investment_calculation(cost_array[1], cost_array[3], cost_array[5], 4), cost_array[2])
            else
                payout_run, generation_run = smr_dispatch_iteration_one(scenario_array, non_ramping_cf_constant, ramping_cf_constant, cost_array[1], price_multiplication_factor_constant, 1)
                npv_tracker_run, break_even_run, npv_payoff_run = npv_calc(payout_run, interest_rate_wacc, initial_investment_calculation(cost_array[1], cost_array[3], cost_array[5], 1), cost_array[2])
            end
    
            # Pushing in all the calculated values 
            push!(payouts_all, payout_run)
            push!(generationOutput_all, generation_run)
            push!(npv_tracker_all, npv_tracker_run)
            push!(break_even_all, break_even_run)
            push!(npv_payoff_all, npv_payoff_run)
        end
    end
    ### Running each SMR through each scenario ###


    ###### functions for plotting ######
    
    """
    Directory that the plots will be saved into
    """
    # TODO: For anyone wanting to replicate the package, please change the directory for upload. Need to add to README.md
    pathname = "/Users/pradyrao/Desktop/thesis_plots"

    """
    Plotting data for break even
    """


    # The index is for reference value of the array for break even all. Will be incremented as iterated through the loop
    breakeven_index = 1
    for prototype_name in smr_names
        # Create empty array for the break even values and names of the scenarios added to be plotted for each prototype
        breakevenvals_array = []
        scenarionames_array = []

        for (index, scenariorun) in enumerate(scenario_names)
            # Access the break even of each scenario for the prototype
            push!(breakevenvals_array, break_even_all[breakeven_index])
            push!(scenarionames_array, scenario_names[index])

            if occursin("DE-LU 2022", scenario_names[index])
                # Plot the first three scenarios in one separate plot
                display_bar_chart(scenarionames_array, breakevenvals_array, prototype_name, "Scenarios Run", "Years [-]", "$prototype_name$breakeven_index", pathname)

                # Clearing the array to add new scenarios
                empty!(breakevenvals_array)
                empty!(scenarionames_array)

            elseif occursin("2050", scenario_names[index])
                # Plot the eight scenarios in one separate plot
                display_bar_chart(scenarionames_array, breakevenvals_array, prototype_name, "Scenarios Run", "Years [-]", "$prototype_name$breakeven_index", pathname)

                # Clearing the array to add new scenarios
                empty!(breakevenvals_array)
                empty!(scenarionames_array)

            end
            
            # Incrementing the break even index that accesses the entire break even array
            breakeven_index += 1
        end
    end

    """
    Plotting payoff in each year
    """
    # This will be added onto the end of the plot name
    npvcalcstring = "NPV_payoff"

    # The break even index is for iterating through the whole loop so that every single scenario is taken into account
    breakeven_index = 1
    for prototype_name in smr_names
        # The first array is for the 
        npv_payoff_array = []
        scenarionames_array = []
        for (index, scenariorun) in enumerate(scenario_names)
            push!(npv_payoff_array, npv_payoff_all[breakeven_index])
            push!(scenarionames_array, scenario_names[index])

            if occursin("DE-LU 2022", scenario_names[index])
                
                
            elseif occursin("2050", scenario_names[index])


            end

            breakeven_index += 1
        end
    end
    # All data is returned to be analysed in depth if needed
    return payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all
end

"""
The following function analyses the NPV and break even for all SMRs for all scenarios. This method corrects 
methodologies from the first iteration
"""
function analysis_npv_all_scenarios_iteration_two(interest_rate, ramping_cf, non_ramping_cf_constant, toPlot::Bool=false, toSave::Bool=false)
    """
    NOTE - How the data is organized
    From the way that the below analysis is coded, the calculated data has been pushed to the above array as follows:
    All scenarios are calculated for an SMR, then pushed onto the array before moving onto the next SMR prototype.
    This is continued till all calculations have been completed for all SMR prototypes.
    """

    # Array for all payouts
    payouts_all = []

    # Array for all generation
    generationOutput_all = []

    # Array for all NPV's
    npv_tracker_all = []

    # Array for all break even times
    break_even_all = []

    # Array for all NPV per year info
    npv_payoff_all = []

    """
    The following constants were used 
    """
    # Interest Rate explored
    interest_rate_wacc = interest_rate

    # Ramping CF used
    ramping_cf_constant = ramping_cf

    # Non-Ramping CF used
    non_ramping_cf_constant = non_ramping_cf_constant

    # The price multiplication factor of the average that ramping begins, 1.3
    price_multiplication_factor_constant = 1.3

    # The path that this method will print plots to
    pathname = "/Users/pradyrao/Desktop/thesis_plots/scenario_plots"

    # The path that the data will be saved to
    datapath = "/Users/pradyrao/Desktop/thesis_plots/thesis_data"


    ### Running each SMR through each scenario ###

    # For loop to go through each SMR prototype
    for (index, cost_array) in enumerate(smr_cost_vals)
        

        ### Curating the scenarios to run the SMRs through ###
        
        # Creating an empty array to store price date of all scenarios
        scenario_price_data_all = []
        
        # Creating a temporary array to store the price data of each scenario
        scenario_price_data_temp = []

        # Creating an empty array to store the breakeven value
        breakevenvals_array = []

        # Creating an empty array to store the lifetime payout
        smrpayouts_array = []

        # Creating empty array for scenario information
        scenario_prototype_array = []

        """
        TODO: The following for loop is a bit messy and needs to be cleaned up.
        """
        # Loop curating the scenarios each have to run through
        for (index3, scenario) in enumerate(scenario_data_all)
            if index3 == 1 || index3 == 2 || index3 == 3
                push!(scenario_price_data_all, scenario)
                continue
            end
            
            # If the length of the temporary array is 8, then push it into the main array
            if length(scenario_price_data_temp) == 8
                push!(scenario_price_data_all, create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], cost_array[2]))
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                # Otherwise, add to the array and continue
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end

        # Pushing the last scenario into the array
        push!(scenario_price_data_all, create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], cost_array[2]))
        
        ### Curating the scenarios to run the SMRs through ###



        ### Running each SMR through each scenario ###


        for (index2, scenario_array) in enumerate(scenario_price_data_all)
            if index2 == 1 || index2 == 2 || index2 == 3
                # Run a separate code for the first three scenarios in Texas and Germany
                if index == 5
                    # If it's NuScale, there are 4 modules
                    payout_run, generation_run = smr_dispatch_iteration_one(scenario_array, non_ramping_cf_constant, ramping_cf_constant, cost_array[1], price_multiplication_factor_constant, 4)
                    npv_tracker_run, break_even_run, npv_payoff_run = npv_calc(payout_run, interest_rate_wacc, initial_investment_calculation(cost_array[1], cost_array[3], cost_array[5], 4), cost_array[2])
                else
                    payout_run, generation_run = smr_dispatch_iteration_one(scenario_array, non_ramping_cf_constant, ramping_cf_constant, cost_array[1], price_multiplication_factor_constant, 1)
                    npv_tracker_run, break_even_run, npv_payoff_run = npv_calc(payout_run, interest_rate_wacc, initial_investment_calculation(cost_array[1], cost_array[3], cost_array[5], 1), cost_array[2])
                end
                # Pushing in all the calculated values 
                push!(payouts_all, payout_run)
                push!(generationOutput_all, generation_run)
                push!(npv_tracker_all, npv_tracker_run)
                push!(break_even_all, break_even_run)
                push!(npv_payoff_all, npv_payoff_run)
                # These are for plotting
                push!(breakevenvals_array, break_even_run)
                push!(smrpayouts_array, sum(payout_run))
                push!(scenario_prototype_array, scenario_array)
                continue

            else
                # Run the scenario codes
                # if it's NuScale, there are 4 modules
                if index == 5
                    # Using the npv scenario calculations
                    payout_run, generation_run = smr_dispatch_iteration_one(scenario_array, non_ramping_cf_constant, ramping_cf_constant, cost_array[1], price_multiplication_factor_constant, 4)
                    npv_tracker_run, break_even_run, npv_payoff_run = npv_calc_scenario(payout_run, interest_rate_wacc, initial_investment_calculation(cost_array[1], cost_array[3], cost_array[5], 4), cost_array[2])
                    # Pushing in all the calculated values 
                    push!(payouts_all, payout_run)
                    push!(generationOutput_all, generation_run)
                    push!(npv_tracker_all, npv_tracker_run)
                    push!(break_even_all, break_even_run)
                    push!(npv_payoff_all, npv_payoff_run)
                    # These are for plotting
                    push!(breakevenvals_array, break_even_run)
                    push!(smrpayouts_array, sum(payout_run))
                    push!(scenario_prototype_array, scenario_array)
                    continue
                else
                    # If not NuScale, use the scenario run with just one module
                    payout_run, generation_run = smr_dispatch_iteration_one(scenario_array, non_ramping_cf_constant, ramping_cf_constant, cost_array[1], price_multiplication_factor_constant, 1)
                    npv_tracker_run, break_even_run, npv_payoff_run = npv_calc_scenario(payout_run, interest_rate_wacc, initial_investment_calculation(cost_array[1], cost_array[3], cost_array[5], 1), cost_array[2])
                    # Pushing in all the calculated values 
                    push!(payouts_all, payout_run)
                    push!(generationOutput_all, generation_run)
                    push!(npv_tracker_all, npv_tracker_run)
                    push!(break_even_all, break_even_run)
                    push!(npv_payoff_all, npv_payoff_run)
                    # These are for plotting
                    push!(breakevenvals_array, break_even_run)
                    push!(smrpayouts_array, sum(payout_run))
                    push!(scenario_prototype_array, scenario_array)
                    continue
                end
            end
        end
        # If plots are to be saved
        if toPlot
            # Plotting the data
            #display_bar_and_box_plot(scenario_names_combined, smrpayouts_array, scenario_prototype_array, smr_names[index], "Scenarios Run", "NPV [\$]", "Electricity Prices [\$/MWh]", smr_names[index], pathname)
            println("Length of the breakeven array is $(length(breakevenvals_array))")
            println("Length of the scenario prototype array is $(length(scenario_prototype_array))")
            plot_bar_and_box(scenario_names_combined, breakevenvals_array, scenario_prototype_array, smr_names[index], "Scenarios Run", "Break Even [Years]", "Electricity Prices [\$/MWh]", smr_names[index], pathname)
        end

        # If the data is to be saved
        if toSave
            # Saving the data
            export_to_csv(scenario_names_combined, smrpayouts_array, breakevenvals_array, scenario_prototype_array, joinpath(datapath, "smr_data_$index.csv"))
        end
    end

    ### Running each SMR through each scenario ###


    return payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all
end

"""
The following function analyses the NPV and break even for all SMRs for all scenarios. This method corrects 
dispatch methodology from the second iteration, and has space for running multiple cases for sensitivity
analyses.

@interest_rate: The interest rate used for the WACC

@construction_start: The year that construction starts

@construction_delay: Years of delay in construction

@construction_interest_rate: The interest rate used for the construction delay, around 10% based on the paper
https://www.sciencedirect.com/science/article/pii/S0301421518303446

@production_credit: The credit given for the electricity produced [\$/MWh]

@production_start: The year that the production credit starts

@production_end: The year that the production credit ends

@toPlot: If the results are to be plotted
"""
function analysis_npv_all_scenarios_iteration_three(interest_rate::Float64, construction_start::Int, construction_delay::Int, 
    construction_interest_rate::Float64, production_credit::Float64, production_start::Int, production_end::Int, 
    toPlot::Bool=false, toIncludeATBcost::Bool=false)
    """
    NOTE - How the data is organized
    From the way that the below analysis is coded, the calculated data has been pushed to the above array as follows:
    All scenarios are calculated for an SMR, then pushed onto the array before moving onto the next SMR prototype.
    This is continued till all calculations have been completed for all SMR prototypes.
    """

    # Array for all payouts
    payouts_all = []

    # Array for all generation
    generationOutput_all = []

    # Array for all NPV's
    npv_tracker_all = []

    # Array for all break even times
    break_even_all = []

    # Array for all NPV per year info
    npv_payoff_all = []

    """
    The following constants were used 
    """
    # Interest Rate explored
    interest_rate_wacc = interest_rate

    # The path that this method will print plots to
    pathname = "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall"

    # The path that the data will be saved to
    datapath = "/Users/pradyrao/Desktop/thesis_plots/thesis_data"


    ### Running each SMR through each scenario ###

    # For loop to go through each SMR prototype
    for (index, cost_array) in enumerate(smr_cost_vals)
        ### Curating the scenarios to run the SMRs through ###
        # Creating an empty array to store price date of all scenarios
        scenario_price_data_all = []
        
        # Creating a temporary array to store the price data of each scenario
        scenario_price_data_temp = []

        # Creating an empty array to store the breakeven value
        breakevenvals_array = []

        # Creating an empty array to store the lifetime payout
        smrpayouts_array = []

        # Creating empty array for scenario information
        scenario_prototype_array = []

        """
        TODO: The following for loop is a bit messy and needs to be cleaned up.
        """
        # Loop curating the scenarios each have to run through
        for (index3, scenario) in enumerate(scenario_data_all)
            if index3 == 1 || index3 == 2 || index3 == 3
                push!(scenario_price_data_all, scenario)
                continue
            end
            
            # If the length of the temporary array is 8, then push it into the main array
            if length(scenario_price_data_temp) == 8
                push!(scenario_price_data_all, create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (cost_array[2] + construction_delay)))
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                # Otherwise, add to the array and continue
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end

        # Pushing the last scenario into the array
        push!(scenario_price_data_all, create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (cost_array[2] + construction_delay)))
        
        ### Curating the scenarios to run the SMRs through ###

        ### Creating the variables for the SMR dispatch ###
        if index != 20 || index != 21 || index != 22
            ## If it's not the SMRs that are not in the ATB
            
            # Module size
            module_size = cost_array[1]

            # Number of modules
            numberof_modules = Int(cost_array[6])

            # Fuel cost
            fuel_cost = cost_array[4]

            # Lifetime of the SMR
            smr_lifetime = Int64(cost_array[2])

            # Construction cost of the SMR
            construction_cost = cost_array[3]

            # O&M cost of the SMR
            om_cost = cost_array[5]

            # Construction duration of the SMR
            construction_duration = cost_array[7]

            # Refueling min time
            refueling_min_time = Int64(cost_array[8])

            # Refueling max time
            refueling_max_time = Int64(cost_array[9])
        else
            ## If it's the SMRs that are in the ATB

            # Module size
            module_size = cost_array[1]

            # Number of modules
            numberof_modules = Int(cost_array[7])

            # Fuel cost
            fuel_cost = cost_array[4]

            # Lifetime of the SMR
            smr_lifetime = cost_array[2]

            # Construction cost of the SMR
            construction_cost = cost_array[3]

            # Fixed O&M cost of the SMR
            fom_cost = cost_array[5]

            # Variable O&M cost of the SMR
            vom_cost = cost_array[6]
            
            # Construction duration of the SMR
            construction_duration = cost_array[8]

            # Refueling min time
            refueling_min_time = Int64(cost_array[9])

            # Refueling max time
            refueling_max_time = Int64(cost_array[10])
        end

        # 

        ### Adjusting the OCC and O&M costs for the ATB data ###
        if toIncludeATBcost
            if index != 20 || index != 21 || index != 22
                if numberof_modules > 1 && numberof_modules < 4
                    # Adjusting the O&M and capital costs
                    om_cost = om_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 2, :OM_Cost_Reduction]
                    construction_cost = construction_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 2, :OCC_Cost_Reduction]
                elseif numberof_modules >= 4 && numberof_modules < 8
                    # Adjusting the O&M and capital costs
                    om_cost = om_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 4, :OM_Cost_Reduction]
                    construction_cost = construction_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 4, :OCC_Cost_Reduction]
                elseif numberof_modules >= 8 && numberof_modules < 10
                    # Adjusting the O&M and capital costs
                    om_cost = om_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 8, :OM_Cost_Reduction]
                    construction_cost = construction_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 8, :OCC_Cost_Reduction]
                elseif numberof_modules >= 10
                    # Adjusting the O&M and capital costs
                    om_cost = om_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 10, :OM_Cost_Reduction]
                    construction_cost = construction_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 10, :OCC_Cost_Reduction]
                end
            else
                if numberof_modules > 1 && numberof_modules < 4
                    # Adjusting the O&M and capital costs
                    fom_cost = fom_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 2, :OM_Cost_Reduction]
                    vom_cost = vom_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 2, :OM_Cost_Reduction]
                    construction_cost = construction_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 2, :OCC_Cost_Reduction]
                elseif numberof_modules >= 4 && numberof_modules < 8
                    # Adjusting the O&M and capital costs
                    fom_cost = fom_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 4, :OM_Cost_Reduction]
                    vom_cost = vom_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 4, :OM_Cost_Reduction]
                    construction_cost = construction_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 4, :OCC_Cost_Reduction]
                elseif numberof_modules >= 8 && numberof_modules < 10
                    # Adjusting the O&M and capital costs
                    fom_cost = fom_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 8, :OM_Cost_Reduction]
                    vom_cost = vom_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 8, :OM_Cost_Reduction]
                    construction_cost = construction_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 8, :OCC_Cost_Reduction]
                elseif numberof_modules >= 10
                    # Adjusting the O&M and capital costs
                    fom_cost = fom_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 10, :OM_Cost_Reduction]
                    vom_cost = vom_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 10, :OM_Cost_Reduction]
                    construction_cost = construction_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 10, :OCC_Cost_Reduction]
                end
            end
        end

        # Calculating the lead time
        start_reactor = Int(ceil(((construction_start - 2024)*12 + construction_duration + (construction_delay*12))/12))
        ### Running each SMR through each scenario ###


        for (index2, scenario_array) in enumerate(scenario_price_data_all)
            if index2 == 1 || index2 == 2 || index2 == 3
                if index == 20 || index == 21 || index == 22
                    # Run a separate code for the first three scenarios in Texas and Germany, but the ATB reactors need different calculations
                    payout_run, generation_run = smr_dispatch_iteration_three_withATB(scenario_array, module_size, numberof_modules, fuel_cost, vom_cost, production_credit, start_reactor, production_start, production_end, refueling_max_time, refueling_min_time, smr_lifetime)
                    npv_tracker_run, break_even_run, npv_tracker_run = npv_calc(payout_run, interest_rate_wacc, calculate_total_investment_with_cost_of_delay(construction_interest_rate, module_size, construction_cost, (fom_cost*smr_lifetime), numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))), smr_lifetime)
                else
                    # Run a separate code for the first three scenarios in Texas and Germany
                    payout_run, generation_run = smr_dispatch_iteration_three(scenario_array, module_size, numberof_modules, fuel_cost, production_credit, start_reactor, production_start, production_end, refueling_max_time, refueling_min_time, smr_lifetime)
                    npv_tracker_run, break_even_run, npv_payoff_run = npv_calc(payout_run, interest_rate_wacc, calculate_total_investment_with_cost_of_delay(construction_interest_rate, module_size, construction_cost, om_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))), smr_lifetime)
                end
                # Pushing in all the calculated values 
                push!(payouts_all, payout_run)
                push!(generationOutput_all, generation_run)
                push!(npv_tracker_all, npv_tracker_run)
                push!(break_even_all, break_even_run)
                push!(npv_payoff_all, npv_payoff_run)
                # These are for plotting
                push!(breakevenvals_array, break_even_run)
                push!(smrpayouts_array, sum(payout_run))
                push!(scenario_prototype_array, scenario_array)
                continue

            else
                if index == 20 || index == 21 || index == 22
                    # If it's the ATB reactors, run the ATB reactor code
                    payout_run, generation_run = smr_dispatch_iteration_three_withATB(scenario_array, module_size, numberof_modules, fuel_cost, vom_cost, production_credit, start_reactor, production_start, production_end, refueling_max_time, refueling_min_time, smr_lifetime)
                    npv_tracker_run, break_even_run, npv_payoff_run = npv_calc_scenario(payout_run, interest_rate_wacc, calculate_total_investment_with_cost_of_delay(construction_interest_rate, module_size, construction_cost, (fom_cost*smr_lifetime), numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))), Float64(smr_lifetime))
                else
                    # Run the scenario codes
                    payout_run, generation_run = smr_dispatch_iteration_three(scenario_array, module_size, numberof_modules, fuel_cost, production_credit, start_reactor, production_start, production_end, refueling_max_time, refueling_min_time, smr_lifetime)
                    npv_tracker_run, break_even_run, npv_payoff_run = npv_calc_scenario(payout_run, interest_rate_wacc, calculate_total_investment_with_cost_of_delay(construction_interest_rate, module_size, construction_cost, om_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))), Float64(smr_lifetime))
                end
                # Pushing in all the calculated values 
                push!(payouts_all, payout_run)
                push!(generationOutput_all, generation_run)
                push!(npv_tracker_all, npv_tracker_run)
                push!(break_even_all, break_even_run)
                push!(npv_payoff_all, npv_payoff_run)
                # These are for plotting
                push!(breakevenvals_array, break_even_run)
                push!(smrpayouts_array, sum(payout_run))
                push!(scenario_prototype_array, scenario_array)
                continue
            end
        end

        # TODO: The following code is incorrect with plotting and saving and needs to be fixed
        # If plots are to be saved
        if toPlot
            # Plotting the data
            #display_bar_and_box_plot(scenario_names_combined, smrpayouts_array, scenario_prototype_array, smr_names[index], "Scenarios Run", "NPV [\$]", "Electricity Prices [\$/MWh]", smr_names[index], pathname)
            #println("Length of the breakeven array is $(length(breakevenvals_array))")
            #println("Length of the scenario prototype array is $(length(scenario_prototype_array))")
            plot_bar_and_box_rcall(breakevenvals_array, scenario_prototype_array, scenario_names_combined, "Break Even [Years]", "Electricity Prices [\$/MWh]", "Scenarios Run", smr_names[index], pathname)
        end
    end

    ### Running each SMR through each scenario ###


    return payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all
end

"""
Starting the sensitivity analysis for the NPV and break even. The following should be analysed:
    - Interest Rate sensitivity
    - Construction Cost sensitivity
        - Learning Rate sensitivity
    - Fuel Cost sensitivity
    - Lead time delay sensitivity
    - Capacity Market sensitivity
    - Ancillary Services sensitivity
"""
function analysis_sensitivity_npv_breakeven()
    # This method will contain the sensitivity to the NPV and break even
end

"""
Starting analysis of addition of capacity markets and ancillary services to see how they would affect the NPV and break even
"""
function analysis_capacity_markets_ancillary_services(interest_rate::Float64, construction_delay:: Int, capacity_market_analysis::Bool, ancillary_services_analysis::Bool, percent_ancillary_services::Float64, toPlot::Bool, toSave::Bool)
    # This method will contain the analysis of capacity markets and ancillary services
            ### Curating the scenarios to run the SMRs through ###
        
        # Creating an empty array to store price date of all scenarios
        scenario_price_data_all = []
        
        # Creating a temporary array to store the price data of each scenario
        scenario_price_data_temp = []

        # Creating an empty array to store the breakeven value
        breakevenvals_array = []

        # Creating an empty array to store the lifetime payout
        smrpayouts_array = []

        # Creating empty array for scenario information
        scenario_prototype_array = []

        """
        TODO: The following for loop is a bit messy and needs to be cleaned up.
        """
        # Loop curating the scenarios each have to run through
        for (index3, scenario) in enumerate(scenario_data_all)
            if index3 == 1 || index3 == 2 || index3 == 3
                push!(scenario_price_data_all, scenario)
                continue
            end
            
            # If the length of the temporary array is 8, then push it into the main array
            if length(scenario_price_data_temp) == 8
                push!(scenario_price_data_all, create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], cost_array[2]))
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                # Otherwise, add to the array and continue
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end

        # Pushing the last scenario into the array
        push!(scenario_price_data_all, create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], cost_array[2]))
        
        ### Curating the scenarios to run the SMRs through ###


        ### Running each SMR through each scenario ###


        ### Running each SMR through each scenario ###
end