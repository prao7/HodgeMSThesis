using HTTP
using CSV
using DataFrames
using Statistics
using Plots
using StatsPlots
using PyCall
using RCall
using FilePathsBase
using Dates
using Interpolations

"""
This function is to convert sharing links from OneDrive to a download link. The download link is required in 
order to download CSV files from OneDrive to convert to DataFrames
@input sharepoint_url: The URL that you pull from 
"""
function sharepoint_to_download_link(sharepoint_url)
    # Check if the URL is a SharePoint share link
    if !contains(sharepoint_url, "sharepoint.com")
        error("Invalid SharePoint share link.")
    end
    
    # Extract the file identifier from the URL
    parts = split(sharepoint_url, "/")
    file_id = last(parts)
    
    if file_id !== nothing
        return "https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/$file_id?download=1"
    else
        error("Unable to extract file identifier from the SharePoint share link.")
    end
end

"""
The following function is for cleaning the data from Texas to convert from 15 minutes to an array for just 
simulating timesteps.
"""
function fifteen_minutes_to_hourly(df::DataFrame, column_name::AbstractString, group_size::Int)
    # Convert the column name to a symbol
    symbol_name = Symbol(column_name)

    # Check if the column exists in the DataFrame
    if !hasproperty(df, symbol_name)
        error("Column '$(column_name)' does not exist in the DataFrame.")
    end

    # Extract the column as an array
    column_values = df[!, symbol_name]

    # Initialize an array to store the averages
    averages = Float64[]

    # Iterate through the column in groups of group_size
    for i in 1:group_size:length(column_values)
        # Take a slice of the column for the current group
        group_slice = column_values[i:min(end, i + group_size - 1)]

        # Calculate the average and push it to the averages array
        push!(averages, mean(group_slice))
    end

    return averages
end

"""
The following function is for extracting an array out of a column in a DataFrame
"""
function array_from_dataframe(df::DataFrame, column_name::AbstractString)
    # Converting the column to a symbol
    symbol_name = Symbol(column_name)

    # Check if the column exists in the DataFrame
    if !hasproperty(df, symbol_name)
        error("Column '$(column_name)' does not exist in the DataFrame.")
    end

    # Extract the column as an array
    return df[!, symbol_name]
end

"""
The following function is for extracting an array out of a row in a DataFrame
"""
function extract_columns_from_third_to_end(df::DataFrame)
    # Get the number of columns in the DataFrame
    num_columns = ncol(df)

    # Initialize an array to store the result
    result_arrays = Vector{Vector{Any}}(undef, nrow(df))

    # Iterate over each row
    for row_index in 1:nrow(df)
        # Extract values from column 3 to the end for the current row
        row_values = df[row_index, 3:end]
        
        # Store the values in the result array
        result_arrays[row_index] = Vector(row_values)
    end

    return result_arrays
end

"""
The following function returns a DataFrame from a URL
"""
function df_from_url(sharepoint_url)
    # First, create a download URL from the sharepoint URL
    download_url = sharepoint_to_download_link(sharepoint_url)

    # Next, import the data from the link into the DataFrame and return it
    return CSV.File(download(download_url)) |> DataFrame
end

"""
The following function takes a DataFrame and returns an array after converting 
prices from Euros/MWh to Dollars/MWh.
"""
function array_from_dataframe_converttoeuro(df::DataFrame, target_name::AbstractString)
    # Extracting the array from the DataFrame
    array_to_convert = array_from_dataframe(df, target_name)

    # Looping through the array to convert each value to $/MWh
    for (index, value) in enumerate(array_to_convert)
        # 1.0032 is the Euro to Dollar conversion rate
        # Source: https://tradingeconomics.com/euro-area/currency
        array_to_convert[index] = value*1.10032
    end

    # Returning the array after it's been converted
    return array_to_convert
end

"""
The following function takes inputs of names and values to create a bar chart. 
DEFUNCT Function
"""
function display_bar_chart(categories, values, chart_title, x_label, y_label, plot_name, directory_path)
    plotly()  # Set the plotly backend

    # Create a bar chart with the specified title, x-axis label, and y-axis label
    p = bar(categories, values, label="Values", title=chart_title, xlabel=x_label, ylabel=y_label, xrotation=45, xtickfont=10)
    
    # Specify the directory and create it if it doesn't exist
    isdir(directory_path) || mkdir(directory_path)

    # Save the plot as a PNG image
    savefig(p, joinpath(directory_path, plot_name))
