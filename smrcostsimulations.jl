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
        
            println("construction cost prior to any manipulations ",cost_array[3])
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
function analysis_sensitivity_npv_breakeven(interest_rate_analysis::Bool=false, construction_learning_rate_analysis::Bool=false, construction_delay_analysis::Bool=false, 
    ptc_analysis::Bool=false, ptc_duration_analysis::Bool=false, capacity_market_analysis::Bool=false, c2n_cost_advantages_analysis::Bool=false, 
    atb_cost_reduction_analysis::Bool=true, toPlot::Bool=false)

    ############################################## BASELINE ##############################################
    baseline_payouts_all, baseline_generationOutput_all, baseline_npv_tracker_all, basline_npv_payoff_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false)
    ############################################## BASELINE ##############################################

    ###### ATB Cost Reduction sensitivity analysis ######
    if atb_cost_reduction_analysis
        # Initialize an empty dictionary to store the results
        atb_cost_reduction_sensitivity_results_dict = Dict{Float64, Tuple{Any, Any, Any, Any}}()

        # Iterate over the interest rates and store the results in the dictionary
        payouts, generationOutput, npv_tracker, npv_payoff = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, true, false, nothing, false)

        # Storing the results in a Dictionary
        atb_cost_reduction_sensitivity_results_dict[1] = (payouts, generationOutput, npv_tracker, npv_payoff)
    end
    ###### ATB Cost Reduction sensitivity analysis ######

    ###### C2N Cost advantages analysis ######

    if c2n_cost_advantages_analysis
        # Initialize an empty dictionary to store the results
        c2n_cost_advantages_sensitivity_results_dict = Dict{String, Tuple{Any, Any, Any, Any}}()


        ### For the Advanced scenario case
        payouts, generationOutput, npv_tracker, npv_payoff = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 
        c2n_cost_reduction[ismissing(c2n_cost_reduction.Category .== "OCC 2030"), :Advanced], c2n_cost_reduction[ismissing(c2n_cost_reduction.Category .== "Fixed O&M"), :Advanced], 
        c2n_cost_reduction[ismissing(c2n_cost_reduction.Category .== "Variable O&M"), :Advanced], c2n_cost_reduction[ismissing(c2n_cost_reduction.Category .== "Fuel Cost"), :Advanced], 
        false, false)

        # Storing the results in a Dictionary
        c2n_cost_advantages_sensitivity_results_dict["Advanced"] = (payouts, generationOutput, npv_tracker, npv_payoff)


        ### For the Conservative scenario case
        payouts, generationOutput, npv_tracker, npv_payoff = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10,
        c2n_cost_reduction[ismissing(c2n_cost_reduction.Category .== "OCC 2030"), :Conservative], c2n_cost_reduction[ismissing(c2n_cost_reduction.Category .== "Fixed O&M"), :Conservative],
        c2n_cost_reduction[ismissing(c2n_cost_reduction.Category .== "Variable O&M"), :Conservative], c2n_cost_reduction[ismissing(c2n_cost_reduction.Category .== "Fuel Cost"), :Conservative],
        false, false)

        # Storing the results in a Dictionary
        c2n_cost_advantages_sensitivity_results_dict["Conservative"] = (payouts, generationOutput, npv_tracker, npv_payoff)


        ### For the Moderate scenario case
        payouts, generationOutput, npv_tracker, npv_payoff = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10,
        c2n_cost_reduction[ismissing(c2n_cost_reduction.Category .== "OCC 2030"), :Moderate], c2n_cost_reduction[ismissing(c2n_cost_reduction.Category .== "Fixed O&M"), :Moderate],
        c2n_cost_reduction[ismissing(c2n_cost_reduction.Category .== "Variable O&M"), :Moderate], c2n_cost_reduction[ismissing(c2n_cost_reduction.Category .== "Fuel Cost"), :Moderate],
        false, false)

        # Storing the results in a Dictionary
        c2n_cost_advantages_sensitivity_results_dict["Moderate"] = (payouts, generationOutput, npv_tracker, npv_payoff)
    end

    ###### C2N Cost advantages analysis ######

    ###### Interest Rate sensitivity analysis ######
    if interest_rate_analysis
        # Interest Rate sensitivity cases
        interest_rate_sensitivity = collect(range(0.01, step=0.01, stop=0.15))

        # Initialize an empty dictionary to store the results
        interest_rate_sensitivity_results_dict = Dict{Float64, Tuple{Any, Any, Any, Any}}()

        # Iterate over the interest rates and store the results in the dictionary
        for interest_rate in interest_rate_sensitivity
            payouts, generationOutput, npv_tracker, npv_payoff = analysis_npv_all_scenarios_iteration_three(
                interest_rate, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, false, false)
            
            interest_rate_sensitivity_results_dict[interest_rate] = (payouts, generationOutput, npv_tracker, npv_payoff)
        end
    end
    ###### Interest Rate sensitivity analysis ######
    

    ###### Learning Rate sensitivity analysis ######
    if construction_learning_rate_analysis
        construction_learning_rate_sensitivity = collect(range(0.40, step=0.05, stop=1.0))

        # Initialize an empty dictionary to store the results
        learning_rate_sensitivity_results_dict = Dict{Float64, Tuple{Any, Any, Any, Any}}()

        # Iterate over the interest rates and store the results in the dictionary
        for learning_rate in construction_learning_rate_sensitivity
            payouts, generationOutput, npv_tracker, npv_payoff = analysis_npv_all_scenarios_iteration_three(
                0.04, 2024, 0, 0.1, 0.0, 10, learning_rate, 1.0, 1.0, 1.0, false, false)
            
            learning_rate_sensitivity_results_dict[interest_rate] = (payouts, generationOutput, npv_tracker, npv_payoff)
        end
    end
    ###### Learning Rate sensitivity analysis ######


    ###### Construction Delay sensitivity analysis ######
    # May not do this analysis as the costs are already high without delays.
    construction_delay_sensitivity = collect(range(0, step=1, stop=5))

    ###### Construction Delay sensitivity analysis ######


    # PTC sensitivity - numbers based on 
    ptc_sensitivity = collect(range(11.0, step=1.0, stop=34))

    # PTC Duration sensitivity
    ptc_duration_sensitivity = collect(range(2025, step=1, stop=2035))

    #### TODO: Need to define the capacity markets results ####
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

#analysis_capacity_market_prices()