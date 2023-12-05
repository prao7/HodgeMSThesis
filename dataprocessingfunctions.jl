using HTTP
using CSV
using DataFrames
using Statistics
using Plots

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
The following function takes inputs of names and values to create a bar chart
"""
function display_bar_chart(categories, values, chart_title, x_label, y_label)
    plotly()  # Set the plotly backend

    # Create a bar chart with the specified title, x-axis label, and y-axis label
    p = bar(categories, values, label="Values", title=chart_title, xlabel=x_label, ylabel=y_label)

    # Display the plot
    display(p)
end