end

"""
The following function uses Python funcationality to create a boxplot and bar chart on the same plot
DEFUNCT Function
"""
function plot_bar_and_box(categories, bar_values, box_values, chart_title, x_label, y_label, box_label, plot_name, directory_path)
    # Import necessary Python modules
    plt = pyimport("matplotlib.pyplot")

    # Create a figure and axis
    fig, ax1 = plt.subplots()

    # Plot the bar chart on the primary y-axis
    ax1.bar(categories, bar_values, label="Values", color="b", alpha=0.7)

    # Create a secondary y-axis for the boxplot
    ax2 = ax1.twinx()

    # Determine the positions for boxplots based on the number of categories
    positions = 1:length(categories)

    # Plot the boxplot on the secondary y-axis
    ax2.boxplot(box_values, positions=positions, widths=0.6, patch_artist=true,
                boxprops=Dict("facecolor"=>"orange", "alpha"=>0.7),
                medianprops=Dict("color"=>"black"))

    # Set labels and title
    ax1.set_xlabel(x_label)
    ax1.set_ylabel(y_label, color="b")
    ax2.set_ylabel(box_label, color="orange")
    plt.title(chart_title)

    # Set x-axis ticks
    ax1.set_xticks(positions)
    ax1.set_xticklabels(categories, rotation=45, ha="right")

    # Adjust layout to prevent labels from getting cut off
    plt.tight_layout()

    # Save the plot
    plt.savefig(joinpath(directory_path, plot_name))

    # Display the plot (optional)
    plt.show()
end

"""
The following function takes array inputs and exports to a CSV file
"""
function export_to_csv(data1, data2, data3, data4, file_path)
    # Create a new DataFrame from the provided data
    new_data = DataFrame(data1 = data1, data2 = data2, data3 = data3, data4 = data4)

    # Specify a larger buffer size (adjust the value as needed)
    buffer_size = 50 * 1024^2  # 50 MB

    # Write the new data to the CSV file
    CSV.write(file_path, new_data, bufsize=buffer_size)
end

"""
The following function takes takes the inputs of eight scenario dates arrays 
and create a single scenario array
"""
function create_scenario_array(scenario_2024, scenario_2026, scenario_2028, scenario_2030, scenario_2035, scenario_2040, scenario_2045, scenario_2050, smr_lifetime)
    # Creating a blank array containing the end of lifetime scenario array
    end_of_lifetime = []

    # If the lifetime is longer than the scenario, then scenario 2050 is used from year 31 to the end of life
    if smr_lifetime > 31
        for i in 1:smr_lifetime-31
            end_of_lifetime = vcat(end_of_lifetime, scenario_2050)
        end
    end

    # Create a combined array of all the scenarios
    combined_array = vcat(scenario_2024, scenario_2024, scenario_2026, scenario_2026, scenario_2028, scenario_2028, scenario_2030, scenario_2030, scenario_2030, scenario_2030, scenario_2030, scenario_2035, scenario_2035, scenario_2035, scenario_2035, 
    scenario_2035, scenario_2040, scenario_2040, scenario_2040, scenario_2040, scenario_2040, scenario_2045, scenario_2045, scenario_2045, scenario_2045, scenario_2045, scenario_2050, scenario_2050, scenario_2050, scenario_2050, scenario_2050, end_of_lifetime)
    
    # Return the combined array
    return combined_array
end

