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
analyses. Baseline inputs are defined by default, and the user can change the inputs as needed.

@interest_rate: The interest rate used for the WACC

@construction_start: The year that construction starts

@construction_delay: Years of delay in construction

@construction_interest_rate: The interest rate used for the construction delay, around 10% based on the paper
https://www.sciencedirect.com/science/article/pii/S0301421518303446

@production_credit: The credit given for the electricity produced [\$/MWh]

@production_start: The year that the production credit starts

@production_end: The year that the production credit ends

@construction_cost_reduction_factor: The factor that the construction cost is reduced or increased by

@toPlot: If the results are to be plotted
"""
function analysis_npv_all_scenarios_iteration_three(interest_rate::Float64=0.04, construction_start::Int=2024, construction_delay::Int=0, construction_interest_rate::Float64=0.04, 
    production_credit::Float64=0.0, production_duration::Int=10, construction_cost_reduction_factor::Float64=1.0, fom_cost_reduction_factor::Float64=1.0, 
    vom_cost_reduction_factor::Float64=1.0, fuel_cost_reduction_factor::Float64=1.0, capacity_market_rate::Float64=0.0, toPlot::Bool=false, 
    toIncludeATBcost::Bool=false, toIncludeITC::Bool=false, itc_case::String="", c2n_cost_advantages::Bool=false, analysis_pathname::String="")
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

    # Final NPV value after lifetime
    npv_final_all = []

    # Array to calculate Internal Rate of Return
    irr_all = []

    # Array to host construction cost
    construction_cost_all = []

    """
    The following constants were used 
    """
    # Interest Rate explored
    interest_rate_wacc = interest_rate

    # The path that this method will print plots to
    pathname = analysis_pathname


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

        # Creating an empty array to track the IRR
        irr_prototype_array = []

        # Creating an empty array to track the NPV
        npv_prototype_array = []


        ### Creating the variables for the SMR dispatch ###
        if index < 20
            ## If it's not the SMRs that are not in the ATB
                    
            # Module size
            module_size = cost_array[1]
        
            # Number of modules
            numberof_modules = Int(cost_array[6])
        
            # Fuel cost
            fuel_cost = cost_array[4]*fuel_cost_reduction_factor
        
            # Lifetime of the SMR
            smr_lifetime = Int64(cost_array[2])
        
            # Construction cost of the SMR
            construction_cost = cost_array[3]*construction_cost_reduction_factor
        
            # O&M cost of the SMR
            om_cost = cost_array[5]*fom_cost_reduction_factor
        
            # Construction duration of the SMR
            construction_duration = cost_array[7]
        
            # Refueling min time
            refueling_min_time = Int64(cost_array[8])
        
            # Refueling max time
            refueling_max_time = Int64(cost_array[9])

            # Scenario
            scenario = cost_array[10]
        else
            ## If it's the SMRs that are in the ATB
        
            # Module size
            module_size = cost_array[1]
        
            # Number of modules
            numberof_modules = Int(cost_array[7])
        
            # Fuel cost
            fuel_cost = cost_array[4]*fuel_cost_reduction_factor
        
            # Lifetime of the SMR
            smr_lifetime = Int64(cost_array[2])
        
            # Construction cost of the SMR
            construction_cost = cost_array[3]*construction_cost_reduction_factor
        
            # Fixed O&M cost of the SMR
            fom_cost = cost_array[5]*fom_cost_reduction_factor
        
            # Variable O&M cost of the SMR
            vom_cost = cost_array[6]*vom_cost_reduction_factor
                    
            # Construction duration of the SMR
            construction_duration = cost_array[8]
        
            # Refueling min time
            refueling_min_time = Int64(cost_array[9])
        
            # Refueling max time
            refueling_max_time = Int64(cost_array[10])

            # Scenario
            scenario = cost_array[11]
        end

        # Calculating the lead time
        start_reactor = Int(ceil(((construction_start - 2024)*12 + construction_duration + (construction_delay*12))/12))

        ### Curating the scenarios to run the SMRs through ###
        for (index3, scenario) in enumerate(scenario_data_all)
            if index3 == 1 || index3 == 2 || index3 == 3
                push!(scenario_price_data_all, create_scenario_array(scenario, scenario, scenario, scenario, scenario, scenario, scenario, scenario, (smr_lifetime + start_reactor)))

                continue
            end
            
            # If the length of the temporary array is 8, then push it into the main array
            if length(scenario_price_data_temp) == 8
                push!(scenario_price_data_all, create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (smr_lifetime + start_reactor)))
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                # Otherwise, add to the array and continue
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end

        # Pushing the last scenario into the array
        push!(scenario_price_data_all, create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (smr_lifetime + start_reactor)))
        ### Curating the scenarios to run the SMRs through ###



        ### Adjusting the OCC and O&M costs for the ATB data ###
        if toIncludeATBcost
            if index != 20 || index != 21 || index != 22
                if numberof_modules > 1 && numberof_modules < 4
                    # Adjusting the O&M and capital costs
                    om_cost = om_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 2, :OM_Cost_Reduction][1]
                    construction_cost = construction_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 2, :OCC_Cost_Reduction][1]
                elseif numberof_modules >= 4 && numberof_modules < 8
                    # Adjusting the O&M and capital costs
                    om_cost = om_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 4, :OM_Cost_Reduction][1]
                    construction_cost = construction_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 4, :OCC_Cost_Reduction][1]
                elseif numberof_modules >= 8 && numberof_modules < 10
                    # Adjusting the O&M and capital costs
                    om_cost = om_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 8, :OM_Cost_Reduction][1]
                    construction_cost = construction_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 8, :OCC_Cost_Reduction][1]
                elseif numberof_modules >= 10
                    # Adjusting the O&M and capital costs
                    om_cost = om_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 10, :OM_Cost_Reduction][1]
                    construction_cost = construction_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 10, :OCC_Cost_Reduction][1]
                end
            else
                if numberof_modules > 1 && numberof_modules < 4
                    # Adjusting the O&M and capital costs
                    fom_cost = fom_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 2, :OM_Cost_Reduction][1]
                    vom_cost = vom_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 2, :OM_Cost_Reduction][1]
                    construction_cost = construction_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 2, :OCC_Cost_Reduction][1]
                elseif numberof_modules >= 4 && numberof_modules < 8
                    # Adjusting the O&M and capital costs
                    fom_cost = fom_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 4, :OM_Cost_Reduction][1]
                    vom_cost = vom_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 4, :OM_Cost_Reduction][1]
                    construction_cost = construction_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 4, :OCC_Cost_Reduction][1]
                elseif numberof_modules >= 8 && numberof_modules < 10
                    # Adjusting the O&M and capital costs
                    fom_cost = fom_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 8, :OM_Cost_Reduction][1]
                    vom_cost = vom_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 8, :OM_Cost_Reduction][1]
                    construction_cost = construction_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 8, :OCC_Cost_Reduction][1]
                elseif numberof_modules >= 10
                    # Adjusting the O&M and capital costs
                    fom_cost = fom_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 10, :OM_Cost_Reduction][1]
                    vom_cost = vom_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 10, :OM_Cost_Reduction][1]
                    construction_cost = construction_cost * multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 10, :OCC_Cost_Reduction][1]
                end
            end
        end

        if c2n_cost_advantages
            if index < 20
                # If not the ATB values
                if scenario == "Advanced"
                    # Adjusting the O&M costs
                    om_cost = (om_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "Fixed O&M", :Advanced])[1]
                    construction_cost = construction_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "OCC 2030", :Advanced][1]
                    fuel_cost = fuel_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "Fuel Cost", :Advanced][1]
                elseif scenario == "Moderate"
                    # Adjusting the O&M and capital costs
                    om_cost = om_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "Fixed O&M", :Moderate][1]
                    construction_cost = construction_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "OCC 2030", :Moderate][1]
                    fuel_cost = fuel_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "Fuel Cost", :Moderate][1]
                elseif scenario == "Conservative"
                    # Adjusting the O&M and capital costs
                    om_cost = om_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "Fixed O&M", :Conservative][1]
                    construction_cost = construction_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "OCC 2030", :Conservative][1]
                    fuel_cost = fuel_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "Fuel Cost", :Conservative][1]
                end
            else
                # If the ATB Reactors
                if scenario == "Advanced"
                    # Adjusting the O&M costs
                    vom_cost = vom_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "Variable O&M", :Advanced][1]
                    fom_cost = fom_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "Fixed O&M", :Advanced][1]
                    construction_cost = construction_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "OCC 2030", :Advanced][1]
                    fuel_cost = fuel_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "Fuel Cost", :Advanced][1]
                elseif scenario == "Moderate"
                    # Adjusting the O&M and capital costs
                    vom_cost = vom_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "Variable O&M", :Moderate][1]
                    fom_cost = fom_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "Fixed O&M", :Moderate][1]
                    construction_cost = construction_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "OCC 2030", :Moderate][1]
                    fuel_cost = fuel_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "Fuel Cost", :Moderate][1]
                elseif scenario == "Conservative"
                    # Adjusting the O&M and capital costs
                    vom_cost = vom_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "Variable O&M", :Conservative][1]
                    fom_cost = fom_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "Fixed O&M", :Conservative][1]
                    construction_cost = construction_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "OCC 2030", :Conservative][1]
                    fuel_cost = fuel_cost * c2n_cost_reduction[c2n_cost_reduction.Category .== "Fuel Cost", :Conservative][1]
                end
            end
        end

        if toIncludeITC
            if scenario == "Advanced"
                # Adjusting the construction costs
                construction_cost = construction_cost * itc_cost_reduction[itc_cost_reduction.Category .== itc_case, :Advanced][1]
            elseif scenario == "Moderate"
                # Adjusting the construction costs
                construction_cost = construction_cost * itc_cost_reduction[itc_cost_reduction.Category .== itc_case, :Moderate][1]
            elseif scenario == "Conservative"
                # Adjusting the construction costs
                construction_cost = construction_cost * itc_cost_reduction[itc_cost_reduction.Category .== itc_case, :Conservative][1]
            end
        end

        ### Adjusting the OCC and O&M costs for the ATB data ###


        ### Running each SMR through each scenario ###

        for (index2, scenario_array) in enumerate(scenario_price_data_all)
            if index >= 20
                # If it's the ATB reactors, run the ATB reactor code
                payout_run, generation_run = smr_dispatch_iteration_three_withATB(scenario_array, module_size, numberof_modules, fuel_cost, vom_cost, production_credit, start_reactor, production_duration, refueling_max_time, refueling_min_time, smr_lifetime)
                # If there is a capacity market rate, run the capacity market analysis
                payout_run = capacity_market_analysis(capacity_market_rate, payout_run, numberof_modules, module_size)
                irr_run = calculate_irr(payout_run, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), construction_cost, (fom_cost*smr_lifetime), numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))))
                npv_tracker_run, break_even_run, npv_payoff_run = npv_calc_scenario(payout_run, interest_rate_wacc, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), construction_cost, (fom_cost*smr_lifetime), numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))), (smr_lifetime + start_reactor))
                push!(construction_cost_all, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), construction_cost, (fom_cost*smr_lifetime), numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))))
            else
                # Run the scenario codes
                payout_run, generation_run = smr_dispatch_iteration_three(scenario_array, module_size, numberof_modules, fuel_cost, production_credit, start_reactor, production_duration, refueling_max_time, refueling_min_time, smr_lifetime)
                payout_run = capacity_market_analysis(capacity_market_rate, payout_run, numberof_modules, module_size)
                irr_run = calculate_irr(payout_run, calculate_total_investment_with_cost_of_delay(construction_interest_rate, module_size, construction_cost, om_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))))
                npv_tracker_run, break_even_run, npv_payoff_run = npv_calc_scenario(payout_run, interest_rate_wacc, calculate_total_investment_with_cost_of_delay(construction_interest_rate, module_size, construction_cost, om_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))), (smr_lifetime + start_reactor))
                push!(construction_cost_all, calculate_total_investment_with_cost_of_delay(construction_interest_rate, module_size, construction_cost, om_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))))
            end

            # Pushing in all the calculated values 
            push!(payouts_all, payout_run)
            push!(generationOutput_all, generation_run)
            push!(npv_tracker_all, npv_tracker_run)
            push!(break_even_all, break_even_run)
            push!(npv_payoff_all, npv_payoff_run)
            push!(irr_all, irr_run)
            push!(npv_final_all, npv_tracker_run[end])
            # These are for plotting
            push!(breakevenvals_array, break_even_run)
            #push!(smrpayouts_array, sum(payout_run))
            push!(scenario_prototype_array, scenario_array)
            push!(irr_prototype_array, irr_run)
            push!(npv_prototype_array, npv_tracker_run[end])

        end
        # If plots are to be saved
        if toPlot
            # Plotting the data
            plot_bar_and_box_pycall(scenario_names_combined, breakevenvals_array, scenario_prototype_array, "Break Even [Years]", "Electricity Prices [\$/MWh]", "Scenarios Run", "$(smr_names[index]) Break Even", pathname)
            plot_bar_and_box_pycall(scenario_names_combined, npv_prototype_array, scenario_prototype_array, "NPV [\$]", "Electricity Prices [\$/MWh]", "Scenarios Run", "$(smr_names[index]) NPV", pathname)
            plot_bar_and_box_pycall(scenario_names_combined, irr_prototype_array, scenario_prototype_array, "IRR", "Electricity Prices [\$/MWh]", "Scenarios Run", "$(smr_names[index]) IRR", pathname)
        end
    end

    ### Running each SMR through each scenario ###


    return payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all
end

"""
Starting the sensitivity analysis for the NPV and break even. The following should be analysed:
    - Interest Rate sensitivity
    - Construction Cost sensitivity
        - Learning Rate sensitivity
    - Lead time delay sensitivity
    - Capacity Market sensitivity
    - Production Tax Credit sensitivity
    - C2N Cost advantages
    - Including the ATB cost reductions from multi-module builds

