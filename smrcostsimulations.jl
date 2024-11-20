using DataFrames
using Statistics
using CSV
using Optim

@info("Importing in the functions needed to run simulation")
include("smrsimulationfunctions.jl")

@info("Importing the data needed for the functions")
include("data.jl")

@info("Bringing in functions for Plotting and Data processing")
include("dataprocessingfunctions.jl")

@info("Bringing in the data from results for processing and analysis")
include("result_data.jl")

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

        

        # Calculating the lead time
        start_reactor = Int(ceil(((construction_start - 2024)*12 + construction_duration + (construction_delay*12))/12))

        ### Curating the scenarios to run the SMRs through ###
        for (index3, scenario) in enumerate(scenario_data_all)
            if index3 == 1 || index3 == 2 || index3 == 3
                push!(scenario_price_data_all, create_scenario_interpolated_array_cambium2022(scenario, scenario, scenario, scenario, scenario, scenario, scenario, scenario, (smr_lifetime + start_reactor)))

                continue
            end
            
            # If the length of the temporary array is 8, then push it into the main array
            if length(scenario_price_data_temp) == 8
                push!(scenario_price_data_all, create_scenario_interpolated_array_cambium2022(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (smr_lifetime + start_reactor)))
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                # Otherwise, add to the array and continue
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end

        # Pushing the last scenario into the array
        push!(scenario_price_data_all, create_scenario_interpolated_array_cambium2022(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (smr_lifetime + start_reactor)))
        ### Curating the scenarios to run the SMRs through ###



        ### Adjusting the OCC and O&M costs for the ATB data ###
        if toIncludeATBcost
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

        if c2n_cost_advantages
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
            payout_run, generation_run = smr_dispatch_iteration_three(scenario_array, Float64(module_size), numberof_modules, fuel_cost, vom_cost, fom_cost, production_credit, start_reactor, production_duration, refueling_max_time, refueling_min_time, smr_lifetime)
            payout_run = capacity_market_analysis(capacity_market_rate, payout_run, numberof_modules, module_size)
            irr_run = calculate_irr(payout_run, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), construction_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))))
            npv_tracker_run, break_even_run, npv_payoff_run = npv_calc_scenario(payout_run, interest_rate_wacc, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), construction_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))), (smr_lifetime + start_reactor))
            

            # Pushing in all the calculated values
            push!(construction_cost_all, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), construction_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))))
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

    ##### Baseline for Cambium 23 Prices #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/baseline_cambium23")
    # save_smr_arrays_to_csv(payouts_all, smr_names, combined_scenario_names, "/Users/pradyrao/Desktop/thesis_plots/output_files/dispatch_outputs/payout_cambium23_baseline.csv")
    # save_smr_arrays_to_csv(generationOutput_all, smr_names, combined_scenario_names, "/Users/pradyrao/Desktop/thesis_plots/output_files/dispatch_outputs/generation_cambium23_baseline.csv")
    # cambium23_baseline_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/baseline_cambium23", "cambium23_baseline_breakeven")
    # cambium23_baseline_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/baseline_cambium23", "cambium23_baseline_npv_final")
    # cambium23_baseline_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/baseline_cambium23", "cambium23_baseline_ irr")
    # cambium23_baseline_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/baseline_cambium23", "cambium23_construction_cost")
    ##### Baseline for Cambium 23 Prices #####

    ##### Baseline for Cambium 23 Prices with a 4% increase in the revenue from ancillary services #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/baseline_cambium23")
    # save_smr_arrays_to_csv(payouts_all, smr_names, combined_scenario_names, "/Users/pradyrao/Desktop/thesis_plots/output_files/dispatch_outputs/payout_cambium23_baseline.csv")
    # save_smr_arrays_to_csv(generationOutput_all, smr_names, combined_scenario_names, "/Users/pradyrao/Desktop/thesis_plots/output_files/dispatch_outputs/generation_cambium23_baseline.csv")
    # cambium23_baseline_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/4percent_ancillary_test", "cambium23_baseline_breakeven")
    # cambium23_baseline_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/4percent_ancillary_test", "cambium23_baseline_npv_final")
    # cambium23_baseline_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/4percent_ancillary_test", "cambium23_baseline_ irr")
    # cambium23_baseline_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/4percent_ancillary_test", "cambium23_construction_cost")
    ##### Baseline for Cambium 23 Prices with a 4% increase in the revenue from ancillary services #####

    ##### Baseline for Future without construction cost overrun #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_future_prices(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/future_prices_cambium23")
    # save_smr_arrays_to_csv(payouts_all, smr_names, combined_scenario_names, "/Users/pradyrao/Desktop/thesis_plots/output_files/dispatch_outputs/payout_cambium23_baseline.csv")
    # save_smr_arrays_to_csv(generationOutput_all, smr_names, combined_scenario_names, "/Users/pradyrao/Desktop/thesis_plots/output_files/dispatch_outputs/generation_cambium23_baseline.csv")
    # cambium23_baseline_breakeven = export_future_prices_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/future_prices_manufacturer", "cambium23_baseline_overrun_breakeven")
    # cambium23_baseline_npv_final = export_future_prices_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/future_prices_manufacturer", "cambium23_baseline_overrun_npv_final")
    # cambium23_baseline_irr = export_future_prices_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/future_prices_manufacturer", "cambium23_baseline_overrun_irr")
    # cambium23_baseline_construction_cost_all = export_future_prices_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/future_prices_manufacturer", "cambium23_construction_overrun_cost")
    ##### Baseline for Cambium 23 Prices with construction cost overrun #####

    ##### Baseline for Future with construction cost overrun #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_future_prices(0.04, 2024, 0, 0.1, 0.0, 10, 2.17, 1.0, 1.0, 1.0, 0.0, true, false, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/future_prices_cost_overrun_cambium23")
    # cambium23_baseline_breakeven = export_future_prices_data_to_csv(break_even_all, "//Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/future_prices_cost_overrun", "cambium23_baseline_overrun_breakeven")
    # cambium23_baseline_npv_final = export_future_prices_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/future_prices_cost_overrun", "cambium23_baseline_overrun_npv_final")
    # cambium23_baseline_irr = export_future_prices_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/future_prices_cost_overrun", "cambium23_baseline_overrun_irr")
    # cambium23_baseline_construction_cost_all = export_future_prices_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/future_prices_cost_overrun", "cambium23_construction_overrun_cost")
    ##### Baseline for Future with construction cost overrun #####

    ##### Baseline for Historical Prices without construction cost overrun #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_historical_prices(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/historical_prices_cambium23")
    # cambium23_baseline_breakeven = export_historical_prices_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/historical_prices_manufacturer", "cambium23_baseline_overrun_breakeven")
    # cambium23_baseline_npv_final = export_historical_prices_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/historical_prices_manufacturer", "cambium23_baseline_overrun_npv_final")
    # cambium23_baseline_irr = export_historical_prices_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/historical_prices_manufacturer", "cambium23_baseline_overrun_irr")
    # cambium23_baseline_construction_cost_all = export_historical_prices_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/historical_prices_manufacturer", "cambium23_construction_overrun_cost")
    ##### Baseline for Historical Prices without construction cost overrun #####

    ##### Baseline for Historical Prices with construction cost overrun ##### - HHHH
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_historical_prices(0.04, 2024, 0, 0.1, 0.0, 10, 2.17, 1.0, 1.0, 1.0, 0.0, true, false, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/historical_prices_cost_overrun_cambium23")
    # cambium23_baseline_breakeven = export_historical_prices_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/historical_prices_cost_overrun", "cambium23_baseline_overrun_breakeven")
    # cambium23_baseline_npv_final = export_historical_prices_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/historical_prices_cost_overrun", "cambium23_baseline_overrun_npv_final")
    # cambium23_baseline_irr = export_historical_prices_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/historical_prices_cost_overrun", "cambium23_baseline_overrun_irr")
    # cambium23_baseline_construction_cost_all = export_historical_prices_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/historical_prices_cost_overrun", "cambium23_construction_overrun_cost")
    ##### Baseline for Historical Prices with construction cost overrun #####

    ##### Baseline for Cambium 23 Prices with LPO 0.0 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/baseline_cambium23")
    # save_smr_arrays_to_csv(payouts_all, smr_names, combined_scenario_names, "/Users/pradyrao/Desktop/thesis_plots/output_files/dispatch_outputs/lpo0_payout_cambium23_baseline.csv")
    # save_smr_arrays_to_csv(generationOutput_all, smr_names, combined_scenario_names, "/Users/pradyrao/Desktop/thesis_plots/output_files/dispatch_outputs/lpo0_generation_cambium23_baseline.csv")
    # cambium23_baseline_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo0", "cambium23_baseline_breakeven_lpo0")
    # cambium23_baseline_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo0", "cambium23_baseline_npv_final_lpo0")
    # cambium23_baseline_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo0", "cambium23_baseline_irr_lp0")
    # cambium23_baseline_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo0", "cambium23_construction_cost_lpo0")
    ##### Baseline for Cambium 23 Prices with LPO 0.0 #####

    ##### Baseline for Cambium 23 Prices with LPO 100.0 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/baseline_cambium23")
    # save_smr_arrays_to_csv(payouts_all, smr_names, combined_scenario_names, "/Users/pradyrao/Desktop/thesis_plots/output_files/dispatch_outputs/lpo100_payout_cambium23_baseline.csv")
    # save_smr_arrays_to_csv(generationOutput_all, smr_names, combined_scenario_names, "/Users/pradyrao/Desktop/thesis_plots/output_files/dispatch_outputs/lpo100_generation_cambium23_baseline.csv")
    # cambium23_baseline_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo100", "cambium23_baseline_breakeven_lpo100")
    # cambium23_baseline_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo100", "cambium23_baseline_npv_final_lpo100")
    # cambium23_baseline_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo100", "cambium23_baseline_irr_lp100")
    # cambium23_baseline_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo100", "cambium23_construction_cost_lpo100")
    ##### Baseline for Cambium 23 Prices with LPO 100.0 #####


    ##### Baseline for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/baseline_ap1000")
    # save_ap1000_arrays_to_csv(payouts_all, ap1000_scenario_names, combined_scenario_names, "/Users/pradyrao/Desktop/thesis_plots/output_files/dispatch_outputs/payout_ap1000_baseline.csv")
    # save_ap1000_arrays_to_csv(generationOutput_all, ap1000_scenario_names, combined_scenario_names, "/Users/pradyrao/Desktop/thesis_plots/output_files/dispatch_outputs/generation_ap1000_baseline.csv")
    # ap1000_baseline_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_baseline", "ap1000_baseline_breakeven")
    # ap1000_baseline_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_baseline", "ap1000_baseline_npv_final")
    # ap1000_baseline_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_baseline", "ap1000_baseline_irr")
    # ap1000_baseline_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_baseline", "ap1000_baseline_construction_cost")
    ##### Baseline for AP1000 #####

    ##### LPO Normal Baseline analysis with $33/MWh, $15/kW-month and ITC case 30% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 33.0, 10, 1.0, 1.0, 1.0, 1.0, 15.0, false, false, false, "30%", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/baseline_cambium23")
    # lponormal_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo0/baseline_v_lpo_files/baseline_ptc_itc", "lponormal_breakeven")
    # lponormal_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo0/baseline_v_lpo_files/baseline_ptc_itc", "lponormal_npv_final")
    # lponormal_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo0/baseline_v_lpo_files/baseline_ptc_itc", "lponormal_irr")
    # lponormal_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo0/baseline_v_lpo_files/baseline_ptc_itc", "lponormal_construction_cost")
    ##### LPO Normal Baseline analysis with $33/MWh, $15/kW-month and ITC case 30% #####

    ##### LPO 0.0 Baseline analysis with $33/MWh, $15/kW-month and ITC case 30% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 33.0, 10, 1.0, 1.0, 1.0, 1.0, 15.0, false, false, false, "30%", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/baseline_cambium23")
    # lpo0_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo0/baseline_v_lpo_files/lpo0_ptc_itc", "lpo0_breakeven")
    # lpo0_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo0/baseline_v_lpo_files/lpo0_ptc_itc", "lpo0_npv_final")
    # lpo0_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo0/baseline_v_lpo_files/lpo0_ptc_itc", "lpo0_irr")
    # lpo0_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo0/baseline_v_lpo_files/lpo0_ptc_itc", "lpo0_construction_cost")
    ##### LPO 0.0 Baseline analysis with $33/MWh, $15/kW-month and ITC case 30% #####

    ##### Baseline Analysis with 0.0 LPO for Cambium 23 Prices #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/LPO_0")
    # save_smr_arrays_to_csv(payouts_all, smr_names, combined_scenario_names, "/Users/pradyrao/Desktop/thesis_plots/output_files/dispatch_outputs/payout_cambium23_baseline.csv")
    # save_smr_arrays_to_csv(generationOutput_all, smr_names, combined_scenario_names, "/Users/pradyrao/Desktop/thesis_plots/output_files/dispatch_outputs/generation_cambium23_baseline.csv")
    # cambium23_baseline_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo0", "cambium23_baseline_breakeven_lpo0")
    # cambium23_baseline_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo0", "cambium23_baseline_npv_final_lpo0")
    # cambium23_baseline_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo0", "cambium23_baseline_ irr_lpo0")
    # cambium23_baseline_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo0", "cambium23_construction_cost_lpo0")
    ##### Baseline Analysis with 0.0 LPO for Cambium 23 Prices #####

    # ##### Analysis adding in multi-modular SMR learning benefits #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/mm_learning")
    # mmlearning_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "mmlearning_breakeven")
    # mmlearning_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "mmlearning_npv_final")
    # mmlearning_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "mmlearning_irr")
    # mmlearning_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "mmlearning_construction_cost")
    # ##### Analysis adding in multi-modular SMR learning benefits #####

    # ##### Analysis adding in multi-modular SMR learning benefits - Cambium 2023 and 2022 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/mmlearning_cambium23")
    # mmlearning_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/mmlearning_cambium23", "mmlearning_breakeven")
    # mmlearning_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/mmlearning_cambium23", "mmlearning_npv_final")
    # mmlearning_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/mmlearning_cambium23", "mmlearning_irr")
    # mmlearning_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/mmlearning_cambium23", "mmlearning_construction_cost")
    # ##### Analysis adding in multi-modular SMR learning benefits #####

    # ##### Analysis for Coal2Nuclear plants #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, true, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/c2n_results")
    # c2n_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline", "c2n_breakeven")
    # c2n_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline", "c2n_npv_final")
    # c2n_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline", "c2n_irr")
    # c2n_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline", "c2n_construction_cost")
    # ##### Analysis adding in multi-modular SMR learning benefits #####

    # # ##### Analysis for Coal2Nuclear plants for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/c2n_cambium23")
    # ap1000_c2n_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/c2n_cambium23", "ap1000_c2n_breakeven")
    # ap1000_c2n_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/c2n_cambium23", "ap1000_c2n_npv_final")
    # ap1000_c2n_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/c2n_cambium23", "ap1000_c2n_irr")
    # ap1000_c2n_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/c2n_cambium23", "ap1000_c2n_construction_cost")
    # # ##### Analysis for Coal2Nuclear plants for AP1000 #####

    # ##### Analysis for Coal2Nuclear plants for Cambium 23 and 22 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000c2n")
    # ap1000_c2n_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_c2n", "ap1000_c2n_breakeven")
    # ap1000_c2n_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_c2n", "ap1000_c2n_npv_final")
    # ap1000_c2n_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_c2n", "ap1000_c2n_irr")
    # ap1000_c2n_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_c2n", "ap1000_c2n_construction_cost")
    # ##### Analysis for Coal2Nuclear plants for AP1000 #####


    # ##### Analysis taking in locations with ITC credits - 6% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, true, "6%", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ITC_results/6%_case")
    # itc6_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline", "itc_breakeven")
    # itc6_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline", "itc_npv_final")
    # itc6_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline", "itc_irr")
    # itc6_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline", "itc_construction_cost")
    # ##### Analysis taking in locations with ITC credits - 6% #####

    # ##### Analysis taking in locations with ITC credits for AP1000 - 6% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, true, "6%", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000itc/ap1000itc6")
    # ap1000_itc6_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_itc/ap1000_itc6", "ap1000_itc6_breakeven")
    # ap1000_itc6_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_itc/ap1000_itc6", "ap1000_itc6_npv_final")
    # ap1000_itc6_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_itc/ap1000_itc6", "ap1000_itc6_irr")
    # ap1000_itc6_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_itc/ap1000_itc6", "ap1000_itc6_construction_cost")
    # ##### Analysis taking in locations with ITC credits for AP1000 - 6% #####

    # ##### Analysis taking in locations with ITC credits - 30% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, true, "30%", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ITC_results/30%_case")
    # itc30_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline", "itc30_breakeven")
    # itc30_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline", "itc30_npv_final")
    # itc30_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline", "itc30_irr")
    # itc30_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline", "itc30_construction_cost")
    # ##### Analysis taking in locations with ITC credits - 30% #####

    # ##### Analysis taking in locations with ITC credits for AP1000 - 30% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, true, "30%", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000itc/ap1000itc30")
    # ap1000_itc30_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_itc/ap1000_itc30", "ap1000_itc30_breakeven")
    # ap1000_itc30_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_itc/ap1000_itc30", "ap1000_itc30_npv_final")
    # ap1000_itc30_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_itc/ap1000_itc30", "ap1000_itc30_irr")
    # ap1000_itc30_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_itc/ap1000_itc30", "ap1000_itc30_construction_cost")
    # ##### Analysis taking in locations with ITC credits for AP1000 - 30% #####

    # ##### Analysis taking in locations with ITC credits - 40% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, true, "40%", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ITC_results/40%_case")
    # itc40_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc40_baseline", "itc40_breakeven")
    # itc40_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc40_baseline", "itc40_npv_final")
    # itc40_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc40_baseline", "itc40_irr")
    # itc40_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc40_baseline", "itc40_construction_cost")
    # ##### Analysis taking in locations with ITC credits - 40% #####

    # ##### Analysis taking in locations with ITC credits for AP1000 - 40% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, true, "40%", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000itc/ap1000itc40")
    # ap1000_itc40_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_itc/ap1000_itc40", "ap1000_itc40_breakeven")
    # ap1000_itc40_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_itc/ap1000_itc40", "ap1000_itc40_npv_final")
    # ap1000_itc40_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_itc/ap1000_itc40", "ap1000_itc40_irr")
    # ap1000_itc40_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_itc/ap1000_itc40", "ap1000_itc40_construction_cost")
    # ##### Analysis taking in locations with ITC credits for AP1000 - 40% #####

    # ##### Analysis taking in locations with ITC credits - 50% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, true, "50%", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ITC_results/50%_case")
    # itc50_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc50_breakeven")
    # itc50_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc50_npv_final")
    # itc50_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc50_irr")
    # itc50_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files", "itc50_construction_cost")
    # ##### Analysis taking in locations with ITC credits - 50% #####

    # ##### Analysis taking in locations with ITC credits for AP1000 - 50% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, true, "50%", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000itc/ap1000itc50")
    # ap1000_itc50_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_itc/ap1000_itc50", "ap1000_itc50_breakeven")
    # ap1000_itc50_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_itc/ap1000_itc50", "ap1000_itc50_npv_final")
    # ap1000_itc50_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_itc/ap1000_itc50", "ap1000_itc50_irr")
    # ap1000_itc50_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_itc/ap1000_itc50", "ap1000_itc50_construction_cost")
    # ##### Analysis taking in locations with ITC credits for AP1000 - 50% #####




    # ##### PTC of $11/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 11.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/11usd_10yrs")
    # ptc11_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline", "ptc11_breakeven")
    # ptc11_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline", "ptc11_npv_final")
    # ptc11_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline", "ptc11_irr")
    # ptc11_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline", "ptc11_construction_cost")
    ##### PTC of $11/MWh for 10 years #####

    # ##### PTC of $12/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 12.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/12usd_10yrs")
    # ptc12_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc12_baseline", "ptc12_breakeven")
    # ptc12_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc12_baseline", "ptc12_npv_final")
    # ptc12_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc12_baseline", "ptc12_irr")
    # ptc12_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc12_baseline", "ptc12_construction_cost")
    # ##### PTC of $12/MWh for 10 years #####

    # ##### PTC of $13/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 13.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/13usd_10yrs")
    # ptc13_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc13_baseline", "ptc13_breakeven")
    # ptc13_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc13_baseline", "ptc13_npv_final")
    # ptc13_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc13_baseline", "ptc13_irr")
    # ptc13_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc13_baseline", "ptc13_construction_cost")
    # ##### PTC of $13/MWh for 10 years #####

    # ##### PTC of $14/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 14.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/14usd_10yrs")
    # ptc14_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc14_baseline", "ptc14_breakeven")
    # ptc14_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc14_baseline", "ptc14_npv_final")
    # ptc14_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc14_baseline", "ptc14_irr")
    # ptc14_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc14_baseline", "ptc14_construction_cost")
    # ##### PTC of $14/MWh for 10 years #####

    # ##### PTC of $15/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/15usd_10yrs")
    # ptc15_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc15_baseline", "ptc15_breakeven")
    # ptc15_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc15_baseline", "ptc15_npv_final")
    # ptc15_irr = export_breakeven_to_csv(irr_all, "//Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc15_baseline", "ptc15_irr")
    # ptc15_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc15_baseline", "ptc15_construction_cost")
    # ##### PTC of $14/MWh for 10 years #####

    # ##### PTC of $16/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 16.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/16usd_10yrs")
    # ptc16_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc16_baseline", "ptc16_breakeven")
    # ptc16_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc16_baseline", "ptc16_npv_final")
    # ptc16_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc16_baseline", "ptc16_irr")
    # ptc16_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc16_baseline", "ptc16_construction_cost")
    # ##### PTC of $16/MWh for 10 years #####

    # ##### PTC of $17/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 17.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/17usd_10yrs")
    # ptc17_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc17_baseline", "ptc17_breakeven")
    # ptc17_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc17_baseline", "ptc17_npv_final")
    # ptc17_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc17_baseline", "ptc17_irr")
    # ptc17_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc17_baseline", "ptc17_construction_cost")
    # ##### PTC of $17/MWh for 10 years #####

    # ##### PTC of $18/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 18.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/18usd_10yrs")
    # ptc18_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc18_baseline", "ptc18_breakeven")
    # ptc18_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc18_baseline", "ptc18_npv_final")
    # ptc18_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc18_baseline", "ptc18_irr")
    # ptc18_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc18_baseline", "ptc18_construction_cost")
    # ##### PTC of $18/MWh for 10 years #####

    # ##### PTC of $19/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 19.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/19usd_10yrs")
    # ptc19_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc19_baseline", "ptc19_breakeven")
    # ptc19_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc19_baseline", "ptc19_npv_final")
    # ptc19_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc19_baseline", "ptc19_irr")
    # ptc19_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc19_baseline", "ptc19_construction_cost")
    # ##### PTC of $19/MWh for 10 years #####

    # ##### PTC of $20/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 20.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/20usd_10yrs")
    # ptc20_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc20_baseline", "ptc20_breakeven")
    # ptc20_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc20_baseline", "ptc20_npv_final")
    # ptc20_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc20_baseline", "ptc20_irr")
    # ptc20_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc20_baseline", "ptc20_construction_cost")
    # ##### PTC of $20/MWh for 10 years #####

    # ##### PTC of $21/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 21.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/21usd_10yrs")
    # ptc21_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc21_baseline", "ptc21_breakeven")
    # ptc21_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc21_baseline", "ptc21_npv_final")
    # ptc21_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc21_baseline", "ptc21_irr")
    # ptc21_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc21_baseline", "ptc21_construction_cost")
    # ##### PTC of $21/MWh for 10 years #####

    # ##### PTC of $22/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 22.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/22usd_10yrs")
    # ptc22_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc22_baseline", "ptc22_breakeven")
    # ptc22_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc22_baseline", "ptc22_npv_final")
    # ptc22_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc22_baseline", "ptc22_irr")
    # ptc22_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc22_baseline", "ptc22_construction_cost")
    # ##### PTC of $22/MWh for 10 years #####

    # ##### PTC of $23/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 23.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/23usd_10yrs")
    # ptc23_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc23_baseline", "ptc23_breakeven")
    # ptc23_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc23_baseline", "ptc23_npv_final")
    # ptc23_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc23_baseline", "ptc23_irr")
    # ptc23_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc23_baseline", "ptc23_construction_cost")
    # ##### PTC of $23/MWh for 10 years #####

    # ##### PTC of $24/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 24.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/24usd_10yrs")
    # ptc24_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc24_baseline", "ptc24_breakeven")
    # ptc24_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc24_baseline", "ptc24_npv_final")
    # ptc24_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc24_baseline", "ptc24_irr")
    # ptc24_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc24_baseline", "ptc24_construction_cost")
    # ##### PTC of $24/MWh for 10 years #####

    # ##### PTC of $25/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 25.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/25usd_10yrs")
    # ptc25_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc25_baseline", "ptc25_breakeven")
    # ptc25_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc25_baseline", "ptc25_npv_final")
    # ptc25_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc25_baseline", "ptc25_irr")
    # ptc25_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc25_baseline", "ptc25_construction_cost")
    # ##### PTC of $25/MWh for 10 years #####

    # ##### PTC of $26/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 26.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/26usd_10yrs")
    # ptc26_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc26_baseline", "ptc26_breakeven")
    # ptc26_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc26_baseline", "ptc26_npv_final")
    # ptc26_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc26_baseline", "ptc26_irr")
    # ptc26_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc26_baseline", "ptc26_construction_cost")
    # ##### PTC of $26/MWh for 10 years #####

    # ##### PTC of $27.5/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 27.5, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/27.5usd_10yrs")
    # ptc275_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc27.5_baseline", "ptc27.5_breakeven")
    # ptc275_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc27.5_baseline", "ptc27.5_npv_final")
    # ptc275_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc27.5_baseline", "ptc27.5_irr")
    # ptc275_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "//Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc27.5_baseline", "ptc27.5_construction_cost")
    # ##### PTC of $27.5/MWh for 10 years #####

    # ##### PTC of $28.05/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 28.05, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/28.05usd_10yrs")
    # ptc2805_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc28.05_baseline", "ptc28.05_breakeven")
    # ptc2805_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc28.05_baseline", "ptc28.05_npv_final")
    # ptc2805_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc28.05_baseline", "ptc28.05_irr")
    # ptc2805_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc28.05_baseline", "ptc2805_construction_cost")
    # ##### PTC of $28.05/MWh for 10 years #####

    # ##### PTC of $30.05/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 30.05, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/30.05usd_10yrs")
    # ptc3005_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc30.05_baseline", "ptc30.05_breakeven")
    # ptc3005_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc30.05_baseline", "ptc30.05_npv_final")
    # ptc3005_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc30.05_baseline", "ptc30.05_irr")
    # ptc3005_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc30.05_baseline", "ptc3005_construction_cost")
    # ##### PTC of $30.05/MWh for 10 years #####

    # ##### PTC of $33.0/MWh for 10 years #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 33.0, 10, 1.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ptc_results/33usd_10yrs")
    # ptc33_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc33_baseline", "ptc33_breakeven")
    # ptc33_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc33_baseline", "ptc33_npv_final")
    # ptc33_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc33_baseline", "ptc33_irr")
    # ptc33_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc33_baseline", "ptc33_construction_cost")
    # ##### PTC of $33.0/MWh for 10 years #####


    ######################################## Capacity Market Analysis ########################################


    # ##### Capacity Market of $1.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 1.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd1kW_month")
    # cm1_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm1_baseline", "cm1_breakeven")
    # cm1_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm1_baseline", "cm1_npv_final")
    # cm1_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm1_baseline", "cm1_irr")
    # cm1_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm1_baseline", "cm1_construction_cost")
    # ##### Capacity Market of $1.0/kW-month #####

    # ##### Capacity Market of $2.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 2.0, false, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd2kW_month")
    # cm2 = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm2_baseline", "cm2_breakeven")
    # cm2_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm2_baseline", "cm2_npv_final")
    # cm2_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm2_baseline", "cm2_irr")
    # cm2_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm2_baseline", "cm2_construction_cost")
    # ##### Capacity Market of $2.0/kW-month #####

    # ##### Capacity Market of $3.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 3.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd3kW_month")
    # cm3_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm3_baseline", "cm3_breakeven")
    # cm3_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm3_baseline", "cm3_npv_final")
    # cm3_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm3_baseline", "cm3_irr")
    # cm3_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm3_baseline", "cm3_construction_cost")
    # ##### Capacity Market of $3.0/kW-month #####

    # ##### Capacity Market of $4.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 4.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd4kW_month")
    # cm4_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm4_baseline", "cm4_breakeven")
    # cm4_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm4_baseline", "cm4_npv_final")
    # cm4_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm4_baseline", "cm4_irr")
    # cm4_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm4_baseline", "cm4_construction_cost")
    # ##### Capacity Market of $4.0/kW-month #####

    # ##### Capacity Market of $5.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd5kW_month")
    # cm5_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm5_baseline", "cm5_breakeven")
    # cm5_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm5_baseline", "cm5_npv_final")
    # cm5_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm5_baseline", "cm5_irr")
    # cm5_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm5_baseline", "cm5_construction_cost")
    # ##### Capacity Market of $5.0/kW-month #####

    # ##### Capacity Market of $6.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 6.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd6kW_month")
    # cm6_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm6_baseline", "cm6_breakeven")
    # cm6_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm6_baseline", "cm6_npv_final")
    # cm6_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm6_baseline", "cm6_irr")
    # cm6_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm6_baseline", "cm6_construction_cost")
    # ##### Capacity Market of $6.0/kW-month #####

    # ##### Capacity Market of $7.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 7.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd7kW_month")
    # cm7_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm7_baseline", "cm7_breakeven")
    # cm7_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm7_baseline", "cm7_npv_final")
    # cm7_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm7_baseline", "cm7_irr")
    # cm7_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm7_baseline", "cm7_construction_cost")
    # ##### Capacity Market of $7.0/kW-month #####

    # ##### Capacity Market of $8.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 8.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd8kW_month")
    # cm8_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm8_baseline", "cm8_breakeven")
    # cm8_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm8_baseline", "cm8_npv_final")
    # cm8_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm8_baseline", "cm8_irr")
    # cm8_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm8_baseline", "cm8_construction_cost")
    # ##### Capacity Market of $8.0/kW-month #####

    # ##### Capacity Market of $15.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 15.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd15kW_month")
    # cm15_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm15_baseline", "cm15_breakeven")
    # cm15_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm15_baseline", "cm15_npv_final")
    # cm15_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm15_baseline", "cm15_irr")
    # cm15_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm15_baseline", "cm15_construction_cost")
    # ##### Capacity Market of $15.0/kW-month #####

    # ##### Capacity Market of $16.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 16.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd16kW_month")
    # cm16_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm16_baseline", "cm16_breakeven")
    # cm16_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm16_baseline", "cm16_npv_final")
    # cm16_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm16_baseline", "cm16_irr")
    # cm16_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm16_baseline", "cm16_construction_cost")
    # ##### Capacity Market of $16.0/kW-month #####

    # ##### Capacity Market of $17.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 17.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd17kW_month")
    # cm17_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm17_baseline", "cm17_breakeven")
    # cm17_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm17_baseline", "cm17_npv_final")
    # cm17_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm17_baseline", "cm17_irr")
    # cm17_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm17_baseline", "cm17_construction_cost")
    # ##### Capacity Market of $17.0/kW-month #####

    # ##### Capacity Market of $18.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 18.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd18kW_month")
    # cm18_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm18_baseline", "cm18_breakeven")
    # cm18_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm18_baseline", "cm18_npv_final")
    # cm18_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm18_baseline", "cm18_irr")
    # cm18_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm18_baseline", "cm18_construction_cost")
    # ##### Capacity Market of $18.0/kW-month #####

    # ##### Capacity Market of $19.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 19.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd19kW_month")
    # cm19_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm19_baseline", "cm19_breakeven")
    # cm19_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm19_baseline", "cm19_npv_final")
    # cm19_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm19_baseline", "cm19_irr")
    # cm19_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm19_baseline", "cm19_construction_cost")
    # ##### Capacity Market of $19.0/kW-month #####

    # ##### Capacity Market of $20.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 20.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd20kW_month")
    # cm20_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm20_baseline", "cm20_breakeven")
    # cm20_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm20_baseline", "cm20_npv_final")
    # cm20_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm20_baseline", "cm20_irr")
    # cm20_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm20_baseline", "cm20_construction_cost")
    # ##### Capacity Market of $20.0/kW-month #####

    # ##### Capacity Market of $21.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 21.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd21kW_month")
    # cm21_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm21_baseline", "cm21_breakeven")
    # cm21_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm21_baseline", "cm21_npv_final")
    # cm21_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm21_baseline", "cm21_irr")
    # cm21_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm21_baseline", "cm21_construction_cost")
    # ##### Capacity Market of $21.0/kW-month #####

    # ##### Capacity Market of $22.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 22.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd22kW_month")
    # cm22_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm22_baseline", "cm22_breakeven")
    # cm22_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm22_baseline", "cm22_npv_final")
    # cm22_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm22_baseline", "cm22_irr")
    # cm22_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm22_baseline", "cm22_construction_cost")
    # ##### Capacity Market of $22.0/kW-month #####

    # ##### Capacity Market of $23.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd23kW_month")
    # cm23_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm23_baseline", "cm23_breakeven")
    # cm23_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm23_baseline", "cm23_npv_final")
    # cm23_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm23_baseline", "cm23_irr")
    # cm23_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm23_baseline", "cm23_construction_cost")
    # ##### Capacity Market of $23.0/kW-month #####

    # ##### Capacity Market of $25.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd25kW_month")
    # cm25_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm25_baseline", "cm25_breakeven")
    # cm25_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm25_baseline", "cm25_npv_final")
    # cm25_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm25_baseline", "cm25_irr")
    # cm25_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm25_baseline", "cm25_construction_cost")
    # ##### Capacity Market of $25.0/kW-month #####

    # ##### Capacity Market of $30.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 30.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd30kW_month")
    # cm30_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm30_baseline", "cm30_breakeven")
    # cm30_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm30_baseline", "cm30_npv_final")
    # cm30_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm30_baseline", "cm30_irr")
    # cm30_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm30_baseline", "cm30_construction_cost")
    # ##### Capacity Market of $30.0/kW-month #####

    # ##### Capacity Market of $35.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 35.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd35kW_month")
    # cm35_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm35_baseline", "cm35_breakeven")
    # cm35_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm35_baseline", "cm35_npv_final")
    # cm35_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm35_baseline", "cm35_irr")
    # cm35_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm35_baseline", "cm35_construction_cost")
    # ##### Capacity Market of $35.0/kW-month #####

    # ##### Capacity Market of $40.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 40.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd40kW_month")
    # cm40_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm40_baseline", "cm40_breakeven")
    # cm40_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm40_baseline", "cm40_npv_final")
    # cm40_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm40_baseline", "cm40_irr")
    # cm40_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm40_baseline", "cm40_construction_cost")
    # ##### Capacity Market of $40.0/kW-month #####

    # ##### Capacity Market of $45.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 45.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd45kW_month")
    # cm45_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm45_baseline", "cm45_breakeven")
    # cm45_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm45_baseline", "cm45_npv_final")
    # cm45_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm45_baseline", "cm45_irr")
    # cm45_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm45_baseline", "cm45_construction_cost")
    # ##### Capacity Market of $45.0/kW-month #####

    # ##### Capacity Market of $50.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 50.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd50kW_month")
    # cm50_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm50_baseline", "cm50_breakeven")
    # cm50_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm50_baseline", "cm50_npv_final")
    # cm50_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm50_baseline", "cm50_irr")
    # cm50_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm50_baseline", "cm50_construction_cost")
    # ##### Capacity Market of $50.0/kW-month #####

    # ##### Capacity Market of $55.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 55.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd55kW_month")
    # cm55_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm55_baseline", "cm55_breakeven")
    # cm55_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm55_baseline", "cm55_npv_final")
    # cm55_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm55_baseline", "cm55_irr")
    # cm55_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm55_baseline", "cm55_construction_cost")
    # ##### Capacity Market of $55.0/kW-month #####

    # ##### Capacity Market of $60.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 60.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd60kW_month")
    # cm60_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm60_baseline", "cm60_breakeven")
    # cm60_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm60_baseline", "cm60_npv_final")
    # cm60_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm60_baseline", "cm60_irr")
    # cm60_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm60_baseline", "cm60_construction_cost")
    # ##### Capacity Market of $60.0/kW-month #####

    # ##### Capacity Market of $65.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 65.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd65kW_month")
    # cm65_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm65_baseline", "cm65_breakeven")
    # cm65_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm65_baseline", "cm65_npv_final")
    # cm65_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm65_baseline", "cm65_irr")
    # cm65_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm65_baseline", "cm65_construction_cost")
    # ##### Capacity Market of $65.0/kW-month #####

    # ##### Capacity Market of $70.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 70.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd70kW_month")
    # cm70_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm70_baseline", "cm70_breakeven")
    # cm70_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm70_baseline", "cm70_npv_final")
    # cm70_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm70_baseline", "cm70_irr")
    # cm70_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm70_baseline", "cm70_construction_cost")
    # ##### Capacity Market of $70.0/kW-month #####

    # ##### Capacity Market of $75.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 75.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd75kW_month")
    # cm75_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm75_baseline", "cm75_breakeven")
    # cm75_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm75_baseline", "cm75_npv_final")
    # cm75_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm75_baseline", "cm75_irr")
    # cm75_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm75_baseline", "cm75_construction_cost")
    # ##### Capacity Market of $75.0/kW-month #####

    # ##### Capacity Market of $80.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 80.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd80kW_month")
    # cm80_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm80_baseline", "cm80_breakeven")
    # cm80_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm80_baseline", "cm80_npv_final")
    # cm80_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm80_baseline", "cm80_irr")
    # cm80_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm80_baseline", "cm80_construction_cost")
    # ##### Capacity Market of $80.0/kW-month #####

    # ##### Capacity Market of $85.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 85.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd85kW_month")
    # cm85_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm85_baseline", "cm85_breakeven")
    # cm85_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm85_baseline", "cm85_npv_final")
    # cm85_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm85_baseline", "cm85_irr")
    # cm85_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm85_baseline", "cm85_construction_cost")
    # ##### Capacity Market of $85.0/kW-month #####

    # ##### Capacity Market of $90.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 90.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd90kW_month")
    # cm90_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm90_baseline", "cm90_breakeven")
    # cm90_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm90_baseline", "cm90_npv_final")
    # cm90_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm90_baseline", "cm90_irr")
    # cm90_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm90_baseline", "cm90_construction_cost")
    # ##### Capacity Market of $90.0/kW-month #####

    # ##### Capacity Market of $95.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 95.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd95kW_month")
    # cm95_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm95_baseline", "cm95_breakeven")
    # cm95_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm95_baseline", "cm95_npv_final")
    # cm95_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm95_baseline", "cm95_irr")
    # cm95_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm95_baseline", "cm95_construction_cost")
    # ##### Capacity Market of $95.0/kW-month #####

    # ##### Capacity Market of $100.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 100.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd100kW_month")
    # cm100_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm100_baseline", "cm100_breakeven")
    # cm100_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm100_baseline", "cm100_npv_final")
    # cm100_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm100_baseline", "cm100_irr")
    # cm100_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm100_baseline", "cm100_construction_cost")
    # ##### Capacity Market of $100.0/kW-month #####

    # ##### Capacity Market of $105.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 105.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd105kW_month")
    # cm105_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm105_baseline", "cm105_breakeven")
    # cm105_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm105_baseline", "cm105_npv_final")
    # cm105_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm105_baseline", "cm105_irr")
    # cm105_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm105_baseline", "cm105_construction_cost")
    # ##### Capacity Market of $105.0/kW-month #####

    # ##### Capacity Market of $110.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 110.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd110kW_month")
    # cm110_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm110_baseline", "cm110_breakeven")
    # cm110_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm110_baseline", "cm110_npv_final")
    # cm110_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm110_baseline", "cm110_irr")
    # cm110_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm110_baseline", "cm110_construction_cost")
    # ##### Capacity Market of $110.0/kW-month #####

    # ##### Capacity Market of $115.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 115.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd115kW_month")
    # cm115_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm115_baseline", "cm115_breakeven")
    # cm115_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm115_baseline", "cm115_npv_final")
    # cm115_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm115_baseline", "cm115_irr")
    # cm115_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm115_baseline", "cm115_construction_cost")
    # ##### Capacity Market of $115.0/kW-month #####

    # ##### Capacity Market of $120.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 120.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd120kW_month")
    # cm120_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm120_baseline", "cm120_breakeven")
    # cm120_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm120_baseline", "cm120_npv_final")
    # cm120_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm120_baseline", "cm120_irr")
    # cm120_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm120_baseline", "cm120_construction_cost")
    # ##### Capacity Market of $120.0/kW-month #####

    # ##### Capacity Market of $125.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 125.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd125kW_month")
    # cm125_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm125_baseline", "cm125_breakeven")
    # cm125_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm125_baseline", "cm125_npv_final")
    # cm125_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm125_baseline", "cm125_irr")
    # cm125_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm125_baseline", "cm125_construction_cost")
    # ##### Capacity Market of $125.0/kW-month #####

    # ##### Capacity Market of $130.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 130.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/capacity_market_results/usd130kW_month")
    # cm130_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm130_baseline", "cm130_breakeven")
    # cm130_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm130_baseline", "cm130_npv_final")
    # cm130_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm130_baseline", "cm130_irr")
    # cm130_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm130_baseline", "cm130_construction_cost")
    # ##### Capacity Market of $130.0/kW-month #####

    """
    Capacity Market Prices for AP1000
    """
    # ##### Capacity Market of $1.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 1.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm1_ap1000")
    # cm1_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm1_ap1000", "cm1_ap1000_breakeven")
    # cm1_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm1_ap1000", "cm1_ap1000_npv_final")
    # cm1_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm1_ap1000", "cm1_ap1000_irr")
    # cm1_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm1_ap1000", "cm1_ap1000_construction_cost")
    # ##### Capacity Market of $1.0/kW-month for AP1000 #####

    # ##### Capacity Market of $2.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 2.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm2_ap1000")
    # cm2_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm2_ap1000", "cm2_ap1000_breakeven")
    # cm2_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm2_ap1000", "cm2_ap1000_npv_final")
    # cm2_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm2_ap1000", "cm2_ap1000_irr")
    # cm2_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm2_ap1000", "cm2_ap1000_construction_cost")
    # ##### Capacity Market of $2.0/kW-month for AP1000 #####

    # ##### Capacity Market of $3.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 3.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm3_ap1000")
    # cm3_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm3_ap1000", "cm3_ap1000_breakeven")
    # cm3_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm3_ap1000", "cm3_ap1000_npv_final")
    # cm3_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm3_ap1000", "cm3_ap1000_irr")
    # cm3_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm3_ap1000", "cm3_ap1000_construction_cost")
    # ##### Capacity Market of $3.0/kW-month for AP1000 #####

    # ##### Capacity Market of $4.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 4.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm4_ap1000")
    # cm4_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm4_ap1000", "cm4_ap1000_breakeven")
    # cm4_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm4_ap1000", "cm4_ap1000_npv_final")
    # cm4_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm4_ap1000", "cm4_ap1000_irr")
    # cm4_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm4_ap1000", "cm4_ap1000_construction_cost")
    # ##### Capacity Market of $4.0/kW-month for AP1000 #####

    # ##### Capacity Market of $5.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm5_ap1000")
    # cm5_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm5_ap1000", "cm5_ap1000_breakeven")
    # cm5_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm5_ap1000", "cm5_ap1000_npv_final")
    # cm5_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm5_ap1000", "cm5_ap1000_irr")
    # cm5_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm5_ap1000", "cm5_ap1000_construction_cost")
    # ##### Capacity Market of $5.0/kW-month for AP1000 #####

    # ##### Capacity Market of $6.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 6.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm6_ap1000")
    # cm6_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm6_ap1000", "cm6_ap1000_breakeven")
    # cm6_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm6_ap1000", "cm6_ap1000_npv_final")
    # cm6_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm6_ap1000", "cm6_ap1000_irr")
    # cm6_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm6_ap1000", "cm6_ap1000_construction_cost")
    # ##### Capacity Market of $6.0/kW-month for AP1000 #####

    # ##### Capacity Market of $7.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 7.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm7_ap1000")
    # cm7_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm7_ap1000", "cm7_ap1000_breakeven")
    # cm7_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm7_ap1000", "cm7_ap1000_npv_final")
    # cm7_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm7_ap1000", "cm7_ap1000_irr")
    # cm7_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm7_ap1000", "cm7_ap1000_construction_cost")
    # ##### Capacity Market of $7.0/kW-month for AP1000 #####

    # ##### Capacity Market of $8.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 8.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm8_ap1000")
    # cm8_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm8_ap1000", "cm8_ap1000_breakeven")
    # cm8_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm8_ap1000", "cm8_ap1000_npv_final")
    # cm8_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm8_ap1000", "cm8_ap1000_irr")
    # cm8_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm8_ap1000", "cm8_ap1000_construction_cost")
    # ##### Capacity Market of $8.0/kW-month for AP1000 #####

    # ##### Capacity Market of $15.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 15.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm15_ap1000")
    # cm15_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm15_ap1000", "cm15_ap1000_breakeven")
    # cm15_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm15_ap1000", "cm15_ap1000_npv_final")
    # cm15_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm15_ap1000", "cm15_ap1000_irr")
    # cm15_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm15_ap1000", "cm15_ap1000_construction_cost")
    # ##### Capacity Market of $15.0/kW-month for AP1000 #####

    # ##### Capacity Market of $16.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 16.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm16_ap1000")
    # cm16_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm16_ap1000", "cm16_ap1000_breakeven")
    # cm16_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm16_ap1000", "cm16_ap1000_npv_final")
    # cm16_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm16_ap1000", "cm16_ap1000_irr")
    # cm16_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm16_ap1000", "cm16_ap1000_construction_cost")
    # ##### Capacity Market of $16.0/kW-month for AP1000 #####

    # ##### Capacity Market of $17.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 17.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm17_ap1000")
    # cm17_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm17_ap1000", "cm17_ap1000_breakeven")
    # cm17_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm17_ap1000", "cm17_ap1000_npv_final")
    # cm17_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm17_ap1000", "cm17_ap1000_irr")
    # cm17_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm17_ap1000", "cm17_ap1000_construction_cost")
    # ##### Capacity Market of $17.0/kW-month for AP1000 #####

    # ##### Capacity Market of $18.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 18.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm18_ap1000")
    # cm18_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm18_ap1000", "cm18_ap1000_breakeven")
    # cm18_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm18_ap1000", "cm18_ap1000_npv_final")
    # cm18_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm18_ap1000", "cm18_ap1000_irr")
    # cm18_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm18_ap1000", "cm18_ap1000_construction_cost")
    # ##### Capacity Market of $18.0/kW-month for AP1000 #####

    # ##### Capacity Market of $19.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 19.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm19_ap1000")
    # cm19_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm19_ap1000", "cm19_ap1000_breakeven")
    # cm19_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm19_ap1000", "cm19_ap1000_npv_final")
    # cm19_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm19_ap1000", "cm19_ap1000_irr")
    # cm19_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm19_ap1000", "cm19_ap1000_construction_cost")
    # ##### Capacity Market of $19.0/kW-month for AP1000 #####

    # ##### Capacity Market of $20.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 20.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm20_ap1000")
    # cm20_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm20_ap1000", "cm20_ap1000_breakeven")
    # cm20_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm20_ap1000", "cm20_ap1000_npv_final")
    # cm20_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm20_ap1000", "cm20_ap1000_irr")
    # cm20_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm20_ap1000", "cm20_ap1000_construction_cost")
    # ##### Capacity Market of $20.0/kW-month for AP1000 #####

    # ##### Capacity Market of $21.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 21.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm21_ap1000")
    # cm21_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm21_ap1000", "cm21_ap1000_breakeven")
    # cm21_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm21_ap1000", "cm21_ap1000_npv_final")
    # cm21_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm21_ap1000", "cm21_ap1000_irr")
    # cm21_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm21_ap1000", "cm21_ap1000_construction_cost")
    # ##### Capacity Market of $21.0/kW-month for AP1000 #####

    # ##### Capacity Market of $22.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 22.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm22_ap1000")
    # cm22_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm22_ap1000", "cm22_ap1000_breakeven")
    # cm22_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm22_ap1000", "cm22_ap1000_npv_final")
    # cm22_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm22_ap1000", "cm22_ap1000_irr")
    # cm22_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm22_ap1000", "cm22_ap1000_construction_cost")
    # ##### Capacity Market of $22.0/kW-month for AP1000 #####

    # ##### Capacity Market of $23.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 23.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm23_ap1000")
    # cm23_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm23_ap1000", "cm23_ap1000_breakeven")
    # cm23_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm23_ap1000", "cm23_ap1000_npv_final")
    # cm23_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm23_ap1000", "cm23_ap1000_irr")
    # cm23_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm23_ap1000", "cm23_ap1000_construction_cost")
    # ##### Capacity Market of $23.0/kW-month for AP1000 #####

    # ##### Capacity Market of $25.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 25.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm25_ap1000")
    # cm25_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm25_ap1000", "cm25_ap1000_breakeven")
    # cm25_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm25_ap1000", "cm25_ap1000_npv_final")
    # cm25_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm25_ap1000", "cm25_ap1000_irr")
    # cm25_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm25_ap1000", "cm25_ap1000_construction_cost")
    # ##### Capacity Market of $25.0/kW-month for AP1000 #####

    # ##### Capacity Market of $30.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 30.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm30_ap1000")
    # cm30_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm30_ap1000", "cm30_ap1000_breakeven")
    # cm30_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm30_ap1000", "cm30_ap1000_npv_final")
    # cm30_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm30_ap1000", "cm30_ap1000_irr")
    # cm30_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm30_ap1000", "cm30_ap1000_construction_cost")
    # ##### Capacity Market of $30.0/kW-month for AP1000 #####

    # ##### Capacity Market of $35.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 35.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm35_ap1000")
    # cm35_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm35_ap1000", "cm35_ap1000_breakeven")
    # cm35_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm35_ap1000", "cm35_ap1000_npv_final")
    # cm35_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm35_ap1000", "cm35_ap1000_irr")
    # cm35_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm35_ap1000", "cm35_ap1000_construction_cost")
    # ##### Capacity Market of $35.0/kW-month for AP1000 #####

    # ##### Capacity Market of $40.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 40.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm40_ap1000")
    # cm40_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm40_ap1000", "cm40_ap1000_breakeven")
    # cm40_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm40_ap1000", "cm40_ap1000_npv_final")
    # cm40_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm40_ap1000", "cm40_ap1000_irr")
    # cm40_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm40_ap1000", "cm40_ap1000_construction_cost")
    # ##### Capacity Market of $40.0/kW-month for AP1000 #####
    
    # ##### Capacity Market of $45.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 45.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm45_ap1000")
    # cm45_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm45_ap1000", "cm45_ap1000_breakeven")
    # cm45_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm45_ap1000", "cm45_ap1000_npv_final")
    # cm45_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm45_ap1000", "cm45_ap1000_irr")
    # cm45_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm45_ap1000", "cm45_ap1000_construction_cost")
    # ##### Capacity Market of $45.0/kW-month for AP1000 #####

    # ##### Capacity Market of $50.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 50.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm50_ap1000")
    # cm50_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm50_ap1000", "cm50_ap1000_breakeven")
    # cm50_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm50_ap1000", "cm50_ap1000_npv_final")
    # cm50_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm50_ap1000", "cm50_ap1000_irr")
    # cm50_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm50_ap1000", "cm50_ap1000_construction_cost")
    # ##### Capacity Market of $50.0/kW-month for AP1000 #####

    # ##### Capacity Market of $55.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 55.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm55_ap1000")
    # cm55_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm55_ap1000", "cm55_ap1000_breakeven")
    # cm55_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm55_ap1000", "cm55_ap1000_npv_final")
    # cm55_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm55_ap1000", "cm55_ap1000_irr")
    # cm55_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm55_ap1000", "cm55_ap1000_construction_cost")
    # ##### Capacity Market of $55.0/kW-month for AP1000 #####

    # ##### Capacity Market of $60.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 60.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm60_ap1000")
    # cm60_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm60_ap1000", "cm60_ap1000_breakeven")
    # cm60_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm60_ap1000", "cm60_ap1000_npv_final")
    # cm60_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm60_ap1000", "cm60_ap1000_irr")
    # cm60_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm60_ap1000", "cm60_ap1000_construction_cost")
    # ##### Capacity Market of $60.0/kW-month for AP1000 #####

    # ##### Capacity Market of $65.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 65.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm65_ap1000")
    # cm65_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm65_ap1000", "cm65_ap1000_breakeven")
    # cm65_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm65_ap1000", "cm65_ap1000_npv_final")
    # cm65_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm65_ap1000", "cm65_ap1000_irr")
    # cm65_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm65_ap1000", "cm65_ap1000_construction_cost")
    # ##### Capacity Market of $65.0/kW-month for AP1000 #####

    # ##### Capacity Market of $70.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 70.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm70_ap1000")
    # cm70_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm70_ap1000", "cm70_ap1000_breakeven")
    # cm70_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm70_ap1000", "cm70_ap1000_npv_final")
    # cm70_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm70_ap1000", "cm70_ap1000_irr")
    # cm70_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm70_ap1000", "cm70_ap1000_construction_cost")
    # ##### Capacity Market of $70.0/kW-month for AP1000 #####

    # ##### Capacity Market of $75.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 75.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm75_ap1000")
    # cm75_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm75_ap1000", "cm75_ap1000_breakeven")
    # cm75_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm75_ap1000", "cm75_ap1000_npv_final")
    # cm75_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm75_ap1000", "cm75_ap1000_irr")
    # cm75_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm75_ap1000", "cm75_ap1000_construction_cost")
    # ##### Capacity Market of $75.0/kW-month for AP1000 #####

    # ##### Capacity Market of $80.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 80.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm80_ap1000")
    # cm80_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm80_ap1000", "cm80_ap1000_breakeven")
    # cm80_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm80_ap1000", "cm80_ap1000_npv_final")
    # cm80_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm80_ap1000", "cm80_ap1000_irr")
    # cm80_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm80_ap1000", "cm80_ap1000_construction_cost")
    # ##### Capacity Market of $80.0/kW-month for AP1000 #####

    # ##### Capacity Market of $85.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 85.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm85_ap1000")
    # cm85_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm85_ap1000", "cm85_ap1000_breakeven")
    # cm85_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm85_ap1000", "cm85_ap1000_npv_final")
    # cm85_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm85_ap1000", "cm85_ap1000_irr")
    # cm85_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm85_ap1000", "cm85_ap1000_construction_cost")
    # ##### Capacity Market of $85.0/kW-month for AP1000 #####

    # ##### Capacity Market of $90.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 90.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm90_ap1000")
    # cm90_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm90_ap1000", "cm90_ap1000_breakeven")
    # cm90_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm90_ap1000", "cm90_ap1000_npv_final")
    # cm90_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm90_ap1000", "cm90_ap1000_irr")
    # cm90_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm90_ap1000", "cm90_ap1000_construction_cost")
    # ##### Capacity Market of $90.0/kW-month for AP1000 #####

    # ##### Capacity Market of $95.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 95.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm95_ap1000")
    # cm95_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm95_ap1000", "cm95_ap1000_breakeven")
    # cm95_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm95_ap1000", "cm95_ap1000_npv_final")
    # cm95_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm95_ap1000", "cm95_ap1000_irr")
    # cm95_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm95_ap1000", "cm95_ap1000_construction_cost")
    # ##### Capacity Market of $95.0/kW-month for AP1000 #####

    # ##### Capacity Market of $100.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 100.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm100_ap1000")
    # cm100_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm100_ap1000", "cm100_ap1000_breakeven")
    # cm100_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm100_ap1000", "cm100_ap1000_npv_final")
    # cm100_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm100_ap1000", "cm100_ap1000_irr")
    # cm100_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm100_ap1000", "cm100_ap1000_construction_cost")
    # ##### Capacity Market of $100.0/kW-month for AP1000 #####

    # ##### Capacity Market of $105.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 105.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm105_ap1000")
    # cm105_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm105_ap1000", "cm105_ap1000_breakeven")
    # cm105_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm105_ap1000", "cm105_ap1000_npv_final")
    # cm105_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm105_ap1000", "cm105_ap1000_irr")
    # cm105_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm105_ap1000", "cm105_ap1000_construction_cost")
    # ##### Capacity Market of $105.0/kW-month for AP1000 #####

    # ##### Capacity Market of $110.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 110.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm110_ap1000")
    # cm110_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm110_ap1000", "cm110_ap1000_breakeven")
    # cm110_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm110_ap1000", "cm110_ap1000_npv_final")
    # cm110_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm110_ap1000", "cm110_ap1000_irr")
    # cm110_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm110_ap1000", "cm110_ap1000_construction_cost")
    # ##### Capacity Market of $110.0/kW-month for AP1000 #####

    # ##### Capacity Market of $115.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 115.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm115_ap1000")
    # cm115_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm115_ap1000", "cm115_ap1000_breakeven")
    # cm115_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm115_ap1000", "cm115_ap1000_npv_final")
    # cm115_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm115_ap1000", "cm115_ap1000_irr")
    # cm115_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm115_ap1000", "cm115_ap1000_construction_cost")
    # ##### Capacity Market of $115.0/kW-month for AP1000 #####

    # ##### Capacity Market of $120.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 120.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm120_ap1000")
    # cm120_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm120_ap1000", "cm120_ap1000_breakeven")
    # cm120_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm120_ap1000", "cm120_ap1000_npv_final")
    # cm120_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm120_ap1000", "cm120_ap1000_irr")
    # cm120_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm120_ap1000", "cm120_ap1000_construction_cost")
    # ##### Capacity Market of $120.0/kW-month for AP1000 #####

    # ##### Capacity Market of $125.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 125.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm125_ap1000")
    # cm125_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm125_ap1000", "cm125_ap1000_breakeven")
    # cm125_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm125_ap1000", "cm125_ap1000_npv_final")
    # cm125_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm125_ap1000", "cm125_ap1000_irr")
    # cm125_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm125_ap1000", "cm125_ap1000_construction_cost")
    # ##### Capacity Market of $125.0/kW-month for AP1000 #####

    # ##### Capacity Market of $130.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 130.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm130_ap1000")
    # cm130_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm130_ap1000", "cm130_ap1000_breakeven")
    # cm130_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm130_ap1000", "cm130_ap1000_npv_final")
    # cm130_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm130_ap1000", "cm130_ap1000_irr")
    # cm130_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm130_ap1000", "cm130_ap1000_construction_cost")
    # ##### Capacity Market of $130.0/kW-month for AP1000 #####

    # ##### Capacity Market of $135.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 135.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm135_ap1000")
    # cm135_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm135_ap1000", "cm135_ap1000_breakeven")
    # cm135_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm135_ap1000", "cm135_ap1000_npv_final")
    # cm135_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm135_ap1000", "cm135_ap1000_irr")
    # cm135_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm135_ap1000", "cm135_ap1000_construction_cost")
    # ##### Capacity Market of $135.0/kW-month for AP1000 #####

    # ##### Capacity Market of $140.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 140.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm140_ap1000")
    # cm140_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm140_ap1000", "cm140_ap1000_breakeven")
    # cm140_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm140_ap1000", "cm140_ap1000_npv_final")
    # cm140_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm140_ap1000", "cm140_ap1000_irr")
    # cm140_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm140_ap1000", "cm140_ap1000_construction_cost")
    # ##### Capacity Market of $140.0/kW-month for AP1000 #####

    # ##### Capacity Market of $145.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 145.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm145_ap1000")
    # cm145_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm145_ap1000", "cm145_ap1000_breakeven")
    # cm145_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm145_ap1000", "cm145_ap1000_npv_final")
    # cm145_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm145_ap1000", "cm145_ap1000_irr")
    # cm145_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm145_ap1000", "cm145_ap1000_construction_cost")
    # ##### Capacity Market of $145.0/kW-month for AP1000 #####

    # ##### Capacity Market of $150.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 150.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm150_ap1000")
    # cm150_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm150_ap1000", "cm150_ap1000_breakeven")
    # cm150_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm150_ap1000", "cm150_ap1000_npv_final")
    # cm150_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm150_ap1000", "cm150_ap1000_irr")
    # cm150_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm150_ap1000", "cm150_ap1000_construction_cost")
    # ##### Capacity Market of $150.0/kW-month for AP1000 #####

    # ##### Capacity Market of $155.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 155.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm155_ap1000")
    # cm155_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm155_ap1000", "cm155_ap1000_breakeven")
    # cm155_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm155_ap1000", "cm155_ap1000_npv_final")
    # cm155_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm155_ap1000", "cm155_ap1000_irr")
    # cm155_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm155_ap1000", "cm155_ap1000_construction_cost")
    # ##### Capacity Market of $155.0/kW-month for AP1000 #####

    # ##### Capacity Market of $160.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 160.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm160_ap1000")
    # cm160_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm160_ap1000", "cm160_ap1000_breakeven")
    # cm160_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm160_ap1000", "cm160_ap1000_npv_final")
    # cm160_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm160_ap1000", "cm160_ap1000_irr")
    # cm160_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm160_ap1000", "cm160_ap1000_construction_cost")
    # ##### Capacity Market of $160.0/kW-month for AP1000 #####

    # ##### Capacity Market of $165.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 165.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm165_ap1000")
    # cm165_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm165_ap1000", "cm165_ap1000_breakeven")
    # cm165_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm165_ap1000", "cm165_ap1000_npv_final")
    # cm165_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm165_ap1000", "cm165_ap1000_irr")
    # cm165_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm165_ap1000", "cm165_ap1000_construction_cost")
    # ##### Capacity Market of $165.0/kW-month for AP1000 #####

    # ##### Capacity Market of $170.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 170.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm170_ap1000")
    # cm170_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm170_ap1000", "cm170_ap1000_breakeven")
    # cm170_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm170_ap1000", "cm170_ap1000_npv_final")
    # cm170_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm170_ap1000", "cm170_ap1000_irr")
    # cm170_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm170_ap1000", "cm170_ap1000_construction_cost")
    # ##### Capacity Market of $170.0/kW-month for AP1000 #####

    # ##### Capacity Market of $175.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 175.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm175_ap1000")
    # cm175_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm175_ap1000", "cm175_ap1000_breakeven")
    # cm175_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm175_ap1000", "cm175_ap1000_npv_final")
    # cm175_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm175_ap1000", "cm175_ap1000_irr")
    # cm175_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm175_ap1000", "cm175_ap1000_construction_cost")
    # ##### Capacity Market of $175.0/kW-month for AP1000 #####

    # ##### Capacity Market of $180.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 180.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm180_ap1000")
    # cm180_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm180_ap1000", "cm180_ap1000_breakeven")
    # cm180_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm180_ap1000", "cm180_ap1000_npv_final")
    # cm180_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm180_ap1000", "cm180_ap1000_irr")
    # cm180_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm180_ap1000", "cm180_ap1000_construction_cost")
    # ##### Capacity Market of $180.0/kW-month for AP1000 #####

    # ##### Capacity Market of $185.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 185.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm185_ap1000")
    # cm185_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm185_ap1000", "cm185_ap1000_breakeven")
    # cm185_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm185_ap1000", "cm185_ap1000_npv_final")
    # cm185_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm185_ap1000", "cm185_ap1000_irr")
    # cm185_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm185_ap1000", "cm185_ap1000_construction_cost")
    # ##### Capacity Market of $185.0/kW-month for AP1000 #####

    # ##### Capacity Market of $190.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 190.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm190_ap1000")
    # cm190_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm190_ap1000", "cm190_ap1000_breakeven")
    # cm190_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm190_ap1000", "cm190_ap1000_npv_final")
    # cm190_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm190_ap1000", "cm190_ap1000_irr")
    # cm190_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm190_ap1000", "cm190_ap1000_construction_cost")
    # ##### Capacity Market of $190.0/kW-month for AP1000 #####

    # ##### Capacity Market of $195.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 195.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm195_ap1000")
    # cm195_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm195_ap1000", "cm195_ap1000_breakeven")
    # cm195_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm195_ap1000", "cm195_ap1000_npv_final")
    # cm195_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm195_ap1000", "cm195_ap1000_irr")
    # cm195_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm195_ap1000", "cm195_ap1000_construction_cost")
    # ##### Capacity Market of $195.0/kW-month for AP1000 #####

    # ##### Capacity Market of $200.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 200.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm200_ap1000")
    # cm200_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm200_ap1000", "cm200_ap1000_breakeven")
    # cm200_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm200_ap1000", "cm200_ap1000_npv_final")
    # cm200_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm200_ap1000", "cm200_ap1000_irr")
    # cm200_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm200_ap1000", "cm200_ap1000_construction_cost")
    # ##### Capacity Market of $200.0/kW-month for AP1000 #####

    # ##### Capacity Market of $205.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 205.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm205_ap1000")
    # cm205_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm205_ap1000", "cm205_ap1000_breakeven")
    # cm205_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm205_ap1000", "cm205_ap1000_npv_final")
    # cm205_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm205_ap1000", "cm205_ap1000_irr")
    # cm205_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm205_ap1000", "cm205_ap1000_construction_cost")
    # ##### Capacity Market of $205.0/kW-month for AP1000 #####

    # ##### Capacity Market of $210.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 210.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm210_ap1000")
    # cm210_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm210_ap1000", "cm210_ap1000_breakeven")
    # cm210_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm210_ap1000", "cm210_ap1000_npv_final")
    # cm210_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm210_ap1000", "cm210_ap1000_irr")
    # cm210_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm210_ap1000", "cm210_ap1000_construction_cost")
    # ##### Capacity Market of $210.0/kW-month for AP1000 #####

    # ##### Capacity Market of $215.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 215.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm215_ap1000")
    # cm215_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm215_ap1000", "cm215_ap1000_breakeven")
    # cm215_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm215_ap1000", "cm215_ap1000_npv_final")
    # cm215_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm215_ap1000", "cm215_ap1000_irr")
    # cm215_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm215_ap1000", "cm215_ap1000_construction_cost")
    # ##### Capacity Market of $215.0/kW-month for AP1000 #####

    # ##### Capacity Market of $220.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 220.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm220_ap1000")
    # cm220_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm220_ap1000", "cm220_ap1000_breakeven")
    # cm220_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm220_ap1000", "cm220_ap1000_npv_final")
    # cm220_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm220_ap1000", "cm220_ap1000_irr")
    # cm220_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm220_ap1000", "cm220_ap1000_construction_cost")
    # ##### Capacity Market of $220.0/kW-month for AP1000 #####

    # ##### Capacity Market of $225.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 225.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm225_ap1000")
    # cm225_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm225_ap1000", "cm225_ap1000_breakeven")
    # cm225_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm225_ap1000", "cm225_ap1000_npv_final")
    # cm225_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm225_ap1000", "cm225_ap1000_irr")
    # cm225_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm225_ap1000", "cm225_ap1000_construction_cost")
    # ##### Capacity Market of $225.0/kW-month for AP1000 #####

    # ##### Capacity Market of $230.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 230.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm230_ap1000")
    # cm230_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm230_ap1000", "cm230_ap1000_breakeven")
    # cm230_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm230_ap1000", "cm230_ap1000_npv_final")
    # cm230_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm230_ap1000", "cm230_ap1000_irr")
    # cm230_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm230_ap1000", "cm230_ap1000_construction_cost")
    # ##### Capacity Market of $230.0/kW-month for AP1000 #####

    # ##### Capacity Market of $235.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 235.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm235_ap1000")
    # cm235_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm235_ap1000", "cm235_ap1000_breakeven")
    # cm235_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm235_ap1000", "cm235_ap1000_npv_final")
    # cm235_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm235_ap1000", "cm235_ap1000_irr")
    # cm235_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm235_ap1000", "cm235_ap1000_construction_cost")
    # ##### Capacity Market of $235.0/kW-month for AP1000 #####

    # ##### Capacity Market of $240.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 240.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm240_ap1000")
    # cm240_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm240_ap1000", "cm240_ap1000_breakeven")
    # cm240_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm240_ap1000", "cm240_ap1000_npv_final")
    # cm240_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm240_ap1000", "cm240_ap1000_irr")
    # cm240_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm240_ap1000", "cm240_ap1000_construction_cost")
    # ##### Capacity Market of $240.0/kW-month for AP1000 #####

    # ##### Capacity Market of $245.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 245.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm245_ap1000")
    # cm245_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm245_ap1000", "cm245_ap1000_breakeven")
    # cm245_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm245_ap1000", "cm245_ap1000_npv_final")
    # cm245_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm245_ap1000", "cm245_ap1000_irr")
    # cm245_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm245_ap1000", "cm245_ap1000_construction_cost")
    # ##### Capacity Market of $245.0/kW-month for AP1000 #####

    # ##### Capacity Market of $250.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 250.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm250_ap1000")
    # cm250_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm250_ap1000", "cm250_ap1000_breakeven")
    # cm250_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm250_ap1000", "cm250_ap1000_npv_final")
    # cm250_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm250_ap1000", "cm250_ap1000_irr")
    # cm250_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm250_ap1000", "cm250_ap1000_construction_cost")
    # ##### Capacity Market of $250.0/kW-month for AP1000 #####

    # ##### Capacity Market of $255.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 255.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm255_ap1000")
    # cm255_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm255_ap1000", "cm255_ap1000_breakeven")
    # cm255_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm255_ap1000", "cm255_ap1000_npv_final")
    # cm255_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm255_ap1000", "cm255_ap1000_irr")
    # cm255_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm255_ap1000", "cm255_ap1000_construction_cost")
    # ##### Capacity Market of $255.0/kW-month for AP1000 #####

    # ##### Capacity Market of $260.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 260.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm260_ap1000")
    # cm260_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm260_ap1000", "cm260_ap1000_breakeven")
    # cm260_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm260_ap1000", "cm260_ap1000_npv_final")
    # cm260_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm260_ap1000", "cm260_ap1000_irr")
    # cm260_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm260_ap1000", "cm260_ap1000_construction_cost")
    # ##### Capacity Market of $260.0/kW-month for AP1000 #####

    # ##### Capacity Market of $265.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 265.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm265_ap1000")
    # cm265_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm265_ap1000", "cm265_ap1000_breakeven")
    # cm265_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm265_ap1000", "cm265_ap1000_npv_final")
    # cm265_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm265_ap1000", "cm265_ap1000_irr")
    # cm265_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm265_ap1000", "cm265_ap1000_construction_cost")
    # ##### Capacity Market of $265.0/kW-month for AP1000 #####

    # ##### Capacity Market of $270.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 270.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm270_ap1000")
    # cm270_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm270_ap1000", "cm270_ap1000_breakeven")
    # cm270_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm270_ap1000", "cm270_ap1000_npv_final")
    # cm270_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm270_ap1000", "cm270_ap1000_irr")
    # cm270_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm270_ap1000", "cm270_ap1000_construction_cost")
    # ##### Capacity Market of $270.0/kW-month for AP1000 #####

    # ##### Capacity Market of $275.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 275.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm275_ap1000")
    # cm275_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm275_ap1000", "cm275_ap1000_breakeven")
    # cm275_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm275_ap1000", "cm275_ap1000_npv_final")
    # cm275_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm275_ap1000", "cm275_ap1000_irr")
    # cm275_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm275_ap1000", "cm275_ap1000_construction_cost")
    # ##### Capacity Market of $275.0/kW-month for AP1000 #####

    # ##### Capacity Market of $280.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 280.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm280_ap1000")
    # cm280_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm280_ap1000", "cm280_ap1000_breakeven")
    # cm280_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm280_ap1000", "cm280_ap1000_npv_final")
    # cm280_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm280_ap1000", "cm280_ap1000_irr")
    # cm280_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm280_ap1000", "cm280_ap1000_construction_cost")
    # ##### Capacity Market of $280.0/kW-month for AP1000 #####

    # ##### Capacity Market of $285.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 285.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm285_ap1000")
    # cm285_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm285_ap1000", "cm285_ap1000_breakeven")
    # cm285_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm285_ap1000", "cm285_ap1000_npv_final")
    # cm285_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm285_ap1000", "cm285_ap1000_irr")
    # cm285_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm285_ap1000", "cm285_ap1000_construction_cost")
    # ##### Capacity Market of $285.0/kW-month for AP1000 #####

    # ##### Capacity Market of $290.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 290.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm290_ap1000")
    # cm290_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm290_ap1000", "cm290_ap1000_breakeven")
    # cm290_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm290_ap1000", "cm290_ap1000_npv_final")
    # cm290_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm290_ap1000", "cm290_ap1000_irr")
    # cm290_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm290_ap1000", "cm290_ap1000_construction_cost")
    # ##### Capacity Market of $290.0/kW-month for AP1000 #####

    # ##### Capacity Market of $295.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 295.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm295_ap1000")
    # cm295_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm295_ap1000", "cm295_ap1000_breakeven")
    # cm295_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm295_ap1000", "cm295_ap1000_npv_final")
    # cm295_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm295_ap1000", "cm295_ap1000_irr")
    # cm295_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm295_ap1000", "cm295_ap1000_construction_cost")
    # ##### Capacity Market of $295.0/kW-month for AP1000 #####

    # ##### Capacity Market of $300.0/kW-month for AP1000 #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_ap1000_scenarios(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 300.0, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/ap1000cases/ap1000capacitymarket/cm300_ap1000")
    # cm300_ap1000_breakeven = export_ap1000_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm300_ap1000", "cm300_ap1000_breakeven")
    # cm300_ap1000_npv_final = export_ap1000_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm300_ap1000", "cm300_ap1000_npv_final")
    # cm300_ap1000_irr = export_ap1000_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm300_ap1000", "cm300_ap1000_irr")
    # cm300_ap1000_construction_cost_all = export_ap1000_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm300_ap1000", "cm300_ap1000_construction_cost")
    # ##### Capacity Market of $300.0/kW-month for AP1000 #####




    """
    Capacity Market Analysis for Cambium 2022 and 23
    """

    # ##### Capacity Market of $1.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 1.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm1_cambium")
    # cm1_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm1_cambium", "cm1_cambium_breakeven")
    # cm1_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm1_cambium", "cm1_cambium_npv_final")
    # cm1_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm1_cambium", "cm1_cambium_irr")
    # cm1_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm1_cambium", "cm1_cambium_construction_cost")
    # ##### Capacity Market of $1.0/kW-month for Cambium #####

    # ##### Capacity Market of $2.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 2.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm2_cambium")
    # cm2_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm2_baseline", "cm2_cambium_breakeven")
    # cm2_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm2_baseline", "cm2_cambium_npv_final")
    # cm2_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm2_baseline", "cm2_cambium_irr")
    # cm2_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm2_baseline", "cm2_cambium_construction_cost")
    # ##### Capacity Market of $2.0/kW-month for Cambium #####

    # ##### Capacity Market of $3.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 3.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm3_cambium")
    # cm3_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm3_baseline", "cm3_cambium_breakeven")
    # cm3_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm3_baseline", "cm3_cambium_npv_final")
    # cm3_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm3_baseline", "cm3_cambium_irr")
    # cm3_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm3_baseline", "cm3_cambium_construction_cost")
    # ##### Capacity Market of $3.0/kW-month for Cambium #####

    # ##### Capacity Market of $4.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 4.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm4_cambium")
    # cm4_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm4_baseline", "cm4_cambium_breakeven")
    # cm4_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm4_baseline", "cm4_cambium_npv_final")
    # cm4_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm4_baseline", "cm4_cambium_irr")
    # cm4_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm4_baseline", "cm4_cambium_construction_cost")
    # ##### Capacity Market of $4.0/kW-month for Cambium #####

    # ##### Capacity Market of $5.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm5_cambium")
    # cm5_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm5_baseline", "cm5_cambium_breakeven")
    # cm5_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm5_baseline", "cm5_cambium_npv_final")
    # cm5_cambium_irr = export_cambium23_data_to_csv(irr_all, "//Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm5_baseline", "cm5_cambium_irr")
    # cm5_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm5_baseline", "cm5_cambium_construction_cost")
    # ##### Capacity Market of $5.0/kW-month for Cambium #####

    # ##### Capacity Market of $6.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 6.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm6_cambium")
    # cm6_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm6_baseline", "cm6_cambium_breakeven")
    # cm6_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm6_baseline", "cm6_cambium_npv_final")
    # cm6_cambium_irr = export_cambium23_data_to_csv(irr_all, "//Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm6_baseline", "cm6_cambium_irr")
    # cm6_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm6_baseline", "cm6_cambium_construction_cost")
    # ##### Capacity Market of $6.0/kW-month for Cambium #####

    # ##### Capacity Market of $7.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 7.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm7_cambium")
    # cm7_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm7_baseline", "cm7_cambium_breakeven")
    # cm7_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm7_baseline", "cm7_cambium_npv_final")
    # cm7_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm7_baseline", "cm7_cambium_irr")
    # cm7_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm7_baseline", "cm7_cambium_construction_cost")
    # ##### Capacity Market of $7.0/kW-month for Cambium #####

    # ##### Capacity Market of $8.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 8.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm8_cambium")
    # cm8_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm8_cambium", "cm8_cambium_breakeven")
    # cm8_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm8_cambium", "cm8_cambium_npv_final")
    # cm8_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm8_cambium", "cm8_cambium_irr")
    # cm8_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm8_cambium", "cm8_cambium_construction_cost")
    # ##### Capacity Market of $8.0/kW-month for Cambium #####

    # ##### Capacity Market of $15.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 15.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm15_cambium")
    # cm15_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm15_cambium", "cm15_cambium_breakeven")
    # cm15_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm15_cambium", "cm15_cambium_npv_final")
    # cm15_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm15_cambium", "cm15_cambium_irr")
    # cm15_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm15_cambium", "cm15_cambium_construction_cost")
    # ##### Capacity Market of $15.0/kW-month for Cambium #####

    # ##### Capacity Market of $16.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 16.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm16_cambium")
    # cm16_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm16_cambium", "cm16_cambium_breakeven")
    # cm16_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm16_cambium", "cm16_cambium_npv_final")
    # cm16_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm16_cambium", "cm16_cambium_irr")
    # cm16_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm16_cambium", "cm16_cambium_construction_cost")
    # ##### Capacity Market of $16.0/kW-month for Cambium #####

    # ##### Capacity Market of $17.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 17.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm17_cambium")
    # cm17_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm17_cambium", "cm17_cambium_breakeven")
    # cm17_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm17_cambium", "cm17_cambium_npv_final")
    # cm17_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm17_cambium", "cm17_cambium_irr")
    # cm17_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm17_cambium", "cm17_cambium_construction_cost")
    # ##### Capacity Market of $17.0/kW-month for Cambium #####

    # ##### Capacity Market of $18.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 18.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm18_cambium")
    # cm18_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm18_cambium", "cm18_cambium_breakeven")
    # cm18_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm18_cambium", "cm18_cambium_npv_final")
    # cm18_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm18_cambium", "cm18_cambium_irr")
    # cm18_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm18_cambium", "cm18_cambium_construction_cost")
    # ##### Capacity Market of $18.0/kW-month for Cambium #####

    # ##### Capacity Market of $19.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 19.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm19_cambium")
    # cm19_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm19_cambium", "cm19_cambium_breakeven")
    # cm19_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm19_cambium", "cm19_cambium_npv_final")
    # cm19_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm19_cambium", "cm19_cambium_irr")
    # cm19_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm19_cambium", "cm19_cambium_construction_cost")
    # ##### Capacity Market of $19.0/kW-month for Cambium #####

    # ##### Capacity Market of $20.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 20.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm20_cambium")
    # cm20_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm20_cambium", "cm20_cambium_breakeven")
    # cm20_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm20_cambium", "cm20_cambium_npv_final")
    # cm20_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm20_cambium", "cm20_cambium_irr")
    # cm20_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm20_cambium", "cm20_cambium_construction_cost")
    # ##### Capacity Market of $20.0/kW-month for Cambium #####

    # ##### Capacity Market of $21.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 21.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm21_cambium")
    # cm21_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm21_cambium", "cm21_cambium_breakeven")
    # cm21_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm21_cambium", "cm21_cambium_npv_final")
    # cm21_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm21_cambium", "cm21_cambium_irr")
    # cm21_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm21_cambium", "cm21_cambium_construction_cost")
    # ##### Capacity Market of $21.0/kW-month for Cambium #####

    # ##### Capacity Market of $22.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 22.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm22_cambium")
    # cm22_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm22_cambium", "cm22_cambium_breakeven")
    # cm22_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm22_cambium", "cm22_cambium_npv_final")
    # cm22_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm22_cambium", "cm22_cambium_irr")
    # cm22_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm22_cambium", "cm22_cambium_construction_cost")
    # ##### Capacity Market of $22.0/kW-month for Cambium #####

    # ##### Capacity Market of $23.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 23.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm23_cambium")
    # cm23_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm23_cambium", "cm23_cambium_breakeven")
    # cm23_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm23_cambium", "cm23_cambium_npv_final")
    # cm23_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm23_cambium", "cm23_cambium_irr")
    # cm23_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm23_cambium", "cm23_cambium_construction_cost")
    # ##### Capacity Market of $23.0/kW-month for Cambium #####

    # ##### Capacity Market of $25.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 25.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm25_cambium")
    # cm25_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm25_cambium", "cm25_cambium_breakeven")
    # cm25_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm25_cambium", "cm25_cambium_npv_final")
    # cm25_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm25_cambium", "cm25_cambium_irr")
    # cm25_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm25_cambium", "cm25_cambium_construction_cost")
    # ##### Capacity Market of $25.0/kW-month for Cambium #####

    # ##### Capacity Market of $30.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 30.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm30_cambium")
    # cm30_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm30_cambium", "cm30_cambium_breakeven")
    # cm30_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm30_cambium", "cm30_cambium_npv_final")
    # cm30_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm30_cambium", "cm30_cambium_irr")
    # cm30_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm30_cambium", "cm30_cambium_construction_cost")
    # ##### Capacity Market of $30.0/kW-month for Cambium #####

    # ##### Capacity Market of $35.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 35.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm35_cambium")
    # cm35_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm35_cambium", "cm35_cambium_breakeven")
    # cm35_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm35_cambium", "cm35_cambium_npv_final")
    # cm35_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm35_cambium", "cm35_cambium_irr")
    # cm35_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm35_cambium", "cm35_cambium_construction_cost")
    # ##### Capacity Market of $35.0/kW-month for Cambium #####

    # ##### Capacity Market of $40.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 40.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm40_cambium")
    # cm40_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm40_cambium", "cm40_cambium_breakeven")
    # cm40_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm40_cambium", "cm40_cambium_npv_final")
    # cm40_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm40_cambium", "cm40_cambium_irr")
    # cm40_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm40_cambium", "cm40_cambium_construction_cost")
    # ##### Capacity Market of $40.0/kW-month for Cambium #####

    # ##### Capacity Market of $45.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 45.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm45_cambium")
    # cm45_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm45_cambium", "cm45_cambium_breakeven")
    # cm45_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm45_cambium", "cm45_cambium_npv_final")
    # cm45_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm45_cambium", "cm45_cambium_irr")
    # cm45_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm45_cambium", "cm45_cambium_construction_cost")
    # ##### Capacity Market of $45.0/kW-month for Cambium #####

    # ##### Capacity Market of $50.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 50.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm50_cambium")
    # cm50_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm50_baseline", "cm50_cambium_breakeven")
    # cm50_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm50_baseline", "cm50_cambium_npv_final")
    # cm50_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm50_baseline", "cm50_cambium_irr")
    # cm50_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm50_baseline", "cm50_cambium_construction_cost")
    # ##### Capacity Market of $50.0/kW-month for Cambium #####

    # ##### Capacity Market of $55.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 55.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm55_cambium")
    # cm55_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm55_cambium", "cm55_cambium_breakeven")
    # cm55_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm55_cambium", "cm55_cambium_npv_final")
    # cm55_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm55_cambium", "cm55_cambium_irr")
    # cm55_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm55_cambium", "cm55_cambium_construction_cost")
    # ##### Capacity Market of $55.0/kW-month for Cambium #####

    # ##### Capacity Market of $60.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 60.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm60_cambium")
    # cm60_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm60_cambium", "cm60_cambium_breakeven")
    # cm60_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm60_cambium", "cm60_cambium_npv_final")
    # cm60_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm60_cambium", "cm60_cambium_irr")
    # cm60_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm60_cambium", "cm60_cambium_construction_cost")
    # ##### Capacity Market of $60.0/kW-month for Cambium #####

    # ##### Capacity Market of $65.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 65.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm65_cambium")
    # cm65_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm65_cambium", "cm65_cambium_breakeven")
    # cm65_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm65_cambium", "cm65_cambium_npv_final")
    # cm65_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm65_cambium", "cm65_cambium_irr")
    # cm65_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm65_cambium", "cm65_cambium_construction_cost")
    # ##### Capacity Market of $65.0/kW-month for Cambium #####

    # ##### Capacity Market of $70.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 70.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm70_cambium")
    # cm70_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm70_cambium", "cm70_cambium_breakeven")
    # cm70_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm70_cambium", "cm70_cambium_npv_final")
    # cm70_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm70_cambium", "cm70_cambium_irr")
    # cm70_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm70_cambium", "cm70_cambium_construction_cost")
    # ##### Capacity Market of $70.0/kW-month for Cambium #####

    # ##### Capacity Market of $75.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 75.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm75_cambium")
    # cm75_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm75_cambium", "cm75_cambium_breakeven")
    # cm75_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm75_cambium", "cm75_cambium_npv_final")
    # cm75_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm75_cambium", "cm75_cambium_irr")
    # cm75_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm75_cambium", "cm75_cambium_construction_cost")
    # ##### Capacity Market of $75.0/kW-month for Cambium #####

    # ##### Capacity Market of $80.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 80.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm80_cambium")
    # cm80_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm80_cambium", "cm80_cambium_breakeven")
    # cm80_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm80_cambium", "cm80_cambium_npv_final")
    # cm80_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm80_cambium", "cm80_cambium_irr")
    # cm80_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm80_cambium", "cm80_cambium_construction_cost")
    # ##### Capacity Market of $80.0/kW-month for Cambium #####

    # ##### Capacity Market of $85.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 85.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm85_cambium")
    # cm85_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm85_cambium", "cm85_cambium_breakeven")
    # cm85_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm85_cambium", "cm85_cambium_npv_final")
    # cm85_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm85_cambium", "cm85_cambium_irr")
    # cm85_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm85_cambium", "cm85_cambium_construction_cost")
    # ##### Capacity Market of $85.0/kW-month for Cambium #####

    # ##### Capacity Market of $90.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 90.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm90_cambium")
    # cm90_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm90_cambium", "cm90_cambium_breakeven")
    # cm90_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm90_cambium", "cm90_cambium_npv_final")
    # cm90_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm90_cambium", "cm90_cambium_irr")
    # cm90_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm90_cambium", "cm90_cambium_construction_cost")
    # ##### Capacity Market of $90.0/kW-month for Cambium #####

    # ##### Capacity Market of $95.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 95.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm95_cambium")
    # cm95_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm95_baseline", "cm95_cambium_breakeven")
    # cm95_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm95_baseline", "cm95_cambium_npv_final")
    # cm95_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm95_baseline", "cm95_cambium_irr")
    # cm95_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm95_baseline", "cm95_cambium_construction_cost")
    # ##### Capacity Market of $95.0/kW-month for Cambium #####

    # ##### Capacity Market of $100.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 100.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm100_cambium")
    # cm100_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm100_baseline", "cm100_cambium_breakeven")
    # cm100_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm100_baseline", "cm100_cambium_npv_final")
    # cm100_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm100_baseline", "cm100_cambium_irr")
    # cm100_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm100_baseline", "cm100_cambium_construction_cost")
    # ##### Capacity Market of $100.0/kW-month for Cambium #####

    # ##### Capacity Market of $105.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 105.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm105_cambium")
    # cm105_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm105_baseline", "cm105_cambium_breakeven")
    # cm105_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm105_baseline", "cm105_cambium_npv_final")
    # cm105_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm105_baseline", "cm105_cambium_irr")
    # cm105_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm105_baseline", "cm105_cambium_construction_cost")
    # ##### Capacity Market of $105.0/kW-month for Cambium #####

    # ##### Capacity Market of $110.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 110.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm110_cambium")
    # cm110_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm110_baseline", "cm110_cambium_breakeven")
    # cm110_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm110_baseline", "cm110_cambium_npv_final")
    # cm110_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm110_baseline", "cm110_cambium_irr")
    # cm110_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm110_baseline", "cm110_cambium_construction_cost")
    # ##### Capacity Market of $110.0/kW-month for Cambium #####

    # ##### Capacity Market of $115.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 115.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm115_cambium")
    # cm115_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm115_baseline", "cm115_cambium_breakeven")
    # cm115_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm115_baseline", "cm115_cambium_npv_final")
    # cm115_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm115_baseline", "cm115_cambium_irr")
    # cm115_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm115_baseline", "cm115_cambium_construction_cost")
    # ##### Capacity Market of $115.0/kW-month for Cambium #####

    # ##### Capacity Market of $120.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 120.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm120_cambium")
    # cm120_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm120_baseline", "cm120_cambium_breakeven")
    # cm120_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm120_baseline", "cm120_cambium_npv_final")
    # cm120_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm120_baseline", "cm120_cambium_irr")
    # cm120_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm120_baseline", "cm120_cambium_construction_cost")
    # ##### Capacity Market of $120.0/kW-month for Cambium #####

    # ##### Capacity Market of $125.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 125.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm125_cambium")
    # cm125_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm125_baseline", "cm125_cambium_breakeven")
    # cm125_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm125_baseline", "cm125_cambium_npv_final")
    # cm125_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm125_baseline", "cm125_cambium_irr")
    # cm125_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm125_baseline", "cm125_cambium_construction_cost")
    # ##### Capacity Market of $125.0/kW-month for Cambium #####

    # ##### Capacity Market of $130.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 130.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm130_cambium")
    # cm130_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm130_baseline", "cm130_cambium_breakeven")
    # cm130_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm130_baseline", "cm130_cambium_npv_final")
    # cm130_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm130_baseline", "cm130_cambium_irr")
    # cm130_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm130_baseline", "cm130_cambium_construction_cost")
    # ##### Capacity Market of $130.0/kW-month for Cambium #####

    # ##### Capacity Market of $135.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 135.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm135_cambium")
    # cm135_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm135_baseline", "cm135_cambium_breakeven")
    # cm135_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm135_baseline", "cm135_cambium_npv_final")
    # cm135_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm135_baseline", "cm135_cambium_irr")
    # cm135_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm135_baseline", "cm135_cambium_construction_cost")
    # ##### Capacity Market of $135.0/kW-month for Cambium #####

    # ##### Capacity Market of $140.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 140.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm140_cambium")
    # cm140_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm140_baseline", "cm140_cambium_breakeven")
    # cm140_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm140_baseline", "cm140_cambium_npv_final")
    # cm140_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm140_baseline", "cm140_cambium_irr")
    # cm140_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm140_baseline", "cm140_cambium_construction_cost")
    # ##### Capacity Market of $140.0/kW-month for Cambium #####

    # ##### Capacity Market of $145.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 145.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm145_cambium")
    # cm145_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm145_baseline", "cm145_cambium_breakeven")
    # cm145_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm145_baseline", "cm145_cambium_npv_final")
    # cm145_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm145_baseline", "cm145_cambium_irr")
    # cm145_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm145_baseline", "cm145_cambium_construction_cost")
    # ##### Capacity Market of $145.0/kW-month for Cambium #####

    # ##### Capacity Market of $150.0/kW-month for Cambium #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 1.0, 1.0, 1.0, 1.0, 150.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/cm_cambium23/cm150_cambium")
    # cm150_cambium_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm150_baseline", "cm150_cambium_breakeven")
    # cm150_cambium_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm150_baseline", "cm150_cambium_npv_final")
    # cm150_cambium_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm150_baseline", "cm150_cambium_irr")
    # cm150_cambium_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/cm_cambium23/cm150_baseline", "cm150_cambium_construction_cost")
    # ##### Capacity Market of $150.0/kW-month for Cambium #####




    ######################################## Capacity Market Analysis ########################################





    ######################################## Learning Rate Analysis ########################################

    # ##### Learning Rates reducing construction costs by 5% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.95, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll5_case")
    # ll5_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll5_baseline", "ll5_breakeven")
    # ll5_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll5_baseline", "ll5_npv_final")
    # ll5_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll5_baseline", "ll5_irr")
    # ll5_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll5_baseline", "ll5_construction_cost")
    # ##### Learning Rates reducing construction costs by 5% #####

    # ##### Learning Rates reducing construction costs by 10% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.90, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll10_case")
    # ll10_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll10_baseline", "ll10_breakeven")
    # ll10_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll10_baseline", "ll10_npv_final")
    # ll10_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll10_baseline", "ll10_irr")
    # ll10_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll10_baseline", "ll10_construction_cost")
    # ##### Learning Rates reducing construction costs by 10% #####

    # ##### Learning Rates reducing construction costs by 15% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.85, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll15_case")
    # ll15_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll15_baseline", "ll15_breakeven")
    # ll15_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll15_baseline", "ll15_npv_final")
    # ll15_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll15_baseline", "ll15_irr")
    # ll15_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll15_baseline", "ll15_construction_cost")
    # ##### Learning Rates reducing construction costs by 15% #####

    # ##### Learning Rates reducing construction costs by 20% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.80, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll20_case")
    # ll20_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll20_baseline", "ll20_breakeven")
    # ll20_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll20_baseline", "ll20_npv_final")
    # ll20_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll20_baseline", "ll20_irr")
    # ll20_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll20_baseline", "ll20_construction_cost")
    # ##### Learning Rates reducing construction costs by 20% #####

    # ##### Learning Rates reducing construction costs by 25% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.75, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll25_case")
    # ll25_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll25_baseline", "ll25_breakeven")
    # ll25_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll25_baseline", "ll25_npv_final")
    # ll25_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll25_baseline", "ll25_irr")
    # ll25_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll25_baseline", "ll25_construction_cost")
    # ##### Learning Rates reducing construction costs by 25% #####

    # ##### Learning Rates reducing construction costs by 30% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.70, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll30_case")
    # ll30_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll30_baseline", "ll30_breakeven")
    # ll30_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll30_baseline", "ll30_npv_final")
    # ll30_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll30_baseline", "ll30_irr")
    # ll30_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll30_baseline", "ll30_construction_cost")
    # ##### Learning Rates reducing construction costs by 30% #####

    # ##### Learning Rates reducing construction costs by 35% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.65, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll35_case")
    # ll35_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll35_baseline", "ll35_breakeven")
    # ll35_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll35_baseline", "ll35_npv_final")
    # ll35_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll35_baseline", "ll35_irr")
    # ll35_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll35_baseline", "ll35_construction_cost")
    # ##### Learning Rates reducing construction costs by 35% #####

    # ##### Learning Rates reducing construction costs by 40% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.60, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll40_case")
    # ll40_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll40_baseline", "ll40_breakeven")
    # ll40_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll40_baseline", "ll40_npv_final")
    # ll40_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll40_baseline", "ll40_irr")
    # ll40_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll40_baseline", "ll40_construction_cost")
    # ##### Learning Rates reducing construction costs by 40% #####

    # ##### Learning Rates reducing construction costs by 45% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.55, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll45_case")
    # ll45_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll45_baseline", "ll45_breakeven")
    # ll45_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll45_baseline", "ll45_npv_final")
    # ll45_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll45_baseline", "ll45_irr")
    # ll45_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll45_baseline", "ll45_construction_cost")
    # ##### Learning Rates reducing construction costs by 45% #####

    # ##### Learning Rates reducing construction costs by 50% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.50, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll50_case")
    # ll50_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll50_baseline", "ll50_breakeven")
    # ll50_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll50_baseline", "ll50_npv_final")
    # ll50_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll50_baseline", "ll50_irr")
    # ll50_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll50_baseline", "ll50_construction_cost")
    # ##### Learning Rates reducing construction costs by 50% #####

    # ##### Learning Rates reducing construction costs by 55% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.45, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll55_case")
    # ll55_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll55_baseline", "ll55_breakeven")
    # ll55_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll55_baseline", "ll55_npv_final")
    # ll55_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll55_baseline", "ll55_irr")
    # ll55_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll55_baseline", "ll55_construction_cost")
    # ##### Learning Rates reducing construction costs by 55% #####

    # ##### Learning Rates reducing construction costs by 60% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.40, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll60_case")
    # ll60_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll60_baseline", "ll60_breakeven")
    # ll60_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll60_baseline", "ll60_npv_final")
    # ll60_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll60_baseline", "ll60_irr")
    # ll60_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll60_baseline", "ll60_construction_cost")
    # ##### Learning Rates reducing construction costs by 60% #####

    # ##### Learning Rates reducing construction costs by 65% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.35, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll65_case")
    # ll65_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll65_baseline", "ll65_breakeven")
    # ll65_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll65_baseline", "ll65_npv_final")
    # ll65_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll65_baseline", "ll65_irr")
    # ll65_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll65_baseline", "ll65_construction_cost")
    # ##### Learning Rates reducing construction costs by 65% #####

    # ##### Learning Rates reducing construction costs by 70% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.30, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll70_case")
    # ll70_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll70_baseline", "ll70_breakeven")
    # ll70_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll70_baseline", "ll70_npv_final")
    # ll70_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll70_baseline", "ll70_irr")
    # ll70_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll70_baseline", "ll70_construction_cost")
    # ##### Learning Rates reducing construction costs by 70% #####

    # ##### Learning Rates reducing construction costs by 75% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.25, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll75_case")
    # ll75_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll75_baseline", "ll75_breakeven")
    # ll75_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll75_baseline", "ll75_npv_final")
    # ll75_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll75_baseline", "ll75_irr")
    # ll75_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll75_baseline", "ll75_construction_cost")
    # ##### Learning Rates reducing construction costs by 75% #####

    # ##### Learning Rates reducing construction costs by 80% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.20, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll80_case")
    # ll80_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll80_baseline", "ll80_breakeven")
    # ll80_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll80_baseline", "ll80_npv_final")
    # ll80_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll80_baseline", "ll80_irr")
    # ll80_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll80_baseline", "ll80_construction_cost")
    # ##### Learning Rates reducing construction costs by 80% #####

    # ##### Learning Rates reducing construction costs by 85% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.15, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll85_case")
    # ll85_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll85_baseline", "ll85_breakeven")
    # ll85_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll85_baseline", "ll85_npv_final")
    # ll85_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll85_baseline", "ll85_irr")
    # ll85_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll85_baseline", "ll85_construction_cost")
    # ##### Learning Rates reducing construction costs by 85% #####

    # ##### Learning Rates reducing construction costs by 90% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.10, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll90_case")
    # ll90_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll90_baseline", "ll90_breakeven")
    # ll90_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll90_baseline", "ll90_npv_final")
    # ll90_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll90_baseline", "ll90_irr")
    # ll90_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll90_baseline", "ll90_construction_cost")
    # ##### Learning Rates reducing construction costs by 90% #####

    # ##### Learning Rates reducing construction costs by 95% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.05, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll95_case")
    # ll95_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll95_baseline", "ll95_breakeven")
    # ll95_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll95_baseline", "ll95_npv_final")
    # ll95_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll95_baseline", "ll95_irr")
    # ll95_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll95_baseline", "ll95_construction_cost")
    # ##### Learning Rates reducing construction costs by 95% #####

    # ##### Learning Rates reducing construction costs by 96% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.04, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll96_case")
    # ll96_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll96_baseline", "ll96_breakeven")
    # ll96_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll96_baseline", "ll96_npv_final")
    # ll96_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll96_baseline", "ll96_irr")
    # ll96_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll96_baseline", "ll96_construction_cost")
    # ##### Learning Rates reducing construction costs by 96% #####

    # ##### Learning Rates reducing construction costs by 97% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.03, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll97_case")
    # ll97_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll97_baseline", "ll97_breakeven")
    # ll97_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll97_baseline", "ll97_npv_final")
    # ll97_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll97_baseline", "ll97_irr")
    # ll97_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll97_baseline", "ll97_construction_cost")
    # ##### Learning Rates reducing construction costs by 97% #####

    # ##### Learning Rates reducing construction costs by 98% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.02, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll98_case")
    # ll98_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll98_baseline", "ll98_breakeven")
    # ll98_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll98_baseline", "ll98_npv_final")
    # ll98_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll98_baseline", "ll98_irr")
    # ll98_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll98_baseline", "ll98_construction_cost")
    # ##### Learning Rates reducing construction costs by 98% #####

    # ##### Learning Rates reducing construction costs by 99% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.01, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll99_case")
    # ll99_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll99_baseline", "ll99_breakeven")
    # ll99_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll99_baseline", "ll99_npv_final")
    # ll99_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll99_baseline", "ll99_irr")
    # ll99_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll99_baseline", "ll99_construction_cost")
    # ##### Learning Rates reducing construction costs by 99% #####

    # ##### Learning Rates reducing construction costs by 100% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.0, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/learning_rates/ll100_case")
    # ll100_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll100_baseline", "ll100_breakeven")
    # ll100_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll100_baseline", "ll100_npv_final")
    # ll100_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll100_baseline", "ll100_irr")
    # ll100_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ll100_baseline", "ll100_construction_cost")
    # ##### Learning Rates reducing construction costs by 100% #####


    # ############### Synthetic Cases ################


    # ##### Synthetic Case 1: Multi-modular, PTC $15/MWh and Capacity Market of $5.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, true, true, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case1")
    # synthetic_case1_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case1", "synthetic_case1_breakeven")
    # synthetic_case1_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case1", "synthetic_case1_npv_final")
    # synthetic_case1_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case1", "synthetic_case1_irr")
    # synthetic_case1_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case1", "synthetic_case1_construction_cost")
    # ##### Synthetic Case 1: Multi-modular, C2N, PTC $15/MWh and Capacity Market of $5.0/kW-month #####

    # ##### Synthetic Case 2: Multi-modular, C2N, PTC $15/MWh and Capacity Market of $5.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, true, true, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case2")
    # synthetic_case2_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case2", "synthetic_case2_breakeven")
    # synthetic_case2_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case2", "synthetic_case2_npv_final")
    # synthetic_case2_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case2", "synthetic_case2_irr")
    # synthetic_case2_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case2", "synthetic_case2_construction_cost")
    # ##### Synthetic Case 2: Multi-modular, C2N, PTC $15/MWh and Capacity Market of $5.0/kW-month #####

    # ##### Synthetic Case 3: Multi-modular, C2N, ITC 6%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, true, true, true, "6%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case3")
    # synthetic_case3_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case3", "synthetic_case3_breakeven")
    # synthetic_case3_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case3", "synthetic_case3_npv_final")
    # synthetic_case3_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case3", "synthetic_case3_irr")
    # synthetic_case3_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case3", "synthetic_case3_construction_cost")
    # ##### Synthetic Case 3: Multi-modular, C2N, ITC 6%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####

    # ##### Synthetic Case 4: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, true, true, true, "30%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case4")
    # synthetic_case4_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case4", "synthetic_case4_breakeven")
    # synthetic_case4_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case4", "synthetic_case4_npv_final")
    # synthetic_case4_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case4", "synthetic_case4_irr")
    # synthetic_case4_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case4", "synthetic_case4_construction_cost")
    # ##### Synthetic Case 4: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####

    # ##### Synthetic Case 5: Multi-modular, C2N, ITC 40%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, true, true, true, "40%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case5")
    # synthetic_case5_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case5", "synthetic_case5_breakeven")
    # synthetic_case5_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case5", "synthetic_case5_npv_final")
    # synthetic_case5_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case5", "synthetic_case5_irr")
    # synthetic_case5_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case5", "synthetic_case5_construction_cost")
    # ##### Synthetic Case 5: Multi-modular, C2N, ITC 40%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####

    # ##### Synthetic Case 6: Multi-modular, C2N, ITC 50%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 5.0, true, true, true, "40%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case6")
    # synthetic_case6_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case6", "synthetic_case6_breakeven")
    # synthetic_case6_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case6", "synthetic_case6_npv_final")
    # synthetic_case6_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case6", "synthetic_case6_irr")
    # synthetic_case6_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case6", "synthetic_case6_construction_cost")
    # ##### Synthetic Case 6: Multi-modular, C2N, ITC 50%, PTC $15/MWh and Capacity Market of $5.0/kW-month #####

    # ##### Synthetic Case 7: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $15.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 15.0, true, true, true, "30%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case7")
    # synthetic_case7_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case7", "synthetic_case7_breakeven")
    # synthetic_case7_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case7", "synthetic_case7_npv_final")
    # synthetic_case7_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case7", "synthetic_case7_irr")
    # synthetic_case7_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case7", "synthetic_case7_construction_cost")
    # ##### Synthetic Case 7: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $15.0/kW-month #####

    # ##### Synthetic Case 8: Multi-modular, C2N, ITC 30%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 27.5, true, true, true, "30%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case8")
    # synthetic_case8_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case8", "synthetic_case8_breakeven")
    # synthetic_case8_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case8", "synthetic_case8_npv_final")
    # synthetic_case8_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case8", "synthetic_case8_irr")
    # synthetic_case8_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case8", "synthetic_case8_construction_cost")
    # ##### Synthetic Case 8: Multi-modular, C2N, ITC 30%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####

    # ##### Synthetic Case 9: Multi-modular, C2N, ITC 40%, PTC $15/MWh and Capacity Market of $15.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 15.0, true, true, true, "40%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case9")
    # synthetic_case9_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case9", "synthetic_case9_breakeven")
    # synthetic_case9_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case9", "synthetic_case9_npv_final")
    # synthetic_case9_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case9", "synthetic_case9_irr")
    # synthetic_case9_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case9", "synthetic_case9_construction_cost")
    # ##### Synthetic Case 9: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $15.0/kW-month #####

    # ##### Synthetic Case 10: Multi-modular, C2N, ITC 50%, PTC $15/MWh and Capacity Market of $15.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 15.0, 10, 1.0, 1.0, 1.0, 1.0, 15.0, true, true, true, "50%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case10")
    # synthetic_case10_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case10", "synthetic_case10_breakeven")
    # synthetic_case10_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case10", "synthetic_case10_npv_final")
    # synthetic_case10_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case10", "synthetic_case10_irr")
    # synthetic_case10_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case10", "synthetic_case10_construction_cost")
    # ##### Synthetic Case 10: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $15.0/kW-month #####

    # ##### Synthetic Case 11: Multi-modular, C2N, ITC 6%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 27.5, 10, 1.0, 1.0, 1.0, 1.0, 15.0, true, true, true, "6%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case11")
    # synthetic_case11_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case11", "synthetic_case11_breakeven")
    # synthetic_case11_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case11", "synthetic_case11_npv_final")
    # synthetic_case11_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case11", "synthetic_case11_irr")
    # synthetic_case11_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case11", "synthetic_case11_construction_cost")
    # ##### Synthetic Case 11: Multi-modular, C2N, ITC 6%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####

    # ##### Synthetic Case 12: Multi-modular, C2N, ITC 40%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 27.5, 10, 1.0, 1.0, 1.0, 1.0, 15.0, true, true, true, "40%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case12")
    # synthetic_case12_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case12", "synthetic_case12_breakeven")
    # synthetic_case12_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case12", "synthetic_case12_npv_final")
    # synthetic_case12_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case12", "synthetic_case12_irr")
    # synthetic_case12_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case12", "synthetic_case12_construction_cost")
    # ##### Synthetic Case 12: Multi-modular, C2N, ITC 40%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####

    # ##### Synthetic Case 13: Multi-modular, C2N, ITC 50%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 27.5, 10, 1.0, 1.0, 1.0, 1.0, 15.0, true, true, true, "50%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case13")
    # synthetic_case13_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case13", "synthetic_case13_breakeven")
    # synthetic_case13_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case13", "synthetic_case13_npv_final")
    # synthetic_case13_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case13", "synthetic_case13_irr")
    # synthetic_case13_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case13", "synthetic_case13_construction_cost")
    # ##### Synthetic Case 13: Multi-modular, C2N, ITC 50%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month #####

    # ##### Synthetic Case 14: Multi-modular, C2N, ITC 6%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 30.05, 10, 1.0, 1.0, 1.0, 1.0, 25.0, true, true, true, "6%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case14")
    # synthetic_case14_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case14", "synthetic_case14_breakeven")
    # synthetic_case14_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case14", "synthetic_case14_npv_final")
    # synthetic_case14_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case14", "synthetic_case14_irr")
    # synthetic_case14_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case14", "synthetic_case14_construction_cost")
    # ##### Synthetic Case 14: Multi-modular, C2N, ITC 6%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month #####

    # ##### Synthetic Case 15: Multi-modular, C2N, ITC 30%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 30.05, 10, 1.0, 1.0, 1.0, 1.0, 25.0, true, true, true, "30%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case15")
    # synthetic_case15_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case15", "synthetic_case15_breakeven")
    # synthetic_case15_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case15", "synthetic_case15_npv_final")
    # synthetic_case15_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case15", "synthetic_case15_irr")
    # synthetic_case15_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case15", "synthetic_case15_construction_cost")
    # ##### Synthetic Case 15: Multi-modular, C2N, ITC 30%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month #####

    # ##### Synthetic Case 16: Multi-modular, C2N, ITC 40%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 30.05, 10, 1.0, 1.0, 1.0, 1.0, 25.0, true, true, true, "40%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case16")
    # synthetic_case16_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case16", "synthetic_case16_breakeven")
    # synthetic_case16_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case16", "synthetic_case16_npv_final")
    # synthetic_case16_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case16", "synthetic_case16_irr")
    # synthetic_case16_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case16", "synthetic_case16_construction_cost")
    # ##### Synthetic Case 16: Multi-modular, C2N, ITC 40%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month #####

    # ##### Synthetic Case 17: Multi-modular, C2N, ITC 50%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 30.05, 10, 1.0, 1.0, 1.0, 1.0, 25.0, true, true, true, "50%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case17")
    # synthetic_case17_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case17", "synthetic_case17_breakeven")
    # synthetic_case17_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case17", "synthetic_case17_npv_final")
    # synthetic_case17_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case17", "synthetic_case17_irr")
    # synthetic_case17_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case17", "synthetic_case17_construction_cost")
    # ##### Synthetic Case 16: Multi-modular, C2N, ITC 40%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month #####

    ##### Synthetic Case 18: Multi-modular, C2N, ITC 50%, PTC $33.0/MWh and Capacity Market of $25.0/kW-month #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 33.0, 10, 1.0, 1.0, 1.0, 1.0, 25.0, true, true, true, "50%", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/synthetic_case18")
    # synthetic_case18_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case18", "synthetic_case18_breakeven")
    # synthetic_case18_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case18", "synthetic_case18_npv_final")
    # synthetic_case18_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case18", "synthetic_case18_irr")
    # synthetic_case18_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case18", "synthetic_case18_construction_cost")
    ##### Synthetic Case 18: Multi-modular, C2N, ITC 50%, PTC $33.0/MWh and Capacity Market of $25.0/kW-month #####


    """
    After noticing that learning rates on purely construction are not enough, the next step is to consider learning rates on the FOM costs.
    Taking the first instance of effective learning construction cost of 65%, we see what reduction of FOM costs is needed to make the projects viable.
    """
    # ############### Synthetic Learning Rate ################

    ###### Synthetic Learning Rate 1: 65% construction cost reduction and 5% FOM cost reduction ######
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.4, 0.95, 1.0, 1.0, 0.0, true, true, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/syntheticll_case1")
    # syntheticll_case1_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case1", "syntheticll_case1_breakeven")
    # syntheticll_case1_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case1", "syntheticll_case1_npv_final")
    # syntheticll_case1_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case1", "syntheticll_case1_irr")
    # syntheticll_case1_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case1", "syntheticll_case1_construction_cost")
    ###### Synthetic Learning Rate 1: 5% construction cost reduction and 5% FOM cost reduction ######

    ###### Synthetic Learning Rate 2: 65% construction cost reduction and 10% FOM cost reduction ######
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.4, 0.90, 1.0, 1.0, 0.0, true, true, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/syntheticll_case2")
    # syntheticll_case2_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case2", "syntheticll_case2_breakeven")
    # syntheticll_case2_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case2", "syntheticll_case2_npv_final")
    # syntheticll_case2_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case2", "syntheticll_case2_irr")
    # syntheticll_case2_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case2", "syntheticll_case2_construction_cost")
    ###### Synthetic Learning Rate 2: 65% construction cost reduction and 10% FOM cost reduction ######

    ###### Synthetic Learning Rate 3: 65% construction cost reduction and 15% FOM cost reduction ######
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.4, 0.85, 1.0, 1.0, 0.0, true, true, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/syntheticll_case3")
    # syntheticll_case3_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case3", "syntheticll_case3_breakeven")
    # syntheticll_case3_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case3", "syntheticll_case3_npv_final")
    # syntheticll_case3_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case3", "syntheticll_case3_irr")
    # syntheticll_case3_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case3", "syntheticll_case3_construction_cost")
    ###### Synthetic Learning Rate 3: 65% construction cost reduction and 15% FOM cost reduction ######

    ###### Synthetic Learning Rate 4: 65% construction cost reduction and 20% FOM cost reduction ######
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.4, 0.80, 1.0, 1.0, 0.0, true, true, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/syntheticll_case4")
    # syntheticll_case4_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case4", "syntheticll_case4_breakeven")
    # syntheticll_case4_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case4", "syntheticll_case4_npv_final")
    # syntheticll_case4_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case4", "syntheticll_case4_irr")
    # syntheticll_case4_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case4", "syntheticll_case4_construction_cost")
    ###### Synthetic Learning Rate 4: 65% construction cost reduction and 20% FOM cost reduction ######

    ###### Synthetic Learning Rate 5: 65% construction cost reduction and 25% FOM cost reduction ######
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.4, 0.75, 1.0, 1.0, 0.0, true, true, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/syntheticll_case5")
    # syntheticll_case5_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case5", "syntheticll_case5_breakeven")
    # syntheticll_case5_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case5", "syntheticll_case5_npv_final")
    # syntheticll_case5_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case5", "syntheticll_case5_irr")
    # syntheticll_case5_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case5", "syntheticll_case5_construction_cost")
    ###### Synthetic Learning Rate 5: 65% construction cost reduction and 25% FOM cost reduction ######

    ###### Synthetic Learning Rate 6: 65% construction cost reduction and 30% FOM cost reduction ######
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.4, 0.70, 1.0, 1.0, 0.0, true, true, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/syntheticll_case6")
    # syntheticll_case6_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case6", "syntheticll_case6_breakeven")
    # syntheticll_case6_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case6", "syntheticll_case6_npv_final")
    # syntheticll_case6_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case6", "syntheticll_case6_irr")
    # syntheticll_case6_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case6", "syntheticll_case6_construction_cost")
    ###### Synthetic Learning Rate 6: 65% construction cost reduction and 30% FOM cost reduction ######

    ###### Synthetic Learning Rate 7: 65% construction cost reduction and 35% FOM cost reduction ######
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.4, 0.65, 1.0, 1.0, 0.0, true, true, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/syntheticll_case7")
    # syntheticll_case7_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case7", "syntheticll_case7_breakeven")
    # syntheticll_case7_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case7", "syntheticll_case7_npv_final")
    # syntheticll_case7_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case7", "syntheticll_case7_irr")
    # syntheticll_case7_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case7", "syntheticll_case7_construction_cost")
    ###### Synthetic Learning Rate 7: 65% construction cost reduction and 35% FOM cost reduction ######

    ###### Synthetic Learning Rate 8: 65% construction cost reduction and 40% FOM cost reduction ######
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.4, 0.60, 1.0, 1.0, 0.0, true, true, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/syntheticll_case8")
    # syntheticll_case8_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case8", "syntheticll_case8_breakeven")
    # syntheticll_case8_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case8", "syntheticll_case8_npv_final")
    # syntheticll_case8_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case8", "syntheticll_case8_irr")
    # syntheticll_case8_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case8", "syntheticll_case8_construction_cost")
    ###### Synthetic Learning Rate 8: 65% construction cost reduction and 40% FOM cost reduction ######

    ###### Synthetic Learning Rate 9: 65% construction cost reduction and 45% FOM cost reduction ######
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.4, 0.55, 1.0, 1.0, 0.0, true, true, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/syntheticll_case9")
    # syntheticll_case9_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case9", "syntheticll_case9_breakeven")
    # syntheticll_case9_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case9", "syntheticll_case9_npv_final")
    # syntheticll_case9_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case9", "syntheticll_case9_irr")
    # syntheticll_case9_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case9", "syntheticll_case9_construction_cost")
    ###### Synthetic Learning Rate 9: 65% construction cost reduction and 45% FOM cost reduction ######

    ###### Synthetic Learning Rate 10: 65% construction cost reduction and 50% FOM cost reduction ######
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.4, 0.50, 1.0, 1.0, 0.0, true, true, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/syntheticll_case10")
    # syntheticll_case10_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case10", "syntheticll_case10_breakeven")
    # syntheticll_case10_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case10", "syntheticll_case10_npv_final")
    # syntheticll_case10_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case10", "syntheticll_case10_irr")
    # syntheticll_case10_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case10", "syntheticll_case10_construction_cost")
    ###### Synthetic Learning Rate 10: 65% construction cost reduction and 50% FOM cost reduction ######

    ###### Synthetic Learning Rate 11: 65% construction cost reduction and 55% FOM cost reduction ######
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.4, 0.45, 1.0, 1.0, 0.0, true, true, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/syntheticll_case11")
    # syntheticll_case11_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case11", "syntheticll_case11_breakeven")
    # syntheticll_case11_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case11", "syntheticll_case11_npv_final")
    # syntheticll_case11_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case11", "syntheticll_case11_irr")
    # syntheticll_case11_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case11", "syntheticll_case11_construction_cost")
    ###### Synthetic Learning Rate 11: 65% construction cost reduction and 55% FOM cost reduction ######

    ###### Synthetic Learning Rate 12: 65% construction cost reduction and 60% FOM cost reduction ######
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_all_scenarios_iteration_three(0.04, 2024, 0, 0.1, 0.0, 10, 0.4, 0.40, 1.0, 1.0, 0.0, true, true, false, "", true, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/synthetic_cases/syntheticll_case12")
    # syntheticll_case12_breakeven = export_breakeven_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case12", "syntheticll_case12_breakeven")
    # syntheticll_case12_npv_final = export_breakeven_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case12", "syntheticll_case12_npv_final")
    # syntheticll_case12_irr = export_breakeven_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case12", "syntheticll_case12_irr")
    # syntheticll_case12_construction_cost_all = export_breakeven_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case12", "syntheticll_case12_construction_cost")
    ###### Synthetic Learning Rate 12: 65% construction cost reduction and 60% FOM cost reduction ######

    # ############### Synthetic Learning Rate ################

    # # println("NPV Final All: ", npv_final_all)
    # # println("NPV Tracker All: ", npv_tracker_all)
    # # println("NPV Payoff All: ", npv_payoff_all)
    # # println("Payouts All: ", length(payouts_all))
    # # println("Generation Output All: ", length(generationOutput_all))

    # ##### Baseline Analysis #####
end

function analysis_learning_rates()
    # ##### Learning Rates reducing construction and FOM costs by 5% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.95, 0.95, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_cambium23/ll5_5_baseline")
    # ll5_5_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll5_5_baseline", "ll5_5_breakeven")
    # ll5_5_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll5_5_baseline", "ll5_5_npv_final")
    # ll5_5_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll5_5_baseline", "ll5_5_irr")
    # ll5_5_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll5_5_baseline", "ll5_5_construction_cost")
    # ##### Learning Rates reducing construction and FOM costs by 5% #####

    # ##### Learning Rates reducing construction and FOM costs by 10% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.90, 0.90, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_cambium23/ll10_10_baseline")
    # ll10_10_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll10_10_baseline", "ll10_10_breakeven")
    # ll10_10_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll10_10_baseline", "ll10_10_npv_final")
    # ll10_10_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll10_10_baseline", "ll10_10_irr")
    # ll10_10_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll10_10_baseline", "ll10_10_construction_cost")
    # ##### Learning Rates reducing construction and FOM costs by 10% #####

    # ##### Learning Rates reducing construction and FOM costs by 15% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.85, 0.85, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_cambium23/ll15_15_baseline")
    # ll15_15_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll15_15_baseline", "ll15_15_breakeven")
    # ll15_15_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll15_15_baseline", "ll15_15_npv_final")
    # ll15_15_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll15_15_baseline", "ll15_15_irr")
    # ll15_15_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll15_15_baseline", "ll15_15_construction_cost")
    # ##### Learning Rates reducing construction and FOM costs by 15% #####

    # ##### Learning Rates reducing construction and FOM costs by 20% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.80, 0.80, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_cambium23/ll20_20_baseline")
    # ll20_20_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll20_20_baseline", "ll20_20_breakeven")
    # ll20_20_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll20_20_baseline", "ll20_20_npv_final")
    # ll20_20_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll20_20_baseline", "ll20_20_irr")
    # ll20_20_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll20_20_baseline", "ll20_20_construction_cost")
    # ##### Learning Rates reducing construction and FOM costs by 20% #####

    # ##### Learning Rates reducing construction and FOM costs by 25% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.75, 0.75, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_cambium23/ll25_25_baseline")
    # ll25_25_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll25_25_baseline", "ll25_25_breakeven")
    # ll25_25_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll25_25_baseline", "ll25_25_npv_final")
    # ll25_25_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll25_25_baseline", "ll25_25_irr")
    # ll25_25_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll25_25_baseline", "ll25_25_construction_cost")
    # ##### Learning Rates reducing construction and FOM costs by 25% #####

    # ##### Learning Rates reducing construction and FOM costs by 30% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.70, 0.70, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_cambium23/ll30_30_baseline")
    # ll30_30_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll30_30_baseline", "ll30_30_breakeven")
    # ll30_30_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll30_30_baseline", "ll30_30_npv_final")
    # ll30_30_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll30_30_baseline", "ll30_30_irr")
    # ll30_30_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll30_30_baseline", "ll30_30_construction_cost")
    # ##### Learning Rates reducing construction and FOM costs by 30% #####

    # ##### Learning Rates reducing construction and FOM costs by 35% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.65, 0.65, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_cambium23/ll35_35_baseline")
    # ll35_35_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll35_35_baseline", "ll35_35_breakeven")
    # ll35_35_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll35_35_baseline", "ll35_35_npv_final")
    # ll35_35_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll35_35_baseline", "ll35_35_irr")
    # ll35_35_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll35_35_baseline", "ll35_35_construction_cost")
    # ##### Learning Rates reducing construction and FOM costs by 35% #####

    # ##### Learning Rates reducing construction and FOM costs by 40% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.60, 0.60, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_cambium23/ll40_40_baseline")
    # ll40_40_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll40_40_baseline", "ll40_40_breakeven")
    # ll40_40_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll40_40_baseline", "ll40_40_npv_final")
    # ll40_40_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll40_40_baseline", "ll40_40_irr")
    # ll40_40_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll40_40_baseline", "ll40_40_construction_cost")
    # ##### Learning Rates reducing construction and FOM costs by 40% #####

    # ##### Learning Rates reducing construction and FOM costs by 45% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.55, 0.55, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_cambium23/ll45_45_baseline")
    # ll45_45_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll45_45_baseline", "ll45_45_breakeven")
    # ll45_45_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll45_45_baseline", "ll45_45_npv_final")
    # ll45_45_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll45_45_baseline", "ll45_45_irr")
    # ll45_45_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll45_45_baseline", "ll45_45_construction_cost")
    # ##### Learning Rates reducing construction and FOM costs by 45% #####

    # ##### Learning Rates reducing construction and FOM costs by 50% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.50, 0.50, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_cambium23/ll50_50_baseline")
    # ll50_50_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll50_50_baseline", "ll50_50_breakeven")
    # ll50_50_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll50_50_baseline", "ll50_50_npv_final")
    # ll50_50_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll50_50_baseline", "ll50_50_irr")
    # ll50_50_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll50_50_baseline", "ll50_50_construction_cost")
    # ##### Learning Rates reducing construction and FOM costs by 50% #####

    # ##### Learning Rates reducing construction and FOM costs by 55% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.45, 0.45, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_cambium23/ll55_55_baseline")
    # ll55_55_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll55_55_baseline", "ll55_55_breakeven")
    # ll55_55_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll55_55_baseline", "ll55_55_npv_final")
    # ll55_55_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll55_55_baseline", "ll55_55_irr")
    # ll55_55_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll55_55_baseline", "ll55_55_construction_cost")
    # ##### Learning Rates reducing construction and FOM costs by 55% #####

    # ##### Learning Rates reducing construction and FOM costs by 60% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.40, 0.40, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_cambium23/ll60_60_baseline")
    # ll60_60_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll60_60_baseline", "ll60_60_breakeven")
    # ll60_60_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll60_60_baseline", "ll60_60_npv_final")
    # ll60_60_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll60_60_baseline", "ll60_60_irr")
    # ll60_60_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll60_60_baseline", "ll60_60_construction_cost")
    # ##### Learning Rates reducing construction and FOM costs by 60% #####

    # ##### Learning Rates reducing construction and FOM costs by 65% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.35, 0.35, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_cambium23/ll65_65_baseline")
    # ll65_65_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll65_65_baseline", "ll65_65_breakeven")
    # ll65_65_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll65_65_baseline", "ll65_65_npv_final")
    # ll65_65_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll65_65_baseline", "ll65_65_irr")
    # ll65_65_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll65_65_baseline", "ll65_65_construction_cost")
    # ##### Learning Rates reducing construction and FOM costs by 65% #####

    # ##### Learning Rates reducing construction and FOM costs by 70% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.30, 0.30, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_cambium23/ll70_70_baseline")
    # ll70_70_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll70_70_baseline", "ll70_70_breakeven")
    # ll70_70_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll70_70_baseline", "ll70_70_npv_final")
    # ll70_70_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll70_70_baseline", "ll70_70_irr")
    # ll70_70_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll70_70_baseline", "ll70_70_construction_cost")
    # ##### Learning Rates reducing construction and FOM costs by 70% #####

    # ##### Learning Rates reducing construction and FOM costs by 75% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.25, 0.25, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_cambium23/ll75_75_baseline")
    # ll75_75_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll75_75_baseline", "ll75_75_breakeven")
    # ll75_75_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll75_75_baseline", "ll75_75_npv_final")
    # ll75_75_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll75_75_baseline", "ll75_75_irr")
    # ll75_75_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll75_75_baseline", "ll75_75_construction_cost")
    # ##### Learning Rates reducing construction and FOM costs by 75% #####

    # ##### Learning Rates reducing construction and FOM costs by 80% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.20, 0.20, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_cambium23/ll80_80_baseline")
    # ll80_80_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll80_80_baseline", "ll80_80_breakeven")
    # ll80_80_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll80_80_baseline", "ll80_80_npv_final")
    # ll80_80_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll80_80_baseline", "ll80_80_irr")
    # ll80_80_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll80_80_baseline", "ll80_80_construction_cost")
    # ##### Learning Rates reducing construction and FOM costs by 80% #####

    # ##### Learning Rates reducing construction and FOM costs by 85% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.15, 0.15, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_cambium23/ll85_85_baseline")
    # ll85_85_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll85_85_baseline", "ll85_85_breakeven")
    # ll85_85_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll85_85_baseline", "ll85_85_npv_final")
    # ll85_85_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll85_85_baseline", "ll85_85_irr")
    # ll85_85_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll85_85_baseline", "ll85_85_construction_cost")
    # ##### Learning Rates reducing construction and FOM costs by 85% #####

    # ##### Learning Rates reducing construction and FOM costs by 90% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.10, 0.10, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_cambium23/ll90_90_baseline")
    # ll90_90_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll90_90_baseline", "ll90_90_breakeven")
    # ll90_90_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll90_90_baseline", "ll90_90_npv_final")
    # ll90_90_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll90_90_baseline", "ll90_90_irr")
    # ll90_90_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll90_90_baseline", "ll90_90_construction_cost")
    # ##### Learning Rates reducing construction and FOM costs by 90% #####

    # ##### Learning Rates reducing construction and FOM costs by 95% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.05, 0.05, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_cambium23/ll95_95_baseline")
    # ll95_95_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll95_95_baseline", "ll95_95_breakeven")
    # ll95_95_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll95_95_baseline", "ll95_95_npv_final")
    # ll95_95_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll95_95_baseline", "ll95_95_irr")
    # ll95_95_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_cambium23/ll95_95_baseline", "ll95_95_construction_cost")
    # ##### Learning Rates reducing construction and FOM costs by 95% #####


    """
    BWRX-300 SMR Prototype - Learning Rate to reasoanble breakeven times
    """
    # ##### Learning Rates reducing construction costs by 85% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.15, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_to_reasonable/SMR/BWRX-300")
    # bwrx300_85_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_85_breakeven")
    # bwrx300_85_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_85_npv_final")
    # bwrx300_85_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_85_irr")
    # bwrx300_85_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_85_construction_cost")
    # ##### Learning Rates reducing construction costs by 85% #####

    # ##### Learning Rates reducing construction costs by 86% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.14, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_to_reasonable/SMR/BWRX-300")
    # bwrx300_86_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_86_breakeven")
    # bwrx300_86_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_86_npv_final")
    # bwrx300_86_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_86_irr")
    # bwrx300_86_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_86_construction_cost")
    # ##### Learning Rates reducing construction costs by 86% #####

    # ##### Learning Rates reducing construction costs by 87% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.13, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_to_reasonable/SMR/BWRX-300")
    # bwrx300_87_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_87_breakeven")
    # bwrx300_87_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_87_npv_final")
    # bwrx300_87_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_87_irr")
    # bwrx300_87_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_87_construction_cost")
    # ##### Learning Rates reducing construction costs by 87% #####

    # ##### Learning Rates reducing construction costs by 88% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.12, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_to_reasonable/SMR/BWRX-300")
    # bwrx300_88_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_88_breakeven")
    # bwrx300_88_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_88_npv_final")
    # bwrx300_88_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_88_irr")
    # bwrx300_88_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_88_construction_cost")
    # ##### Learning Rates reducing construction costs by 88% #####
    

    # ##### Learning Rates reducing construction costs by 90% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.10, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_to_reasonable/SMR/BWRX-300")
    # bwrx300_90_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_90_breakeven")
    # bwrx300_90_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_90_npv_final")
    # bwrx300_90_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_90_irr")
    # bwrx300_90_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_90_construction_cost")
    # ##### Learning Rates reducing construction costs by 90% #####

    # ##### Learning Rates reducing construction costs by 91% #####
    # payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all = analysis_npv_cambium23_scenario(0.04, 2024, 0, 0.1, 0.0, 10, 0.09, 1.0, 1.0, 1.0, 0.0, true, false, false, "", false, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cambium23_results/ll_to_reasonable/SMR/BWRX-300")
    # bwrx300_91_breakeven = export_cambium23_data_to_csv(break_even_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_91_breakeven")
    # bwrx300_91_npv_final = export_cambium23_data_to_csv(npv_final_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_91_npv_final")
    # bwrx300_91_irr = export_cambium23_data_to_csv(irr_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_91_irr")
    # bwrx300_91_construction_cost_all = export_cambium23_data_to_csv(construction_cost_all, "/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/ll_to_reasonable/SMR/BWRX-300", "bwrx300_91_construction_cost")
    # ##### Learning Rates reducing construction costs by 91% #####
end

"""
# Define initial learning rates [OCC, O&M, Fuel] with enhanced precision
initial_learning_rates = [0.9302115, 0.9002115, 0.9105115]
6%
30%
40%
50%
"""
function analysis_for_learning_rates(smr_prototype::String, is_favorable::Bool=true, breakeven_standard::Float64=20.0, 
    production_credit::Float64=0.0, capacity_market_rate::Float64=0.0, itc_case::String="", initial_learning_rates=[0.9302115, 0.9002115, 0.9105115], if_gradient::Bool=true)
    
    if if_gradient
        @time optimize_learning_rates_gradient(smr_prototype, production_credit, capacity_market_rate, breakeven_standard, is_favorable, itc_case, initial_learning_rates)
    else
        @time optimize_learning_rates(smr_prototype, production_credit, capacity_market_rate, breakeven_standard, is_favorable, itc_case, initial_learning_rates)
    end
    
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
    ##### Analysis 1 is a methodology test with just the cost of delay of 5 years plotted against standard time.
    for (index, cost_array) in enumerate(smr_cost_vals)
        # Create plots for all the SMRs
        if index < 20
            plot_construction_cost_distribution(0.1, Float64(cost_array[1]), Float64(cost_array[3]), Float64(cost_array[5]), Int(cost_array[6]), Int(ceil(cost_array[7]/12)), Int(ceil(cost_array[7]/12)) + 5, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cost_of_delay", String(smr_names[index]))
        else
            plot_construction_cost_distribution(0.1, Float64(cost_array[1]), Float64(cost_array[3]), Float64(cost_array[5]), Int(cost_array[7]), Int(ceil(cost_array[8]/12)), Int(ceil(cost_array[8]/12)) + 5, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/cost_of_delay", String(smr_names[index]))
        end
    end
end

"""
The following function analyses the NPV and break even for all SMRs for all Cambium 2023 scenarios. This method corrects 
dispatch methodology from the second iteration, and has space for running multiple cases for sensitivity
analyses. Baseline inputs are defined by default, and the user can change the inputs as needed.
"""
function analysis_npv_cambium23_scenario(interest_rate::Float64=0.04, construction_start::Int=2024, construction_delay::Int=0, construction_interest_rate::Float64=0.04, 
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


        # Calculating the lead time
        start_reactor = Int(ceil(((construction_start - 2024)*12 + construction_duration + (construction_delay*12))/12))

        ### Curating the scenarios to run the SMRs through ###        

        # Texas, DE-LU and Cambium 2022 Data
        for (index3, scenario) in enumerate(scenario_data_all)
            if index3 == 1 || index3 == 2 || index3 == 3
                push!(scenario_price_data_all, create_scenario_interpolated_array_cambium2022(scenario, scenario, scenario, scenario, scenario, scenario, scenario, scenario, (smr_lifetime + start_reactor)))

                continue
            end
            
            # If the length of the temporary array is 8, then push it into the main array
            if length(scenario_price_data_temp) == 8
                push!(scenario_price_data_all, create_scenario_interpolated_array_cambium2022(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (smr_lifetime + start_reactor)))
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                # Otherwise, add to the array and continue
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end

        # Pushing the last scenario into the array
        push!(scenario_price_data_all, create_scenario_interpolated_array_cambium2022(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (smr_lifetime + start_reactor)))
        empty!(scenario_price_data_temp)

        # Cambium 2023 Data
        for (index4, scenario) in enumerate(scenario_23_data_all)
            if length(scenario_price_data_temp) == 6
                push!(scenario_price_data_all, create_scenario_interpolated_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], (smr_lifetime + start_reactor)))
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end

        # Pushing the last scenario
        push!(scenario_price_data_all, create_scenario_interpolated_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], (smr_lifetime + start_reactor)))
        ### Curating the scenarios to run the SMRs through ###


        ### Adjusting the OCC and O&M costs for the ATB data ###
        if toIncludeATBcost
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

        if c2n_cost_advantages
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
            payout_run, generation_run = smr_dispatch_iteration_three(scenario_array, Float64(module_size), numberof_modules, fuel_cost, vom_cost, fom_cost, production_credit, start_reactor, production_duration, refueling_max_time, refueling_min_time, smr_lifetime)
            payout_run = capacity_market_analysis(capacity_market_rate, payout_run, numberof_modules, module_size)
            irr_run = calculate_irr(payout_run, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), construction_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))))
            npv_tracker_run, break_even_run, npv_payoff_run = npv_calc_scenario(payout_run, interest_rate_wacc, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), construction_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))), (smr_lifetime + start_reactor))
            

            # Pushing in all the calculated values
            push!(construction_cost_all, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), construction_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))))
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
            plot_bar_and_box_pycall(combined_scenario_names, breakevenvals_array, scenario_prototype_array, "Break Even [Years]", "Electricity Prices [\$/MWh]", "Scenarios Run", "$(smr_names[index]) Break Even", pathname)
            plot_bar_and_box_pycall(combined_scenario_names, npv_prototype_array, scenario_prototype_array, "NPV [\$]", "Electricity Prices [\$/MWh]", "Scenarios Run", "$(smr_names[index]) NPV", pathname)
            plot_bar_and_box_pycall(combined_scenario_names, irr_prototype_array, scenario_prototype_array, "IRR", "Electricity Prices [\$/MWh]", "Scenarios Run", "$(smr_names[index]) IRR", pathname)
        end
    end

    ### Running each SMR through each scenario ###


    return payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all