"""
The following function takes in a DataFrame input and creates a bar chart with a box plot overlayed
"""
function plot_bar_and_box_pycall(categories, bar_values, box_values, y1_label, y2_label, x_label, title, save_folder)
    # Import necessary Python modules
    plt = pyimport("matplotlib.pyplot")
    np = pyimport("numpy")

    # Ensure categories and bar_values are 1D arrays of the same length
    if length(categories) != length(bar_values)
        error("Length of categories and bar_values must be the same")
    end

    # Ensure box_values is a 2D array where each row corresponds to a category
    if length(categories) != length(box_values)
        error("Length of categories and box_values must be the same")
    end

    # Convert box_values to a format that matplotlib can handle
    box_data = [np.array(box_values[i]) for i in 1:length(box_values)]

    # Create a figure and axis
    fig, ax1 = plt.subplots()

    # Plot the bar chart on the primary y-axis
    ax1.bar(1:length(categories), bar_values, color="skyblue", alpha=0.7)

    # Create a secondary y-axis for the boxplot
    ax2 = ax1.twinx()

    # Determine the positions for boxplots based on the number of categories
    positions = 1:length(categories)

    # Plot the boxplot on the secondary y-axis
    ax2.boxplot(box_data, positions=positions, widths=0.6, patch_artist=true,
                boxprops=Dict("facecolor"=>"orange", "alpha"=>0.7),
                medianprops=Dict("color"=>"black"),
                whiskerprops=Dict("color"=>"black"),
                capprops=Dict("color"=>"black"),
                flierprops=Dict("marker"=>"", "color"=>"black", "alpha"=>0.5),
                showfliers=false)  # Remove outliers

    # Set labels and title
    ax1.set_xlabel(x_label)
    ax1.set_ylabel(y1_label, color="skyblue")
    ax2.set_ylabel(y2_label, color="orange")
    plt.title(title)

    # Set x-ticks and labels
    ax1.set_xticks(positions)
    ax1.set_xticklabels(categories, rotation=45, ha="right")

    # Adjust layout to prevent labels from getting cut off
    plt.tight_layout()

    # Save the plot
    save_path = joinpath(save_folder, title * ".png")
    plt.savefig(save_path)

    # Display the plot (optional)
    #plt.show()

    # Close the figure to avoid too many open figures warning
    plt.close(fig)
end

"""
The following function takes in the correct inputs and creates a bar chart with a box plot overlayed
This function is using RCall to create the plot
"""
function plot_bar_and_box_rcall(categories, bar_values, box_values, y1_label, y2_label, x_label, title, save_folder)
    # Print the types of the inputs
    println("categories type: ", typeof(categories))
    println("bar_values type: ", typeof(bar_values))
    println("box_values type: ", typeof(box_values))

    # Print the inputs themselves for inspection
    println("categories: ", length(categories))
    println("bar_values: ", length(bar_values))
    println("box_values: ", length(box_values))

    # Create a DataFrame
    data = DataFrame(category=categories, bar_value=bar_values, box_value=box_values)

    # Pass data to R
    @rput data
    @rput y1_label
    @rput y2_label
    @rput x_label
    @rput title
    @rput save_folder

    # Create and save the plot in R with additional checks
    R"""
    library(ggplot2)

    # Print the data types within R
    print(str(data))

    # Separate the data for the box plot
    data_box <- data.frame(category = rep(data$category, lengths(data$box_value)), 
                           box_value = unlist(data$box_value))

    # Print the box plot data types
    print(str(data_box))

    # Create the plot
    p <- ggplot() +
        geom_bar(data = data, aes(x = factor(category), y = as.numeric(bar_value)), stat = "identity", fill = "skyblue", alpha = 0.7) +
        geom_boxplot(data = data_box, aes(x = factor(category), y = as.numeric(box_value), group = category), alpha = 0.5, color = "red") +
        labs(x = x_label, y = y1_label, title = title) +
        scale_y_continuous(sec.axis = sec_axis(~., name = y2_label))

    # Save the plot
    ggsave(filename = file.path(save_folder, paste0(title, ".png")), plot = p, device = "png", width = 8, height = 6)
    """
end

"""
The following function takes a multidimension array and 
"""
function flatten_array_recursive(arr)
    if !isa(arr, Array)
        return [arr]
    end
    result = []
    for element in arr
        append!(result, flatten_array_recursive(element))
    end
    return result
end

"""
This function separates 3 arrays in the last index of an array array
"""
function separate_last_index!(array_to_separate::Vector{Vector{Any}})
    # Extract the last element which is a nested array
    nested_array = pop!(array_to_separate)
    
    # Ensure the nested array is of the correct type (Array of Arrays)
    nested_array = Array{Any,1}(nested_array)
    
    # Append each array inside the nested array to the main smr_cost_vals array
    append!(array_to_separate, nested_array)
    
    return array_to_separate
