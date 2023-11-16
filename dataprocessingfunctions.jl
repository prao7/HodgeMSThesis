using HTTP
using CSV
using DataFrames
using Statistics

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