end

"""
The following function analyses the NPV and break even for all SMRs for all of what we would consider future scenarios. This method corrects 
dispatch methodology from the second iteration, and has space for running multiple cases for sensitivity
analyses. Baseline inputs are defined by default, and the user can change the inputs as needed.
"""
function analysis_npv_future_prices(interest_rate::Float64=0.04, construction_start::Int=2024, construction_delay::Int=0, construction_interest_rate::Float64=0.04, 
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

        # Calculating the lead time
        start_reactor = Int(ceil(((construction_start - 2024)*12 + construction_duration + (construction_delay*12))/12))

        ### Curating the scenarios to run the SMRs through ###
        index_to_consider = 0        

        # Texas, DE-LU and Cambium 2022 Data
        for (index3, scenario) in enumerate(scenario_data_all)
            if index3 == 1 || index3 == 2 || index3 == 3
                continue
            end
            
            # If the length of the temporary array is 8, then push it into the main array
            if length(scenario_price_data_temp) == 8
                if index_to_consider == 0 || index_to_consider == 5
                    push!(scenario_price_data_all, create_scenario_interpolated_array_cambium2022(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (smr_lifetime + start_reactor)))
                    empty!(scenario_price_data_temp)
                    push!(scenario_price_data_temp, scenario)
                    index_to_consider += 1
                else
                    index_to_consider += 1
                    empty!(scenario_price_data_temp)
                    continue
                end
                
            else
                # Otherwise, add to the array and continue
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end

        # Pushing the last scenario into the array
        empty!(scenario_price_data_temp)

        # Cambium 2023 Data
        for (index4, scenario) in enumerate(scenario_23_data_all)
            if length(scenario_price_data_temp) == 6
                push!(scenario_price_data_all, create_scenario_interpolated_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], (smr_lifetime + start_reactor)))
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end

        # Pushing the last scenario
        push!(scenario_price_data_all, create_scenario_interpolated_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], (smr_lifetime + start_reactor)))
        ### Curating the scenarios to run the SMRs through ###


        ### Adjusting the OCC and O&M costs for the ATB data ###
        if toIncludeATBcost
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

        if c2n_cost_advantages
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
            payout_run, generation_run = smr_dispatch_iteration_three(scenario_array, Float64(module_size), numberof_modules, fuel_cost, vom_cost, fom_cost, production_credit, start_reactor, production_duration, refueling_max_time, refueling_min_time, smr_lifetime)
            payout_run = capacity_market_analysis(capacity_market_rate, payout_run, numberof_modules, module_size)
            irr_run = calculate_irr(payout_run, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), construction_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))))
            npv_tracker_run, break_even_run, npv_payoff_run = npv_calc_scenario(payout_run, interest_rate_wacc, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), construction_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))), (smr_lifetime + start_reactor))
            

            # Pushing in all the calculated values
            push!(construction_cost_all, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), construction_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))))
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
            plot_bar_and_box_pycall(future_scenario_names, breakevenvals_array, scenario_prototype_array, "Break Even [Years]", "Electricity Prices [\$/MWh]", "Scenarios Run", "$(smr_names[index]) Break Even", pathname)
            plot_bar_and_box_pycall(future_scenario_names, npv_prototype_array, scenario_prototype_array, "NPV [\$]", "Electricity Prices [\$/MWh]", "Scenarios Run", "$(smr_names[index]) NPV", pathname)
            plot_bar_and_box_pycall(future_scenario_names, irr_prototype_array, scenario_prototype_array, "IRR", "Electricity Prices [\$/MWh]", "Scenarios Run", "$(smr_names[index]) IRR", pathname)
        end
    end

    ### Running each SMR through each scenario ###


    return payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all
