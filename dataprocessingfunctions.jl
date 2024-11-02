using HTTP
using CSV
using DataFrames
using Statistics
using Plots
using StatsPlots
using PyCall
using RCall
using KernelDensity
using FilePathsBase
using Dates
using Interpolations
plt = pyimport("matplotlib.pyplot")
pd = pyimport("pandas")
np = pyimport("numpy")

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

    # Attempt to clean and convert the column to Float64 if it's not already numeric
    if !(eltype(df[!, symbol_name]) <: AbstractFloat)
        try
            # Remove commas and parse each value to Float64
            df[!, symbol_name] = parse.(Float64, replace.(string.(df[!, symbol_name]), "," => ""))
        catch e
            error("Failed to convert column '$(column_name)' to Float64: $(e)")
        end
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
function export_future_prices_data_to_csv(breakeven_array::Vector{Any}, output_path::String, sheet_title::String)
    # Define SMR prototypes and scenarios
    smr_prototypes = ["BWRX-300", "UK-SMR", "SMR-160", "SMART", "NuScale", "RITM 200M", "ACPR 50S", 
                      "KLT-40S", "CAREM", "EM2", "HTR-PM", "PBMR-400", "ARC-100", "CEFR", "4S", 
                      "IMSR (300)", "SSR-W", "e-Vinci", "Brest-OD-300", "ATB_Cons", "ATB_Mod", "ATB Adv"]
    
    scenarios = ["Electrification", "Low RE TC Expire", "Mid Case", "High Demand Growth", "Mid Case 100", "Mid Case 95",
                "Low RE Cost", "High RE Cost", "Low NG Prices", "High NG Prices"]
       
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
Data processing function to make sure that the data is sorted in ascending order
"""
function sort_heatmap_data(x_data::Vector{Float64}, y_data::Vector{Float64}, z_data::Matrix{Float64})
    # Sort x_data and reorder z_data columns accordingly
    x_sorted_indices = sortperm(x_data)
    x_data_sorted = x_data[x_sorted_indices]

    # Check if the number of columns in z_data matches the length of x_data
    if size(z_data, 1) != length(x_data)
        error("Number of columns in z_data does not match length of x_data.")
    end
    
    z_data_sorted_x = z_data[x_sorted_indices, :]

    # Sort y_data and reorder z_data rows accordingly
    y_sorted_indices = sortperm(y_data)
    y_data_sorted = y_data[y_sorted_indices]
    
    # Check if the number of rows in z_data matches the length of y_data
    if size(z_data, 2) != length(y_data)
        error("Number of rows in z_data does not match length of y_data.")
    end

    z_data_sorted = z_data_sorted_x[:, y_sorted_indices]

    return x_data_sorted, y_data_sorted, z_data_sorted
end



"""
Function to generate heatmaps from x, y, and z data
"""
function create_heatmap(x_data::Vector{Float64}, y_data::Vector{Float64}, z_data::Matrix{Float64};
    x_label::String="X-Axis", y_label::String="Y-Axis", 
    title::String="Heatmap", color_scheme=:viridis,
    output_file::String="heatmap.png")
    # Ensure z_data is already in the correct shape and can be plotted directly
    plt = heatmap(x_data, y_data, z_data, xlabel=x_label, ylabel=y_label, title=title, color=color_scheme)

    # Save the plot to the specified file
    savefig(plt, output_file)
end




"""
This function prepares the data for the heatmap
"""
function process_smr_scenario_cm_data_to_array(scenario_data, capacity_market_dict)
    # Extract unique x and y values
    x_data = unique([cm_dict["Capacity Market Price"] for cm_dict in capacity_market_dict])
    y_data = unique([mean(scenario_dict["data"]) for scenario_dict in scenario_data])

    # Create a dictionary to store breakeven times and a count for averaging
    z_dict = Dict{Tuple{Float64, Float64}, Vector{Float64}}()

    for cm_dict in capacity_market_dict
        cm_price = cm_dict["Capacity Market Price"]
        breakeven_df = cm_dict["Breakeven DataFrame"]

        for scenario_dict in scenario_data
            smr_name = scenario_dict["smr"]
            scenario_name = scenario_dict["scenario"]
            avg_price = mean(scenario_dict["data"])

            # Check if the smr_name is a valid column and scenario_name is a valid row
            if smr_name in names(breakeven_df) && scenario_name in breakeven_df[!, 1]
                row_index = findfirst(x -> x == scenario_name, breakeven_df[!, 1])
                breakeven_time = breakeven_df[row_index, smr_name]
                
                # Insert the breakeven time into the dictionary for this (x, y) pair
                key = (cm_price, avg_price)
                if haskey(z_dict, key)
                    push!(z_dict[key], breakeven_time)
                else
                    z_dict[key] = [breakeven_time]
                end
            else
                println("SMR: $smr_name, Scenario: $scenario_name not found in Breakeven DataFrame.")
            end
        end
    end

    # Create the z_data matrix with averaged values where conflicts occur
    z_data = zeros(Float64, length(x_data), length(y_data))

    for ((cm_price, avg_price), breakeven_times) in z_dict
        x_index = findfirst(x -> x == cm_price, x_data)
        y_index = findfirst(x -> x == avg_price, y_data)
        z_data[x_index, y_index] = mean(breakeven_times)
    end
    
    return x_data, y_data, z_data
end


"""
The following function 
"""
function process_smr_scenario_cm_data_multiple_arrays(scenario_data, capacity_market_dict, smr_names)

    # Initialize dictionaries to store data for each prototype (SMR)
    x_data_arrays = Dict(smr_name => Vector{Float64}() for smr_name in smr_names)
    y_data_arrays = Dict(smr_name => Vector{Float64}() for smr_name in smr_names)
    z_data_matrices = Dict(smr_name => Matrix{Float64}(undef, 0, 0) for smr_name in smr_names)  # Initialize to empty until x and y lengths are known

    # Iterate over the capacity market dictionary (list of dictionaries)
    for smr_name in smr_names

        # Temporary holders for x, y, z data for each prototype (SMR)
        x_data = Float64[]  # To store unique capacity market prices
        y_data = Float64[]  # To store unique average scenario prices
        temp_z_data = []    # Temporary storage for z_data rows

        for capacity_dict in capacity_market_dict
            cm_price = capacity_dict["Capacity Market Price"]
            breakeven_df = capacity_dict["Breakeven DataFrame"]

            # Add the capacity market price to x_data if it's not already there
            if !(cm_price in x_data)
                push!(x_data, cm_price)
            end

            # Iterate over each row in the breakeven dataframe to get scenario names
            for row_idx in 1:nrow(breakeven_df)
                scenario_name = breakeven_df[row_idx, 1]  # Assuming first column is scenario names

                # Check if the current SMR has a corresponding breakeven value
                if smr_name in names(breakeven_df)
                    breakeven_value = breakeven_df[row_idx, smr_name]

                    # Find the corresponding scenario in scenario_data
                    scenario_index = findfirst(x -> x["smr"] == smr_name && x["scenario"] == scenario_name, scenario_data)

                    if scenario_index !== nothing
                        scenario_dict = scenario_data[scenario_index]
                        avg_scenario_price = mean(scenario_dict["data"])

                        # Add the average scenario price to y_data if it's not already there
                        if !(avg_scenario_price in y_data)
                            push!(y_data, avg_scenario_price)
                        end

                        # Add the breakeven value to the temporary z_data holder
                        push!(temp_z_data, (avg_scenario_price, cm_price, breakeven_value))
                    else
                        println("Warning: Scenario '$scenario_name' for SMR '$smr_name' not found in scenario_data.")
                    end
                else
                    println("Warning: SMR '$smr_name' not found in breakeven_df.")
                end
            end
        end

        # Now we know the length of x_data and y_data, so we can initialize z_data correctly
        z_data = Matrix{Float64}(undef, length(x_data), length(y_data))

        # Fill z_data based on the temporary data
        for (avg_price, cm_price, breakeven_value) in temp_z_data
            x_idx = findfirst(x -> x == cm_price, x_data)
            y_idx = findfirst(y -> y == avg_price, y_data)
            z_data[x_idx, y_idx] = breakeven_value
        end

        # Need to sort the data before storing it
        x_data, y_data, z_data = sort_heatmap_data(x_data, y_data, z_data)

        # Store the processed arrays in the result dictionaries
        x_data_arrays[smr_name] = x_data
        y_data_arrays[smr_name] = y_data
        z_data_matrices[smr_name] = z_data
    end

    return x_data_arrays, y_data_arrays, z_data_matrices
end


"""
The following function creates a panel of heatmaps for multiple SMR prototypes.
"""
function create_panel_of_heatmaps(x_data_array::Dict, 
                                  y_data_array::Dict, 
                                  z_data_array::Dict;
                                  x_label::String="Capacity Market Price [\$/kW-month]", 
                                  y_label::String="Average Electricity Price [\$/MWh]", 
                                  output_dir::String="heatmap_panels")

    smr_names = map(string, collect(keys(z_data_array)))  # Convert keys to String
    num_prototypes = length(smr_names)
    heatmaps = Vector{Any}(undef, num_prototypes)

    # Create heatmaps
    for i in 1:num_prototypes
        smr_name = smr_names[i]
        x_data = x_data_array[smr_name]  # Get x_data corresponding to the SMR name
        y_data = y_data_array[smr_name]  # Get y_data corresponding to the SMR name
        z_data = z_data_array[smr_name]  # Get z_data corresponding to the SMR name

        # Create individual heatmap with inferno theme and y-axis limit of 100
        heatmaps[i] = heatmap(x_data, y_data, z_data, 
                              xlabel=x_label, ylabel=y_label, 
                              title=smr_name, 
                              color=:inferno, ylim=(24, 80))  # Set y-axis limit to 100
    end

    # Determine the number of heatmaps per file
    heatmaps_per_file = 6
    num_files = ceil(Int, num_prototypes / heatmaps_per_file)

    # Ensure output directory exists
    if !isdir(output_dir)
        mkdir(output_dir)
    end

    file_count = 1
    for file_index in 1:heatmaps_per_file:num_prototypes
        end_index = min(file_index + heatmaps_per_file - 1, num_prototypes)
        current_heatmaps = heatmaps[file_index:end_index]

        # Restrict to 3 heatmaps per row
        num_columns = 3
        num_rows = ceil(Int, length(current_heatmaps) / num_columns)

        # Plot heatmaps in a grid layout
        panel_plot = plot(current_heatmaps..., layout=(num_rows, num_columns), size=(1200, 800))

        # Save each file with incremental naming
        output_file = joinpath(output_dir, "heatmap_panel_$(file_count).png")
        savefig(panel_plot, output_file)
        println("Saved panel of heatmaps to $output_file")

        file_count += 1
    end
end


"""
    save_arrays_to_csv(arrays_of_arrays::Vector{Any}, smr_names::Vector{AbstractString}, scenario_names::Vector{AbstractString}, output_file::String)

