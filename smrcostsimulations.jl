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
    # Naming the plot to


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
function analysis_npv_all_scenarios_iteration_two()
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

   ### Creating the organized array of price data of all scenarios ###

   # Creating an empty array to store price date of all scenarios
   scenario_price_data_all = []

   # Creating a temporary array to store the price data of each scenario
   scenario_price_data_temp = []

   # For loop to creating the organized array of price data of all scenarios
   for (index, scenario_array) in enumerate(scenario_data_all)

    # For Texas and Gernamy, the price data is in the first three indices
      if index == 1 || index == 2 || index == 3
            # Pushing in the price data for the first three scenarios
            push!(scenario_price_data_all, scenario_array)
            continue
      end

      # Now, create the combined scenarios for each Cambium scenario
      push!(scenario_price_data_temp, scenario_array)

      # If the length of the temporary array is 8, then push it into the main array
      if length(scenario_price_data_temp) == 8
        push!(scenario_price_data_all, create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8]))
        empty!(scenario_price_data_temp)
      end

   end
   ### Creating the organized array of price data of all scenarios ###
 
   ### Running each SMR through each scenario ###
   ### Running each SMR through each scenario ###

    end