end

"""
The following function analyses the NPV and break even for all SMRs for all of what we would consider future scenarios. This method corrects 
dispatch methodology from the second iteration, and has space for running multiple cases for sensitivity
analyses. Baseline inputs are defined by default, and the user can change the inputs as needed.
"""
function analysis_npv_historical_prices(interest_rate::Float64=0.04, construction_start::Int=2024, construction_delay::Int=0, construction_interest_rate::Float64=0.04, 
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

        # Calculating the lead time
        start_reactor = Int(ceil(((construction_start - 2024)*12 + construction_duration + (construction_delay*12))/12))

        ### Curating the scenarios to run the SMRs through ###
        for (index4, scenario) in enumerate(historical_prices_array)
            push!(scenario_price_data_all, create_historical_scenario(scenario, (smr_lifetime + start_reactor)))
        end
        ### Curating the scenarios to run the SMRs through ###


        ### Adjusting the OCC and O&M costs for the ATB data ###
        if toIncludeATBcost
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

        if c2n_cost_advantages
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
            payout_run, generation_run = smr_dispatch_iteration_three(scenario_array, Float64(module_size), numberof_modules, fuel_cost, vom_cost, fom_cost, production_credit, start_reactor, production_duration, refueling_max_time, refueling_min_time, smr_lifetime)
            payout_run = capacity_market_analysis(capacity_market_rate, payout_run, numberof_modules, module_size)
            irr_run = calculate_irr(payout_run, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), construction_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))))
            npv_tracker_run, break_even_run, npv_payoff_run = npv_calc_scenario(payout_run, interest_rate_wacc, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), construction_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))), (smr_lifetime + start_reactor))
            

            # Pushing in all the calculated values
            push!(construction_cost_all, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), construction_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))))
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
            plot_bar_and_box_pycall(historical_scenario_names, breakevenvals_array, scenario_prototype_array, "Break Even [Years]", "Electricity Prices [\$/MWh]", "Scenarios Run", "$(smr_names[index]) Break Even", pathname)
            plot_bar_and_box_pycall(historical_scenario_names, npv_prototype_array, scenario_prototype_array, "NPV [\$]", "Electricity Prices [\$/MWh]", "Scenarios Run", "$(smr_names[index]) NPV", pathname)
            plot_bar_and_box_pycall(historical_scenario_names, irr_prototype_array, scenario_prototype_array, "IRR", "Electricity Prices [\$/MWh]", "Scenarios Run", "$(smr_names[index]) IRR", pathname)
        end
    end

    ### Running each SMR through each scenario ###


    return payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all