Save an array of arrays to a CSV, where each array corresponds to data from the AP1000 in a specific scenario.
The header will be of the format "AP1000-Scenario".
"""
function save_ap1000_arrays_to_csv(arrays_of_arrays::Vector{Any}, 
                            smr_names::Vector{String31}, 
                            scenario_names::Vector{String}, 
                            output_file::String)

    # Ensure smr_names and scenario_names are Strings
    smr_names = map(string, smr_names)
    scenario_names = map(string, scenario_names)

    # Number of SMRs and Scenarios
    num_smrs = length(smr_names)
    num_scenarios = length(scenario_names)

    # Flatten the header to match SMR-Scenario combinations
    headers = [smr_name * "-" * scenario_name for smr_name in smr_names for scenario_name in scenario_names]
    println("Length of headers: ", length(headers))
    println("Length of arrays: ", length(arrays_of_arrays))

    # Determine the max length among all arrays
    max_len = maximum(length.(arrays_of_arrays))

    # Create a DataFrame with columns initialized to missing values
    df = DataFrame()
    
    for i in 1:length(headers)
        # Convert the array to Vector{Float64} if it's not already
        column_data = Vector{Float64}(arrays_of_arrays[i])
        # Pad the shorter arrays with `missing` to match the max length
        column_data_padded = vcat(column_data, fill(missing, max_len - length(column_data)))
        df[!, headers[i]] = column_data_padded
    end

    # Save the DataFrame to CSV
    CSV.write(output_file, df)
    println("Data saved to $output_file")
end

"""
The following function takes in a vector of capacity market prices and returns the breakeven dataframes for AP1000.
"""
function extract_ap1000_cm_data(prices::Vector{Float64})
    # Fetching all AP1000 cases
    ap1000_cm_cases = get_ap1000_cm_data()

    # Filtering dictionaries based on the specified Capacity Market Prices
    filtered_cases = filter(x -> x["Capacity Market Price"] in prices, ap1000_cm_cases)

    # Extracting only "Breakeven DataFrame" and "Capacity Market Price" fields
    result = [Dict("Capacity Market Price" => case["Capacity Market Price"],
                   "Breakeven DataFrame" => case["Breakeven DataFrame"]) for case in filtered_cases]

    return result
end

"""
The following function takes in a vector of capacity market prices and returns the breakeven dataframes for AP1000.
"""
function extract_smr_cm_data(prices::Vector{Float64})
    # Fetching all AP1000 cases
    smr_cm_cases = get_smr_cm_data()

    # Filtering dictionaries based on the specified Capacity Market Prices
    filtered_cases = filter(x -> x["Capacity Market Price"] in prices, smr_cm_cases)

    # Extracting only "Breakeven DataFrame" and "Capacity Market Price" fields
    result = [Dict("Capacity Market Price" => case["Capacity Market Price"],
                   "Breakeven DataFrame" => case["Breakeven DataFrame"]) for case in filtered_cases]

    return result
end


"""
Function to create a box and whisker plot from the dataframes for AP1000
"""
function create_ap1000_breakeven_boxplot(baseline_df::DataFrame, cm_data::Array{Dict{String,Any}}, output_dir::String)
    # Combine all the breakeven values in the baseline columns into a single array
    baseline_breakeven_combined = vcat(
        baseline_df[:, "Baseline (V3&4 realized)"], 
        baseline_df[:, "Baseline (V3&4 if built today)"],
        baseline_df[:, "Next 2 @ Vogtle"], 
        baseline_df[:, "Next 2 @ Greenfield"],
        baseline_df[:, "NOAK"], 
        baseline_df[:, "ATB_LR_Adv"], 
        baseline_df[:, "ATB_LR_Mod"], 
        baseline_df[:, "ATB_LR_Cons"]
    )

    # Combine all breakeven times for the $5.0/kW-month scenario
    breakeven_5_df = cm_data[1]["Breakeven DataFrame"]
    breakeven_5_combined = vcat(
        breakeven_5_df[:, "Baseline (V3&4 realized)"],
        breakeven_5_df[:, "Baseline (V3&4 if built today)"],
        breakeven_5_df[:, "Next 2 @ Vogtle"],
        breakeven_5_df[:, "Next 2 @ Greenfield"],
        breakeven_5_df[:, "NOAK"], 
        breakeven_5_df[:, "ATB_LR_Adv"], 
        breakeven_5_df[:, "ATB_LR_Mod"], 
        breakeven_5_df[:, "ATB_LR_Cons"]
    )

    # Combine all breakeven times for the $15.0/kW-month scenario
    breakeven_15_df = cm_data[2]["Breakeven DataFrame"]
    breakeven_15_combined = vcat(
        breakeven_15_df[:, "Baseline (V3&4 realized)"],
        breakeven_15_df[:, "Baseline (V3&4 if built today)"],
        breakeven_15_df[:, "Next 2 @ Vogtle"],
        breakeven_15_df[:, "Next 2 @ Greenfield"],
        breakeven_15_df[:, "NOAK"], 
        breakeven_15_df[:, "ATB_LR_Adv"], 
        breakeven_15_df[:, "ATB_LR_Mod"], 
        breakeven_15_df[:, "ATB_LR_Cons"]
    )

    # Combine all breakeven times for the $25.0/kW-month scenario
    breakeven_25_df = cm_data[3]["Breakeven DataFrame"]
    breakeven_25_combined = vcat(
        breakeven_25_df[:, "Baseline (V3&4 realized)"],
        breakeven_25_df[:, "Baseline (V3&4 if built today)"],
        breakeven_25_df[:, "Next 2 @ Vogtle"],
        breakeven_25_df[:, "Next 2 @ Greenfield"],
        breakeven_25_df[:, "NOAK"], 
        breakeven_25_df[:, "ATB_LR_Adv"], 
        breakeven_25_df[:, "ATB_LR_Mod"], 
        breakeven_25_df[:, "ATB_LR_Cons"]
    )

    # Create a DataFrame in R for plotting
    @rput baseline_breakeven_combined breakeven_5_combined breakeven_15_combined breakeven_25_combined

    R"""
    library(ggplot2)
    # Creating a data frame in R
    data <- data.frame(
        BreakevenTime = c(baseline_breakeven_combined, breakeven_5_combined, breakeven_15_combined, breakeven_25_combined),
        MarketType = factor(rep(c('Energy Market Only', '5.0/kW-month', '15.0/kW-month', '25.0/kW-month'), 
                            times=c(length(baseline_breakeven_combined), 
                                    length(breakeven_5_combined), 
                                    length(breakeven_15_combined), 
                                    length(breakeven_25_combined))))
    )

    # Creating the boxplot
    p <- ggplot(data, aes(x=MarketType, y=BreakevenTime)) +
        geom_boxplot() +
        theme_minimal() +
        labs(title="Breakeven Times Across Energy and Capacity Market Prices", 
             x="Market Type", y="Breakeven Time") +
        theme(plot.title = element_text(hjust = 0.5, size=15))

    # Saving the plot
    ggsave(filename=paste0($output_dir, "/breakeven_boxplot.png"), plot=p, width=8, height=6)
    """

    println("Plot saved to: $output_dir/breakeven_boxplot.png")
end

"""
Function to create a box and whisker plot from the dataframes for SMR's.
"""
function create_smr_breakeven_boxplot(baseline_df::DataFrame, cm_data::Array{Dict{String,Any}}, output_dir::String)
    # Combine all the breakeven values in the baseline columns into a single array
    baseline_breakeven_combined = vcat(
        baseline_df[:, "BWRX-300"], 
        baseline_df[:, "UK-SMR"],
        baseline_df[:, "SMR-160"], 
        baseline_df[:, "SMART"],
        baseline_df[:, "NuScale"], 
        baseline_df[:, "RITM 200M"], 
        baseline_df[:, "ACPR 50S"], 
        baseline_df[:, "KLT-40S"],
        baseline_df[:, "CAREM"],
        baseline_df[:, "EM2"],
        baseline_df[:, "HTR-PM"],
        baseline_df[:, "PBMR-400"],
        baseline_df[:, "ARC-100"],
        baseline_df[:, "CEFR"],
        baseline_df[:, "4S"],
        baseline_df[:, "IMSR (300)"],
        baseline_df[:, "SSR-W"],
        baseline_df[:, "e-Vinci"],
        baseline_df[:, "Brest-OD-300"],
        baseline_df[:, "ATB_Cons"],
        baseline_df[:, "ATB_Mod"],
        baseline_df[:, "ATB Adv"]
    )

    # Combine all breakeven times for the $5.0/kW-month scenario
    breakeven_5_df = cm_data[1]["Breakeven DataFrame"]
    breakeven_5_combined = vcat(
        breakeven_5_df[:, "BWRX-300"],
        breakeven_5_df[:, "UK-SMR"],
        breakeven_5_df[:, "SMR-160"],
        breakeven_5_df[:, "SMART"],
        breakeven_5_df[:, "NuScale"], 
        breakeven_5_df[:, "RITM 200M"], 
        breakeven_5_df[:, "ACPR 50S"], 
        breakeven_5_df[:, "KLT-40S"],
        breakeven_5_df[:, "CAREM"],
        breakeven_5_df[:, "EM2"],
        breakeven_5_df[:, "HTR-PM"],
        breakeven_5_df[:, "PBMR-400"],
        breakeven_5_df[:, "ARC-100"],
        breakeven_5_df[:, "CEFR"],
        breakeven_5_df[:, "4S"],
        breakeven_5_df[:, "IMSR (300)"],
        breakeven_5_df[:, "SSR-W"],
        breakeven_5_df[:, "e-Vinci"],
        breakeven_5_df[:, "Brest-OD-300"],
        breakeven_5_df[:, "ATB_Cons"],
        breakeven_5_df[:, "ATB_Mod"],
        breakeven_5_df[:, "ATB Adv"]
    )

    # Combine all breakeven times for the $15.0/kW-month scenario
    breakeven_15_df = cm_data[2]["Breakeven DataFrame"]
    breakeven_15_combined = vcat(
        breakeven_15_df[:, "BWRX-300"],
        breakeven_15_df[:, "UK-SMR"],
        breakeven_15_df[:, "SMR-160"],
        breakeven_15_df[:, "SMART"],
        breakeven_15_df[:, "NuScale"], 
        breakeven_15_df[:, "RITM 200M"], 
        breakeven_15_df[:, "ACPR 50S"], 
        breakeven_15_df[:, "KLT-40S"],
        breakeven_15_df[:, "CAREM"],
        breakeven_15_df[:, "EM2"],
        breakeven_15_df[:, "HTR-PM"],
        breakeven_15_df[:, "PBMR-400"],
        breakeven_15_df[:, "ARC-100"],
        breakeven_15_df[:, "CEFR"],
        breakeven_15_df[:, "4S"],
        breakeven_15_df[:, "IMSR (300)"],
        breakeven_15_df[:, "SSR-W"],
        breakeven_15_df[:, "e-Vinci"],
        breakeven_15_df[:, "Brest-OD-300"],
        breakeven_15_df[:, "ATB_Cons"],
        breakeven_15_df[:, "ATB_Mod"],
        breakeven_15_df[:, "ATB Adv"]
    )

    # Combine all breakeven times for the $25.0/kW-month scenario
    breakeven_25_df = cm_data[3]["Breakeven DataFrame"]
    breakeven_25_combined = vcat(
        breakeven_25_df[:, "BWRX-300"],
        breakeven_25_df[:, "UK-SMR"],
        breakeven_25_df[:, "SMR-160"],
        breakeven_25_df[:, "SMART"],
        breakeven_25_df[:, "NuScale"], 
        breakeven_25_df[:, "RITM 200M"], 
        breakeven_25_df[:, "ACPR 50S"], 
        breakeven_25_df[:, "KLT-40S"],
        breakeven_25_df[:, "CAREM"],
        breakeven_25_df[:, "EM2"],
        breakeven_25_df[:, "HTR-PM"],
        breakeven_25_df[:, "PBMR-400"],
        breakeven_25_df[:, "ARC-100"],
        breakeven_25_df[:, "CEFR"],
        breakeven_25_df[:, "4S"],
        breakeven_25_df[:, "IMSR (300)"],
        breakeven_25_df[:, "SSR-W"],
        breakeven_25_df[:, "e-Vinci"],
        breakeven_25_df[:, "Brest-OD-300"],
        breakeven_25_df[:, "ATB_Cons"],
        breakeven_25_df[:, "ATB_Mod"],
        breakeven_25_df[:, "ATB Adv"]
    )

    # Create a DataFrame in R for plotting
    @rput baseline_breakeven_combined breakeven_5_combined breakeven_15_combined breakeven_25_combined

    R"""
    library(ggplot2)
    # Creating a data frame in R
    data <- data.frame(
        BreakevenTime = c(baseline_breakeven_combined, breakeven_5_combined, breakeven_15_combined, breakeven_25_combined),
        MarketType = factor(rep(c('Energy Market Only', '+ 5.0/kW-month', '+ 15.0/kW-month', '+ 25.0/kW-month'), 
                            times=c(length(baseline_breakeven_combined), 
                                    length(breakeven_5_combined), 
                                    length(breakeven_15_combined), 
                                    length(breakeven_25_combined))),
                            levels = c('Energy Market Only', '+ 5.0/kW-month', '+ 15.0/kW-month', '+ 25.0/kW-month'))  # Custom ordering
    )

    # Creating the boxplot
    p <- ggplot(data, aes(x=MarketType, y=BreakevenTime)) +
        geom_boxplot() +
        theme_minimal() +
        labs(title="Breakeven Times Across Energy and Capacity Market Prices", 
             x="Market Type", y="Breakeven Time") +
        theme(plot.title = element_text(hjust = 0.5, size=15))

    # Saving the plot
    ggsave(filename=paste0($output_dir, "/smr_breakeven_boxplot.png"), plot=p, width=8, height=6)
    """

    println("Plot saved to: $output_dir/smr_breakeven_boxplot.png")
end



"""
    save_arrays_to_csv(arrays_of_arrays::Vector{Any}, smr_names::Vector{AbstractString}, scenario_names::Vector{AbstractString}, output_file::String)