end

"""
The following function cycles through the capacity market prices of ISO-NE 
for the entire lifetime of an SMR
"""
function capacity_market_iso_ne_scenario(lifetime_years::Int, iso_ne_df::DataFrame)::Array{Float64}
    # Calculate total number of months in the lifetime
    total_months = lifetime_years * 12

    # Extract the monthly prices from the DataFrame
    monthly_prices = iso_ne_df.Clearing_Price
    
    # Length of the available monthly prices in the DataFrame
    num_months_in_df = length(monthly_prices)
    
    # Create an array to hold the prices for the entire lifetime
    full_lifetime_prices = Float64[]
    
    # Fill the array with cycling prices
    for i in 1:total_months
        # Calculate the index to cycle through the DataFrame prices
        index = ((i - 1) % num_months_in_df) + 1
        push!(full_lifetime_prices, monthly_prices[index])
    end
    
    return full_lifetime_prices
end

"""
The following function cycles through the capacity market prices of NYISO
for the entire lifetime of an SMR
"""
function capacity_market_nyiso_scenario(df::DataFrame, lifetime::Int)
    # Extract the price data
    prices = df[!, "Default Reference Price (USD/kW-month)_first"]
    
    # Determine the length of the price data
    num_months = length(prices)
    
    # Calculate the total number of months needed
    total_months_needed = lifetime * 12
    
    # Repeat the prices to cover the lifetime
    repeated_prices = repeat(prices, div(total_months_needed, num_months) + 1)
    
    # Trim the repeated prices to match the exact number of months needed
    cycled_prices = repeated_prices[1:total_months_needed]
    
    return cycled_prices
end


"""
The following function cycles through the capacity market prices of PJM
for the entire lifetime of an SMR
"""
function capacity_market_pjm_scenario(df::DataFrame, lifetime::Int)
    # Extract the prices and the number of available years
    prices = df.Resource_Clearing_Price
    years = df.Delivery_Year
    num_prices = length(prices)

    # Calculate the number of years to cycle
    num_years_to_generate = lifetime

    # Initialize the array to hold the cycled prices
    cycled_prices = Float64[]

    for i in 1:num_years_to_generate
        # Find the index to use from the prices array
        index = ((i - 1) % num_prices) + 1
        push!(cycled_prices, prices[index])
    end

    return cycled_prices
end


"""
The following function cycles through the capacity market prices of MISO
for the entire lifetime of an SMR
"""
function capacity_market_misoold_scenario(df::DataFrame, lifetime::Int)
    # Extract the prices for the ERZ zone (excluding the Zone column)
    erz_prices = df[df.Zone .== "ERZ", Not(:Zone)]

    # Convert each row of prices to a flat vector and concatenate them
    flat_prices = [price for row in eachrow(erz_prices) for price in row]

    # Number of prices available
    num_prices = length(flat_prices)

    # Initialize the array to hold the cycled prices
    cycled_prices = Float64[]

    for i in 1:lifetime
        # Find the index to use from the prices array
        index = ((i - 1) % num_prices) + 1
        push!(cycled_prices, flat_prices[index])
    end

    return cycled_prices
end

"""
The following function cycles through the seasonal capacity market prices of MISO
for the entire lifetime of an SMR
"""
function capacity_market_misoseasonal_scenario(df::DataFrame, lifetime::Int64)
    # Extract the row for ERZ (assuming ERZ is always the first row)
    erz_row = df[1, 2:end]  # Exclude the Zone column

    # Extract values from the row into a vector
    prices = [erz_row[column] for column in names(df)[2:end]]
    
    # Calculate the total number of seasons
    num_seasons = length(prices)
    
    # Create a vector to hold the prices for the specified number of years
    total_prices = Float64[]
    
    # Fill the total_prices vector by cycling through the prices
    for _ in 1:lifetime
        append!(total_prices, prices)
    end
    
    # Ensure the total_prices vector has exactly the number of elements for 60 years
    total_prices = total_prices[1:num_seasons * lifetime]
    
    return total_prices
end