end

"""
The following function analyses the NPV and break even for the AP1000 for all Cambium 2023 and 2022 scenarios. Baseline 
inputs are defined by default, and the user can change the inputs as needed.
"""
function analysis_npv_ap1000_scenarios(interest_rate::Float64=0.04, construction_start::Int=2024, construction_delay::Int=0, construction_interest_rate::Float64=0.04, 
    production_credit::Float64=0.0, production_duration::Int=10, construction_cost_reduction_factor::Float64=1.0, fom_cost_reduction_factor::Float64=1.0, 
    vom_cost_reduction_factor::Float64=1.0, fuel_cost_reduction_factor::Float64=1.0, capacity_market_rate::Float64=0.0, toPlot::Bool=false, 
    toIncludeITC::Bool=false, itc_case::String="", c2n_cost_advantages::Bool=false, analysis_pathname::String="")
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
    for (index, cost_array) in enumerate(ap1000_cost_vals)
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

        # Calculating the lead time
        start_reactor = Int(ceil(((construction_start - 2024)*12 + construction_duration + (construction_delay*12))/12))

        ### Curating the scenarios to run the SMRs through ###        

        for (index3, scenario) in enumerate(scenario_data_all)
            if index3 == 1 || index3 == 2 || index3 == 3
                push!(scenario_price_data_all, create_scenario_interpolated_array_cambium2022(scenario, scenario, scenario, scenario, scenario, scenario, scenario, scenario, (smr_lifetime + start_reactor)))

                continue
            end
            
            # If the length of the temporary array is 8, then push it into the main array
            if length(scenario_price_data_temp) == 8
                push!(scenario_price_data_all, create_scenario_interpolated_array_cambium2022(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (smr_lifetime + start_reactor)))
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                # Otherwise, add to the array and continue
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end

        # Pushing the last scenario into the array
        push!(scenario_price_data_all, create_scenario_interpolated_array_cambium2022(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (smr_lifetime + start_reactor)))
        empty!(scenario_price_data_temp)

        for (index4, scenario) in enumerate(scenario_23_data_all)
            if length(scenario_price_data_temp) == 6
                push!(scenario_price_data_all, create_scenario_interpolated_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], (smr_lifetime + start_reactor)))
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end

        # Pushing the last scenario
        push!(scenario_price_data_all, create_scenario_interpolated_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], (smr_lifetime + start_reactor)))
        empty!(scenario_price_data_temp)



        ### Curating the scenarios to run the SMRs through ###


        ### Adjusting the OCC and O&M costs for the ATB data ###

        if c2n_cost_advantages
            # If the ATB Reactors
            if scenario == "Advanced"
                # Adjusting the O&M costs
                vom_cost = vom_cost * c2n_cost_reduction_lr[c2n_cost_reduction_lr.Category .== "Variable O&M", :Advanced][1]
                fom_cost = fom_cost * c2n_cost_reduction_lr[c2n_cost_reduction_lr.Category .== "Fixed O&M", :Advanced][1]
                construction_cost = construction_cost * c2n_cost_reduction_lr[c2n_cost_reduction_lr.Category .== "OCC 2030", :Advanced][1]
                fuel_cost = fuel_cost * c2n_cost_reduction_lr[c2n_cost_reduction_lr.Category .== "Fuel Cost", :Advanced][1]
            elseif scenario == "Moderate"
                # Adjusting the O&M and capital costs
                vom_cost = vom_cost * c2n_cost_reduction_lr[c2n_cost_reduction_lr.Category .== "Variable O&M", :Moderate][1]
                fom_cost = fom_cost * c2n_cost_reduction_lr[c2n_cost_reduction_lr.Category .== "Fixed O&M", :Moderate][1]
                construction_cost = construction_cost * c2n_cost_reduction_lr[c2n_cost_reduction_lr.Category .== "OCC 2030", :Moderate][1]
                fuel_cost = fuel_cost * c2n_cost_reduction_lr[c2n_cost_reduction_lr.Category .== "Fuel Cost", :Moderate][1]
            elseif scenario == "Conservative"
                # Adjusting the O&M and capital costs
                vom_cost = vom_cost * c2n_cost_reduction_lr[c2n_cost_reduction_lr.Category .== "Variable O&M", :Conservative][1]
                fom_cost = fom_cost * c2n_cost_reduction_lr[c2n_cost_reduction_lr.Category .== "Fixed O&M", :Conservative][1]
                construction_cost = construction_cost * c2n_cost_reduction_lr[c2n_cost_reduction_lr.Category .== "OCC 2030", :Conservative][1]
                fuel_cost = fuel_cost * c2n_cost_reduction_lr[c2n_cost_reduction_lr.Category .== "Fuel Cost", :Conservative][1]
            end
        end

        if toIncludeITC
            if scenario == "Advanced"
                # Adjusting the construction costs
                construction_cost = construction_cost * itc_cost_reduction_lr[itc_cost_reduction_lr.Category .== itc_case, :Advanced][1]
            elseif scenario == "Moderate"
                # Adjusting the construction costs
                construction_cost = construction_cost * itc_cost_reduction_lr[itc_cost_reduction_lr.Category .== itc_case, :Moderate][1]
            elseif scenario == "Conservative"
                # Adjusting the construction costs
                construction_cost = construction_cost * itc_cost_reduction_lr[itc_cost_reduction_lr.Category .== itc_case, :Conservative][1]
            end
        end

        ### Adjusting the OCC and O&M costs for the ATB data ###


        ### Running each SMR through each scenario ###

        for (index2, scenario_array) in enumerate(scenario_price_data_all)
            # If it's the ATB reactors, run the ATB reactor code
            payout_run, generation_run = ap1000_dispatch_iteration_one(scenario_array, module_size, numberof_modules, fuel_cost, vom_cost, fom_cost, production_credit, start_reactor, production_duration, refueling_max_time, refueling_min_time, smr_lifetime)
            # If there is a capacity market rate, run the capacity market analysis
            payout_run = capacity_market_analysis(capacity_market_rate, payout_run, numberof_modules, module_size)
            irr_run = calculate_irr(payout_run, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), construction_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))))
            npv_tracker_run, break_even_run, npv_payoff_run = npv_calc_scenario(payout_run, interest_rate_wacc, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), construction_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))), (smr_lifetime + start_reactor))
            push!(construction_cost_all, calculate_total_investment_with_cost_of_delay(construction_interest_rate, Float64(module_size), construction_cost, numberof_modules, Int(ceil(construction_duration/12)), Int(ceil((construction_duration+(construction_delay*12))/12))))

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
            plot_bar_and_box_pycall(combined_scenario_names, breakevenvals_array, scenario_prototype_array, "Break Even [Years]", "Electricity Prices [\$/MWh]", "Scenarios Run", "$(ap1000_scenario_names[index]) Break Even", pathname)
            plot_bar_and_box_pycall(combined_scenario_names, npv_prototype_array, scenario_prototype_array, "NPV [\$]", "Electricity Prices [\$/MWh]", "Scenarios Run", "$(ap1000_scenario_names[index]) NPV", pathname)
            plot_bar_and_box_pycall(combined_scenario_names, irr_prototype_array, scenario_prototype_array, "IRR", "Electricity Prices [\$/MWh]", "Scenarios Run", "$(ap1000_scenario_names[index]) IRR", pathname)
        end
    end

    ### Running each SMR through each scenario ###


    return payouts_all, generationOutput_all, npv_tracker_all, npv_payoff_all, npv_final_all, irr_all, break_even_all, construction_cost_all