Save an array of arrays to a CSV, where each array corresponds to data from the SMR in a specific scenario.
The header will be of the format "SMR-Scenario".
"""
function save_smr_arrays_to_csv(arrays_of_arrays::Vector{Any},
                            smr_names::Vector{String15}, 
                            scenario_names::Vector{String}, 
                            output_file::String)

    # Ensure smr_names and scenario_names are Strings
    smr_names = map(string, smr_names)
    scenario_names = map(string, scenario_names)

    # Number of SMRs and Scenarios
    num_smrs = length(smr_names)
    num_scenarios = length(scenario_names)

    # Flatten the header to match SMR-Scenario combinations
    headers = [smr_name * "-" * scenario_name for smr_name in smr_names for scenario_name in scenario_names]
    println("Length of headers: ", length(headers))
    println("Length of arrays: ", length(arrays_of_arrays))

    # Determine the max length among all arrays
    max_len = maximum(length.(arrays_of_arrays))

    # Create a DataFrame with columns initialized to missing values
    df = DataFrame()
    
    for i in 1:length(headers)
        # Convert the array to Vector{Float64} if it's not already
        column_data = Vector{Float64}(arrays_of_arrays[i])
        # Pad the shorter arrays with `missing` to match the max length
        column_data_padded = vcat(column_data, fill(missing, max_len - length(column_data)))
        df[!, headers[i]] = column_data_padded
    end

    # Save the DataFrame to CSV
    CSV.write(output_file, df)
    println("Data saved to $output_file")
end

"""
    process_csv_to_dicts(file_path::String)