"""
The following function extracts the capacity market prices from a DataFrame for NYISO
"""
function extract_nyiso_capacity_prices(df::DataFrame)::Vector{Float64}
    # Ensure the DataFrame has the necessary column
    if "Default Reference Price (USD/kW-month)_first" in names(df)
        # Extract the column as a vector
        return df[!, "Default Reference Price (USD/kW-month)_first"]
    else
        error("Column 'Default Reference Price (USD/kW-month)' not found in DataFrame")
    end
end

"""
The following function extracts the capacity market prices from a DataFrame for MISO
"""
function extract_miso_yearly_capacity_prices(df::DataFrame)::Vector{Float64}
    # Initialize an empty vector to store the prices
    all_prices = Float64[]
    
    # Iterate over each period column in the DataFrame
    for period in names(df)[2:end]  # Skip the first column "Zone"
        # Append the prices from the current period to the all_prices vector
        append!(all_prices, df[!, period])
    end
    
    return all_prices
end

"""
The following function extracts the capacity market prices from a Dict for PJM
"""
function extract_prices_from_dict(pjm_capacity_market::Dict{String, Vector})::Vector{Float64}
    # Access the "Resource_Clearing_Price" value and convert it to a Vector{Float64}
    prices = pjm_capacity_market["Resource_Clearing_Price"]
    return prices
end

"""
The following function takes an array of prices in \$/MW-day and converts them to \$/kW-month
"""
function convert_prices_to_kw_month(prices_mw_day::Vector{Float64})::Vector{Float64}
    # Conversion factors
    mw_to_kw = 1 / 1000  # 1 MW = 1000 kW
    days_to_month = 30.44  # Average number of days in a month

    # Convert prices
    prices_kw_month = prices_mw_day .* mw_to_kw .* days_to_month
    return prices_kw_month
end

"""
The following function looks through multiple dataframes containing capacity market results
and plots their price results.
"""
function plot_box_plots(
    nyiso_prices::Vector{Float64},
    miso_old_prices::Vector{Float64},
    miso_new_prices::Vector{Float64},
    iso_ne_prices::Vector{Float64},
    pjm_prices::Vector{Float64}
)
    # Create DataFrames from the arrays
    nyiso_df = DataFrame(Price=nyiso_prices, Market="NYISO")
    miso_old_df = DataFrame(Price=miso_old_prices, Market="MISO Yearly")
    miso_new_df = DataFrame(Price=miso_new_prices, Market="MISO Seasonal")
    iso_ne_df = DataFrame(Price=iso_ne_prices, Market="ISO-NE")
    pjm_df = DataFrame(Price=pjm_prices, Market="PJM")

    # Combine all DataFrames
    combined_df = vcat(nyiso_df, miso_old_df, miso_new_df, iso_ne_df, pjm_df)

    # Convert to R data frame
    @rput combined_df

    # Plot using ggplot2 in R
    R"""
    library(ggplot2)
    ggplot(combined_df, aes(x=Market, y=Price, fill=Market)) +
        geom_boxplot() +
        labs(title="Capacity Market Price Comparison", x="Market", y="Price (USD/kW-month)") +
        theme_minimal() +
        scale_fill_brewer(palette="Set3") +
        theme(legend.position="none")
    """
end


"""
The following function takes in the prices of the capacity markets and returns a summary of the statistics
"""
function summarize_and_plot_prices(nyiso_prices::Vector{Float64}, 
                                   miso_old_prices::Vector{Float64}, 
                                   miso_new_prices::Vector{Float64}, 
                                   iso_ne_prices::Vector{Float64}, 
                                   pjm_prices::Vector{Float64})

    function calculate_summary_stats(prices::Vector{Float64})
        return (
            mean = mean(prices),
            median = median(prices),
            minimum = minimum(prices),
            maximum = maximum(prices),
            stddev = std(prices)
        )
    end

    summary_stats = Dict(
        "NYISO" => calculate_summary_stats(nyiso_prices),
        "MISO Old" => calculate_summary_stats(miso_old_prices),
        "MISO New" => calculate_summary_stats(miso_new_prices),
        "ISO-NE" => calculate_summary_stats(iso_ne_prices),
        "PJM" => calculate_summary_stats(pjm_prices)
    )

    # Combine all price arrays for the aggregated histogram and summary stats
    all_prices = vcat(nyiso_prices, miso_old_prices, miso_new_prices, iso_ne_prices, pjm_prices)
    summary_stats["All Markets"] = calculate_summary_stats(all_prices)

    println("Summary Statistics:")
    for (market, stats) in summary_stats
        println("$market: $stats")
    end

    # Plot histograms for each price array and the aggregated data in a single figure
    plot_titles = ["NYISO", "MISO Old", "MISO New", "ISO-NE", "PJM", "All Markets"]
    price_arrays = [nyiso_prices, miso_old_prices, miso_new_prices, iso_ne_prices, pjm_prices, all_prices]

    # Define the light orange color using RGB
    light_orange = RGB(1.0, 0.8, 0.6)

    # Use a 2x3 grid layout
    p = plot(layout = (2, 3), size = (900, 600))
    for i in 1:6
        histogram!(p, price_arrays[i], 
                   xlabel = "Capacity Market Price (\$/kW-month)", ylabel = "Frequency",
                   title = "$(plot_titles[i])",
                   legend = false, subplot = i, seriescolor = light_orange)
    end

    display(p)

    return summary_stats
