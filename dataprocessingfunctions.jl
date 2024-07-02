using HTTP
using CSV
using DataFrames
using Statistics
using Plots
using StatsPlots
using PyCall
using RCall
using FilePathsBase

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
function plot_bar_and_box_rcall(y1, y2, x, y1_label, y2_label, x_label, title, save_path)
    # Convert inputs to the correct types
    y1 = Float64.(y1)
    y2 = Float64.(y2)
    x = String.(x)

    # Check that the input vectors have the same length
    if length(y1) != length(y2) || length(y2) != length(x)
        error("All input vectors must have the same length")
    end

    # Convert the input vectors to a DataFrame
    data = DataFrame(y1=y1, y2=y2, x=x)

    # Ensure the directory exists
    dir_path = dirname(save_path)
    if !isdir(dir_path)
        mkpath(dir_path)
    end

    # Pass the data to R
    @rput data
    @rput save_path
    @rput y1_label
    @rput y2_label
    @rput x_label
    @rput title

    # Create the plot in R
    R"""
    library(ggplot2)

    # Convert x to factor for plotting
    data$x <- as.factor(data$x)

    # Create the bar plot with the secondary axis for the box plot
    p <- ggplot(data, aes(x = x)) +
        geom_bar(aes(y = y1), stat = "identity", fill = "skyblue", alpha = 0.7) +
        geom_boxplot(aes(y = y2, group = x), alpha = 0.5, color = "red") +
        theme_minimal() +
        labs(x = x_label, y = y1_label, title = title) +
        theme(axis.title.y.right = element_text(color = "red"),
              axis.text.y.right = element_text(color = "red")) +
        scale_y_continuous(sec.axis = sec_axis(~., name = y2_label))

    # Save the plot to the specified path
    ggsave(filename = save_path, plot = p, device = "png", width = 8, height = 6)
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