Reads a CSV file with columns in the format "SMR-Scenario" and processes it into an array of dictionaries.
Each dictionary will have keys "smr", "scenario", and "data", with the respective values.
"""

function process_csv_to_dicts(file_path::String)
    # Read the CSV file into a DataFrame
    df = CSV.read(file_path, DataFrame)
    
    # Initialize an array to store the dictionaries
    result = []
    
    # Iterate over each column in the DataFrame
    for (col_name, col_data) in zip(names(df), eachcol(df))
        # Ensure the column name is a string
        if isa(col_name, AbstractString) && occursin("-", col_name)
            # Split the column name, prioritizing the split after the last '-'
            split_parts = split(col_name, "-")
            if length(split_parts) > 2
                # Recombine everything except the last part as the SMR name
                smr = join(split_parts[1:end-1], "-")
                scenario = split_parts[end]
            else
                # Handle the case where there's only one '-' (standard case)
                smr, scenario = split_parts
            end
            
            # Create a dictionary for each column
            dict_entry = Dict(
                "smr" => smr,
                "scenario" => scenario,
                "data" => col_data
            )
            
            # Append the dictionary to the result array
            push!(result, dict_entry)
        else
            println("Skipping column $col_name as it does not have the expected format.")
        end
    end
    
    return result
end

"""
This function creates an overlaid histogram based on three cost arrays.
"""
function create_overlaid_histogram(cost_array1::Vector{Float64}, 
                                   cost_array2::Vector{Float64}, 
                                   cost_array3::Vector{Float64};
                                   labels::Vector{String}=["Cost 1", "Cost 2", "Cost 3"], 
                                   nbins::Int=30, 
                                   output_dir::String="histogram_plots",
                                   output_file::String="overlaid_histogram.png")
    
    # Ensure output directory exists, create if it doesn't
    if !isdir(output_dir)
        mkdir(output_dir)
    end

    # Full path for the output file
    output_path = joinpath(output_dir, output_file)

    # Create the histogram for the first array
    p = histogram(cost_array1, nbins=nbins, alpha=0.5, label=labels[1], lw=2, legend=:topleft)
    
    # Overlay the second histogram
    histogram!(p, cost_array2, nbins=nbins, alpha=0.5, label=labels[2], lw=2)
    
    # Overlay the third histogram
    histogram!(p, cost_array3, nbins=nbins, alpha=0.5, label=labels[3], lw=2)

    # Set the title and labels
    xlabel!("Cost Value")
    ylabel!("Frequency")
    title!("Overlaid Histograms of Costs")
    
    # Save the plot to the specified directory
    savefig(p, output_path)
    println("Overlaid histogram saved to $output_path")

    return p
end

"""
The function creates a panel plot with two sets of generation, payout, and price data.
"""
function panel_plot_with_price_overlay(
    generation1::DataFrame, generation2::DataFrame,
    payout1::DataFrame, payout2::DataFrame,
    prices1::Vector{Float64}, prices2::Vector{Float64},
    column_name::String, output_dir::String
)
    # Extract the specific column for plotting
    gen1 = generation1[!, column_name]
    gen2 = generation2[!, column_name]
    pay1 = payout1[!, column_name]
    pay2 = payout2[!, column_name]
    
    # Create a 2x2 panel plot layout
    p1 = plot(pay1, ylabel="LPO 40% (Realistic) Operational Profit", title="Realistic Operational Profit", label="Op Profit", legend=:topright)
    plot!(p1, prices1, ylabel="Price (\$/MWh)", right=true, label="Price", legend=:bottomright)

    p2 = plot(pay2, ylabel="LPO 0% (Ideal) Operational Profit", title="LPO 0% Operational Profit", label="Op Profit", legend=:topright)
    plot!(p2, prices2, ylabel="Price (\$/MWh)", right=true, label="Price", legend=:bottomright)

    p3 = plot(gen1, ylabel="Generation (Realistic)", title="Realistic Generation", label="Generation", legend=:topright)
    plot!(p3, prices1, ylabel="Price (\$/MWh)", right=true, label="Price", legend=:bottomright)

    p4 = plot(gen2, ylabel="Generation (LPO 0%)", title="LPO 0% Generation", label="Generation", legend=:topright)
    plot!(p4, prices2, ylabel="Price (\$/MWh)", right=true, label="Price", legend=:bottomright)

    # Combine all plots into a 2x2 grid
    panel_plot = plot(p1, p2, p3, p4, layout=(2,2), size=(1000,800))

    # Save the plot
    savepath = joinpath(output_dir, "payout_and_generation_panel_plot.png")
    savefig(panel_plot, savepath)
    println("Panel plot saved to: $savepath")
end



# Import necessary Python modules
py"""
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.gridspec import GridSpec