end


"""
The following function takes in a breakeven array and exports it to a CSV file
"""
function export_breakeven_to_csv(breakeven_array::Vector{Any}, output_path::String, sheet_title::String)
    # Define SMR prototypes and scenarios
    smr_prototypes = ["BWRX-300", "UK-SMR", "SMR-160", "SMART", "NuScale", "RITM 200M", "ACPR 50S", 
                      "KLT-40S", "CAREM", "EM2", "HTR-PM", "PBMR-400", "ARC-100", "CEFR", "4S", 
                      "IMSR (300)", "SSR-W", "e-Vinci", "Brest-OD-300", "ATB_Cons", "ATB_Mod", "ATB Adv"]
    
    scenarios = ["Texas 2022", "DE-LU 2020", "DE-LU 2022", "Electrification", "High RE", "High NG", 
                 "Low NG", "Low RE", "Low RE TC Expire", "Mid Case", "Mid Case 100", "Mid Case 95"]
    
    # Initialize a DataFrame
    breakeven_df = DataFrame()

    # For each SMR prototype, create a column with corresponding breakeven values
    for (i, smr) in enumerate(smr_prototypes)
        start_index = (i - 1) * length(scenarios) + 1
        end_index = i * length(scenarios)
        breakeven_df[!, smr] = breakeven_array[start_index:end_index]
    end

    # Set the scenarios as the row labels
    breakeven_df[!, :Scenario] = scenarios

    # Rearrange the columns to have Scenario as the first column
    breakeven_df = select(breakeven_df, :Scenario, Not(:Scenario))

    # Export to CSV
    CSV.write(output_path * "/" * sheet_title * ".csv", breakeven_df)
end

"""
The following function takes in a breakeven array and exports it to a CSV file
"""
function export_cambium23_data_to_csv(breakeven_array::Vector{Any}, output_path::String, sheet_title::String)
    # Define SMR prototypes and scenarios
    smr_prototypes = ["BWRX-300", "UK-SMR", "SMR-160", "SMART", "NuScale", "RITM 200M", "ACPR 50S", 
                      "KLT-40S", "CAREM", "EM2", "HTR-PM", "PBMR-400", "ARC-100", "CEFR", "4S", 
                      "IMSR (300)", "SSR-W", "e-Vinci", "Brest-OD-300", "ATB_Cons", "ATB_Mod", "ATB Adv"]
    
    scenarios = ["Texas 2022", "DE-LU 2020", "DE-LU 2022", "Electrification", "High RE", "High NG", 
                 "Low NG", "Low RE", "Low RE TC Expire", "Mid Case", "Mid Case 100", "Mid Case 95",
                 "23 Cambium Mid Case", "23 Cambium High Demand Growth", "23 Cambium Mid Case 100", 
                 "23 Cambium Mid Case 95", "23 Cambium Low RE Cost", "23 Cambium High RE Cost", 
                 "23 Cambium Low NG Prices", "23 Cambium High NG Prices"]
       
    # Initialize a DataFrame
    breakeven_df = DataFrame()

    # For each SMR prototype, create a column with corresponding breakeven values
    for (i, smr) in enumerate(smr_prototypes)
        start_index = (i - 1) * length(scenarios) + 1
        end_index = i * length(scenarios)
        breakeven_df[!, smr] = breakeven_array[start_index:end_index]
    end

    # Set the scenarios as the row labels
    breakeven_df[!, :Scenario] = scenarios

    # Rearrange the columns to have Scenario as the first column
    breakeven_df = select(breakeven_df, :Scenario, Not(:Scenario))

    # Export to CSV
    CSV.write(output_path * "/" * sheet_title * ".csv", breakeven_df)