Boolean values are used to determine which sensitivity analysis is to be run, for computational tractibility
Check only one analysis at a time.
"""
function analysis_sensitivity_npv_breakeven()

    ##### Baseline Analysis #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/Baseline_Runs_Breakeven_Results")
    # baseline_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "baseline_breakeven")
    # baseline_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "baseline_npv_final")
    # baseline_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "baseline_irr")
    # baseline_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "baseline_construction_cost")
    ##### Baseline Analysis #####

    # ##### Analysis adding in multi-modular SMR learning benefits #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/mm_learning")
    # mmlearning_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "mmlearning_breakeven")
    # mmlearning_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "mmlearning_npv_final")
    # mmlearning_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "mmlearning_irr")
    # mmlearning_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "mmlearning_construction_cost")
    # ##### Analysis adding in multi-modular SMR learning benefits #####

    # ##### Analysis for Coal2Nuclear plants #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, true, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/c2n_results")
    # c2n_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline", "c2n_breakeven")
    # c2n_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline", "c2n_npv_final")
    # c2n_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline", "c2n_irr")
    # c2n_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline", "c2n_construction_cost")
    # ##### Analysis adding in multi-modular SMR learning benefits #####


    # ##### Analysis taking in locations with ITC credits - 6% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, true, "6%", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ITC_results/6%_case")
    # itc6_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline", "itc_breakeven")
    # itc6_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline", "itc_npv_final")
    # itc6_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline", "itc_irr")
    # itc6_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline", "itc_construction_cost")
    # ##### Analysis taking in locations with ITC credits - 6% #####

    # ##### Analysis taking in locations with ITC credits - 30% #####
    payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, true, "30%", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ITC_results/30%_case")
    itc30_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline", "itc30_breakeven")
    itc30_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline", "itc30_npv_final")
    itc30_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline", "itc30_irr")
    itc30_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline", "itc30_construction_cost")
    ##### Analysis taking in locations with ITC credits - 30% #####

    # ##### Analysis taking in locations with ITC credits - 40% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, true, "40%", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ITC_results/40%_case")
    # itc40_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc40_baseline", "itc40_breakeven")
    # itc40_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc40_baseline", "itc40_npv_final")
    # itc40_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc40_baseline", "itc40_irr")
    # itc40_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc40_baseline", "itc40_construction_cost")
    # ##### Analysis taking in locations with ITC credits - 40% #####

    # ##### Analysis taking in locations with ITC credits - 50% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, true, "50%", false)
    # itc50_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc50_breakeven")
    # itc50_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc50_npv_final")
    # itc50_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc50_irr")
    # itc50_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc50_construction_cost")
    # ##### Analysis taking in locations with ITC credits - 50% #####





    # ##### PTC of $11/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 11.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/11usd_10yrs")
    # ptc11_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline", "ptc11_breakeven")
    # ptc11_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline", "ptc11_npv_final")
    # ptc11_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline", "ptc11_irr")
    # ptc11_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline", "ptc11_construction_cost")
    # ##### PTC of $11/MWh for 10 years #####

    # ##### PTC of $12/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 12.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    # ptc12_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc12_breakeven")
    # ptc12_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc12_npv_final")
    # ptc12_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc12_irr")
    # ptc12_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc12_construction_cost")
    # ##### PTC of $12/MWh for 10 years #####

    # ##### PTC of $13/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 13.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    # ptc13_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc13_breakeven")
    # ptc13_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc13_npv_final")
    # ptc13_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc13_irr")
    # ptc13_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc13_construction_cost")
    # ##### PTC of $13/MWh for 10 years #####

    # ##### PTC of $14/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 14.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    # ptc14_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc14_breakeven")
    # ptc14_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc14_npv_final")
    # ptc14_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc14_irr")
    # ptc14_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc14_construction_cost")
    # ##### PTC of $14/MWh for 10 years #####

    # ##### PTC of $15/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    # ptc15_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc15_breakeven")
    # ptc15_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc15_npv_final")
    # ptc15_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc15_irr")
    # ptc15_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc15_construction_cost")
    # ##### PTC of $14/MWh for 10 years #####

    # ##### PTC of $16/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 16.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    # ptc16_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc16_breakeven")
    # ptc16_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc16_npv_final")
    # ptc16_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc16_irr")
    # ptc16_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc16_construction_cost")
    # ##### PTC of $16/MWh for 10 years #####

    # ##### PTC of $17/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 17.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    # ptc17_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc17_breakeven")
    # ptc17_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc17_npv_final")
    # ptc17_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc17_irr")
    # ptc17_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc17_construction_cost")
    # ##### PTC of $17/MWh for 10 years #####

    # ##### PTC of $18/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 18.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    # ptc18_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc18_breakeven")
    # ptc18_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc18_npv_final")
    # ptc18_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc18_irr")
    # ptc18_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc18_construction_cost")
    # ##### PTC of $18/MWh for 10 years #####

    # ##### PTC of $19/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 19.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    # ptc19_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc19_breakeven")
    # ptc19_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc19_npv_final")
    # ptc19_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc19_irr")
    # ptc19_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc19_construction_cost")
    # ##### PTC of $19/MWh for 10 years #####

    # ##### PTC of $20/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 20.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    # ptc20_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc20_breakeven")
    # ptc20_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc20_npv_final")
    # ptc20_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc20_irr")
    # ptc20_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc20_construction_cost")
    # ##### PTC of $20/MWh for 10 years #####

    # ##### PTC of $21/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 21.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    # ptc21_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc21_breakeven")
    # ptc21_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc21_npv_final")
    # ptc21_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc21_irr")
    # ptc21_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc21_construction_cost")
    # ##### PTC of $21/MWh for 10 years #####

    # ##### PTC of $22/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 22.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    # ptc22_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc22_breakeven")
    # ptc22_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc22_npv_final")
    # ptc22_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc22_irr")
    # ptc22_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc22_construction_cost")
    # ##### PTC of $22/MWh for 10 years #####

    # ##### PTC of $23/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 23.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    # ptc23_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc23_breakeven")
    # ptc23_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc23_npv_final")
    # ptc23_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc23_irr")
    # ptc23_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc23_construction_cost")
    # ##### PTC of $23/MWh for 10 years #####

    # ##### PTC of $24/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 24.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    # ptc24_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc24_breakeven")
    # ptc24_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc24_npv_final")
    # ptc24_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc24_irr")
    # ptc24_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc24_construction_cost")
    # ##### PTC of $24/MWh for 10 years #####

    # ##### PTC of $25/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 25.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    # ptc25_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc25_breakeven")
    # ptc25_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc25_npv_final")
    # ptc25_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc25_irr")
    # ptc25_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc25_construction_cost")
    # ##### PTC of $25/MWh for 10 years #####

    # ##### PTC of $26/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 26.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    # ptc26_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc26_breakeven")
    # ptc26_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc26_npv_final")
    # ptc26_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc26_irr")
    # ptc26_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc26_construction_cost")
    # ##### PTC of $26/MWh for 10 years #####

    # ##### PTC of $27.5/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 27.5, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    # ptc275_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc27.5_breakeven")
    # ptc275_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc27.5_npv_final")
    # ptc275_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc27.5_irr")
    # ptc275_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc27.5_construction_cost")
    # ##### PTC of $27.5/MWh for 10 years #####

    # ##### PTC of $28.05/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 28.05, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    # ptc2805_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc28.05_breakeven")
    # ptc2805_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc28.05_npv_final")
    # ptc2805_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc28.05_irr")
    # ptc2805_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc2805_construction_cost")
    # ##### PTC of $28.05/MWh for 10 years #####

    # ##### PTC of $30.05/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 30.05, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    # ptc3005_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc30.05_breakeven")
    # ptc3005_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc30.05_npv_final")
    # ptc3005_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc30.05_irr")
    # ptc3005_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc3005_construction_cost")
    # ##### PTC of $30.05/MWh for 10 years #####

    # ##### PTC of $33.0/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 33.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    # ptc33_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc33_breakeven")
    # ptc33_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc33_npv_final")
    # ptc33_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc33_irr")
    # ptc33_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ptc33_construction_cost")
    # ##### PTC of $33.0/MWh for 10 years #####




    # ##### Capacity Market of $1.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 1.0, false, false, false, "", false)
    # cm1_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm1_breakeven")
    # cm1_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm1_npv_final")
    # cm1_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm1_irr")
    # cm1_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm1_construction_cost")
    # ##### Capacity Market of $1.0/kW-month #####

    # ##### Capacity Market of $2.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 2.0, false, false, false, "", false)
    # cm2 = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm2_breakeven")
    # cm2_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm2_npv_final")
    # cm2_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm2_irr")
    # cm2_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm2_construction_cost")
    # ##### Capacity Market of $2.0/kW-month #####

    # ##### Capacity Market of $3.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 3.0, false, false, false, "", false)
    # cm3_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm3_breakeven")
    # cm3_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm3_npv_final")
    # cm3_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm3_irr")
    # cm3_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm3_construction_cost")
    # ##### Capacity Market of $3.0/kW-month #####

    # ##### Capacity Market of $4.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 4.0, false, false, false, "", false)
    # cm4_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm4_breakeven")
    # cm4_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm4_npv_final")
    # cm4_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm4_irr")
    # cm4_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm4_construction_cost")
    # ##### Capacity Market of $4.0/kW-month #####

    # ##### Capacity Market of $5.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, false, false, false, "", false)
    # cm5_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm5_breakeven")
    # cm5_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm5_npv_final")
    # cm5_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm5_irr")
    # cm5_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm5_construction_cost")
    # ##### Capacity Market of $5.0/kW-month #####

    # ##### Capacity Market of $6.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 6.0, false, false, false, "", false)
    # cm6_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm6_breakeven")
    # cm6_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm6_npv_final")
    # cm6_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm6_irr")
    # cm6_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm6_construction_cost")
    # ##### Capacity Market of $6.0/kW-month #####

    # ##### Capacity Market of $7.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 7.0, false, false, false, "", false)
    # cm7_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm7_breakeven")
    # cm7_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm7_npv_final")
    # cm7_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm7_irr")
    # cm7_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm7_construction_cost")
    # ##### Capacity Market of $7.0/kW-month #####

    # ##### Capacity Market of $8.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 8.0, false, false, false, "", false)
    # cm8_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm8_breakeven")
    # cm8_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm8_npv_final")
    # cm8_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm8_irr")
    # cm8_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm8_construction_cost")
    # ##### Capacity Market of $8.0/kW-month #####

    # ##### Capacity Market of $15.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 15.0, false, false, false, "", false)
    # cm15_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm15_breakeven")
    # cm15_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm15_npv_final")
    # cm15_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm15_irr")
    # cm15_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm15_construction_cost")
    # ##### Capacity Market of $15.0/kW-month #####

    # ##### Capacity Market of $16.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 16.0, false, false, false, "", false)
    # cm16_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm16_breakeven")
    # cm16_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm16_npv_final")
    # cm16_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm16_irr")
    # cm16_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm16_construction_cost")
    # ##### Capacity Market of $16.0/kW-month #####

    # ##### Capacity Market of $17.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 17.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd17kW_month")
    # cm17_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm17_breakeven")
    # cm17_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm17_npv_final")
    # cm17_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm17_irr")
    # cm17_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm17_construction_cost")
    # ##### Capacity Market of $17.0/kW-month #####

    # ##### Capacity Market of $18.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 18.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd18kW_month")
    # cm18_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm18_breakeven")
    # cm18_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm18_npv_final")
    # cm18_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm18_irr")
    # cm18_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm18_construction_cost")
    # ##### Capacity Market of $18.0/kW-month #####

    # ##### Capacity Market of $19.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 19.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd19kW_month")
    # cm19_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm19_breakeven")
    # cm19_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm19_npv_final")
    # cm19_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm19_irr")
    # cm19_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm19_construction_cost")
    # ##### Capacity Market of $19.0/kW-month #####

    # ##### Capacity Market of $20.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 20.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd20kW_month")
    # cm20_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm20_breakeven")
    # cm20_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm20_npv_final")
    # cm20_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm20_irr")
    # cm20_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm20_construction_cost")
    # ##### Capacity Market of $20.0/kW-month #####

    # ##### Capacity Market of $21.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 21.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd21kW_month")
    # cm21_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm21_breakeven")
    # cm21_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm21_npv_final")
    # cm21_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm21_irr")
    # cm21_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm21_construction_cost")
    # ##### Capacity Market of $21.0/kW-month #####

    # ##### Capacity Market of $22.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 22.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd22kW_month")
    # cm22_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm22_breakeven")
    # cm22_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm22_npv_final")
    # cm22_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm22_irr")
    # cm22_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm22_construction_cost")
    # ##### Capacity Market of $22.0/kW-month #####

    # ##### Capacity Market of $23.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 25.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd23kW_month")
    # cm23_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm23_breakeven")
    # cm23_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm23_npv_final")
    # cm23_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm23_irr")
    # cm23_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm23_construction_cost")
    # ##### Capacity Market of $23.0/kW-month #####

    # ##### Capacity Market of $25.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 25.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd25kW_month")
    # cm25_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm25_breakeven")
    # cm25_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm25_npv_final")
    # cm25_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm25_irr")
    # cm25_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "cm25_construction_cost")
    # ##### Capacity Market of $25.0/kW-month #####

    # ##### Learning Rates reducing construction costs by 5% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.95, 1.0, 1.0, 1.0, 25.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll5_case")
    # ll5_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll5_breakeven")
    # ll5_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll5_npv_final")
    # ll5_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll5_irr")
    # ll5_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll5_construction_cost")
    # ##### Learning Rates reducing construction costs by 5% #####

    # ##### Learning Rates reducing construction costs by 10% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.90, 1.0, 1.0, 1.0, 25.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll10_case")
    # ll10_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll10_breakeven")
    # ll10_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll10_npv_final")
    # ll10_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll10_irr")
    # ll10_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll10_construction_cost")
    # ##### Learning Rates reducing construction costs by 10% #####

    # ##### Learning Rates reducing construction costs by 15% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.85, 1.0, 1.0, 1.0, 25.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll15_case")
    # ll15_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll15_breakeven")
    # ll15_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll15_npv_final")
    # ll15_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll15_irr")
    # ll15_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll15_construction_cost")
    # ##### Learning Rates reducing construction costs by 15% #####

    # ##### Learning Rates reducing construction costs by 20% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.80, 1.0, 1.0, 1.0, 25.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll20_case")
    # ll20_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll20_breakeven")
    # ll20_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll20_npv_final")
    # ll20_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll20_irr")
    # ll20_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll20_construction_cost")
    # ##### Learning Rates reducing construction costs by 20% #####

    # ##### Learning Rates reducing construction costs by 25% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.75, 1.0, 1.0, 1.0, 25.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll25_case")
    # ll25_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll25_breakeven")
    # ll25_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll25_npv_final")
    # ll25_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll25_irr")
    # ll25_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll25_construction_cost")
    # ##### Learning Rates reducing construction costs by 25% #####

    # ##### Learning Rates reducing construction costs by 30% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.70, 1.0, 1.0, 1.0, 25.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll30_case")
    # ll30_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll30_breakeven")
    # ll30_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll30_npv_final")
    # ll30_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll30_irr")
    # ll30_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll30_construction_cost")
    # ##### Learning Rates reducing construction costs by 30% #####

    # ##### Learning Rates reducing construction costs by 35% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.65, 1.0, 1.0, 1.0, 25.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll35_case")
    # ll35_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll35_breakeven")
    # ll35_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll35_npv_final")
    # ll35_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll35_irr")
    # ll35_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll35_construction_cost")
    # ##### Learning Rates reducing construction costs by 35% #####

    # ##### Learning Rates reducing construction costs by 40% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.60, 1.0, 1.0, 1.0, 25.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll40_case")
    # ll40_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll40_breakeven")
    # ll40_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll40_npv_final")
    # ll40_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll40_irr")
    # ll40_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll40_construction_cost")
    # ##### Learning Rates reducing construction costs by 40% #####

    # ##### Learning Rates reducing construction costs by 45% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.55, 1.0, 1.0, 1.0, 25.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll45_case")
    # ll45_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll45_breakeven")
    # ll45_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll45_npv_final")
    # ll45_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll45_irr")
    # ll45_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll45_construction_cost")
    # ##### Learning Rates reducing construction costs by 45% #####

    # ##### Learning Rates reducing construction costs by 50% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.50, 1.0, 1.0, 1.0, 25.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll50_case")
    # ll50_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll50_breakeven")
    # ll50_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll50_npv_final")
    # ll50_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll50_irr")
    # ll50_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll50_construction_cost")
    # ##### Learning Rates reducing construction costs by 50% #####

    # ##### Learning Rates reducing construction costs by 55% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.45, 1.0, 1.0, 1.0, 25.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll55_case")
    # ll55_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll55_breakeven")
    # ll55_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll55_npv_final")
    # ll55_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll55_irr")
    # ll55_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll55_construction_cost")
    # ##### Learning Rates reducing construction costs by 55% #####

    # ##### Learning Rates reducing construction costs by 60% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.40, 1.0, 1.0, 1.0, 25.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll60_case")
    # ll60_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll60_breakeven")
    # ll60_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll60_npv_final")
    # ll60_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll60_irr")
    # ll60_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll60_construction_cost")
    # ##### Learning Rates reducing construction costs by 60% #####

    # ##### Learning Rates reducing construction costs by 65% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.35, 1.0, 1.0, 1.0, 25.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll65_case")
    # ll65_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll65_breakeven")
    # ll65_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll65_npv_final")
    # ll65_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll65_irr")
    # ll65_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll65_construction_cost")
    # ##### Learning Rates reducing construction costs by 65% #####

    # ##### Learning Rates reducing construction costs by 70% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.30, 1.0, 1.0, 1.0, 25.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll70_case")
    # ll70_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll70_breakeven")
    # ll70_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll70_npv_final")
    # ll70_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll70_irr")
    # ll70_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll70_construction_cost")
    # ##### Learning Rates reducing construction costs by 70% #####

    # ##### Learning Rates reducing construction costs by 75% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.25, 1.0, 1.0, 1.0, 25.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll75_case")
    # ll75_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll75_breakeven")
    # ll75_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll75_npv_final")
    # ll75_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll75_irr")
    # ll75_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "ll75_construction_cost")
    # ##### Learning Rates reducing construction costs by 75% #####

    # ############### Synthetic Cases ################


    # ##### Synthetic Case 1: Multi-modular, PTC $15/MWh and Capacity Market of $5.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, false, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case1")
    # synthetic_case1_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case1_breakeven")
    # synthetic_case1_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case1_npv_final")
    # synthetic_case1_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case1_irr")
    # synthetic_case1_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case1_construction_cost")
    # ##### Synthetic Case 1: Multi-modular, C2N, PTC $15/MWh and Capacity Market of $5.0/kW-month #####

    # ##### Synthetic Case 2: Multi-modular, C2N, PTC $15/MWh and Capacity Market of $5.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, false, true, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case2")
    # synthetic_case2_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case2_breakeven")
    # synthetic_case2_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case2_npv_final")
    # synthetic_case2_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case2_irr")
    # synthetic_case2_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case2_construction_cost")
    # ##### Synthetic Case 2: Multi-modular, C2N, PTC $15/MWh and Capacity Market of $5.0/kW-month #####

    # ##### Synthetic Case 3: Multi-modular, C2N, ITC 6%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, false, true, true, "6%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case3")
    # synthetic_case3_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case3_breakeven")
    # synthetic_case3_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case3_npv_final")
    # synthetic_case3_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case3_irr")
    # synthetic_case3_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case3_construction_cost")
    # ##### Synthetic Case 3: Multi-modular, C2N, ITC 6%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####

    # ##### Synthetic Case 4: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, false, true, true, "30%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case4")
    # synthetic_case4_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case4_breakeven")
    # synthetic_case4_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case4_npv_final")
    # synthetic_case4_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case4_irr")
    # synthetic_case4_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case4_construction_cost")
    # ##### Synthetic Case 4: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####

    # ##### Synthetic Case 5: Multi-modular, C2N, ITC 40%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, false, true, true, "40%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case5")
    # synthetic_case5_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case5_breakeven")
    # synthetic_case5_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case5_npv_final")
    # synthetic_case5_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case5_irr")
    # synthetic_case5_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case5_construction_cost")
    # ##### Synthetic Case 5: Multi-modular, C2N, ITC 40%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####

    # ##### Synthetic Case 6: Multi-modular, C2N, ITC 50%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, false, true, true, "40%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case6")
    # synthetic_case6_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case6_breakeven")
    # synthetic_case6_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case6_npv_final")
    # synthetic_case6_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case6_irr")
    # synthetic_case6_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case6_construction_cost")
    # ##### Synthetic Case 6: Multi-modular, C2N, ITC 50%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####

    # ##### Synthetic Case 7: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $15.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 15.0, false, true, true, "30%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case7")
    # synthetic_case7_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case7_breakeven")
    # synthetic_case7_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case7_npv_final")
    # synthetic_case7_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case7_irr")
    # synthetic_case7_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case7_construction_cost")
    # ##### Synthetic Case 7: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $15.0/kW-month #####

    # ##### Synthetic Case 8: Multi-modular, C2N, ITC 30%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 27.5, false, true, true, "30%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case8")
    # synthetic_case8_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case8_breakeven")
    # synthetic_case8_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case8_npv_final")
    # synthetic_case8_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case8_irr")
    # synthetic_case8_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case8_construction_cost")
    # ##### Synthetic Case 8: Multi-modular, C2N, ITC 30%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####

    # ##### Synthetic Case 9: Multi-modular, C2N, ITC 40%, PTC $15/MWh and Capacity Market of $15.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 15.0, false, true, true, "40%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case9")
    # synthetic_case9_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case9_breakeven")
    # synthetic_case9_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case9_npv_final")
    # synthetic_case9_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case9_irr")
    # synthetic_case9_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case9_construction_cost")
    # ##### Synthetic Case 9: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $15.0/kW-month #####

    # ##### Synthetic Case 10: Multi-modular, C2N, ITC 50%, PTC $15/MWh and Capacity Market of $15.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 15.0, false, true, true, "50%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case10")
    # synthetic_case10_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case10_breakeven")
    # synthetic_case10_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case10_npv_final")
    # synthetic_case10_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case10_irr")
    # synthetic_case10_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case10_construction_cost")
    # ##### Synthetic Case 10: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $15.0/kW-month #####

    # ##### Synthetic Case 11: Multi-modular, C2N, ITC 6%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 27.5, 10, 1.0, 1.0, 1.0, 1.0, 15.0, false, true, true, "6%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case11")
    # synthetic_case11_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case11_breakeven")
    # synthetic_case11_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case11_npv_final")
    # synthetic_case11_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case11_irr")
    # synthetic_case11_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case11_construction_cost")
    # ##### Synthetic Case 11: Multi-modular, C2N, ITC 6%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####

    # ##### Synthetic Case 12: Multi-modular, C2N, ITC 40%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 27.5, 10, 1.0, 1.0, 1.0, 1.0, 15.0, false, true, true, "40%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case12")
    # synthetic_case12_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case12_breakeven")
    # synthetic_case12_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case12_npv_final")
    # synthetic_case12_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case12_irr")
    # synthetic_case12_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case12_construction_cost")
    # ##### Synthetic Case 12: Multi-modular, C2N, ITC 40%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####

    # ##### Synthetic Case 13: Multi-modular, C2N, ITC 50%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 27.5, 10, 1.0, 1.0, 1.0, 1.0, 15.0, false, true, true, "50%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case13")
    # synthetic_case13_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case13_breakeven")
    # synthetic_case13_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case13_npv_final")
    # synthetic_case13_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case13_irr")
    # synthetic_case13_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case13_construction_cost")
    # ##### Synthetic Case 13: Multi-modular, C2N, ITC 50%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####

    # ##### Synthetic Case 14: Multi-modular, C2N, ITC 6%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 30.05, 10, 1.0, 1.0, 1.0, 1.0, 25.0, false, true, true, "6%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case14")
    # synthetic_case14_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case14_breakeven")
    # synthetic_case14_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case14_npv_final")
    # synthetic_case14_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case14_irr")
    # synthetic_case14_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case14_construction_cost")
    # ##### Synthetic Case 14: Multi-modular, C2N, ITC 6%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month #####

    # ##### Synthetic Case 15: Multi-modular, C2N, ITC 30%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 30.05, 10, 1.0, 1.0, 1.0, 1.0, 25.0, false, true, true, "30%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case15")
    # synthetic_case15_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case15_breakeven")
    # synthetic_case15_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case15_npv_final")
    # synthetic_case15_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case15_irr")
    # synthetic_case15_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case15_construction_cost")
    # ##### Synthetic Case 15: Multi-modular, C2N, ITC 30%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month #####

    # ##### Synthetic Case 16: Multi-modular, C2N, ITC 40%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 30.05, 10, 1.0, 1.0, 1.0, 1.0, 25.0, false, true, true, "40%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case16")
    # synthetic_case16_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case16_breakeven")
    # synthetic_case16_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case16_npv_final")
    # synthetic_case16_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case16_irr")
    # synthetic_case16_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case16_construction_cost")
    # ##### Synthetic Case 16: Multi-modular, C2N, ITC 40%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month #####

    # ##### Synthetic Case 17: Multi-modular, C2N, ITC 50%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 30.05, 10, 1.0, 1.0, 1.0, 1.0, 25.0, false, true, true, "50%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case17")
    # synthetic_case17_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case17_breakeven")
    # synthetic_case17_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case17_npv_final")
    # synthetic_case17_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case17_irr")
    # synthetic_case17_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case17_construction_cost")
    # ##### Synthetic Case 16: Multi-modular, C2N, ITC 40%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month #####

    ##### Synthetic Case 18: Multi-modular, C2N, ITC 50%, PTC $33.0/MWh and Capacity Market of $25.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 33.0, 10, 1.0, 1.0, 1.0, 1.0, 25.0, false, true, true, "50%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case18")
    # synthetic_case18_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case18_breakeven")
    # synthetic_case18_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case18_npv_final")
    # synthetic_case18_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case18_irr")
    # synthetic_case18_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "synthetic_case18_construction_cost")
    ##### Synthetic Case 18: Multi-modular, C2N, ITC 50%, PTC $33.0/MWh and Capacity Market of $25.0/kW-month #####

    # # println("NPV Final All: ", npv_final_all)
    # # println("NPV Tracker All: ", npv_tracker_all)
    # # println("NPV Payoff All: ", npv_payoff_all)
    # # println("Payouts All: ", length(payouts_all))
    # # println("Generation Output All: ", length(generationOutput_all))

    # ##### Baseline Analysis #####
end

"""
The following function analyses the capacity market prices for the different ISOs.
The function is to mainly plot the capacity market prices for the different ISOs.
"""
function analysis_capacity_market_prices()
    ## Extracting the capacity market data into arrays for faster analysis
    nyiso_capacity_market_price_array = extract_nyiso_capacity_prices(nyiso_capacity_market_data)
    miso_yearly_capacity_prices_array = convert_prices_to_kw_month(extract_miso_yearly_capacity_prices(miso_capacity_market_prices_old))
    miso_seasonal_capacity_prices_array = convert_prices_to_kw_month(extract_miso_yearly_capacity_prices(miso_new_cap_market_prices))
    iso_ne_capacity_market_price_array = clearing_price
    pjm_capacity_market_prices_array = convert_prices_to_kw_month(extract_prices_from_dict(pjm_capacity_market))

    ## Plotting all the price distribution for comparison in a box plot
    #plot_box_plots(nyiso_capacity_market_price_array,miso_yearly_capacity_prices_array,miso_seasonal_capacity_prices_array,iso_ne_capacity_market_price_array,pjm_capacity_market_prices_array)

    ## Creating summary statistics for the capacity market prices, which will be used to determine the runs that will be used.
    summarize_and_plot_prices(nyiso_capacity_market_price_array, miso_yearly_capacity_prices_array, miso_seasonal_capacity_prices_array, iso_ne_capacity_market_price_array, pjm_capacity_market_prices_array)
end

"""
The following function analyses the cost of delay and how it affects some of the good cases
"""
function analysis_cost_of_delay()
    # Running the analysis for the cost of delay
    cost_of_delay_analysis()
end