def create_subplot_with_secondary_axis(ax, data, prices, fuel_cost, ylabel, title):
    # Plot the data (e.g., generation or payout) on the primary y-axis
    ax.plot(np.arange(len(data)), data, label='Data', color='b')
    ax.set_ylabel(ylabel)
    ax.set_title(title)
    
    # Create a secondary y-axis for price
    ax2 = ax.twinx()
    ax2.plot(np.arange(len(prices)), prices, label='Price', color='r', linestyle='dashed')
    ax2.axhline(y=fuel_cost, color='g', linestyle='--', label='Fuel Cost')
    ax2.set_ylabel('Price ($/MWh)')
    
    # Set legend and labels
    ax.legend(loc='upper left')
    ax2.legend(loc='upper right')

def save_panel_plot(gen1, gen2, pay1, pay2, prices1, prices2, fuel_cost, output_dir):
    # Create a 2x2 grid of subplots
    fig = plt.figure(figsize=(12, 10))
    gs = GridSpec(2, 2, figure=fig)

    # Create the 4 subplots with secondary axes for price
    ax1 = fig.add_subplot(gs[0, 0])
    create_subplot_with_secondary_axis(ax1, pay1, prices1, fuel_cost, "Operational Profit [$]", "Realistic LPO Operational Profit")

    ax2 = fig.add_subplot(gs[0, 1])
    create_subplot_with_secondary_axis(ax2, pay2, prices2, fuel_cost, "Operational Profit [$]", "LPO 0% Operational Profit")

    ax3 = fig.add_subplot(gs[1, 0])
    create_subplot_with_secondary_axis(ax3, gen1, prices1, fuel_cost, "Generation [MW]", "Realistic Generation")

    ax4 = fig.add_subplot(gs[1, 1])
    create_subplot_with_secondary_axis(ax4, gen2, prices2, fuel_cost, "Generation [MW]", "LPO 0% Generation")

    # Adjust layout and save the plot
    plt.tight_layout()
    save_path = output_dir + "/payout_and_generation_panel_plot.png"
    plt.savefig(save_path)
    plt.close()
    return save_path