end

"""
The following function takes in a breakeven array and exports it to a CSV file
"""
function export_ap1000_data_to_csv(breakeven_array::Vector{Any}, output_path::String, sheet_title::String)
    # Define AP1000 prototypes and scenarios
    ap1000_prototypes = ["Baseline (V3&4 realized)", "Baseline (V3&4 if built today)", "Next 2 @ Vogtle",
                         "Next 2 @ Greenfield", "NOAK", "ATB_LR_Adv", "ATB_LR_Mod", "ATB_LR_Cons"]
    
    scenarios = ["Texas 2022", "DE-LU 2020", "DE-LU 2022", "Electrification", "High RE", "High NG", 
                 "Low NG", "Low RE", "Low RE TC Expire", "Mid Case", "Mid Case 100", "Mid Case 95",
                 "23 Cambium Mid Case", "23 Cambium High Demand Growth", "23 Cambium Mid Case 100", 
                 "23 Cambium Mid Case 95", "23 Cambium Low RE Cost", "23 Cambium High RE Cost", 
                 "23 Cambium Low NG Prices", "23 Cambium High NG Prices"]
    
    # Initialize a DataFrame
    breakeven_df = DataFrame()

    # For each SMR prototype, create a column with corresponding breakeven values
    for (i, smr) in enumerate(ap1000_prototypes)
        start_index = (i - 1) * length(scenarios) + 1
        end_index = i * length(scenarios)
        breakeven_df[!, smr] = breakeven_array[start_index:end_index]
    end

    # Set the scenarios as the row labels
    breakeven_df[!, :Scenario] = scenarios

    # Rearrange the columns to have Scenario as the first column
    breakeven_df = select(breakeven_df, :Scenario, Not(:Scenario))

    # Export to CSV
    CSV.write(output_path * "/" * sheet_title * ".csv", breakeven_df)
end


"""
The following function takes in price arrays from the Cambium 2023, linearly 
interpolates them to the lifetime of the input reactor, and returns a single array.
"""
function create_scenario_interpolated_array(
    prices_2025::Vector{Float64},
    prices_2030::Vector{Float64},
    prices_2035::Vector{Float64},
    prices_2040::Vector{Float64},
    prices_2045::Vector{Float64},
    prices_2050::Vector{Float64},
    lifetime::Int
) :: Vector{Float64}

    # Check if all input arrays have the correct length
    profiles = [prices_2025, prices_2030, prices_2035, prices_2040, prices_2045, prices_2050]
    for profile in profiles
        if length(profile) != 8760
            error("All price arrays must have a length of 8760 (one year's hourly prices).")
        end
    end

    # Define the years corresponding to each price profile
    years = [2025, 2030, 2035, 2040, 2045, 2050]

    # Prepare an array to store all interpolated prices
    all_interpolated_prices = []

    # Interpolate between each consecutive pair of profiles
    for i in 1:(length(profiles) - 1)
        start_prices = profiles[i]
        end_prices = profiles[i + 1]
        start_year = years[i]
        end_year = years[i + 1]
        years_diff = end_year - start_year

        # Interpolate between start and end profiles for each year
        for year in 0:years_diff
            interpolated_year_prices = start_prices .+ year * ((end_prices .- start_prices) / years_diff)
            append!(all_interpolated_prices, interpolated_year_prices)
        end
    end

    # Extend the prices from 2050 to the specified lifetime year
    end_year = 2050
    while end_year < 2025 + lifetime
        # Extend using the trend of the last interval (2045 to 2050)
        start_prices = profiles[end]
        end_prices = profiles[end] .+ (profiles[end] .- profiles[end - 1])
        for year in 1:5
            extended_year_prices = start_prices .+ year * ((end_prices .- start_prices) / 5)
            append!(all_interpolated_prices, extended_year_prices)
        end
        end_year += 5
    end

    # Return the combined interpolated and extended price profile
    return all_interpolated_prices