end

"""
The following function plots all construction cost vs. breakeven times for the scenarios ran and returns a heatmap
"""
function analysis_construction_cost_vs_breakeven()
    # Importing the results data
    @info("Bringing in results data for processing and plotting")
    include("result_data.jl")
    # Processing data for the AP1000
    capacity_market_prices, avg_scenario_prices, breakeven_values = process_smr_scenario_cm_data_to_array(get_ap1000_scenario_prices(), get_ap1000_cm_data())
    capacity_market_prices, avg_scenario_prices, breakeven_values = sort_heatmap_data(capacity_market_prices, avg_scenario_prices, breakeven_values)

    # Plotting the data
    create_heatmap(capacity_market_prices, avg_scenario_prices, breakeven_values,
                    x_label="Capacity Market Price [\$/kW-month]", 
                    y_label="Average Electricity Price [\$/MWh]", 
                    title="AP1000",
                    output_file="/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/heatmaps/overall/ap1000_breakeven_heatmap.png")

    # Processing data for the SMR
    capacity_market_prices, avg_scenario_prices, breakeven_values = process_smr_scenario_cm_data_to_array(get_all_scenario_prices_smr(), get_smr_cm_data())
    capacity_market_prices, avg_scenario_prices, breakeven_values = sort_heatmap_data(capacity_market_prices, avg_scenario_prices, breakeven_values)

    # Plotting the data
    create_heatmap(capacity_market_prices, avg_scenario_prices, breakeven_values,
                    x_label="Capacity Market Price [\$/kW-month]", 
                    y_label="Average Electricity Price [\$/MWh]", 
                    title="Small Modular Reactors",
                    output_file="/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/heatmaps/overall/smr_breakeven_heatmap.png")
    
    
    # Processing data for the SMR's
    capacity_market_prices, avg_scenario_prices, breakeven_values = process_smr_scenario_cm_data_multiple_arrays(get_all_scenario_prices_smr(), get_smr_cm_data(), smr_names)
    create_panel_of_heatmaps(capacity_market_prices, avg_scenario_prices, breakeven_values,
        x_label="Capacity Market Price [\$/kW-month]", y_label="Average Scenario Price [\$/MWh]",
        output_dir="/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/heatmaps/smr")
    
    # Processing data for the AP1000
    capacity_market_prices_ap1000, avg_scenario_prices_ap1000, breakeven_values_ap1000 = process_smr_scenario_cm_data_multiple_arrays(get_ap1000_scenario_prices(), get_ap1000_cm_data(), ap1000_scenario_names)
    create_panel_of_heatmaps(capacity_market_prices_ap1000, avg_scenario_prices_ap1000, breakeven_values_ap1000,
        x_label="Capacity Market Price [\$/kW-month]", y_label="Average Scenario Price [\$/MWh]",
        output_dir="/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/heatmaps/ap1000")