"""

# Function to call the Python code from Julia
function panel_plot_with_price_overlay_PyCall(
    generation1::DataFrame, generation2::DataFrame,
    payout1::DataFrame, payout2::DataFrame,
    prices1::Vector{Float64}, prices2::Vector{Float64},
    column_name::String, fuel_cost::Float64, output_dir::String
)
    # Extract the specific column for plotting
    gen1 = generation1[!, column_name]
    gen2 = generation2[!, column_name]
    pay1 = payout1[!, column_name]
    pay2 = payout2[!, column_name]

    # Call the Python function via PyCall with the fuel cost parameter
    py"""
    save_panel_plot(np.array($gen1), np.array($gen2), np.array($pay1), np.array($pay2), np.array($prices1), np.array($prices2), $fuel_cost, $output_dir)
    """
    
    println("Panel plot saved to: $output_dir/payout_and_generation_panel_plot.png")
end



"""
The following function creates a stacked bar chart for the breakeven times of selected prototypes vs. LPO 0% results
"""
function plot_stacked_bar_chart(baseline_path::String, lpo0_path::String, output_dir::String)
    # Load data
    baseline_df = CSV.read(baseline_path, DataFrame)
    lpo0_df = CSV.read(lpo0_path, DataFrame)
    
    # Specify the prototypes and scenarios of interest
    selected_prototypes = ["NuScale", "BWRX-300", "PBMR-400", "ATB_Cons", "ATB_Mod", "ATB Adv"]
    # selected_scenarios = ["High NG", "Mid Case 100", "Mid Case 95", "23 Cambium Mid Case 100", "23 Cambium Mid Case 95", "23 Cambium High NG Prices"]
    selected_scenarios = ["DE-LU 2022"]

    # Ensure the data has the Scenario column for filtering
    if !("Scenario" in names(baseline_df)) || !("Scenario" in names(lpo0_df))
        error("Both data files must contain a 'Scenario' column for filtering.")
    end

    # Filter rows using `filter` for readability
    baseline_filtered = filter(row -> row.Scenario in selected_scenarios, baseline_df)
    lpo0_filtered = filter(row -> row.Scenario in selected_scenarios, lpo0_df)

    # Select only the columns of interest
    baseline_filtered = baseline_filtered[:, ["Scenario", selected_prototypes...]]
    lpo0_filtered = lpo0_filtered[:, ["Scenario", selected_prototypes...]]

    # Check dimensions of filtered data frames for debugging
    if size(baseline_filtered) != size(lpo0_filtered)
        println("Mismatch in dimensions after filtering:")
        println("Baseline dimensions: ", size(baseline_filtered))
        println("LPO0 dimensions: ", size(lpo0_filtered))
        error("Filtered data dimensions do not match.")
    end

    # Remove the Scenario column for averaging purposes
    baseline_filtered = select(baseline_filtered, Not("Scenario"))
    lpo0_filtered = select(lpo0_filtered, Not("Scenario"))

    # Calculate column-wise averages only for the selected columns
    baseline_averages = combine(baseline_filtered, names(baseline_filtered) .=> mean)
    lpo0_averages = combine(lpo0_filtered, names(lpo0_filtered) .=> mean)

    # Extract averages as vectors for plotting
    baseline_means = baseline_averages[1, :] |> Vector
    lpo0_means = lpo0_averages[1, :] |> Vector
    labels = selected_prototypes  # Labels are the selected prototype names

    # Check if means are of equal length
    if length(baseline_means) != length(lpo0_means)
        println("Number of baseline means: ", length(baseline_means))
        println("Number of LPO0 means: ", length(lpo0_means))
        error("Baseline and LPO0 means do not have matching lengths.")
    end

    # Plotting
    bar(
        labels,
        [baseline_means lpo0_means],
        label=["Baseline" "LPO = 0"],
        xlabel="Prototypes",
        ylabel="Average Breakeven Time",
        title="Average Breakeven Time of Selected Prototypes: Baseline vs LPO=0",
        legend=:topright,
        bar_width=0.6
    )
    
    # Save plot
    savepath = joinpath(output_dir, "filtered_average_breakeven_stacked_bar_chart.png")
    savefig(savepath)
    println("Plot saved to: $savepath")
end

# plot_stacked_bar_chart("/Users/pradyrao/Desktop/thesis_plots/output_files/cambium_all_cases/baseline_cambium23/cambium23_baseline_breakeven.csv", "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo0/cambium23_baseline_breakeven_lpo0.csv", "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/baseline_v_lpo0")
# plot_stacked_bar_chart("/Users/pradyrao/Desktop/thesis_plots/output_files/lpo0/baseline_v_lpo_files/baseline_ptc_itc/lponormal_breakeven.csv", "/Users/pradyrao/Desktop/thesis_plots/output_files/lpo0/baseline_v_lpo_files/lpo0_ptc_itc/lpo0_breakeven.csv", "/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/baseline_v_lpo0")

"""
The following function creates a scenario with a constant price
"""
function create_constant_price_scenario(price_rate::Float64, lifetime::Int)
    return fill(price_rate, lifetime*8760)
end

"""
The following function reorders a DataFrame and converts it to a Matrix.
"""
function load_and_reverse_df(df::DataFrame)
    # Convert to a Matrix and return
    return Matrix(df)
end


"""
Function to plot a panel of heatmaps with labeled axes and save to a directory for the AP1000 data.
"""
function plot_heatmap_panel_with_unified_legend_ap1000(ap1000_data_reversed, output_dir::String)
    # Set up the layout for the panel with one subplot for each heatmap
    n = length(ap1000_data_reversed)
    plot_layout = @layout [grid(n÷3 + 1, 3)]  # Adjust based on the number of heatmaps

    # Define x and y values for the heatmaps
    x_values = collect(0.0:1.0:100.0)
    y_values = collect(0.0:1.0:100.0)

    # Generate a heatmap for each dataset in ap1000_data_reversed
    heatmaps = [
        heatmap(x_values, y_values, d["Data"], 
                title=d["AP1000"], 
                xlabel="Capacity Market Price [\$/kW-month]",
                ylabel="Electricity Market Price [\$/MWh]",
                color=:inferno,
                colorbar=true,
                legend=false)  # Suppress individual legends
        for d in ap1000_data_reversed
    ]

    # Overlay white dashed lines and contour lines on each heatmap
    for (i, d) in enumerate(ap1000_data_reversed)
        # Plot reference lines
        plot!(heatmaps[i], [8.21, 8.21], [0, 100], color=:white, linestyle=:dash, linewidth=1, label=false)   # PJM 2025 x-axis
        plot!(heatmaps[i], [19.46, 19.46], [0, 100], color=:white, linestyle=:dash, linewidth=1, label=false) # NYISO 2023 x-axis
        plot!(heatmaps[i], [0, 100], [25.73, 25.73], color=:white, linestyle=:dash, linewidth=1, label=false) # ERCOT 2020 y-axis
        plot!(heatmaps[i], [0, 100], [65.13, 65.13], color=:white, linestyle=:dash, linewidth=1, label=false) # ERCOT 2023 y-axis

        # Add contour lines at specified levels
        contour!(heatmaps[i], x_values, y_values, d["Data"], levels=[40], color=:white, linewidth=1, linestyle=:solid, label=false)
        contour!(heatmaps[i], x_values, y_values, d["Data"], levels=[20], color=:white, linewidth=1, linestyle=:solid, label=false)
        contour!(heatmaps[i], x_values, y_values, d["Data"], levels=[15], color=:white, linewidth=1, linestyle=:solid, label=false)
        contour!(heatmaps[i], x_values, y_values, d["Data"], levels=[7], color=:white, linewidth=1, linestyle=:solid, label=false)
    end

    # Create an invisible plot with the legend entries
    legend_plot = plot(legend=:bottom, size=(700, 600))
    plot!(legend_plot, [8.21, 8.21], [0, 100], color=:white, linestyle=:dash, linewidth=1, label="Vertical line at \$8.21/kW-month (PJM 2025)")
    plot!(legend_plot, [19.46, 19.46], [0, 100], color=:white, linestyle=:dash, linewidth=1, label="Vertical line at \$19.46/kW-month (NYISO 2023)")
    plot!(legend_plot, [0, 100], [25.73, 25.73], color=:white, linestyle=:dash, linewidth=1, label="Horizontal line at \$25.73/MWh (ERCOT 2020)")
    plot!(legend_plot, [0, 100], [65.13, 65.13], color=:white, linestyle=:dash, linewidth=1, label="Horizontal line at \$65.13/MWh (ERCOT 2023)")

    # Hide grid lines and axes in the legend plot
    plot!(legend_plot, grid=false, framestyle=:none, xticks=:none, yticks=:none, legendfontsize=10)

    # Combine all heatmaps and the legend plot into a single panel plot
    panel_plot = plot(heatmaps..., legend_plot, layout=plot_layout, size=(1400, 1000))
    
    # Save the panel plot to the specified output directory
    save_path = joinpath(output_dir, "ap1000_heatmap_panel_with_unified_legend.png")
    savefig(panel_plot, save_path)
    println("Panel plot with unified legend saved to: $save_path")

    return panel_plot
end

"""
Function to plot a panel of heatmaps with labeled axes and save to a directory for the SMR data.
"""
function plot_heatmap_panel_with_unified_legend_smr(smr_data_reversed, output_dir::String)
    # Define x and y values for the heatmaps
    x_values = collect(0.0:1.0:100.0)
    y_values = collect(0.0:1.0:100.0)

    # Total number of heatmaps per panel, excluding the legend
    num_heatmaps_per_panel = 8

    # Split the data into chunks of 8 heatmaps each
    for (panel_index, chunk) in enumerate(Iterators.partition(smr_data_reversed, num_heatmaps_per_panel))
        # Generate heatmaps for the current chunk
        heatmaps = [
            heatmap(x_values, y_values, d["Data"],
                    title=d["SMR"],
                    xlabel="Capacity Market Price [\$/kW-month]",
                    ylabel="Electricity Market Price [\$/MWh]",
                    color=:inferno,
                    colorbar=true,
                    legend=false)
            for d in chunk
        ]

        # Overlay white dashed lines and contour lines at specified levels
        for (i, d) in enumerate(chunk)
            # Plot reference lines
            plot!(heatmaps[i], [8.21, 8.21], [0, 100], color=:white, linestyle=:dash, linewidth=1, label=false)   # PJM 2025 x-axis
            plot!(heatmaps[i], [19.46, 19.46], [0, 100], color=:white, linestyle=:dash, linewidth=1, label=false) # NYISO 2023 x-axis
            plot!(heatmaps[i], [0, 100], [25.73, 25.73], color=:white, linestyle=:dash, linewidth=1, label=false) # ERCOT 2020 y-axis
            plot!(heatmaps[i], [0, 100], [65.13, 65.13], color=:white, linestyle=:dash, linewidth=1, label=false) # ERCOT 2023 y-axis

            # Add contour lines at specified levels
            contour!(heatmaps[i], x_values, y_values, d["Data"], levels=[40], color=:white, linewidth=1, linestyle=:solid, label=false)
            contour!(heatmaps[i], x_values, y_values, d["Data"], levels=[20], color=:white, linewidth=1, linestyle=:solid, label=false)
            contour!(heatmaps[i], x_values, y_values, d["Data"], levels=[15], color=:white, linewidth=1, linestyle=:solid, label=false)
            contour!(heatmaps[i], x_values, y_values, d["Data"], levels=[7], color=:white, linewidth=1, linestyle=:solid, label=false)
        end

        # Create an invisible plot with the legend entries
        legend_plot = plot(legend=:bottom, size=(700, 600))
        plot!(legend_plot, [8.21, 8.21], [0, 100], color=:white, linestyle=:dash, linewidth=1, label="Vertical line at \$8.21/kW-month (PJM 2025)")
        plot!(legend_plot, [19.46, 19.46], [0, 100], color=:white, linestyle=:dash, linewidth=1, label="Vertical line at \$19.46/kW-month (NYISO 2023)")
        plot!(legend_plot, [0, 100], [25.73, 25.73], color=:white, linestyle=:dash, linewidth=1, label="Horizontal line at \$25.73/MWh (ERCOT 2020)")
        plot!(legend_plot, [0, 100], [65.13, 65.13], color=:white, linestyle=:dash, linewidth=1, label="Horizontal line at \$65.13/MWh (ERCOT 2023)")

        # Hide grid lines and axes in the legend plot
        plot!(legend_plot, grid=false, framestyle=:none, xticks=:none, yticks=:none, legendfontsize=10)

        # Combine the heatmaps and the legend plot into a single panel
        panel_plot = plot(heatmaps..., legend_plot, layout=@layout([grid(3, 3)]), size=(1400, 1000))

        # Save the panel plot to the specified output directory with an index
        save_path = joinpath(output_dir, "smr_heatmap_panel_with_unified_legend_part_$(panel_index).png")
        savefig(panel_plot, save_path)
        println("Panel plot part $(panel_index) with unified legend saved to: $save_path")
    end
end

"""
Function to plot a panel of heatmaps with labeled axes and save to a directory for the SMR data.
"""
function save_density_plot(values::Vector{<:Real}, xlabel::String, title::String, output_dir::String)
    # Compute the histogram to get frequency information
    hist_values = fit(Histogram, values, nbins=30)
    
    # Compute the kernel density estimate for a smooth curve
    density_est = kde(values)
    
    # Scale the density to match the histogram's maximum frequency
    scale_factor = maximum(hist_values.weights) / maximum(density_est.density)
    scaled_density = density_est.density * scale_factor

    # Create the histogram and overlay the scaled KDE
    plot(
        hist_values, 
        xlabel=xlabel,
        ylabel="Frequency",
        title=title,
        label="Histogram",
        legend=:topright,
        alpha=0.5, # Slight transparency for the histogram
        color=:blue,
        normalize=false
    )

    # Plot the smooth, scaled KDE curve with fill
    plot!(
        density_est.x, scaled_density,
        linewidth=2,
        label="Smooth Curve",
        fillrange=0,
        fillalpha=0.4,
        fillcolor=:blue
    )

    # Format title to create a valid filename
    filename = joinpath(output_dir, replace(title, r"[^\w\d\s]" => "") * ".png")

    # Save the plot
    savefig(filename)
    println("Density plot saved to: $filename")
end

function plot_construction_cost_histograms(literature_path::String, historical_path::String, output_dir::String)
    # Load the literature estimates CSV
    literature_df = CSV.read(literature_path, DataFrame)
    
    # Filter and adjust the literature data based on Classification
    LR_estimates = literature_df[literature_df.Classification .== "LR", :]
    LR_estimates = LR_estimates[!, "Construction Cost [\$2024/MWel]"] ./ 1000  # Convert to $/kW
    
    SMR_estimates = literature_df[literature_df.Classification .== "SMR", :]
    SMR_estimates = SMR_estimates[!, "Construction Cost [\$2024/MWel]"] ./ 1000  # Convert to $/kW
    
    # Load the historical construction costs CSV
    historical_df = CSV.read(historical_path, DataFrame)
    LR_historical = historical_df[!, "USD2024"]  # Already in $/kW format

    # Set up the plot
    fig, ax = plt.subplots(figsize=(10, 6))

    # Plot histograms with density (smooth) and fill
    ax.hist(LR_estimates, bins=20, density=true, alpha=0.5, label="LR Estimates", color="blue", edgecolor="black")
    ax.hist(SMR_estimates, bins=20, density=true, alpha=0.5, label="SMR Estimates", color="green", edgecolor="black")
    ax.hist(LR_historical, bins=20, density=true, alpha=0.5, label="LR Historical", color="orange", edgecolor="black")

    # Add title and labels
    ax.set_xlabel("Construction Cost [\$/kW]")
    ax.set_ylabel("Density")  # Added y-axis label
    ax.set_title("Comparison of Historical Costs and Estimates for Small Modular and Large Reactors")

    # Add legend
    ax.legend(loc="upper right")

    # Save plot
    savepath = joinpath(output_dir, "Comparison_of_historical_costs_and_estimates.png")
    fig.savefig(savepath)
    plt.close(fig)  # Close the figure to free memory
    println("Plot saved to: $savepath")
end


# plot_construction_cost_histograms("/Users/pradyrao/Desktop/thesis_plots/literature_estimates.csv","/Users/pradyrao/Downloads/historical_nuclear_construction_costs.csv","/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/estimates_v_historical")

function process_estimates(literature_path::String)
    # Load the literature estimates CSV
    literature_df = CSV.read(literature_path, DataFrame)
    
    # Split the data into LR and SMR estimates based on Classification
    LR_estimates = literature_df[literature_df.Classification .== "LR", ["Classification", "Estimate Type", "Reference Pair", "Construction Cost [\$2024/MWel]"]]
    SMR_estimates = literature_df[literature_df.Classification .== "SMR", ["Classification", "Estimate Type", "Reference Pair", "Construction Cost [\$2024/MWel]"]]
    
    # Sort LR and SMR estimates by "Reference Pair"
    sort!(LR_estimates, :("Reference Pair"))
    sort!(SMR_estimates, :("Reference Pair"))

    # Initialize array to store percentage differences for LR reference pairs
    lr_differences = []

    # Calculate percentage differences for LR estimates
    for ref_pair in unique(LR_estimates."Reference Pair")
        subset = LR_estimates[LR_estimates."Reference Pair" .== ref_pair, :]
        
        # Get average values based on Estimate Type
        pre_construction = mean(subset[subset."Estimate Type" .== "Pre-Construction Estimate", "Construction Cost [\$2024/MWel]"])
        post_construction = mean(subset[subset."Estimate Type" .== "Post-Construction Estimate", "Construction Cost [\$2024/MWel]"])
        actual = mean(subset[subset."Estimate Type" .== "Actual", "Construction Cost [\$2024/MWel]"])
        
        # Skip if any estimates are missing
        if isnan(pre_construction) || isnan(post_construction) || isnan(actual)
            continue
        end
        
        # Calculate percentage differences
        pre_to_post_diff = ((post_construction - pre_construction) / pre_construction) * 100
        post_to_actual_diff = ((actual - post_construction) / post_construction) * 100
        push!(lr_differences, [pre_to_post_diff, post_to_actual_diff])
    end
    
    # For SMR, find the single reference pair with Pre- and Post-Construction Estimate
    smr_difference = nothing
    for ref_pair in unique(SMR_estimates."Reference Pair")
        subset = SMR_estimates[SMR_estimates."Reference Pair" .== ref_pair, :]
        
        # Check if both Pre- and Post-Construction Estimates exist
        if "Pre-Construction Estimate" in subset."Estimate Type" && "Post-Construction Estimate" in subset."Estimate Type"
            pre_construction = mean(subset[subset."Estimate Type" .== "Pre-Construction Estimate", "Construction Cost [\$2024/MWel]"])
            post_construction = mean(subset[subset."Estimate Type" .== "Post-Construction Estimate", "Construction Cost [\$2024/MWel]"])
            
            # Calculate percentage difference and store
            smr_difference = ((post_construction - pre_construction) / pre_construction) * 100
            break
        end
    end
    
    return lr_differences, smr_difference
end

# lr_differences, smr_difference = process_estimates("/Users/pradyrao/Desktop/thesis_plots/literature_estimates.csv")

function calculate_averages_and_adjustment(lr_differences, smr_difference)
    # Calculate the average of the first and second indices in lr_differences
    lr_average_differences = [
        mean([diff[1] for diff in lr_differences]),  # Average of first indices
        mean([diff[2] for diff in lr_differences])   # Average of second indices
    ]

    # Calculate smr_average_differences
    smr_average_differences = [
        smr_difference,
        (smr_difference / lr_average_differences[1]) * lr_average_differences[2]
    ]

    return smr_average_differences, lr_average_differences
end

function save_smr_cost_estimates(cost_values::Vector{Any}, smr_names::Vector{String15}, 
    smr_average_differences::Vector{Float64}, lr_average_differences::Vector{Float64}, 
    output_dir::String)
    # Calculate the Post-Construction and Actual estimates
    post_construction_estimates = cost_values .* (smr_average_differences[1]/100.0)
    actual_estimates = post_construction_estimates .* (smr_average_differences[2]/100.0)

    # Create the DataFrame
    df = DataFrame(
    "SMR" => smr_names,
    "Pre-Construction Estimate" => cost_values,
    "Post-Construction Estimate" => post_construction_estimates,
    "Actual" => actual_estimates
    )

    # Define the output path and save the DataFrame as CSV
    save_path = joinpath(output_dir, "smr_cost_estimates.csv")
    CSV.write(save_path, df)
    println("DataFrame saved to: $save_path")

    return df
end

# Extract just the investment costs of the SMR's
# smr_investment_costs = []
# for (index, cost_array) in enumerate(smr_cost_vals)
#     push!(smr_investment_costs, (Float64(cost_array[3])/1000.0))
# end

# save_smr_cost_estimates(smr_investment_costs, smr_names, smr_average_differences, lr_average_differences, "/Users/pradyrao/Desktop/thesis_plots/output_files/investment_cost_distributions")

# smr_average_differences, lr_average_differences = calculate_averages_and_adjustment(lr_differences, smr_difference)



function process_mean_estimates_by_type(literature_path::String, output_dir::String)
    # Load the data
    literature_df = CSV.read(literature_path, DataFrame)

    # Filter for rows classified as "LR" and sort by the integer in "Reference Pair"
    LR_df = filter(row -> row["Classification"] == "LR", literature_df)
    LR_df = sort(LR_df, :"Reference Pair")  # Use symbol syntax for sorting

    # Initialize a DataFrame to store the mean construction costs by type
    mean_costs_df = DataFrame(
        "Reference Pair" => String[],
        "Pre-Construction Cost" => Float64[],
        "Post-Construction Cost" => Float64[],
        "Actual" => Float64[]
    )

    # Loop over unique reference pairs
    for pair in unique(LR_df[!, "Reference Pair"])
        estimates = filter(row -> row["Reference Pair"] == pair, LR_df)
        
        # Calculate mean values by Estimate Type
        pre_construction_cost = mean(filter(row -> row["Estimate Type"] == "Pre-Construction Estimate", estimates)[!, "Construction Cost [\$2024/MWel]"])
        post_construction_cost = mean(filter(row -> row["Estimate Type"] == "Post-Construction Estimate", estimates)[!, "Construction Cost [\$2024/MWel]"])
        actual_cost = mean(filter(row -> row["Estimate Type"] == "Actual", estimates)[!, "Construction Cost [\$2024/MWel]"])
        
        # Add to the DataFrame if all required estimates are present
        if !isnan(pre_construction_cost) && !isnan(post_construction_cost) && !isnan(actual_cost)
            push!(mean_costs_df, (string(pair), pre_construction_cost, post_construction_cost, actual_cost))
        end
    end

    # Save the resulting DataFrame to a CSV file
    save_path = joinpath(output_dir, "LR_mean_estimates_by_type.csv")
    CSV.write(save_path, mean_costs_df)
    println("Mean estimates by estimate type saved to: $save_path")

    return mean_costs_df
end


# process_mean_estimates_by_type("/Users/pradyrao/Desktop/thesis_plots/literature_estimates.csv","/Users/pradyrao/Desktop/thesis_plots/output_files/investment_cost_distributions")

function plot_kernel_density(csv_path::String, output_dir::String)
    # Load the CSV data into a DataFrame
    df = CSV.read(csv_path, DataFrame)

    # Check that the columns are present
    required_columns = ["Pre-Construction Estimate", "Post-Construction Estimate", "Actual"]
    for col in required_columns
        if !(col in names(df))
            error("Column $col not found in the CSV file.")
        end
    end

    # Extract the data for the kernel density plots
    pre_construction_values = df[!, "Pre-Construction Estimate"]
    post_construction_values = df[!, "Post-Construction Estimate"]
    actual_values = df[!, "Actual"]
    
    # Create the kernel density plot with shaded areas
    density(pre_construction_values, label="Pre-Construction Estimate", linewidth=2, fillrange=0, alpha=0.3)
    density!(post_construction_values, label="Post-Construction Estimate", linewidth=2, fillrange=0, alpha=0.3)
    density!(actual_values, label="Actual", linewidth=2, fillrange=0, alpha=0.3)

    # Label axes and set title
    xlabel!("Construction Cost [\$/kW]")
    ylabel!("Density")
    title!("Kernel Density Plot for Large Reactor Estimates")

    # Save the plot
    save_path = joinpath(output_dir, "lr_construction_cost_density_plot.png")
    savefig(save_path)
    println("Density plot with shading saved to: $save_path")
end



# plot_kernel_density("/Users/pradyrao/Desktop/thesis_plots/output_files/investment_cost_distributions/LR_mean_estimates_by_type.csv","/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/investment_cost_distributions")

# plot_kernel_density("/Users/pradyrao/Desktop/thesis_plots/output_files/investment_cost_distributions/smr_cost_estimates.csv","/Users/pradyrao/Desktop/thesis_plots/thesis_plots_rcall/investment_cost_distributions")

"""
The following function creates a historical scenario by repeating a given price array for a specified lifetime.
"""
function create_historical_scenario(price_array::Vector{Any}, lifetime::Int)
    return repeat(price_array, ceil(Int, lifetime * 8760 / length(price_array)))[1:lifetime * 8760]
end