end


"""
The following method creates an interpolated array between years of price data 
of Cambium 2022. The function then extends the prices to the lifetime of the
reactor and returns a single array.
"""
function create_scenario_interpolated_array_cambium2022(
    prices_2024::Vector{Float64},
    prices_2026::Vector{Float64},
    prices_2028::Vector{Float64},
    prices_2030::Vector{Float64},
    prices_2035::Vector{Float64},
    prices_2040::Vector{Float64},
    prices_2045::Vector{Float64},
    prices_2050::Vector{Float64},
    lifetime::Int
) :: Vector{Float64}

    # Check and trim all input arrays to the correct length
    profiles = [prices_2024, prices_2026, prices_2028, prices_2030, prices_2035, prices_2040, prices_2045, prices_2050]
    for i in 1:length(profiles)
        if length(profiles[i]) > 8760
            profiles[i] = profiles[i][1:8760]
        elseif length(profiles[i]) < 8760
            error("All price arrays must have a length of at least 8760 (one year's hourly prices).")
        end
    end

    # Define the years corresponding to each price profile
    years = [2024, 2026, 2028, 2030, 2035, 2040, 2045, 2050]

    # Prepare an array to store all interpolated prices
    all_interpolated_prices = Float64[]

    # Interpolate between each consecutive pair of profiles
    for i in 1:(length(profiles) - 1)
        start_prices = profiles[i]
        end_prices = profiles[i + 1]
        start_year = years[i]
        end_year_profile = years[i + 1]
        years_diff = end_year_profile - start_year

        # Interpolate between start and end profiles for each year
        for year in 0:(years_diff-1)
            if start_year + year <= 2024 + lifetime - 1
                interpolated_year_prices = start_prices .+ year * ((end_prices .- start_prices) / years_diff)
                append!(all_interpolated_prices, interpolated_year_prices)
            end
        end
    end

    # Extend the prices from 2050 to the specified lifetime year
    while length(all_interpolated_prices) < lifetime * 8760
        start_prices = profiles[end]
        end_prices = profiles[end] .+ (profiles[end] .- profiles[end - 1])
        for year in 1:5
            if length(all_interpolated_prices) + 8760 <= lifetime * 8760
                extended_year_prices = start_prices .+ year * ((end_prices .- start_prices) / 5)
                append!(all_interpolated_prices, extended_year_prices)
            end
        end
    end

    # Ensure the resulting profile length matches the expected duration
    expected_length = lifetime * 8760
    return all_interpolated_prices[1:expected_length]
end

"""
Function to calculate average energy prices from scenario data
"""
function calculate_avg_energy_prices(scenario_data)
    return mean(scenario_data)  # Adjust as needed based on how your data is structured
end

"""
Function to generate heatmaps from 
"""
function generate_heatmaps(filtered_cases::Vector{Dict{String, Any}}, scenario_prices::Vector{Dict{String, Any}})
    heatmaps = []

    # Loop over each filtered case
    for case in filtered_cases
        scenario_name = case["Scenario"]
        breakeven_df = case["Breakeven DataFrame"]
        
        # Find corresponding scenario prices
        scenario_price_data = filter(scenario -> scenario["scenario"] == scenario_name, scenario_prices)
        
        if length(scenario_price_data) > 0
            avg_energy_prices = calculate_avg_energy_prices(scenario_price_data[1]["data"])
            capacity_prices = breakeven_df[!, "Capacity Price"]
            breakeven_times = breakeven_df[!, "Breakeven Time"]

            # Generate heatmap
            hm = heatmap(capacity_prices, avg_energy_prices, breakeven_times,
                         xlabel="Capacity Price (\$/kW-month)",
                         ylabel="Average Energy Price (\$/MWh)",
                         title=scenario_name,
                         color=:viridis)
                         
            push!(heatmaps, hm)
        end
    end

    # Check if heatmaps are generated
    if length(heatmaps) > 0
        plot_layout = layoutgrid(length(heatmaps), 1)  # Create a layout grid
        plot(heatmaps..., layout=plot_layout, size=(800, 600 * length(heatmaps)))
    else
        println("No heatmaps were generated.")
    end
end