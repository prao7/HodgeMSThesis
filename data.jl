using HTTP
using CSV
using DataFrames

# Loading in the functions.jl so that 
@info("Loading in the functions file for data")
include("dataprocessingfunctions.jl")

"""
Current prices data import
"""

# Texas usage
texas_sharepoint_url = "https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ER6qRc8BSptGryd1qBXXrCoBkxO3I5yC4NutrqrCaxZC0w"
texas_download_link = sharepoint_to_download_link(texas_sharepoint_url)
texasdf = CSV.File(download(texas_download_link)) |> DataFrame
texas_input_data = fifteen_minutes_to_hourly(texasdf,"Settlement Point Price", 4)

# DE-LU 2020 usage
de2020_sharepoint_url = "https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EY1LQ3vkqmFFqw4-AizUjWwBcAWJm4t-Up46YJxNil8ETQ"
de2020_download_link = sharepoint_to_download_link(de2020_sharepoint_url)
de2020df = CSV.File(download(de2020_download_link)) |> DataFrame

# DE-LU 2022 usage
de2022_sharepoint_url = "https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EYX1aiuaKXVJjB5AWc72HA8BmVDnUUI7rgpxkBEG5gJOZA"
de2022_download_link = sharepoint_to_download_link(de2022_sharepoint_url)
de2022df = CSV.File(download(de2022_download_link)) |> DataFrame

"""
Importing SMR data to the folder
"""

# SMR data import from OneDrive
smr_info_sharepoint_url = "https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EZ4zSrIazY9AlCuEO3KSacwB3olC3pY_ila47dhpSa_ApQ"
smr_info_download_link = sharepoint_to_download_link(smr_info_sharepoint_url)
smr_infodf = CSV.File(download(smr_info_download_link)) |> DataFrame

"""
Electrification Scenarios Data
"""

# Electrification 2024 prices
elec_2024_sharepoint_url = "https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ERPH8DkFnnVBpVWHmBQYk-sBgs_fEEOumPDnnUOLhFGehg"
elec_2024_download_link = sharepoint_to_download_link(elec_2024_sharepoint_url)
elec_2024df = CSV.File(download(elec_2024_download_link)) |> DataFrame

# Electrification 2026 prices
elec_2026_sharepoint_url = "https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EU8atUzhbp9Ck3huiUturcIBBSuu-PJ0cW36cclTOOZ2QA"
elec_2026_download_link = sharepoint_to_download_link(elec_2026_sharepoint_url)
elec_2026df = CSV.File(download(elec_2026_download_link)) |> DataFrame