end

"""
The following function analyses interesting the 
"""
function analysis_time_slice()
    dispatch_df_normal_smr = get_dispatch_df_normal_smr()
    payoff_df_normal_smr = get_payoff_df_normal_smr()

    dispatch_df_lpo0_smr = get_dispatch_df_lpo0_smr()
    payoff_df_lpo0_smr = get_payoff_df_lpo0_smr()

    price_array = get_all_scenario_prices_smr()[findfirst(d -> d["smr"] == "NuScale" && d["scenario"] == "23 Cambium High NG Prices", get_all_scenario_prices_smr())]["data"]

    # Finding the index of NuScale in smr_names
    nuscale_index = findfirst(smr -> smr == "NuScale", smr_names)

    # Extracting the cost values for NuScale
    nuscale_cost_vals = smr_cost_vals[nuscale_index]

    # Extracting the module size
    module_size = Float64(nuscale_cost_vals[1])

    # Extracting the number of modules
    numberof_modules = Int(nuscale_cost_vals[7])

    # Extracting the fuel price
    fuel_cost = nuscale_cost_vals[4]

    # Extract the specific column from the DataFrame
    nuscale_column = "NuScale-23 Cambium High NG Prices"

    # Extracting the week of data where the prices are mixed and ramping occurs
    significant_dispatch_df1, significant_dispatch_df2, significant_payout_df1, significant_payout_df2, significant_prices1, significant_prices2 = find_first_common_week_with_mixed_prices_and_ramping(dispatch_df_normal_smr, dispatch_df_lpo0_smr, payoff_df_normal_smr, payoff_df_lpo0_smr, price_array, price_array, module_size, numberof_modules, nuscale_column)

    # Output directory
    output_dir = "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/time_slice"
    
    # Plotting the data
    panel_plot_with_price_overlay_PyCall(significant_dispatch_df1, significant_dispatch_df2, significant_payout_df1, significant_payout_df2, significant_prices1, significant_prices2, nuscale_column, fuel_cost, output_dir)
