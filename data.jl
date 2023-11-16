using HTTP
using CSV
using DataFrames

# Loading in the functions.jl so that 
@info("Loading in the functions file for data")
include("functions.jl")

# Texas usage
texas_sharepoint_url = "https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ER6qRc8BSptGryd1qBXXrCoBkxO3I5yC4NutrqrCaxZC0w"
texas_download_link = sharepoint_to_download_link(texas_sharepoint_url)
texasdf = CSV.File(download(texas_download_link)) |> DataFrame

# DE-LU 2020 usage
de2020_sharepoint_url = "https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EY1LQ3vkqmFFqw4-AizUjWwBcAWJm4t-Up46YJxNil8ETQ"
de2020_download_link = sharepoint_to_download_link(de2020_sharepoint_url)
de2020df = CSV.File(download(de2020_download_link)) |> DataFrame

# DE-LU 2022 usage
de2022_sharepoint_url = "https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EYX1aiuaKXVJjB5AWc72HA8BmVDnUUI7rgpxkBEG5gJOZA"
de2022_download_link = sharepoint_to_download_link(de2022_sharepoint_url)
de2022df = CSV.File(download(de2022_download_link)) |> DataFrame

# Importing SMR data to the folder
smr_info_sharepoint_url = "https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EZ4zSrIazY9AlCuEO3KSacwB3olC3pY_ila47dhpSa_ApQ"
smr_info_download_link = sharepoint_to_download_link(smr_info_sharepoint_url)
smr_infodf = CSV.File(download(smr_info_download_link)) |> DataFrame