end

"""
The following analysis creates a boxplot of the breakeven times distributions for the SMR's with
Energy and Capacity Market Revenues
"""
function analysis_cm_breakeven_boxplot()
    # Example of how to use the function
    baseline_df = CSV.read("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/baseline_cambium23/cambium23_baseline_breakeven.csv", DataFrame)

    # Example usage:
    cm_data = extract_smr_cm_data([5.0, 15.0, 25.0])

    # Call the function with your data and directory path
    create_smr_breakeven_boxplot(baseline_df, cm_data, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/energy_capacity_box_whisker")
end

# analysis_time_slice()

function analysis_lpo0()
    # Plotting the LPO0 vs the baseline data
end

"""
The following analysis builds the panel heatmap plots for the SMR's with Energy and Capacity Market Revenues
"""
function analysis_cm_energy_breakeven_smr_heatmap()
    # Uncomment this line and place your intended output directory to build the heatmap data
    # calculate_smr_heatmap_data("put your output directory here")

    # Call the function to get smr_data
    smr_data = get_heatmap_smr_data()

    # Reverse DataFrames and convert them to matrices
    smr_data_reversed = [
        Dict("SMR" => d["SMR"], "Data" => load_and_reverse_df(d["Data"])) for d in smr_data
    ]
    
    # Plot the heatmap
    # Average price used for LMP ERCOT in 2020 is $25.73, Average price for LMP ERCOT in 2023 is $65.13
    # Source: https://www.potomaceconomics.com/wp-content/uploads/2024/05/2023-State-of-the-Market-Report_Final.pdf
    plot_heatmap_panel_with_unified_legend_smr(smr_data_reversed, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/heatmaps/smr")

    # If you want to plot heatmaps for the construction overrun SMR's
    smr_overrun_data = get_heatmap_smr_cost_overrun_data()

    # Reverse DataFrames and convert them to matrices
    smr_overrun_data_reversed = [
        Dict("SMR" => d["SMR"], "Data" => load_and_reverse_df(d["Data"])) for d in smr_overrun_data
    ]

    # Plot the heatmap
    plot_heatmap_panel_with_unified_legend_smr(smr_overrun_data_reversed, "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/heatmaps/cost_overrun")
end

"""
The following analysis builds the panel heatmap plots for the AP1000's with Energy and Capacity Market Revenues
"""
function analysis_cm_energy_breakeven_ap1000_heatmap()
    # Uncomment this line and place your intended output directory to build the heatmap data
    # calculate_ap1000_heatmap_data("put your output directory here")

    # Call the function to get ap1000_data
    ap1000_data = get_heatmap_ap1000_data()

    # Reverse DataFrames and convert them to matrices
    ap1000_data_reversed = [
        Dict("AP1000" => d["AP1000"], "Data" => load_and_reverse_df(d["Data"])) for d in ap1000_data
    ]


    # Plot the heatmap
    # Average price used for LMP ERCOT in 2020 is $25.73, Average price for LMP ERCOT in 2023 is $65.13
    # Source: https://www.potomaceconomics.com/wp-content/uploads/2024/05/2023-State-of-the-Market-Report_Final.pdf
    plot_heatmap_panel_with_unified_legend_ap1000(ap1000_data_reversed,"/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/heatmaps/ap1000")
end

"""
This function is for analysis of the input data of the cost simulations
"""
function analysis_input_data()
    # Bringing in the investment cost data for all SMR's
    smr_investment_cost_array = Vector{Float64}(undef, 0)

    # Pulling in the investment cost then converting to $/kWe for all SMR's
    for (index, cost_array) in enumerate(smr_cost_vals)
        push!(smr_investment_cost_array, (Float64(cost_array[3])/1000.0))
    end

    # Saving the data as a histogram
    save_density_plot(smr_investment_cost_array, "SMR Investment Cost [\$/kWe]", "SMR Investment Cost Histogram", "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/input_data_distribution/investment_cost_distribution")

    # Bringing the investment cost data for all AP1000's
    ap1000_investment_cost_array = Vector{Float64}(undef, 0)

    # Pulling in the investment cost then converting to $/kWe for all AP1000's
    for (index, cost_array) in enumerate(ap1000_cost_vals)
        push!(ap1000_investment_cost_array, (Float64(cost_array[3])/1000.0))
    end

    # Saving the data as a histogram
    save_density_plot(ap1000_investment_cost_array, "AP1000 Investment Cost [\$/kWe]", "AP1000 Investment Cost Histogram", "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/input_data_distribution/investment_cost_distribution")

    # Doing the same for fuel costs
    smr_fuel_cost_array = Vector{Float64}(undef, 0)

    # Pulling in the fuel cost SMR's
    for (index, cost_array) in enumerate(smr_cost_vals)
        push!(smr_fuel_cost_array, Float64(cost_array[4]))
    end

    # Saving the data as a histogram
    save_density_plot(smr_fuel_cost_array, "SMR Fuel Cost [\$/MWh]", "SMR Fuel Cost Histogram", "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/input_data_distribution/fuel_cost_distribution")

    # AP1000 fuel costs
    ap1000_fuel_cost_array = Vector{Float64}(undef, 0)

    # Pulling in the fuel cost AP1000's
    for (index, cost_array) in enumerate(ap1000_cost_vals)
        push!(ap1000_fuel_cost_array, Float64(cost_array[4]))
    end

    # Saving the data as a histogram
    save_density_plot(ap1000_fuel_cost_array, "AP1000 Fuel Cost [\$/MWh]", "AP1000 Fuel Cost Histogram", "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/input_data_distribution/fuel_cost_distribution")

    # Doing the same for the fixed O&M costs
    smr_fom_cost_array = Vector{Float64}(undef, 0)

    # Pulling in the fixed O&M cost SMR's
    for (index, cost_array) in enumerate(smr_cost_vals)
        if index < 20
            push!(smr_fom_cost_array, Float64(cost_array[5]))
        else
            push!(smr_fom_cost_array, (Float64(cost_array[6])*Float64(cost_array[2])))
        end
    end

    # Saving the data as a histogram
    save_density_plot(smr_fom_cost_array, "SMR Fixed O&M Cost [\$/MWh]", "SMR Fixed O&M Cost Histogram", "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/input_data_distribution/om_cost_distribution")

    # AP1000 fixed O&M costs
    ap1000_fom_cost_array = Vector{Float64}(undef, 0)

    # Pulling in the fixed O&M cost AP1000's
    for (index, cost_array) in enumerate(ap1000_cost_vals)
        push!(ap1000_fom_cost_array, (Float64(cost_array[5])*Float64(cost_array[2])))
    end

    # Saving the data as a histogram
    save_density_plot(ap1000_fom_cost_array, "AP1000 Fixed O&M Cost [\$/MWh]", "AP1000 Fixed O&M Cost Histogram", "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/input_data_distribution/om_cost_distribution")
end