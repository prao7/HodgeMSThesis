using HTTP
using CSV
using DataFrames
using Dates
using CategoricalArrays
using Plots

# Loading in the functions.jl so that 
@info("Loading in the functions file for data processing")
include("dataprocessingfunctions.jl")

"""
Empty array for all scenario data to be input. This will contain all price data to be analyzed on.
"""
scenario_data_all = []

# Array for 2023 Cambium scenario prices
scenario_23_data_all = []

"""
Empty arrays for the ancillary services data from PJM. The first array will contain the various markets that the SMR's will bid into.
The second array will contain the generation requirements of the various markets.
"""
ancillary_services_prices = []
ancillary_services_demand = []

"""
This is the array of all the scenarios in order
"""
scenario_names = ["Texas 2022", "DE-LU 2020", "DE-LU 2022", "Electrification 2024", "Electrification 2026", "Electrification 2028",
"Electrification 2030", "Electrification 2035", "Electrification 2040", "Electrification 2045", "Electrification 2050", "High RE 2024",
"High RE 2026", "High RE 2028", "High RE 2030", "High RE 2035", "High RE 2040", "High RE 2045", "High RE 2050", "High NG 2024",
"High NG 2026", "High NG 2028", "High NG 2030", "High NG 2035", "High NG 2040", "High NG 2045", "High NG 2050", "Low NG 2024", 
"Low NG 2026", "Low NG 2028", "Low NG 2030", "Low NG 2035", "Low NG 2040", "Low NG 2045", "Low NG 2050", "Low RE 2024", "Low RE 2026",
"Low RE 2028", "Low RE 2030", "Low RE 2035", "Low RE 2040", "Low RE 2045", "Low RE 2050", "Low RE TC Expire 2024", "Low RE TC Expire 2026",
"Low RE TC Expire 2028", "Low RE TC Expire 2030", "Low RE TC Expire 2035", "Low RE TC Expire 2040", "Low RE TC Expire 2045", "Low RE TC Expire 2050",
"Mid Case 2024", "Mid Case 2026", "Mid Case 2028", "Mid Case 2030", "Mid Case 2035", "Mid Case 2040", "Mid Case 2045", "Mid Case 2050",
"Mid Case 100 2024", "Mid Case 100 2026", "Mid Case 100 2028", "Mid Case 100 2030", "Mid Case 100 2035", "Mid Case 100 2040", "Mid Case 100 2045",
"Mid Case 100 2050", "Mid Case 95 2024", "Mid Case 95 2026", "Mid Case 95 2028", "Mid Case 95 2030", "Mid Case 95 2035", "Mid Case 95 2040",
"Mid Case 95 2045", "Mid Case 95 2050", "Cambium 2023 Mid Case 2025", "Cambium 2023 Mid Case 2027", "Cambium 2023 Mid Case 2029", "Cambium 2023 Mid Case 2031",]

"""
This is the array of the names of the combined scenarios analyzed
"""
scenario_names_combined = ["Texas 2022", "DE-LU 2020", "DE-LU 2022", "Electrification", "High RE", "High NG", "Low NG", "Low RE",
"Low RE TC Expire", "Mid Case", "Mid Case 100", "Mid Case 95"]

scenario_names_23cambium = ["23 Cambium Mid Case", "23 Cambium High Demand Growth", "23 Cambium Mid Case 100", 
"23 Cambium Mid Case 95", "23 Cambium Low RE Cost", "23 Cambium High RE Cost", "23 Cambium Low NG Prices", "23 Cambium High NG Prices"]

combined_scenario_names = vcat(scenario_names_combined, scenario_names_23cambium)

# Empty array with all the names of the SMR's to be pushed from the SMR DataFrame
smr_names = []


"""
Current prices data import
"""

# Texas usage
texasdf = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ER6qRc8BSptGryd1qBXXrCoBkxO3I5yC4NutrqrCaxZC0w")
push!(scenario_data_all, fifteen_minutes_to_hourly(texasdf,"Settlement Point Price", 4))

# DE-LU 2020 usage
de2020df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EY1LQ3vkqmFFqw4-AizUjWwBcAWJm4t-Up46YJxNil8ETQ")
push!(scenario_data_all, array_from_dataframe_converttoeuro(de2020df,"Germany/Luxembourg [€/MWh] Original resolutions"))

# DE-LU 2022 usage
de2022df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EYX1aiuaKXVJjB5AWc72HA8BmVDnUUI7rgpxkBEG5gJOZA")
push!(scenario_data_all, array_from_dataframe_converttoeuro(de2022df,"Germany/Luxembourg [€/MWh] Original resolutions"))

"""
Importing SMR data to the DataFrame and adding to arrays.
"""

# SMR data import from OneDrive
smr_infodf = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EZ4zSrIazY9AlCuEO3KSacwB3olC3pY_ila47dhpSa_ApQ")

# Array with all the names of the SMR's
smr_names = array_from_dataframe(smr_infodf, "Project")

"""
Importing in data about AP1000
"""
ap1000_df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ERhS7ik6UzpJrfZfLcOUNAQBgwQhO8ZB4Gvda976ISeYYA")

ap1000_scenario_names = array_from_dataframe(ap1000_df, "ATB Scenario")

"""
Adding in all the rows of economic data of SMR's
"""

# Array to extract Capacity [MWel]  Lifetime [years]  Construction Cost [USD2020/MWel]  Fuel cost [USD2020/MWh]  O&M cost [USD2020/MWel] from SMR DataFrame
smr_cost_vals = extract_columns_from_third_to_end(smr_infodf)

"""
Extracting the AP1000 economic data
"""
ap1000_cost_vals = extract_columns_from_third_to_end(ap1000_df)

"""
ATB Information regarding the cost of SMR's
"""

# Adding in the ATB cost scenarios as SMR's to the cost values DataFrame
# Capacity [MWel]	Lifetime [years]	Construction Cost [USD2020/MWel]	Fuel cost [USD2020/MWh]	Fixed O&M cost [USD2020/MW-yr]	Variable O&M cost [USD2024/MWh]	Number of Modules	Construction Duration [Months]	Refueling Minimum Time [Months]	Refueling Maximum Time [Months]
atb_cost_scenariosdf = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ETduGx3k3mxOtnklMGLigc0BMScT6oal5hctCyEvZK6XpQ")
push!(smr_cost_vals, extract_columns_from_third_to_end(atb_cost_scenariosdf))

smr_cost_vals = separate_last_index!(smr_cost_vals)

# Print the modified smr_cost_vals array to verify the result
#display(smr_cost_vals)


# Pushing the names 
push!(smr_names, "ATB_Cons")
push!(smr_names, "ATB_Mod")
push!(smr_names, "ATB Adv")


# Creating the DataFrame for the C2N DataFrame
# Source: https://inldigitallibrary.inl.gov/sites/sti/sti/Sort_107010.pdf
c2n_cost_reduction = DataFrame(
    Category = ["OCC 2030", "Fuel Cost", "Fixed O&M", "Variable O&M"],
    Advanced = [0.59, 1.0, 0.902, 1.16],
    Moderate = [0.59, 1.13, 0.83, 1.04],
    Conservative = [0.752, 1.248, 1.31, 1.03]
)

c2n_cost_reduction_lr = DataFrame(
    Category = ["OCC 2030", "Fuel Cost", "Fixed O&M", "Variable O&M"],
    Advanced = [0.71, 0.89, 1.23, 1.0],
    Moderate = [0.78, 1.0097, 1.568, 1.14],
    Conservative = [0.742, 1.115, 1.879, 1.265]
)

# How to extract the value from the DataFrame above
# fuel_cost_advanced = c2n_cost_reduction[ismissing(c2n_cost_reduction.Category .== "Fuel Cost"), :Advanced]



# Importing in the learning rates given in the ATB
# Source: https://atb.nrel.gov/electricity/2024/nuclear
multiple_plant_cost_reduction = DataFrame(
    Number_of_units = CategoricalArray([1, 2, 4, 8, 10]),
    OCC_Cost_Reduction = [1.0, 0.9, 0.8, 0.7, 0.7],
    OM_Cost_Reduction = [1.0, 0.67, 0.67, 0.67, 0.67]
)


# Example reference the associated value for OCC Cost Reduction where Number_of_units is 4
# occ_cost_reduction_for_4_units = multiple_plant_cost_reduction[multiple_plant_cost_reduction.Number_of_units .== 4, :OCC_Cost_Reduction]


# Creating a DataFrame for the ITC OCC cost reduction.
# Source: https://inldigitallibrary.inl.gov/sites/sti/sti/Sort_107010.pdf
itc_cost_reduction = DataFrame(
    Category = ["6%", "30%", "40%", "50%"],
    Advanced = [0.954545, 0.7272727, 0.6363636, 0.5454545],
    Moderate = [0.9375, 0.71875, 0.625, 0.53125],
    Conservative = [0.95, 0.725, 0.625, 0.55]
)

itc_cost_reduction_lr = DataFrame(
    Category = ["6%", "30%", "40%", "50%"],
    Advanced = [0.9524, 0.7143, 0.619, 0.5238],
    Moderate = [0.9565, 0.7391, 0.6522, 0.5217],
    Conservative = [0.935, 0.742, 0.645, 0.54839]
)

# How to extract the value from the DataFrame above
# itc_advanced = itc_cost_reduction[ismissing(itc_cost_reduction.Category .== "6%"), :Advanced]

"""
String defining the column to be imported from Cambium Data
"""
column_name_cambium = "total_cost_busbar"

"""
Electrification Scenarios Data
"""

# Electrification 2024 prices
elec_2024df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ERPH8DkFnnVBpVWHmBQYk-sBgs_fEEOumPDnnUOLhFGehg")
push!(scenario_data_all, array_from_dataframe(elec_2024df, column_name_cambium))

# Electrification 2026 prices
elec_2026df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EU8atUzhbp9Ck3huiUturcIBBSuu-PJ0cW36cclTOOZ2QA")
push!(scenario_data_all, array_from_dataframe(elec_2026df, column_name_cambium))

# Electrification 2028 prices
elec_2028df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ERVSyaiiru1EtPwhFqkmkAMBU-exSUf-UudhuQTPbWb4xA")
push!(scenario_data_all, array_from_dataframe(elec_2028df, column_name_cambium))

# Electrification 2030 prices
elec_2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EfwzZ7YCNMBLq5FYTPEIg1oBI0UM_4pwV5MQ4a3UjBNnrA")
push!(scenario_data_all, array_from_dataframe(elec_2030df, column_name_cambium))

# Electrification 2035 prices
elec_2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ETRvRrd-hEZDqRtUqHY2duABIWloYTYcKooBLWJWW8PVVQ")
push!(scenario_data_all, array_from_dataframe(elec_2035df, column_name_cambium))

# Electrification 2040 prices
elec_2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EZqxfTEvWldIkH2eZ20G3ekBSoOTjwzOAfwD5yKaFx6Bsw")
push!(scenario_data_all, array_from_dataframe(elec_2040df, column_name_cambium))

# Electrification 2045 prices
elec_2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/Eb6x9qT8zxRBmh7qT8565BoBeAgj9GW9ln1OMKLGFUF73g")
push!(scenario_data_all, array_from_dataframe(elec_2045df, column_name_cambium))

# Electrification 2050 prices
elec_2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/Ebia0G9_ExBCnDxg9nGF8y4BPuWRHZbDDbFarxksozGMiw")
push!(scenario_data_all, array_from_dataframe(elec_2050df, column_name_cambium))

"""
High RE Cost Scenarios Data
"""

# High RE Cost 2024 prices
highRE_2024df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ETIox6tJ369JlrtBIk_JvhYByjraB_H-WNHC71kUM5sErw")
push!(scenario_data_all, array_from_dataframe(highRE_2024df, column_name_cambium))

# High RE Cost 2026 prices
highRE_2026df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ETuDnqr6qylKh_WN9cW11ZcB1_T8vmflzTqcmIsbkhDTeA")
push!(scenario_data_all, array_from_dataframe(highRE_2026df, column_name_cambium))

# High RE Cost 2028 prices
highRE_2028df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/Edbk9Aqa7xFOjAPLZeY1FK4BtxlGlqgLGLpsOyGWbyKYIQ")
push!(scenario_data_all, array_from_dataframe(highRE_2028df, column_name_cambium))

# High RE Cost 2030 prices
highRE_2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EQsJkk9wkXxPnhx1tcJEDikBEvNiozIMWiV5m9-e_6_VLA")
push!(scenario_data_all, array_from_dataframe(highRE_2030df, column_name_cambium))

# High RE Cost 2035 prices
highRE_2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EUd1DnFFUVJEo1pQTKd2GdwBPRaOeanA3JvkX63HSsCFZQ")
push!(scenario_data_all, array_from_dataframe(highRE_2035df, column_name_cambium))

# High RE Cost 2040 prices
highRE_2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EetA2thaSvlDt1WTZIwsGN8BDQbyZ7q6Kr9-QnbAzU7new")
push!(scenario_data_all, array_from_dataframe(highRE_2040df, column_name_cambium))

# High RE Cost 2045 prices
highRE_2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EZVO3eC8wd5Mkg1-pVFjNzkBCk4z8D1uXy62mUsPYlpbWQ")
push!(scenario_data_all, array_from_dataframe(highRE_2045df, column_name_cambium))

# High RE Cost 2050 prices
highRE_2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EdWyKNSJ1TJMqup5-yeoxcABm2f53B5MC6-Uk80-hQDJ7Q")
push!(scenario_data_all, array_from_dataframe(highRE_2050df, column_name_cambium))

"""
High NG Scenarios Data
"""

# High NG 2024 prices
highNG_2024df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EYTxYZImGFRPpEnLVKqQLMYBkoe25xDQb1d_ywzHYT6JRw")
push!(scenario_data_all, array_from_dataframe(highNG_2024df, column_name_cambium))

# High NG 2026 prices
highNG_2026df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ETgUwIuDriZAv_V6I_n7MzQBvGgj0_GI4IEFhusB7SAYww")
push!(scenario_data_all, array_from_dataframe(highNG_2026df, column_name_cambium))

# High NG 2028 prices
highNG_2028df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EW3jGqs1pi1CoSwDz-j61WQBnMoQaHlF4CFJZwMweiwLiQ")
push!(scenario_data_all, array_from_dataframe(highNG_2028df, column_name_cambium))

# High NG 2030 prices
highNG_2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EeFOzw_IZvZBjz8NfNB_ekUBjRFfMy1nXPMASwcbdwshag")
push!(scenario_data_all, array_from_dataframe(highNG_2030df, column_name_cambium))

# High NG 2035 prices
highNG_2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EWIy_qmLhYNDq2pQ4XuZt-UBetpdr_cbvzUqZ_nPQ4akSg")
push!(scenario_data_all, array_from_dataframe(highNG_2035df, column_name_cambium))

# High NG 2040 prices
highNG_2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ET_bEPi2rhhKgxtiy8Z028gBiu5dXCemIrW18kKPKydxSA")
push!(scenario_data_all, array_from_dataframe(highNG_2040df, column_name_cambium))

# High NG 2045 prices
highNG_2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EcQNxuzYODZNnIaCiQOcMucBDDz2pX6KNbh0EoxB6Lo8eg")
push!(scenario_data_all, array_from_dataframe(highNG_2045df, column_name_cambium))

# High NG 2050 prices
highNG_2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EVFLxQBXeeJOovTYUeblTJMBaXQZDMUCcH6eL6MQnHSNxQ")
push!(scenario_data_all, array_from_dataframe(highNG_2050df, column_name_cambium))

"""
Low NG prices Scenarios Data
"""

# Low NG prices 2024
lowNG_2024df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EVz1EL7U-XVOiwSWuxwBD_YBGhON5Lx4yGp5fdxPNmmqnA")
push!(scenario_data_all, array_from_dataframe(lowNG_2024df, column_name_cambium))

# Low NG prices 2026
lowNG_2026df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EWYUFcjmQwJLqMf2qIRW3y4BlgXKd42KBOCsV4P9k1KU_A")
push!(scenario_data_all, array_from_dataframe(lowNG_2026df, column_name_cambium))

# Low NG prices 2028
lowNG_2028df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ESZhC9TxG-9PjoNy5JHFYxUBiHqm195IrdU7_oobmJYdZQ")
push!(scenario_data_all, array_from_dataframe(lowNG_2028df, column_name_cambium))

# Low NG prices 2030
lowNG_2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ESvuM-5pd_xFjp2HaAUOBw8BN6Le2VR9JC_BbZ50-8pPWA")
push!(scenario_data_all, array_from_dataframe(lowNG_2030df, column_name_cambium))

# Low NG prices 2035
lowNG_2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EXNvXnrdzFlFjMa5rSHhCv4Bau-kX_QitB4Jz7Z00p6ARw")
push!(scenario_data_all, array_from_dataframe(lowNG_2035df, column_name_cambium))

# Low NG prices 2040
lowNG_2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EahSONo8MMNJt0ZT9YLYhjcBUA2TUsTYZPx6AamVm6yM5w")
push!(scenario_data_all, array_from_dataframe(lowNG_2040df, column_name_cambium))

# Low NG prices 2045
lowNG_2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ERyHGoKVLvRBl-g4F4KZHTABCNlx4LX_5v8PesJrTX3XCQ")
push!(scenario_data_all, array_from_dataframe(lowNG_2045df, column_name_cambium))

# Low NG prices 2050
lowNG_2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EX0TC9OumNJKmcGb4VU0u9YBwZklZfFgBXegZgYnQa5nSA")
push!(scenario_data_all, array_from_dataframe(lowNG_2050df, column_name_cambium))

"""
Low RE Cost Scenarios Data
"""

# Low RE Cost 2024
lowRECost_2024df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EelyFEyo69BJpDV86ObjNT0B9CP6TfS5kZcbZTFU_MZBDw")
push!(scenario_data_all, array_from_dataframe(lowRECost_2024df, column_name_cambium))

# Low RE Cost 2026
lowRECost_2026df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EfSEKfUgpLFAmI1tBqM_LhQBJsnETa2tY0o4jv59-Cad5A")
push!(scenario_data_all, array_from_dataframe(lowRECost_2026df, column_name_cambium))

# Low RE Cost 2028
lowRECost_2028df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ES_qTZL5oPhEp8U3JjeAIrMBueMKPzQoKH5FyBVq-gvpjQ")
push!(scenario_data_all, array_from_dataframe(lowRECost_2028df, column_name_cambium))

# Low RE Cost 2030
lowRECost_2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ESO_H8WaIclHpC89Nu9jM_cBWdr2pg83bMp18H4teTEdWg")
push!(scenario_data_all, array_from_dataframe(lowRECost_2030df, column_name_cambium))

# Low RE Cost 2035
lowRECost_2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EYq36K11Fn1IovfXTkzPxCABVbbbqL424cyf7Ox1rbnwaQ")
push!(scenario_data_all, array_from_dataframe(lowRECost_2035df, column_name_cambium))

# Low RE Cost 2040
lowRECost_2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EdW3PqsFCk5IsTZBROG-NWUBk23ia6vqsbthXjXkzdHzyA")
push!(scenario_data_all, array_from_dataframe(lowRECost_2040df, column_name_cambium))

# Low RE Cost 2045
lowRECost_2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EdaHcdiGDQZPu0OduOVtIdMB7u7NGdaZ94AfjDbnxou6cA")
push!(scenario_data_all, array_from_dataframe(lowRECost_2045df, column_name_cambium))

# Low RE Cost 2050
lowRECost_2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EXvT0HhvM-dEikIbzanWUbEBAvIzdQPbLDlLeViwWnpTfw")
push!(scenario_data_all, array_from_dataframe(lowRECost_2050df, column_name_cambium))

"""
Low RE Cost TC Expire Scenarios Data
"""

# Low RE Cost TC Expire 2024
lowRECostTCE_2024df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EQFIEzfraMxDjiuJHwVykukB8euH9cvRJ0ZuJk7tzvO_TA")
push!(scenario_data_all, array_from_dataframe(lowRECostTCE_2024df, column_name_cambium))

# Low RE Cost TC Expire 2026
lowRECostTCE_2026df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EeM7Eu7n9NdJlEzL0GOZ2o4Bb97IS1BeqKsCQGWYSiBgtA")
push!(scenario_data_all, array_from_dataframe(lowRECostTCE_2026df, column_name_cambium))

# Low RE Cost TC Expire 2028
lowRECostTCE_2028df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/Ebg96qc11VBAmIGXXXnKyZ4BkqPLCddU6yh32It-uTQqNA")
push!(scenario_data_all, array_from_dataframe(lowRECostTCE_2028df, column_name_cambium))

# Low RE Cost TC Expire 2030
lowRECostTCE_2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EW2XCkZhb3VGiPClCkWL4DMBrsjQ067M1DUlrtnBczXu6g")
push!(scenario_data_all, array_from_dataframe(lowRECostTCE_2030df, column_name_cambium))

# Low RE Cost TC Expire 2035
lowRECostTCE_2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EdH8bM_UTqdIrgxwZUQZhVsBLaC_PZTHoNcVy2DWb4euCg")
push!(scenario_data_all, array_from_dataframe(lowRECostTCE_2035df, column_name_cambium))

# Low RE Cost TC Expire 2040
lowRECostTCE_2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ET-ALZRihnVGtPfQ1K3RHn4BH7EZWi_8ESA3-ghmJLlh5A")
push!(scenario_data_all, array_from_dataframe(lowRECostTCE_2040df, column_name_cambium))

# Low RE Cost TC Expire 2045
lowRECostTCE_2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EQtZYgRFTP1FgUPcs6Wmig8BTqWkSQ6Cq5Lzi7IPu9DLqQ")
push!(scenario_data_all, array_from_dataframe(lowRECostTCE_2045df, column_name_cambium))

# Low RE Cost TC Expire 2050
lowRECostTCE_2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EfP6cXZVmwhAs5XKIOcbtcoB0gXrGFmEARPlcuGHdEqtuQ")
push!(scenario_data_all, array_from_dataframe(lowRECostTCE_2050df, column_name_cambium))

"""
Mid Case Scenarios Data
"""

# Mid Case 2024
midcase_2024df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EU0MhHgaBj5EtTu2g22BXw8B9jUpbdZZ0uLU0gKkpKDOmQ")
push!(scenario_data_all, array_from_dataframe(midcase_2024df, column_name_cambium))

# Mid Case 2026
midcase_2026df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ETQBwwx3w3tJnmpOyH_ioBoBebXuzSljjGt66Jz5yExP8g")
push!(scenario_data_all, array_from_dataframe(midcase_2026df, column_name_cambium))

# Mid Case 2028
midcase_2028df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ETmg7jlxPSlDnlws4Lg0gGYB8ULV8hTdEo4lFhMe5KERKQ")
push!(scenario_data_all, array_from_dataframe(midcase_2028df, column_name_cambium))

# Mid Case 2030
midcase_2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EQ11BQVSdoZKlStCsgbNAggBhqB_tAmWsYOmwRE50aparg")
push!(scenario_data_all, array_from_dataframe(midcase_2030df, column_name_cambium))

# Mid Case 2035
midcase_2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EaZwdInAMrNClKwcObEOU30BiFVZ5UI7r0mATOolv6x4XQ")
push!(scenario_data_all, array_from_dataframe(midcase_2035df, column_name_cambium))

# Mid Case 2040
midcase_2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EWxIOhdu2U1Nkmp9Mb9U_NMBqAxVope16to3IdnpxqtM6Q")
push!(scenario_data_all, array_from_dataframe(midcase_2040df, column_name_cambium))

# Mid Case 2045
midcase_2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EXupfDNVYIpCnByp0HHXIXYBYeWvVKRlGAPlUP1j_vp8DQ")
push!(scenario_data_all, array_from_dataframe(midcase_2045df, column_name_cambium))

# Mid Case 2050
midcase_2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EYdNXYEoJs9Gonl91c2Y5SsB8dKlYzBADVDRdgF7McFYBw")
push!(scenario_data_all, array_from_dataframe(midcase_2050df, column_name_cambium))

"""
Mid Case 100 by 2035 Scenarios Data
"""

# Mid Case 100 2024
midcase100_2024df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EaJhSteK1bhDmFGyG_19K3EB-X9CGXXSouppUXhRcJcq_A")
push!(scenario_data_all, array_from_dataframe(midcase100_2024df, column_name_cambium))

# Mid Case 100 2026
midcase100_2026df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EXbK74g8pEdGkKOwP9oUOBABAY4F2l_XBJu5jqXfz-cgcQ")
push!(scenario_data_all, array_from_dataframe(midcase100_2026df, column_name_cambium))

# Mid Case 100 2028
midcase100_2028df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EYs5MxIKSttNhlMxIGF2BUIBhJd_B1mAHL-cp4UZVeAkIQ")
push!(scenario_data_all, array_from_dataframe(midcase100_2028df, column_name_cambium))

# Mid Case 100 2030
midcase100_2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EUKN9XQ-74BAgixylxmQwlYBEhW86vACOGARCYZZGcPdPA")
push!(scenario_data_all, array_from_dataframe(midcase100_2030df, column_name_cambium))

# Mid Case 100 2035
midcase100_2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ERtBJuXSwsBBp2hH63AslzoB7sCnK6bQZYNPtiLnCz6p1w")
push!(scenario_data_all, array_from_dataframe(midcase100_2035df, column_name_cambium))

# Mid Case 100 2040
midcase100_2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EfgeTMzKSj5Nr5WhbwgOTeMBkcTvT4MFHCpn8T8PQrN0bA")
push!(scenario_data_all, array_from_dataframe(midcase100_2040df, column_name_cambium))

# Mid Case 100 2045
midcase100_2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EdmWiQi0PclIn8ieapldzAoBuEj8YU_3MMHa_ELDSKFPMA")
push!(scenario_data_all, array_from_dataframe(midcase100_2045df, column_name_cambium))

# Mid Case 100 2050
midcase100_2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EU8hXGsSDOJOmbtgub28kD4Bbfl2ebJFev_nJo09vNljhg")
push!(scenario_data_all, array_from_dataframe(midcase100_2050df, column_name_cambium))

"""
Mid Case 95 by 2035 Scenarios Data
"""

# Mid Case 95 2024
midcase95_2024df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EXJQOUib6TVGmDNpRFiaCwcBVJaQGAEHWan_X65UMPXH8Q")
push!(scenario_data_all, array_from_dataframe(midcase95_2024df, column_name_cambium))

# Mid Case 95 2026
midcase95_2026df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EcY1X3Y5QjNEv0T-j0uADEkBEm3Vu8Z-qxCsHbqkcsdLwA")
push!(scenario_data_all, array_from_dataframe(midcase95_2026df, column_name_cambium))

# Mid Case 95 2028
midcase95_2028df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EcttazbTz9REr5swD1K20NwBdv_cJQn2Krr-x5mDwQitZw")
push!(scenario_data_all, array_from_dataframe(midcase95_2028df, column_name_cambium))

# Mid Case 95 2030
midcase95_2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EfKRtGz2rT9KjSTe2JgdT1cBo8GDRVryBD2IW3Mlu_AWaQ")
push!(scenario_data_all, array_from_dataframe(midcase95_2030df, column_name_cambium))

# Mid Case 95 2035
midcase95_2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EaRublfEzHpHknzxSCv0YPUBEuRGlQdNZuZwkT5BUotSUQ")
push!(scenario_data_all, array_from_dataframe(midcase95_2035df, column_name_cambium))

# Mid Case 95 2040
midcase95_2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EZ0WsVtzRWtMoOCZFIJ8PBEBL7R5NgIaNBHmwsYAygjZ8A")
push!(scenario_data_all, array_from_dataframe(midcase95_2040df, column_name_cambium))

# Mid Case 95 2045
midcase95_2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EXKBdutb3WVElbgrv8x6eLQBMGcTMmT0nqDKU807Zr6ryQ")
push!(scenario_data_all, array_from_dataframe(midcase95_2045df, column_name_cambium))

# Mid Case 95 2050
midcase95_2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ESxZILpDkH5InMhMy5npH30B1vvj5JhAEoriW4cTUfN8bA")
push!(scenario_data_all, array_from_dataframe(midcase95_2050df, column_name_cambium))

"""
Cambium 2023 Mid Case Scenarios Data
"""

# Mid Case 2025
c23_midcase2025df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/Ee_dil24J4RIvOn-7dpm1dABUnUbi-Xvx9iQA8XMw6xHgw")
push!(scenario_23_data_all, array_from_dataframe(c23_midcase2025df, column_name_cambium))

# Mid Case 2030
c23_midcase2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EUJ-5lnUpK5Jo2mRYVF_ArQBBbcg7qNcsthk5-Xtxv3rQA")
push!(scenario_23_data_all, array_from_dataframe(c23_midcase2030df, column_name_cambium))

# Mid Case 2035
c23_midcase2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EbS9lsUpCg1KniZEX5bE_ysB19oqA0B5Vgy-ajZZuSZauw")
push!(scenario_23_data_all, array_from_dataframe(c23_midcase2035df, column_name_cambium))

# Mid Case 2040
c23_midcase2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ES_fqhx7y-BLm8YYYhmaUwABHuieR74apoRwVKyMsn9yDg")
push!(scenario_23_data_all, array_from_dataframe(c23_midcase2040df, column_name_cambium))

# Mid Case 2045
c23_midcase2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EX69k344WvRMrS8sBJaPipgB66lugerF-i0nc35CEhL3Ew")
push!(scenario_23_data_all, array_from_dataframe(c23_midcase2045df, column_name_cambium))

# Mid Case 2050
c23_midcase2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EaBtDg_8fHRGk0X7-vi-LGABgjwGMz3l1Qv14cF0-BTIUw")
push!(scenario_23_data_all, array_from_dataframe(c23_midcase2050df, column_name_cambium))

"""
High Demand Growth
"""

# High Demand Growth 2025
highDemandGrowth_2025df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EWwkI-w8gT9Epula2tVhh0wBJQwwJBaeQAFZzjUY3nxOoA")
push!(scenario_23_data_all, array_from_dataframe(highDemandGrowth_2025df, column_name_cambium))

# High Demand Growth 2030
highDemandGrowth_2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ERiNhTSzmOhDqjiLCiaHn7sBBjYlrRKjXgefQiDY7qpCaA")
push!(scenario_23_data_all, array_from_dataframe(highDemandGrowth_2030df, column_name_cambium))

# High Demand Growth 2035
highDemandGrowth_2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EZV7PFFZk-JCoahRvGkfJ98BnJiHLu04hZdxyihkKSZlGg")
push!(scenario_23_data_all, array_from_dataframe(highDemandGrowth_2035df, column_name_cambium))

# High Demand Growth 2040
highDemandGrowth_2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EZOxg2pomMdCoQb5c32SWOcBDZ3pQk_9W5vprfUMlsC1SA")
push!(scenario_23_data_all, array_from_dataframe(highDemandGrowth_2040df, column_name_cambium))

# High Demand Growth 2045
highDemandGrowth_2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EVssLSWvRXdGjfW9sh04ocUBNtoUx6_TwSA-fcVOZ2cEXQ")
push!(scenario_23_data_all, array_from_dataframe(highDemandGrowth_2045df, column_name_cambium))

# High Demand Growth 2050
highDemandGrowth_2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ETNuOtlP9wFKjZRlr3q0LsoBdMfJea4jksL7S0UED3KJsQ")
push!(scenario_23_data_all, array_from_dataframe(highDemandGrowth_2050df, column_name_cambium))

"""
Cambium 2023 Mid Case 100
"""

# Mid Case 100 2025
c23_midcase1002025df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ERFt2j5nrFFGoAuAOeEs0kUBvAA23E5HNOQIi1q6QNl-lw")
push!(scenario_23_data_all, array_from_dataframe(c23_midcase1002025df, column_name_cambium))

# Mid Case 100 2030
c23_midcase1002030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EV7urTXMKQNInXPeoh5_RcYBmL1OHJo9ajsCFbp6W96T8g")
push!(scenario_23_data_all, array_from_dataframe(c23_midcase1002030df, column_name_cambium))

# Mid Case 100 2035
c23_midcase1002035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EdIV1NFNwS1FmzzGhEwPHLIBoD9og28AlennBpzD8ln1qQ")
push!(scenario_23_data_all, array_from_dataframe(c23_midcase1002035df, column_name_cambium))

# Mid Case 100 2040
c23_midcase1002040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EU3W70et4NFGgjQyqJAYSHsBo--lFxUs8P_PZnR5Hjax1Q")
push!(scenario_23_data_all, array_from_dataframe(c23_midcase1002040df, column_name_cambium))

# Mid Case 100 2045
c23_midcase1002045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/Ebne3e1viuhIriJNftEWVwUB8NH7tRfznvzlgq0lyzIxCA")
push!(scenario_23_data_all, array_from_dataframe(c23_midcase1002045df, column_name_cambium))

# Mid Case 100 2050
c23_midcase1002050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EWK3xaSh6T5LrxDRxnT9T4sB3CDSEwccOWEGgHm8wh39Mw")
push!(scenario_23_data_all, array_from_dataframe(c23_midcase1002050df, column_name_cambium))

"""
Cambium 2023 Mid Case 95
"""

# Mid Case 95 2025
c23_midcase952025df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EZgbgDRNOt1Cri5OdusEDM8BrLtuNePJ533r-SKJvz9xfw")
push!(scenario_23_data_all, array_from_dataframe(c23_midcase952025df, column_name_cambium))

# Mid Case 95 2030
c23_midcase952030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ERxt5GFEj2NGiqfFPfRStkMBBqF8yNopjAD22CheXQZYkw")
push!(scenario_23_data_all, array_from_dataframe(c23_midcase952030df, column_name_cambium))

# Mid Case 95 2035
c23_midcase952035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EcmaanIgNfBEpd71-MduPjMByWhOj9TAXKbUazS-5V10Mw")
push!(scenario_23_data_all, array_from_dataframe(c23_midcase952035df, column_name_cambium))

# Mid Case 95 2040
c23_midcase952040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EXtGBmCqoddAs2Snz5WxAUwByNQ1KZ-XMs2UTmeZZt7bpw")
push!(scenario_23_data_all, array_from_dataframe(c23_midcase952040df, column_name_cambium))

# Mid Case 95 2045
c23_midcase952045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EbquHgg00z1Pi1Q4Vazpm8EBYm5b96qMqUxPraVebcESpg")
push!(scenario_23_data_all, array_from_dataframe(c23_midcase952045df, column_name_cambium))

# Mid Case 95 2050
c23_midcase952050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EVjT_kE3hcNEum-KWGJGK0wBpV2ptiT4ZCv0QBxjcdQ39A")
push!(scenario_23_data_all, array_from_dataframe(c23_midcase952050df, column_name_cambium))

"""
Cambium 2023 Low RE Cost
"""

# Low RE Cost 2025
c23_lowRECost2025df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EQWfsSS6RyNHhBujsRWvRtEBdU_ftaFqug3_Y7ViRnxhVg")
push!(scenario_23_data_all, array_from_dataframe(c23_lowRECost2025df, column_name_cambium))

# Low RE Cost 2030
c23_lowRECost2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EduGB7JtBd1FrpNwUkaJ6EoB0OF9zEduXMRUWMVQ_YFeRw")
push!(scenario_23_data_all, array_from_dataframe(c23_lowRECost2030df, column_name_cambium))

# Low RE Cost 2035
c23_lowRECost2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EWclMNCRF4FDpjeM8p-g1hMBwUx9ev2RbXxTIAnhiWy-xg")
push!(scenario_23_data_all, array_from_dataframe(c23_lowRECost2035df, column_name_cambium))

# Low RE Cost 2040
c23_lowRECost2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EZhQ9oJWzwNKkP3wh5wLka4BQXLkQ_nB9S2tfG-yMEkGKQ")
push!(scenario_23_data_all, array_from_dataframe(c23_lowRECost2040df, column_name_cambium))

# Low RE Cost 2045
c23_lowRECost2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EXlYj4yzLkpOso-sHVj3880BP7SbBYh6mY7lsNJvNLm_yw")
push!(scenario_23_data_all, array_from_dataframe(c23_lowRECost2045df, column_name_cambium))

# Low RE Cost 2050
c23_lowRECost2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EcEz40nzRAJEjegg8I1xvHoB-_CIRl_Bu4FHVnuCAkVNPA")
push!(scenario_23_data_all, array_from_dataframe(c23_lowRECost2050df, column_name_cambium))

"""
2023 Cambium High Renewable Cost
"""

# High Renewable Cost 2025
c23_highRenewableCost2025df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/Ec-yAO6yPZ5Ot8agXTFo4pABSBChpPM0Ijv5H0Ij7FRvZQ")
push!(scenario_23_data_all, array_from_dataframe(c23_highRenewableCost2025df, column_name_cambium))

# High Renewable Cost 2030
c23_highRenewableCost2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EU5dEiDfWgpJrpsEOtPmYbIBH7BKwPrgdDkwAlVYyYyZTA")
push!(scenario_23_data_all, array_from_dataframe(c23_highRenewableCost2030df, column_name_cambium))

# High Renewable Cost 2035
c23_highRenewableCost2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EZejVH3qFJZJrMygCVGWeTEBXz9X0qruBf268Rxyv3npjQ")
push!(scenario_23_data_all, array_from_dataframe(c23_highRenewableCost2035df, column_name_cambium))

# High Renewable Cost 2040
c23_highRenewableCost2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ERtgqap8hRJLrmWkq4APhr4BOpR9_71y6J09CTR04FfRMA")
push!(scenario_23_data_all, array_from_dataframe(c23_highRenewableCost2040df, column_name_cambium))

# High Renewable Cost 2045
c23_highRenewableCost2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EfFASK0BV2lCvdHpsirsWWsB6bvrxWFUI4Sj1dnx-7CayA")
push!(scenario_23_data_all, array_from_dataframe(c23_highRenewableCost2045df, column_name_cambium))

# High Renewable Cost 2050
c23_highRenewableCost2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ETCFBpp7AIhNmgb20ir63PkBO8gXoyB8gP5qw9BHLfPZkA")
push!(scenario_23_data_all, array_from_dataframe(c23_highRenewableCost2050df, column_name_cambium))

"""
Cambium 2023 Low NG Prices
"""

# Low NG Prices 2025
c23_lowNGPrices2025df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EWkNhHiXJF1NvYX8VgpdbgkBMg5MiyOXiabPUY3Xo3odiw")
push!(scenario_23_data_all, array_from_dataframe(c23_lowNGPrices2025df, column_name_cambium))

# Low NG Prices 2030
c23_lowNGPrices2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ERO19A31V9JNuNnqq9_uzjABvGh1W3k9yhvdTF2TX9rEJg")
push!(scenario_23_data_all, array_from_dataframe(c23_lowNGPrices2030df, column_name_cambium))

# Low NG Prices 2035
c23_lowNGPrices2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EZDvaCQbrGBIp0ygEsrKL1kBF2JR8GUp4UqgBc3_2udV4w")
push!(scenario_23_data_all, array_from_dataframe(c23_lowNGPrices2035df, column_name_cambium))

# Low NG Prices 2040
c23_lowNGPrices2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/Eb0G7BOj471JpbbwzwNC6gABDdFsAlZ3r5z9USVaE7WBRA")
push!(scenario_23_data_all, array_from_dataframe(c23_lowNGPrices2040df, column_name_cambium))

# Low NG Prices 2045
c23_lowNGPrices2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ESnJinnHvzlGhN6nrlcLN-8BIRLSlzK0YPdjwZ68wADpuA")
push!(scenario_23_data_all, array_from_dataframe(c23_lowNGPrices2045df, column_name_cambium))

# Low NG Prices 2050
c23_lowNGPrices2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EacreUJkxUVFoC9NEayd1TUBoDi3gFz7VzNvR9_WaEREpg")
push!(scenario_23_data_all, array_from_dataframe(c23_lowNGPrices2050df, column_name_cambium))

"""
Cambium 2023 High NG Prices
"""

# High NG Prices 2025
c23_highNGPrices2025df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ESQOUfsVuYBGutw-mlfCHYMBZtCwqkS-FyYpmWAMslcJvQ")
push!(scenario_23_data_all, array_from_dataframe(c23_highNGPrices2025df, column_name_cambium))

# High NG Prices 2030
c23_highNGPrices2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EdMHbngeTixKr3BfkqSH53IB8jlP2KmY8_YfgTTmESvXWA")
push!(scenario_23_data_all, array_from_dataframe(c23_highNGPrices2030df, column_name_cambium))

# High NG Prices 2035
c23_highNGPrices2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ERXU2rRE8_hEtwgjlf7z5i0BUyTmYwfdvTayFMyVg8B_qA")
push!(scenario_23_data_all, array_from_dataframe(c23_highNGPrices2035df, column_name_cambium))

# High NG Prices 2040
c23_highNGPrices2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EeOVG1QnoFNLoUWk4xpz8p4BSOiTrXGIb4YDpQmfSvVNnA")
push!(scenario_23_data_all, array_from_dataframe(c23_highNGPrices2040df, column_name_cambium))

# High NG Prices 2045
c23_highNGPrices2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EU9OvtOnW1tPnqZB3qQRpQ4BaPRFk-9QcYc0LnJHeCETrA")
push!(scenario_23_data_all, array_from_dataframe(c23_highNGPrices2045df, column_name_cambium))

# High NG Prices 2050
c23_highNGPrices2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/Eds064PR_HpKldceez5XJdIBADFLdUUXfNaL1-7G7yQkng")
push!(scenario_23_data_all, array_from_dataframe(c23_highNGPrices2050df, column_name_cambium))


"""
PJM Ancillary Services Market Data

Columns:
datetime_beginning_utc	datetime_beginning_ept	locale	service	mcp	mcp_capped	reg_ccp	reg_pcp	as_req_mw	total_mw	as_mw	ss_mw	tier1_mw	ircmwt2	dsr_as_mw	nsr_mw	regd_mw
"""

# Defining the market price data column name
column_name_pjm_prices = "mcp"

# Defining the column name for the demand for ancillary services
column_name_pjm_demand = "as_req_mw"

# SR Market, Synchronized Reserves Market, from PJM Ancillary Services
pjmsrmarket_df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EQ_vSY-29sBCoMtftn6xzRYBSzSwjzb8TexXnWTeOJJnDg")
push!(ancillary_services_prices, array_from_dataframe(pjmsrmarket_df, column_name_pjm_prices))
push!(ancillary_services_demand, array_from_dataframe(pjmsrmarket_df, column_name_pjm_demand))

# REG Market, Regulation Market, from PJM Ancillary Services
pjmregmarket_df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EWlblX180JVNnKKPvUWD2-YB9vO02eUc4OGzEqJDq67SgQ")
push!(ancillary_services_prices, array_from_dataframe(pjmregmarket_df, column_name_pjm_prices))
push!(ancillary_services_demand, array_from_dataframe(pjmregmarket_df, column_name_pjm_demand))

# PR Market, Primary Reserves Market, from PJM Ancillary Services
pjmprmarket_df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EW9ws1YklENEqhGsueZrLIgBqvr4OZGdfic9-DZYSmin5A")
push!(ancillary_services_prices, array_from_dataframe(pjmprmarket_df, column_name_pjm_prices))
push!(ancillary_services_demand, array_from_dataframe(pjmprmarket_df, column_name_pjm_demand))

# 30 Minute Market, Thirty-Minutes Market, from PJM Ancillary Services
pjm30minmarket_df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EbaEquVOgitClt-84vznxjwB_rUkrx0AiArfQdnhwVyQDg")
push!(ancillary_services_prices, array_from_dataframe(pjm30minmarket_df, column_name_pjm_prices))
push!(ancillary_services_demand, array_from_dataframe(pjm30minmarket_df, column_name_pjm_demand))

# Plot the data
# plot(
#     nyiso_capacity_market_data."Auction Month",
#     nyiso_capacity_market_data."Default Reference Price (\$/kW-month)",
#     xlabel = "Auction Month",
#     ylabel = "Default Reference Price (\$/kW-month)",
#     title = "Default Reference Prices NYC",
#     legend = false,
#     linewidth = 2,
#     color = :blue
# )


"""
Adding in the NYISO Capacity Market Data
"""
# Source: http://icap.nyiso.com/ucap/public/auc_view_default_reference_price_detail.do

# Create DataFrame with the provided data
nyiso_capacity_market_data = DataFrame(
    "Auction Month" => Date[
        Date("11/2020", "mm/yyyy"), Date("12/2020", "mm/yyyy"), Date("01/2021", "mm/yyyy"), Date("02/2021", "mm/yyyy"), Date("03/2021", "mm/yyyy"), Date("04/2021", "mm/yyyy"),
        Date("05/2021", "mm/yyyy"), Date("06/2021", "mm/yyyy"), Date("07/2021", "mm/yyyy"), Date("08/2021", "mm/yyyy"), Date("09/2021", "mm/yyyy"), Date("10/2021", "mm/yyyy"),
        Date("11/2021", "mm/yyyy"), Date("12/2021", "mm/yyyy"), Date("01/2022", "mm/yyyy"), Date("02/2022", "mm/yyyy"), Date("03/2022", "mm/yyyy"), Date("04/2022", "mm/yyyy"),
        Date("05/2022", "mm/yyyy"), Date("06/2022", "mm/yyyy"), Date("07/2022", "mm/yyyy"), Date("08/2022", "mm/yyyy"), Date("09/2022", "mm/yyyy"), Date("10/2022", "mm/yyyy"),
        Date("11/2022", "mm/yyyy"), Date("12/2022", "mm/yyyy"), Date("01/2023", "mm/yyyy"), Date("02/2023", "mm/yyyy"), Date("03/2023", "mm/yyyy"), Date("04/2023", "mm/yyyy"),
        Date("05/2023", "mm/yyyy"), Date("06/2023", "mm/yyyy"), Date("07/2023", "mm/yyyy"), Date("08/2023", "mm/yyyy"), Date("09/2023", "mm/yyyy"), Date("10/2023", "mm/yyyy"),
        Date("11/2023", "mm/yyyy"), Date("12/2023", "mm/yyyy"), Date("01/2024", "mm/yyyy"), Date("02/2024", "mm/yyyy"), Date("03/2024", "mm/yyyy"), Date("04/2024", "mm/yyyy"),
        Date("05/2024", "mm/yyyy"), Date("06/2024", "mm/yyyy"), Date("07/2024", "mm/yyyy"),
        Date("11/2018", "mm/yyyy"), Date("12/2018", "mm/yyyy"), Date("01/2019", "mm/yyyy"), Date("02/2019", "mm/yyyy"), Date("03/2019", "mm/yyyy"), Date("04/2019", "mm/yyyy"),
        Date("05/2019", "mm/yyyy"), Date("06/2019", "mm/yyyy"), Date("07/2019", "mm/yyyy"), Date("08/2019", "mm/yyyy"), Date("09/2019", "mm/yyyy"), Date("10/2019", "mm/yyyy"),
        Date("11/2019", "mm/yyyy"), Date("12/2019", "mm/yyyy"), Date("01/2020", "mm/yyyy"), Date("02/2020", "mm/yyyy"), Date("03/2020", "mm/yyyy"), Date("04/2020", "mm/yyyy"),
        Date("05/2020", "mm/yyyy"), Date("06/2020", "mm/yyyy"), Date("07/2020", "mm/yyyy"), Date("08/2020", "mm/yyyy"), Date("09/2020", "mm/yyyy"), Date("10/2020", "mm/yyyy"),
        Date("11/2016", "mm/yyyy"), Date("12/2016", "mm/yyyy"), Date("01/2017", "mm/yyyy"), Date("02/2017", "mm/yyyy"), Date("03/2017", "mm/yyyy"), Date("04/2017", "mm/yyyy"),
        Date("05/2017", "mm/yyyy"), Date("06/2017", "mm/yyyy"), Date("07/2017", "mm/yyyy"), Date("08/2017", "mm/yyyy"), Date("09/2017", "mm/yyyy"), Date("10/2017", "mm/yyyy"),
        Date("11/2017", "mm/yyyy"), Date("12/2017", "mm/yyyy"), Date("01/2018", "mm/yyyy"), Date("02/2018", "mm/yyyy"), Date("03/2018", "mm/yyyy"), Date("04/2018", "mm/yyyy"),
        Date("05/2018", "mm/yyyy"), Date("06/2018", "mm/yyyy"), Date("07/2018", "mm/yyyy"), Date("08/2018", "mm/yyyy"), Date("09/2018", "mm/yyyy"), Date("10/2018", "mm/yyyy")
    ],
    "Default Reference Price (USD/kW-month)" => [
        8.31, 8.22, 8.15, 8.38, 8.34, 8.19,
        5.02, 4.88, 4.84, 4.88, 4.87, 4.87,
        0.00, 0.00, 0.00, 0.00, 0.00, 0.00,
        3.22, 3.13, 3.12, 2.82, 2.82, 2.89,
        0.00, 0.00, 0.00, 0.00, 0.00, 0.00,
        18.47, 18.57, 19.46, 19.46, 19.45, 19.25,
        12.71, 12.65, 12.63, 12.66, 12.66, 12.77,
        14.33, 14.24, 14.21,
        0.00, 0.00, 0.00, 0.00, 0.00, 0.00,
        13.59, 13.46, 13.46, 13.37, 13.33, 13.07,
        3.51, 3.50, 3.22, 3.22, 3.23, 2.98,
        18.86, 18.98, 18.89, 18.57, 18.46, 18.01,
        1.29, 1.26, 1.12, 1.06, 0.76, 0.63,
        10.52, 10.21, 9.85, 9.83, 9.76, 9.48,
        0.00, 0.00, 0.00, 0.00, 0.00, 1.82,
        9.46, 9.29, 9.23, 7.66, 7.66, 7.57
    ]
)

new_entries = DataFrame(
    "Auction Month" => Date[
        Date("05/2008", "mm/yyyy"), Date("06/2008", "mm/yyyy"), Date("07/2008", "mm/yyyy"), Date("08/2008", "mm/yyyy"), Date("09/2008", "mm/yyyy"), Date("10/2008", "mm/yyyy"),
        Date("11/2008", "mm/yyyy"), Date("12/2008", "mm/yyyy"), Date("01/2009", "mm/yyyy"), Date("02/2009", "mm/yyyy"), Date("03/2009", "mm/yyyy"), Date("04/2009", "mm/yyyy"),
        Date("05/2009", "mm/yyyy"), Date("06/2009", "mm/yyyy"), Date("07/2009", "mm/yyyy"), Date("08/2009", "mm/yyyy"), Date("09/2009", "mm/yyyy"), Date("10/2009", "mm/yyyy"),
        Date("11/2009", "mm/yyyy"), Date("12/2009", "mm/yyyy"), Date("01/2010", "mm/yyyy"), Date("02/2010", "mm/yyyy"), Date("03/2010", "mm/yyyy"), Date("04/2010", "mm/yyyy"),
        Date("05/2010", "mm/yyyy"), Date("06/2010", "mm/yyyy"), Date("07/2010", "mm/yyyy"), Date("08/2010", "mm/yyyy"), Date("09/2010", "mm/yyyy"), Date("10/2010", "mm/yyyy"),
        Date("11/2010", "mm/yyyy"), Date("12/2010", "mm/yyyy"), Date("01/2011", "mm/yyyy"), Date("02/2011", "mm/yyyy"), Date("03/2011", "mm/yyyy"), Date("04/2011", "mm/yyyy"),
        Date("05/2011", "mm/yyyy"), Date("06/2011", "mm/yyyy"), Date("07/2011", "mm/yyyy"), Date("08/2011", "mm/yyyy"), Date("09/2011", "mm/yyyy"), Date("10/2011", "mm/yyyy"),
        Date("11/2011", "mm/yyyy"), Date("12/2011", "mm/yyyy"), Date("01/2012", "mm/yyyy"), Date("02/2012", "mm/yyyy"), Date("03/2012", "mm/yyyy"), Date("04/2012", "mm/yyyy"),
        Date("05/2012", "mm/yyyy"), Date("06/2012", "mm/yyyy"), Date("07/2012", "mm/yyyy"), Date("08/2012", "mm/yyyy"), Date("09/2012", "mm/yyyy"), Date("10/2012", "mm/yyyy")
    ],
    "Default Reference Price (USD/kW-month)" => [
        5.36, 5.85, 6.26, 6.14, 5.85, 5.78,
        0.00, 0.00, 0.00, 0.00, 0.00, 0.27,
        8.64, 8.62, 8.46, 8.24, 7.64, 7.69,
        0.88, 0.57, 0.08, 7.48, 7.49, 6.99,
        13.32, 13.00, 12.90, 12.82, 12.35, 12.58,
        3.81, 3.49, 3.46, 3.44, 3.43, 3.04,
        11.69, 11.51, 5.49, 5.45, 5.04, 6.50,
        0.00, 0.00, 0.00, 0.00, 0.00, 0.00,
        16.33, 11.10, 10.51, 10.34, 10.13, 10.11
    ]
)

new_data = DataFrame(
    "Auction Month" => Date[
        Date("05/2008", "mm/yyyy"), Date("06/2008", "mm/yyyy"), Date("07/2008", "mm/yyyy"), Date("08/2008", "mm/yyyy"), Date("09/2008", "mm/yyyy"), Date("10/2008", "mm/yyyy"),
        Date("11/2008", "mm/yyyy"), Date("12/2008", "mm/yyyy"), Date("01/2009", "mm/yyyy"), Date("02/2009", "mm/yyyy"), Date("03/2009", "mm/yyyy"), Date("04/2009", "mm/yyyy"),
        Date("05/2009", "mm/yyyy"), Date("06/2009", "mm/yyyy"), Date("07/2009", "mm/yyyy"), Date("08/2009", "mm/yyyy"), Date("09/2009", "mm/yyyy"), Date("10/2009", "mm/yyyy"),
        Date("11/2009", "mm/yyyy"), Date("12/2009", "mm/yyyy"), Date("01/2010", "mm/yyyy"), Date("02/2010", "mm/yyyy"), Date("03/2010", "mm/yyyy"), Date("04/2010", "mm/yyyy"),
        Date("05/2010", "mm/yyyy"), Date("06/2010", "mm/yyyy"), Date("07/2010", "mm/yyyy"), Date("08/2010", "mm/yyyy"), Date("09/2010", "mm/yyyy"), Date("10/2010", "mm/yyyy"),
        Date("11/2010", "mm/yyyy"), Date("12/2010", "mm/yyyy"), Date("01/2011", "mm/yyyy"), Date("02/2011", "mm/yyyy"), Date("03/2011", "mm/yyyy"), Date("04/2011", "mm/yyyy"),
        Date("05/2011", "mm/yyyy"), Date("06/2011", "mm/yyyy"), Date("07/2011", "mm/yyyy"), Date("08/2011", "mm/yyyy"), Date("09/2011", "mm/yyyy"), Date("10/2011", "mm/yyyy"),
        Date("11/2011", "mm/yyyy"), Date("12/2011", "mm/yyyy"), Date("01/2012", "mm/yyyy"), Date("02/2012", "mm/yyyy"), Date("03/2012", "mm/yyyy"), Date("04/2012", "mm/yyyy"),
        Date("05/2012", "mm/yyyy"), Date("06/2012", "mm/yyyy"), Date("07/2012", "mm/yyyy"), Date("08/2012", "mm/yyyy"), Date("09/2012", "mm/yyyy"), Date("10/2012", "mm/yyyy"),
        Date("11/2012", "mm/yyyy"), Date("12/2012", "mm/yyyy"), Date("01/2013", "mm/yyyy"), Date("02/2013", "mm/yyyy"), Date("03/2013", "mm/yyyy"), Date("04/2013", "mm/yyyy"),
        Date("05/2013", "mm/yyyy"), Date("06/2013", "mm/yyyy"), Date("07/2013", "mm/yyyy"), Date("08/2013", "mm/yyyy"), Date("09/2013", "mm/yyyy"), Date("10/2013", "mm/yyyy"),
        Date("11/2013", "mm/yyyy"), Date("12/2013", "mm/yyyy"), Date("01/2014", "mm/yyyy"), Date("02/2014", "mm/yyyy"), Date("03/2014", "mm/yyyy"), Date("04/2014", "mm/yyyy"),
        Date("05/2014", "mm/yyyy"), Date("06/2014", "mm/yyyy"), Date("07/2014", "mm/yyyy"), Date("08/2014", "mm/yyyy"), Date("09/2014", "mm/yyyy"), Date("10/2014", "mm/yyyy"),
        Date("11/2014", "mm/yyyy"), Date("12/2014", "mm/yyyy"), Date("01/2015", "mm/yyyy"), Date("02/2015", "mm/yyyy"), Date("03/2015", "mm/yyyy"), Date("04/2015", "mm/yyyy"),
        Date("05/2015", "mm/yyyy"), Date("06/2015", "mm/yyyy"), Date("07/2015", "mm/yyyy"), Date("08/2015", "mm/yyyy"), Date("09/2015", "mm/yyyy"), Date("10/2015", "mm/yyyy"),
        Date("11/2015", "mm/yyyy"), Date("12/2015", "mm/yyyy"), Date("01/2016", "mm/yyyy"), Date("02/2016", "mm/yyyy"), Date("03/2016", "mm/yyyy"), Date("04/2016", "mm/yyyy"),
        Date("05/2016", "mm/yyyy"), Date("06/2016", "mm/yyyy"), Date("07/2016", "mm/yyyy"), Date("08/2016", "mm/yyyy"), Date("09/2016", "mm/yyyy"), Date("10/2016", "mm/yyyy")
    ],
    "Default Reference Price (USD/kW-month)" => [
        5.36, 5.85, 6.26, 6.14, 5.85, 5.78,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.27,
        8.64, 8.62, 8.46, 8.24, 7.64, 7.69,
        0.88, 0.57, 0.08, 7.48, 7.49, 6.99,
        13.32, 13.00, 12.90, 12.82, 12.35, 12.58,
        3.81, 3.49, 3.46, 3.44, 3.43, 3.04,
        11.69, 11.51, 5.49, 5.45, 5.04, 6.50,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        16.33, 11.10, 10.51, 10.34, 10.13, 10.11,
        2.86, 2.75, 2.69, 2.21, 2.15, 2.22,
        15.69, 16.37, 15.98, 15.60, 15.51, 15.42,
        9.98, 9.67, 9.60, 9.53, 9.54, 9.61,
        18.67, 18.76, 18.63, 18.44, 18.06, 17.81,
        8.86, 8.81, 8.75, 8.71, 6.98, 6.99,
        15.96, 15.36, 14.88, 15.18, 14.74, 14.67,
        6.11, 6.16, 5.81, 5.80, 5.79, 5.58,
        12.30, 12.19, 12.19, 12.16, 12.16, 12.01
    ]
)

# Append the new data to the existing DataFrame
append!(nyiso_capacity_market_data, new_data)
append!(nyiso_capacity_market_data, new_entries)

# Sort the DataFrame by "Auction Month"
sort!(nyiso_capacity_market_data, "Auction Month")

nyiso_capacity_market_data = combine(groupby(nyiso_capacity_market_data, :"Auction Month"), "Default Reference Price (USD/kW-month)" => first)



# println(nyiso_capacity_market_data)
# println("")
# test_cycle = capacity_market_nyiso_scenario(nyiso_capacity_market_data, 60)

# println(test_cycle)
# println(length(test_cycle))

"""
Adding in the MISO Capacity Market Data
"""

# Local_Balancing_Authorities = [
#     "DPC, GRE, MDU, MP, NSP, OTP, SMP",
#     "ALTE, MGE, UPPC, WEC, WPS, MIUP",
#     "ALTW, MEC, MPW",
#     "AMIL, CWLP, SIPC",
#     "AMMO, CWLD",
#     "BREC, CIN, HE, IPL, NIPS, SIGE",
#     "CONS, DECO",
#     "EAI",
#     "CLEC, EES, LAFA, LAGN, LEPA",
#     "EMBA, SME",
#     "SPP, PJM, OVEC, LGEE, AECI, SPA, TVA"
# ],

# Data from the images
miso_capacity_market_prices_old = DataFrame(
    Zone = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "ERZ"],
    Price_2019_2020 = [2.99, 2.99, 2.99, 2.99, 2.99, 2.99, 24.30, 2.99, 2.99, 2.99, 2.99],
    Price_2020_2021 = [5.00, 5.00, 5.00, 5.00, 5.00, 5.00, 5.00, 0.01, 0.01, 0.01, 2.78],
    Price_2021_2022 = [5.00, 5.00, 5.00, 5.00, 5.00, 5.00, 5.00, 0.01, 0.01, 0.01, 2.78],
    Price_2022_2023 = [236.66, 236.66, 236.66, 236.66, 236.66, 236.66, 236.66, 2.88, 2.88, 2.88, 133.70]
)

# Seasonal Prices DataFrame
miso_new_cap_market_prices = DataFrame(
    Zone = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "ERZ"],
    Price_Summer_2023 = [10.00, 10.00, 10.00, 10.00, 10.00, 10.00, 10.00, 10.00, 10.00, 10.00, 10.00],
    Price_Fall_2023 = [15.00, 15.00, 15.00, 15.00, 15.00, 15.00, 15.00, 15.00, 59.21, 15.00, 15.00],
    Price_Winter_2023 = [2.00, 2.00, 2.00, 2.00, 2.00, 2.00, 2.00, 2.00, 18.88, 2.00, 2.00],
    Price_Spring_2023 = [10.00, 10.00, 10.00, 10.00, 10.00, 10.00, 10.00, 10.00, 10.00, 10.00, 10.00],
    Price_Summer_2024 = [30.00, 30.00, 30.00, 30.00, 30.00, 30.00, 30.00, 30.00, 30.00, 30.00, 30.00],
    Price_Fall_2024 = [15.00, 15.00, 15.00, 15.00, 719.81, 15.00, 15.00, 15.00, 15.00, 15.00, 15.00],
    Price_Winter_2024 = [0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75],
    Price_Spring_2024 = [34.10, 34.10, 34.10, 34.10, 719.81, 34.10, 34.10, 34.10, 34.10, 34.10, 34.10]
)

# test_cycle = capacity_market_misoold_scenario(miso_capacity_market_prices_old, 60)

# println(test_cycle)
# println(length(test_cycle))

# test_cycle = capacity_market_misoseasonal_scenario(miso_new_cap_market_prices, 60)
# println(test_cycle)
# println(length(test_cycle))

#display(miso_capacity_market_acp)

###### Plotting the MISO data
# Plotting the miso_capacity_market_prices_old DataFrame
# plot1 = plot(
#     miso_capacity_market_prices_old.Zone,
#     [miso_capacity_market_prices_old.Price_2019_2020, miso_capacity_market_prices_old.Price_2020_2021, miso_capacity_market_prices_old.Price_2021_2022, miso_capacity_market_prices_old.Price_2022_2023],
#     xlabel="Zone",
#     ylabel="Price (\$/MW-Day)",
#     title="MISO Capacity Market Prices (2019-2023)",
#     labels=["2019-2020" "2020-2021" "2021-2022" "2022-2023"],
#     lw=2,
#     markershape=:circle
# )

# # Plotting the miso_new_cap_market_prices DataFrame
# plot2 = plot(
#     miso_new_cap_market_prices.Zone,
#     [miso_new_cap_market_prices.Price_Summer_2023, miso_new_cap_market_prices.Price_Fall_2023, miso_new_cap_market_prices.Price_Winter_2023, miso_new_cap_market_prices.Price_Spring_2023, miso_new_cap_market_prices.Price_Summer_2024, miso_new_cap_market_prices.Price_Fall_2024, miso_new_cap_market_prices.Price_Winter_2024, miso_new_cap_market_prices.Price_Spring_2024],
#     xlabel="Zone",
#     ylabel="Price (\$/MW-Day)",
#     title="MISO Seasonal Capacity Market Prices (2023-2024)",
#     labels=["Summer 2023" "Fall 2023" "Winter 2023" "Spring 2023" "Summer 2024" "Fall 2024" "Winter 2024" "Spring 2024"],
#     lw=2,
#     markershape=:circle
# )

# Display plots
#plot(plot1, plot2, layout=(2, 1))


"""
ISO-NE Capacity Market Data
"""
# Corrected data from the images
date = [
    "6/1/2011", "6/1/2012", "6/1/2013", "6/1/2014", "6/1/2015", "6/1/2016", "6/1/2017", "6/1/2018", "6/1/2019", "6/1/2020",
    "6/1/2021", "6/1/2022", "6/1/2023", "6/1/2024", "6/1/2025", "6/1/2026", "6/1/2027",
    "6/1/2011", "6/1/2012", "6/1/2013", "6/1/2014", "6/1/2015", "6/1/2016", "6/1/2017", "6/1/2018", "6/1/2019", "6/1/2020",
    "6/1/2021", "6/1/2022", "6/1/2023", "6/1/2024", "6/1/2025", "6/1/2026", "6/1/2027"
]
zone_name = [
    "Rest-of-Pool", "Rest-of-Pool", "Rest-of-Pool", "Rest-of-Pool", "Rest-of-Pool", "Rest-of-Pool", "Rest-of-Pool", "Rest-of-Pool", "Rest-of-Pool", "Rest-of-Pool",
    "Rest-of-Pool", "Rest-of-Pool", "Rest-of-Pool", "Rest-of-Pool", "Rest-of-Pool", "Rest-of-Pool", "Rest-of-Pool",
    "Maine", "Maine", "Maine", "Maine", "Maine", "Maine", "Maine", "Maine", "Maine", "Maine",
    "Maine", "Maine", "Maine", "Maine", "Maine", "Maine", "Maine"
]
clearing_price = [
    3.600, 2.951, 2.951, 3.209, 3.434, 3.150, 15.000, 9.551, 7.030, 5.297,
    4.631, 3.800, 2.001, 2.477, 2.591, 2.590, 3.580,
    2.951, 2.951, 2.951, 3.209, 3.434, 3.150, 15.000, 9.551, 7.030, 5.297,
    4.631, 3.800, 2.001, 2.477, 2.591, 2.590, 3.580
]

iso_ne_capacity_market = DataFrame(Date=date, Zone_Name=zone_name, Clearing_Price=clearing_price)

# Display the DataFrame
#println(iso_ne_capacity_market)

# Convert Date to a Date type
iso_ne_capacity_market.Date = Date.(iso_ne_capacity_market.Date, "m/d/yyyy")

# # Example usage
# lifetime_years = 60
# price_array = capacity_market_iso_ne_scenario(lifetime_years, iso_ne_capacity_market)
# println(price_array)
# println(length(price_array))

# # Initialize the plot
# p = plot()

# # Add each zone's data to the plot
# for zone in unique(iso_ne_capacity_market.Zone_Name)
#     zone_data = iso_ne_capacity_market[iso_ne_capacity_market.Zone_Name .== zone, :]
#     plot!(p, zone_data.Date, zone_data.Clearing_Price, label=zone, marker=:auto, linewidth=2)
# end

# # Set labels and title
# xlabel!("Date")
# ylabel!("Clearing Price (\$/kW-Month)")
# title!("ISO-NE Clearing Prices by Zone Over Time")

# # Show the plot with legend
# plot!(p, legend=:topright)

# # Display the plot
# display(p)



"""
PJM Capacity Market Data
"""

# Source: Default Gross ACR for MOPR (2026/2027) - PJM, Spreadsheet: https://pjm.com/-/media/markets-ops/rpm/rpm-auction-info/2026-2027/2026-2027-acr-rates.ashx
# Source: Default Gross ACR for MOPR (2026/2027) - PJM, Spreadsheet: https://pjm.com/-/media/markets-ops/rpm/rpm-auction-info/2026-2027/2026-2027-acr-rates.ashx
# Data extracted from the image
pjm_capacity_market = Dict(
    "Delivery_Year" => [
        "2007/2008", "2008/2009", "2009/2010", "2010/2011", "2011/2012", 
        "2012/2013", "2013/2014", "2014/2015", "2015/2016", "2016/2017", 
        "2017/2018", "2018/2019", "2019/2020", "2020/2021", "2021/2022", 
        "2022/2023", "2023/2024", "2024/2025", "2025/2026"
    ],
    "Resource_Clearing_Price" => [
        40.80, 111.92, 102.04, 174.29, 110.00, 
        16.46, 27.73, 125.99, 136.00, 59.37, 
        120.00, 164.77, 100.00, 76.53, 140.00, 
        50.00, 34.13, 28.92, 269.92
    ]
)

# Create DataFrame
pjm_capacity_markets_prices = DataFrame(pjm_capacity_market)

# test_cycle = capacity_market_pjm_scenario(pjm_capacity_markets_prices, 60)

# println(test_cycle)
# println(length(test_cycle))

# Display the DataFrame to the user
#println(pjm_capacity_markets_prices)

# Plotting the data
# plot(pjm_capacity_markets_prices.Delivery_Year, pjm_capacity_markets_prices.Resource_Clearing_Price, 
#      marker=:circle, linestyle=:solid, color=:blue, 
#      title="PJM Resource Clearing Price Over Years", 
#      xlabel="Delivery Year", ylabel="Resource Clearing Price (\$/MW-day)", 
#      xticks=1:length(pjm_capacity_markets_prices.Delivery_Year), xrotation=45, 
#      grid=true, legend=false)

"""
The following function returns all the scenarios used as price arrays for the SMR dispatch
"""
function get_all_scenario_prices_smr()::Vector{Dict{String, Any}}
    scenario_price_data_all = []

    scenario_price_data_temp = []

    for (index2, cost_array) in enumerate(smr_cost_vals)
        if index2 < 20
            smr_lifetime = Int64(cost_array[2])
            construction_duration = cost_array[7]
        else
            smr_lifetime = Int64(cost_array[2])
            construction_duration = cost_array[8]
        end

        start_reactor = Int(ceil((construction_duration)/12))

        for (index3, scenario) in enumerate(scenario_data_all)
            if index3 == 1 || index3 == 2 || index3 == 3
                scenario_dict = Dict(
                    "smr" =>  "$(smr_names[index2])",
                    "scenario" => "$(scenario_names_combined[index3])",
                    "data" => create_scenario_array(scenario, scenario, scenario, scenario, scenario, scenario, scenario, scenario, (smr_lifetime + start_reactor))
                )

                push!(scenario_price_data_all, scenario_dict)
                continue
            end

            if length(scenario_price_data_temp) == 8
                scen_names_combined_index = Int((index3 - 4)/8)
                scenario_dict = Dict(
                    "smr" =>  "$(smr_names[index2])",
                    "scenario" => "$(scenario_names_combined[scen_names_combined_index])",
                    "data" => create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (smr_lifetime + start_reactor))
                )

                push!(scenario_price_data_all, scenario_dict)
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end

        scenario_dict = Dict(
            "smr" =>  "$(smr_names[index2])",
            "scenario" => "$(last(scenario_names_combined))",
            "data" => create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (smr_lifetime + start_reactor))
        )

        push!(scenario_price_data_all, scenario_dict)
        empty!(scenario_price_data_temp)
    end

    # Resetting the temporary array
    scenario_price_data_temp = []

    for (index2, cost_array) in enumerate(smr_cost_vals)
        if index2 < 20
            smr_lifetime = Int64(cost_array[2])
            construction_duration = cost_array[7]
        else
            smr_lifetime = Int64(cost_array[2])
            construction_duration = cost_array[8]
        end

        start_reactor = Int(ceil((construction_duration)/12))

        for (index3, scenario) in enumerate(scenario_23_data_all)
            if length(scenario_price_data_temp) == 6
                scen_names_combined_index = Int((index3 - 1)/6)
                scenario_dict = Dict(
                    "smr" =>  "$(smr_names[index2])",
                    "scenario" => "$(scenario_names_23cambium[scen_names_combined_index])",
                    "data" => create_scenario_interpolated_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], (smr_lifetime + start_reactor))
                )

                push!(scenario_price_data_all, scenario_dict)
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end

        scenario_dict = Dict(
            "smr" =>  "$(smr_names[index2])",
            "scenario" => "$(last(scenario_names_23cambium))",
            "data" => create_scenario_interpolated_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], (smr_lifetime + start_reactor))
        )

        push!(scenario_price_data_all, scenario_dict)
        empty!(scenario_price_data_temp)
        
    end

    return scenario_price_data_all
end


"""
The following function imports in the results from the case analysis, and stores them in a dictionary.
Returned is an array of dictionaries of all the cases
"""
function get_results_all_cases()
    # Creating an array to hold dictionaries for all cases
    all_cases = []

    # Baseline
    baseline_dict = Dict(
        "Scenario" => "Baseline", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/baseline/baseline_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/baseline/baseline_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/baseline/baseline_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/baseline/baseline_npv_final.csv"))
    )
    push!(all_cases, baseline_dict)

    # Coal2Nuclear
    c2n_dict = Dict(
        "Scenario" => "C2N", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline/c2n_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline/c2n_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline/c2n_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/c2n_baseline/c2n_npv_final.csv"))
    )
    push!(all_cases, c2n_dict)

    # Multi-Module Learning
    multi_module_dict = Dict(
        "Scenario" => "Multi-Module Learning", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/mmlearning_baseline/mmlearning_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/mmlearning_baseline/mmlearning_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/mmlearning_baseline/mmlearning_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/mmlearning_baseline/mmlearning_npv_final.csv"))
    )
    push!(all_cases, multi_module_dict)

    # ITC 6%
    itc_6_dict = Dict(
        "Scenario" => "ITC 6%", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline/itc_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline/itc_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline/itc_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc_baseline/itc_npv_final.csv"))
    )
    push!(all_cases, itc_6_dict)

    # ITC 30%
    itc_30_dict = Dict(
        "Scenario" => "ITC 30%", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline/itc30_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline/itc30_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline/itc30_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc30_baseline/itc30_npv_final.csv"))
    )
    push!(all_cases, itc_30_dict)

    # ITC 40%
    itc_40_dict = Dict(
        "Scenario" => "ITC 40%", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc40_baseline/itc40_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc40_baseline/itc40_breakeven.csv"))
    )
    push!(all_cases, itc_40_dict)

    # ITC 50%
    itc_50_dict = Dict(
        "Scenario" => "ITC 50%", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc50_baseline/itc50_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc50_baseline/itc50_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc50_baseline/itc50_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/itc50_baseline/itc50_npv_final.csv"))
    )
    push!(all_cases, itc_50_dict)

    # PTC $11/MWh
    ptc_11_dict = Dict(
        "Scenario" => "PTC \$11/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline/ptc11_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline/ptc11_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline/ptc11_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc11_baseline/ptc11_npv_final.csv"))
    )
    push!(all_cases, ptc_11_dict)

    # PTC $12/MWh
    ptc_12_dict = Dict(
        "Scenario" => "PTC \$12/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc12_baseline/ptc12_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc12_baseline/ptc12_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc12_baseline/ptc12_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc12_baseline/ptc12_npv_final.csv"))
    )
    push!(all_cases, ptc_12_dict)

    # PTC $13/MWh
    ptc_13_dict = Dict(
        "Scenario" => "PTC \$13/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc13_baseline/ptc13_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc13_baseline/ptc13_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc13_baseline/ptc13_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc13_baseline/ptc13_npv_final.csv"))
    )
    push!(all_cases, ptc_13_dict)

    # PTC $14/MWh
    ptc_14_dict = Dict(
        "Scenario" => "PTC \$14/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc14_baseline/ptc14_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc14_baseline/ptc14_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc14_baseline/ptc14_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc14_baseline/ptc14_npv_final.csv"))
    )
    push!(all_cases, ptc_14_dict)

    # PTC $15/MWh
    ptc_15_dict = Dict(
        "Scenario" => "PTC \$15/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc15_baseline/ptc15_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc15_baseline/ptc15_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc15_baseline/ptc15_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc15_baseline/ptc15_npv_final.csv"))
    )
    push!(all_cases, ptc_15_dict)

    # PTC $16/MWh
    ptc_16_dict = Dict(
        "Scenario" => "PTC \$16/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc16_baseline/ptc16_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc16_baseline/ptc16_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc16_baseline/ptc16_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc16_baseline/ptc16_npv_final.csv"))
    )
    push!(all_cases, ptc_16_dict)

    # PTC $17/MWh
    ptc_17_dict = Dict(
        "Scenario" => "PTC \$17/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc17_baseline/ptc17_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc17_baseline/ptc17_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc17_baseline/ptc17_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc17_baseline/ptc17_npv_final.csv"))
    )
    push!(all_cases, ptc_17_dict)

    # PTC $18/MWh
    ptc_18_dict = Dict(
        "Scenario" => "PTC \$18/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc18_baseline/ptc18_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc18_baseline/ptc18_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc18_baseline/ptc18_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc18_baseline/ptc18_npv_final.csv"))
    )
    push!(all_cases, ptc_18_dict)

    # PTC $19/MWh
    ptc_19_dict = Dict(
        "Scenario" => "PTC \$19/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc19_baseline/ptc19_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc19_baseline/ptc19_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc19_baseline/ptc19_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc19_baseline/ptc19_npv_final.csv"))
    )
    push!(all_cases, ptc_19_dict)

    # PTC $20/MWh
    ptc_20_dict = Dict(
        "Scenario" => "PTC \$20/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc20_baseline/ptc20_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc20_baseline/ptc20_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc20_baseline/ptc20_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc20_baseline/ptc20_npv_final.csv"))
    )
    push!(all_cases, ptc_20_dict)

    # PTC $21/MWh
    ptc_21_dict = Dict(
        "Scenario" => "PTC \$21/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc21_baseline/ptc21_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc21_baseline/ptc21_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc21_baseline/ptc21_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc21_baseline/ptc21_npv_final.csv"))
    )
    push!(all_cases, ptc_21_dict)

    # PTC $22/MWh
    ptc_22_dict = Dict(
        "Scenario" => "PTC \$22/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc22_baseline/ptc22_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc22_baseline/ptc22_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc22_baseline/ptc22_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc22_baseline/ptc22_npv_final.csv"))
    )
    push!(all_cases, ptc_22_dict)

    # PTC $23/MWh
    ptc_23_dict = Dict(
        "Scenario" => "PTC \$23/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc23_baseline/ptc23_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc23_baseline/ptc23_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc23_baseline/ptc23_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc23_baseline/ptc23_npv_final.csv"))
    )
    push!(all_cases, ptc_23_dict)

    # PTC $24/MWh
    ptc_24_dict = Dict(
        "Scenario" => "PTC \$24/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc24_baseline/ptc24_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc24_baseline/ptc24_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc24_baseline/ptc24_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc24_baseline/ptc24_npv_final.csv"))
    )
    push!(all_cases, ptc_24_dict)

    # PTC $25/MWh
    ptc_25_dict = Dict(
        "Scenario" => "PTC \$25/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc25_baseline/ptc25_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc25_baseline/ptc25_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc25_baseline/ptc25_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc25_baseline/ptc25_npv_final.csv"))
    )
    push!(all_cases, ptc_25_dict)

    # PTC $26/MWh
    ptc_26_dict = Dict(
        "Scenario" => "PTC \$26/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc26_baseline/ptc26_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc26_baseline/ptc26_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc26_baseline/ptc26_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc26_baseline/ptc26_npv_final.csv"))
    )
    push!(all_cases, ptc_26_dict)

    # PTC $27.5/MWh
    ptc_27_5_dict = Dict(
        "Scenario" => "PTC \$27.5/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc27.5_baseline/ptc27.5_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc27.5_baseline/ptc27.5_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc27.5_baseline/ptc27.5_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc27.5_baseline/ptc27.5_npv_final.csv"))
    )
    push!(all_cases, ptc_27_5_dict)

    # PTC $28.05/MWh
    ptc_28_05_dict = Dict(
        "Scenario" => "PTC \$28.05/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc28.05_baseline/ptc2805_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc28.05_baseline/ptc28.05_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc28.05_baseline/ptc28.05_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc28.05_baseline/ptc28.05_npv_final.csv"))
    )
    push!(all_cases, ptc_28_05_dict)

    # PTC $30.05/MWh
    ptc_30_05_dict = Dict(
        "Scenario" => "PTC \$30.05/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc30.05_baseline/ptc3005_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc30.05_baseline/ptc30.05_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc30.05_baseline/ptc30.05_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc30.05_baseline/ptc30.05_npv_final.csv"))
    )
    push!(all_cases, ptc_30_05_dict)

    # PTC $33/MWh
    ptc_33_dict = Dict(
        "Scenario" => "PTC \$33/MWh", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc33_baseline/ptc33_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc33_baseline/ptc33_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc33_baseline/ptc33_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/ptc33_baseline/ptc33_npv_final.csv"))
    )
    push!(all_cases, ptc_33_dict)

    # Capacity Market $1/kW-month
    cm_1_dict = Dict(
        "Scenario" => "Capacity Market \$1/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm1_baseline/cm1_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm1_baseline/cm1_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm1_baseline/cm1_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm1_baseline/cm1_npv_final.csv"))
    )
    push!(all_cases, cm_1_dict)

    # Capacity Market $2/kW-month
    cm_2_dict = Dict(
        "Scenario" => "Capacity Market \$2/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm2_baseline/cm2_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm2_baseline/cm2_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm2_baseline/cm2_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm2_baseline/cm2_npv_final.csv"))
    )
    push!(all_cases, cm_2_dict)

    # Capacity Market $3/kW-month
    cm_3_dict = Dict(
        "Scenario" => "Capacity Market \$3/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm3_baseline/cm3_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm3_baseline/cm3_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm3_baseline/cm3_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm3_baseline/cm3_npv_final.csv"))
    )
    push!(all_cases, cm_3_dict)

    # Capacity Market $4/kW-month
    cm_4_dict = Dict(
        "Scenario" => "Capacity Market \$4/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm4_baseline/cm4_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm4_baseline/cm4_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm4_baseline/cm4_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm4_baseline/cm4_npv_final.csv"))
    )
    push!(all_cases, cm_4_dict)

    # Capacity Market $5/kW-month
    cm_5_dict = Dict(
        "Scenario" => "Capacity Market \$5/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm5_baseline/cm5_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm5_baseline/cm5_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm5_baseline/cm5_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm5_baseline/cm5_npv_final.csv"))
    )
    push!(all_cases, cm_5_dict)

    # Capacity Market $6/kW-month
    cm_6_dict = Dict(
        "Scenario" => "Capacity Market \$6/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm6_baseline/cm6_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm6_baseline/cm6_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm6_baseline/cm6_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm6_baseline/cm6_npv_final.csv"))
    )
    push!(all_cases, cm_6_dict)

    # Capacity Market $7/kW-month
    cm_7_dict = Dict(
        "Scenario" => "Capacity Market \$7/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm7_baseline/cm7_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm7_baseline/cm7_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm7_baseline/cm7_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm7_baseline/cm7_npv_final.csv"))
    )
    push!(all_cases, cm_7_dict)

    # Capacity Market $8/kW-month
    cm_8_dict = Dict(
        "Scenario" => "Capacity Market \$8/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm8_baseline/cm8_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm8_baseline/cm8_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm8_baseline/cm8_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm8_baseline/cm8_npv_final.csv"))
    )
    push!(all_cases, cm_8_dict)

    # Capacity Market $15/kW-month
    cm_15_dict = Dict(
        "Scenario" => "Capacity Market \$15/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm15_baseline/cm15_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm15_baseline/cm15_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm15_baseline/cm15_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm15_baseline/cm15_npv_final.csv"))
    )
    push!(all_cases, cm_15_dict)

    # Capacity Market $16/kW-month
    cm_16_dict = Dict(
        "Scenario" => "Capacity Market \$16/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm16_baseline/cm16_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm16_baseline/cm16_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm16_baseline/cm16_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm16_baseline/cm16_npv_final.csv"))
    )
    push!(all_cases, cm_16_dict)

    # Capacity Market $17/kW-month
    cm_17_dict = Dict(
        "Scenario" => "Capacity Market \$17/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm17_baseline/cm17_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm17_baseline/cm17_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm17_baseline/cm17_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm17_baseline/cm17_npv_final.csv"))
    )
    push!(all_cases, cm_17_dict)

    # Capacity Market $18/kW-month
    cm_18_dict = Dict(
        "Scenario" => "Capacity Market \$18/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm18_baseline/cm18_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm18_baseline/cm18_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm18_baseline/cm18_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm18_baseline/cm18_npv_final.csv"))
    )
    push!(all_cases, cm_18_dict)

    # Capacity Market $19/kW-month
    cm_19_dict = Dict(
        "Scenario" => "Capacity Market \$19/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm19_baseline/cm19_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm19_baseline/cm19_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm19_baseline/cm19_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm19_baseline/cm19_npv_final.csv"))
    )
    push!(all_cases, cm_19_dict)

    # Capacity Market $20/kW-month
    cm_20_dict = Dict(
        "Scenario" => "Capacity Market \$20/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm20_baseline/cm20_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm20_baseline/cm20_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm20_baseline/cm20_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm20_baseline/cm20_npv_final.csv"))
    )
    push!(all_cases, cm_20_dict)

    # Capacity Market $21/kW-month
    cm_21_dict = Dict(
        "Scenario" => "Capacity Market \$21/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm21_baseline/cm21_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm21_baseline/cm21_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm21_baseline/cm21_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm21_baseline/cm21_npv_final.csv"))
    )
    push!(all_cases, cm_21_dict)

    # Capacity Market $22/kW-month
    cm_22_dict = Dict(
        "Scenario" => "Capacity Market \$22/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm22_baseline/cm22_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm22_baseline/cm22_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm22_baseline/cm22_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm22_baseline/cm22_npv_final.csv"))
    )
    push!(all_cases, cm_22_dict)

    # Capacity Market $23/kW-month
    cm_23_dict = Dict(
        "Scenario" => "Capacity Market \$23/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm23_baseline/cm23_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm23_baseline/cm23_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm23_baseline/cm23_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm23_baseline/cm23_npv_final.csv"))
    )
    push!(all_cases, cm_23_dict)

    # Capacity Market $25/kW-month
    cm_25_dict = Dict(
        "Scenario" => "Capacity Market \$25/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm25_baseline/cm25_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm25_baseline/cm25_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm25_baseline/cm25_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm25_baseline/cm25_npv_final.csv"))
    )
    push!(all_cases, cm_25_dict)

    # Capacity Market $30/kW-month
    cm_30_dict = Dict(
        "Scenario" => "Capacity Market \$30/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm30_baseline/cm30_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm30_baseline/cm30_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm30_baseline/cm30_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm30_baseline/cm30_npv_final.csv"))
    )
    push!(all_cases, cm_30_dict)

    # Capacity Market $35/kW-month
    cm_35_dict = Dict(
        "Scenario" => "Capacity Market \$35/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm35_baseline/cm35_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm35_baseline/cm35_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm35_baseline/cm35_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm35_baseline/cm35_npv_final.csv"))
    )
    push!(all_cases, cm_35_dict)

    # Capacity Market $40/kW-month
    cm_40_dict = Dict(
        "Scenario" => "Capacity Market \$40/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm40_baseline/cm40_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm40_baseline/cm40_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm40_baseline/cm40_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm40_baseline/cm40_npv_final.csv"))
    )
    push!(all_cases, cm_40_dict)

    # Capacity Market $45/kW-month
    cm_45_dict = Dict(
        "Scenario" => "Capacity Market \$45/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm45_baseline/cm45_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm45_baseline/cm45_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm45_baseline/cm45_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm45_baseline/cm45_npv_final.csv"))
    )
    push!(all_cases, cm_45_dict)

    # Capacity Market $50/kW-month
    cm_50_dict = Dict(
        "Scenario" => "Capacity Market \$50/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm50_baseline/cm50_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm50_baseline/cm50_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm50_baseline/cm50_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm50_baseline/cm50_npv_final.csv"))
    )
    push!(all_cases, cm_50_dict)

    # Capacity Market $55/kW-month
    cm_55_dict = Dict(
        "Scenario" => "Capacity Market \$55/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm55_baseline/cm55_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm55_baseline/cm55_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm55_baseline/cm55_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm55_baseline/cm55_npv_final.csv"))
    )
    push!(all_cases, cm_55_dict)

    # Capacity Market $60/kW-month
    cm_60_dict = Dict(
        "Scenario" => "Capacity Market \$60/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm60_baseline/cm60_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm60_baseline/cm60_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm60_baseline/cm60_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm60_baseline/cm60_npv_final.csv"))
    )
    push!(all_cases, cm_60_dict)

    # Capacity Market $65/kW-month
    cm_65_dict = Dict(
        "Scenario" => "Capacity Market \$65/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm65_baseline/cm65_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm65_baseline/cm65_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm65_baseline/cm65_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm65_baseline/cm65_npv_final.csv"))
    )
    push!(all_cases, cm_65_dict)

    # Capacity Market $70/kW-month
    cm_70_dict = Dict(
        "Scenario" => "Capacity Market \$70/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm70_baseline/cm70_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm70_baseline/cm70_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm70_baseline/cm70_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm70_baseline/cm70_npv_final.csv"))
    )
    push!(all_cases, cm_70_dict)

    # Capacity Market $75/kW-month
    cm_75_dict = Dict(
        "Scenario" => "Capacity Market \$75/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm75_baseline/cm75_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm75_baseline/cm75_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm75_baseline/cm75_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm75_baseline/cm75_npv_final.csv"))
    )
    push!(all_cases, cm_75_dict)

    # Capacity Market $80/kW-month
    cm_80_dict = Dict(
        "Scenario" => "Capacity Market \$80/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm80_baseline/cm80_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm80_baseline/cm80_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm80_baseline/cm80_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm80_baseline/cm80_npv_final.csv"))
    )
    push!(all_cases, cm_80_dict)

    # Capacity Market $85/kW-month
    cm_85_dict = Dict(
        "Scenario" => "Capacity Market \$85/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm85_baseline/cm85_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm85_baseline/cm85_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm85_baseline/cm85_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm85_baseline/cm85_npv_final.csv"))
    )
    push!(all_cases, cm_85_dict)

    # Capacity Market $90/kW-month
    cm_90_dict = Dict(
        "Scenario" => "Capacity Market \$90/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm90_baseline/cm90_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm90_baseline/cm90_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm90_baseline/cm90_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm90_baseline/cm90_npv_final.csv"))
    )
    push!(all_cases, cm_90_dict)

    # Capacity Market $95/kW-month
    cm_95_dict = Dict(
        "Scenario" => "Capacity Market \$95/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm95_baseline/cm95_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm95_baseline/cm95_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm95_baseline/cm95_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm95_baseline/cm95_npv_final.csv"))
    )
    push!(all_cases, cm_95_dict)

    # Capacity Market $100/kW-month
    cm_100_dict = Dict(
        "Scenario" => "Capacity Market \$100/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm100_baseline/cm100_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm100_baseline/cm100_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm100_baseline/cm100_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm100_baseline/cm100_npv_final.csv"))
    )
    push!(all_cases, cm_100_dict)

    # Capacity Market $105/kW-month
    cm_105_dict = Dict(
        "Scenario" => "Capacity Market \$105/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm105_baseline/cm105_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm105_baseline/cm105_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm105_baseline/cm105_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm105_baseline/cm105_npv_final.csv"))
    )
    push!(all_cases, cm_105_dict)

    # Capacity Market $110/kW-month
    cm_110_dict = Dict(
        "Scenario" => "Capacity Market \$110/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm110_baseline/cm110_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm110_baseline/cm110_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm110_baseline/cm110_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm110_baseline/cm110_npv_final.csv"))
    )
    push!(all_cases, cm_110_dict)

    # Capacity Market $115/kW-month
    cm_115_dict = Dict(
        "Scenario" => "Capacity Market \$115/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm115_baseline/cm115_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm115_baseline/cm115_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm115_baseline/cm115_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm115_baseline/cm115_npv_final.csv"))
    )
    push!(all_cases, cm_115_dict)

    # Capacity Market $120/kW-month
    cm_120_dict = Dict(
        "Scenario" => "Capacity Market \$120/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm120_baseline/cm120_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm120_baseline/cm120_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm120_baseline/cm120_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm120_baseline/cm120_npv_final.csv"))
    )
    push!(all_cases, cm_120_dict)

    # Capacity Market $125/kW-month
    cm_125_dict = Dict(
        "Scenario" => "Capacity Market \$125/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm125_baseline/cm125_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm125_baseline/cm125_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm125_baseline/cm125_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm125_baseline/cm125_npv_final.csv"))
    )
    push!(all_cases, cm_125_dict)

    # Capacity Market $130/kW-month
    cm_130_dict = Dict(
        "Scenario" => "Capacity Market \$130/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm130_baseline/cm130_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm130_baseline/cm130_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm130_baseline/cm130_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/baseline_sensitivities_all/cm130_baseline/cm130_npv_final.csv"))
    )
    push!(all_cases, cm_130_dict)

    # Synthetic Case 1: Multi-modular, PTC $15/MWh and Capacity Market of $5.0/kW-month
    synthetic_case1_dict = Dict(
        "Scenario" => "Synthetic Case 1: Multi-modular, PTC \$15/MWh and Capacity Market of \$5.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case1/synthetic_case1_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case1/synthetic_case1_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case1/synthetic_case1_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case1/synthetic_case1_npv_final.csv"))
    )
    push!(all_cases, synthetic_case1_dict)

    # Synthetic Case 2: Multi-modular, C2N, PTC $15/MWh and Capacity Market of $5.0/kW-month
    synthetic_case2_dict = Dict(
        "Scenario" => "Synthetic Case 2: Multi-modular, C2N, PTC \$15/MWh and Capacity Market of \$5.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case2/synthetic_case2_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case2/synthetic_case2_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case2/synthetic_case2_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case2/synthetic_case2_npv_final.csv"))
    )
    push!(all_cases, synthetic_case2_dict)

    # Synthetic Case 3: Multi-modular, C2N, ITC 6%, PTC $15/MWh and Capacity Market of $5.0/kW-month
    synthetic_case3_dict = Dict(
        "Scenario" => "Synthetic Case 3: Multi-modular, C2N, ITC 6%, PTC \$15/MWh and Capacity Market of \$5.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case3/synthetic_case3_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case3/synthetic_case3_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case3/synthetic_case3_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case3/synthetic_case3_npv_final.csv"))
    )
    push!(all_cases, synthetic_case3_dict)

    # Synthetic Case 4: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $5.0/kW-month
    synthetic_case4_dict = Dict(
        "Scenario" => "Synthetic Case 4: Multi-modular, C2N, ITC 30%, PTC \$15/MWh and Capacity Market of \$5.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case4/synthetic_case4_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case4/synthetic_case4_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case4/synthetic_case4_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case4/synthetic_case4_npv_final.csv"))
    )
    push!(all_cases, synthetic_case4_dict)

    # Synthetic Case 5: Multi-modular, C2N, ITC 40%, PTC $15/MWh and Capacity Market of $5.0/kW-month
    synthetic_case5_dict = Dict(
        "Scenario" => "Synthetic Case 5: Multi-modular, C2N, ITC 40%, PTC \$15/MWh and Capacity Market of \$5.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case5/synthetic_case5_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case5/synthetic_case5_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case5/synthetic_case5_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case5/synthetic_case5_npv_final.csv"))
    )
    push!(all_cases, synthetic_case5_dict)

    # Synthetic Case 6:  Multi-modular, C2N, ITC 50%, PTC $15/MWh and Capacity Market of $5.0/kW-month 
    synthetic_case6_dict = Dict(
        "Scenario" => "Synthetic Case 6: Multi-modular, C2N, ITC 50%, PTC \$15/MWh and Capacity Market of \$5.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case6/synthetic_case6_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case6/synthetic_case6_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case6/synthetic_case6_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case6/synthetic_case6_npv_final.csv"))
    )
    push!(all_cases, synthetic_case6_dict)

    # Synthetic Case 7: Multi-modular, C2N, ITC 30%, PTC $15/MWh and Capacity Market of $15.0/kW-month
    synthetic_case7_dict = Dict(
        "Scenario" => "Synthetic Case 7: Multi-modular, C2N, ITC 30%, PTC \$15/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case7/synthetic_case7_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case7/synthetic_case7_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case7/synthetic_case7_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case7/synthetic_case7_npv_final.csv"))
    
    )
    push!(all_cases, synthetic_case7_dict)

    # Synthetic Case 8: Multi-modular, C2N, ITC 30%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month
    synthetic_case8_dict = Dict(
        "Scenario" => "Synthetic Case 8: Multi-modular, C2N, ITC 30%, PTC \$27.5/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case8/synthetic_case8_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case8/synthetic_case8_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case8/synthetic_case8_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case8/synthetic_case8_npv_final.csv"))
    )
    push!(all_cases, synthetic_case8_dict)

    # Synthetic Case 9: Multi-modular, C2N, ITC 40%, PTC $15/MWh and Capacity Market of $15.0/kW-month
    synthetic_case9_dict = Dict(
        "Scenario" => "Synthetic Case 9: Multi-modular, C2N, ITC 40%, PTC \$15/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case9/synthetic_case9_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case9/synthetic_case9_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case9/synthetic_case9_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case9/synthetic_case9_npv_final.csv"))
    )
    push!(all_cases, synthetic_case9_dict)

    # Synthetic Case 10: Multi-modular, C2N, ITC 50%, PTC $15/MWh and Capacity Market of $15.0/kW-month
    synthetic_case10_dict = Dict(
        "Scenario" => "Synthetic Case 10: Multi-modular, C2N, ITC 50%, PTC \$15/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case10/synthetic_case10_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case10/synthetic_case10_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case10/synthetic_case10_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case10/synthetic_case10_npv_final.csv"))
    )
    push!(all_cases, synthetic_case10_dict)

    # Synthetic Case 11: Multi-modular, C2N, ITC 6%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month
    synthetic_case11_dict = Dict(
        "Scenario" => "Synthetic Case 11: Multi-modular, C2N, ITC 6%, PTC \$27.5/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case11/synthetic_case11_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case11/synthetic_case11_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case11/synthetic_case11_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case11/synthetic_case11_npv_final.csv"))
    )
    push!(all_cases, synthetic_case11_dict)

    # Synthetic Case 12: Multi-modular, C2N, ITC 40%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month
    synthetic_case12_dict = Dict(
        "Scenario" => "Synthetic Case 12: Multi-modular, C2N, ITC 40%, PTC \$27.5/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case12/synthetic_case12_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case12/synthetic_case12_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case12/synthetic_case12_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case12/synthetic_case12_npv_final.csv"))
    )
    push!(all_cases, synthetic_case12_dict)

    # Synthetic Case 13: Multi-modular, C2N, ITC 50%, PTC $27.5/MWh and Capacity Market of $15.0/kW-month
    synthetic_case13_dict = Dict(
        "Scenario" => "Synthetic Case 13: Multi-modular, C2N, ITC 50%, PTC \$27.5/MWh and Capacity Market of \$15.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case13/synthetic_case13_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case13/synthetic_case13_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case13/synthetic_case13_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case13/synthetic_case13_npv_final.csv"))
    )
    push!(all_cases, synthetic_case13_dict)

    # Synthetic Case 14: Multi-modular, C2N, ITC 6%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month
    synthetic_case14_dict = Dict(
        "Scenario" => "Synthetic Case 14: Multi-modular, C2N, ITC 6%, PTC \$30.05/MWh and Capacity Market of \$25.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case14/synthetic_case14_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case14/synthetic_case14_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case14/synthetic_case14_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case14/synthetic_case14_npv_final.csv"))
    )
    push!(all_cases, synthetic_case14_dict)

    # Synthetic Case 15: Multi-modular, C2N, ITC 30%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month
    synthetic_case15_dict = Dict(
        "Scenario" => "Synthetic Case 15: Multi-modular, C2N, ITC 30%, PTC \$30.05/MWh and Capacity Market of \$25.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case15/synthetic_case15_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case15/synthetic_case15_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case15/synthetic_case15_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case15/synthetic_case15_npv_final.csv"))
    )
    push!(all_cases, synthetic_case15_dict)

    # Synthetic Case 16: Multi-modular, C2N, ITC 40%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month
    synthetic_case16_dict = Dict(
        "Scenario" => "Synthetic Case 16: Multi-modular, C2N, ITC 40%, PTC \$30.05/MWh and Capacity Market of \$25.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case16/synthetic_case16_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case16/synthetic_case16_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case16/synthetic_case16_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case16/synthetic_case16_npv_final.csv"))
    )
    push!(all_cases, synthetic_case16_dict)

    # Synthetic Case 17: Multi-modular, C2N, ITC 50%, PTC $30.05/MWh and Capacity Market of $25.0/kW-month
    synthetic_case17_dict = Dict(
        "Scenario" => "Synthetic Case 17: Multi-modular, C2N, ITC 50%, PTC \$30.05/MWh and Capacity Market of \$25.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case17/synthetic_case17_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case17/synthetic_case17_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case17/synthetic_case17_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case17/synthetic_case17_npv_final.csv"))
    )
    push!(all_cases, synthetic_case17_dict)

    # Synthetic Case 18: Multi-modular, C2N, ITC 50%, PTC $33.0/MWh and Capacity Market of $25.0/kW-month
    synthetic_case18_dict = Dict(
        "Scenario" => "Synthetic Case 18: Multi-modular, C2N, ITC 50%, PTC \$33.0/MWh and Capacity Market of \$25.0/kW-month", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case18/synthetic_case18_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case18/synthetic_case18_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case18/synthetic_case18_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/synthetic_case18/synthetic_case18_npv_final.csv"))
    )
    push!(all_cases, synthetic_case18_dict)

    # Synthetic Learning Rate 1: 65% construction cost reduction and 5% FOM cost reduction
    syntheticll_1_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 1: 65% construction cost reduction and 5% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case1/syntheticll_case1_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case1/syntheticll_case1_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case1/syntheticll_case1_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case1/syntheticll_case1_npv_final.csv"))
    )
    push!(all_cases, syntheticll_1_dict)

    # Synthetic Learning Rate 2: 65% construction cost reduction and 10% FOM cost reduction
    syntheticll_2_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 2: 65% construction cost reduction and 10% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case2/syntheticll_case2_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case2/syntheticll_case2_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case2/syntheticll_case2_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case2/syntheticll_case2_npv_final.csv"))
    )
    push!(all_cases, syntheticll_2_dict)

    # Synthetic Learning Rate 3: 65% construction cost reduction and 15% FOM cost reduction
    syntheticll_3_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 3: 65% construction cost reduction and 15% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case3/syntheticll_case3_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case3/syntheticll_case3_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case3/syntheticll_case3_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case3/syntheticll_case3_npv_final.csv"))
    )
    push!(all_cases, syntheticll_3_dict)

    # Synthetic Learning Rate 4: 65% construction cost reduction and 20% FOM cost reduction
    syntheticll_4_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 4: 65% construction cost reduction and 20% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case4/syntheticll_case4_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case4/syntheticll_case4_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case4/syntheticll_case4_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case4/syntheticll_case4_npv_final.csv"))
    )
    push!(all_cases, syntheticll_4_dict)

    # Synthetic Learning Rate 5: 65% construction cost reduction and 25% FOM cost reduction
    syntheticll_5_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 5: 65% construction cost reduction and 25% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case5/syntheticll_case5_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case5/syntheticll_case5_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case5/syntheticll_case5_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case5/syntheticll_case5_npv_final.csv"))
    )
    push!(all_cases, syntheticll_5_dict)

    # Synthetic Learning Rate 6: 65% construction cost reduction and 30% FOM cost reduction
    syntheticll_6_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 6: 65% construction cost reduction and 30% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case6/syntheticll_case6_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case6/syntheticll_case6_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case6/syntheticll_case6_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case6/syntheticll_case6_npv_final.csv"))
    )
    push!(all_cases, syntheticll_6_dict)

    # Synthetic Learning Rate 7: 65% construction cost reduction and 35% FOM cost reduction
    syntheticll_7_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 7: 65% construction cost reduction and 35% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case7/syntheticll_case7_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case7/syntheticll_case7_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case7/syntheticll_case7_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case7/syntheticll_case7_npv_final.csv"))
    )
    push!(all_cases, syntheticll_7_dict)

    # Synthetic Learning Rate 8: 65% construction cost reduction and 40% FOM cost reduction
    syntheticll_8_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 8: 65% construction cost reduction and 40% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case8/syntheticll_case8_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case8/syntheticll_case8_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case8/syntheticll_case8_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case8/syntheticll_case8_npv_final.csv"))
    )
    push!(all_cases, syntheticll_8_dict)

    # Synthetic Learning Rate 9: 65% construction cost reduction and 45% FOM cost reduction
    syntheticll_9_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 9: 65% construction cost reduction and 45% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case9/syntheticll_case9_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case9/syntheticll_case9_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case9/syntheticll_case9_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case9/syntheticll_case9_npv_final.csv"))
    )
    push!(all_cases, syntheticll_9_dict)

    # Synthetic Learning Rate 10: 65% construction cost reduction and 50% FOM cost reduction
    syntheticll_10_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 10: 65% construction cost reduction and 50% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case10/syntheticll_case10_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case10/syntheticll_case10_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case10/syntheticll_case10_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case10/syntheticll_case10_npv_final.csv"))
    )
    push!(all_cases, syntheticll_10_dict)

    # Synthetic Learning Rate 11: 65% construction cost reduction and 55% FOM cost reduction
    syntheticll_11_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 11: 65% construction cost reduction and 55% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case11/syntheticll_case11_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case11/syntheticll_case11_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case11/syntheticll_case11_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case11/syntheticll_case11_npv_final.csv"))
    )
    push!(all_cases, syntheticll_11_dict)

    # Synthetic Learning Rate 12: 65% construction cost reduction and 60% FOM cost reduction
    syntheticll_12_dict = Dict(
        "Scenario" => "Synthetic Learning Rate 12: 65% construction cost reduction and 60% FOM cost reduction", 
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case12/syntheticll_case12_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case12/syntheticll_case12_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case12/syntheticll_case12_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/synthetic_cases/syntheticll_case12/syntheticll_case12_npv_final.csv"))
    )
    push!(all_cases, syntheticll_12_dict)
    

    return all_cases
end

"""
This function returns the 2023 Cambium price profiles for the AP1000
reactor
"""
function get_ap1000_scenario_prices()
    scenario_price_data_all = []

    scenario_price_data_temp = []

    for (index2, cost_array) in enumerate(ap1000_cost_vals)
        if index2 < 20
            smr_lifetime = Int64(cost_array[2])
            construction_duration = cost_array[7]
        else
            smr_lifetime = Int64(cost_array[2])
            construction_duration = cost_array[8]
        end

        start_reactor = Int(ceil((construction_duration)/12))

        for (index3, scenario) in enumerate(scenario_data_all)
            if index3 == 1 || index3 == 2 || index3 == 3
                scenario_dict = Dict(
                    "smr" =>  "$(ap1000_scenario_names[index2])",
                    "scenario" => "$(scenario_names_combined[index3])",
                    "data" => create_scenario_array(scenario, scenario, scenario, scenario, scenario, scenario, scenario, scenario, (smr_lifetime + start_reactor))
                )

                push!(scenario_price_data_all, scenario_dict)
                continue
            end

            if length(scenario_price_data_temp) == 8
                scen_names_combined_index = Int((index3 - 4)/8)
                scenario_dict = Dict(
                    "smr" =>  "$(ap1000_scenario_names[index2])",
                    "scenario" => "$(scenario_names_combined[scen_names_combined_index])",
                    "data" => create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (smr_lifetime + start_reactor))
                )

                push!(scenario_price_data_all, scenario_dict)
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end

        scenario_dict = Dict(
            "smr" =>  "$(ap1000_scenario_names[index2])",
            "scenario" => "$(last(scenario_names_combined))",
            "data" => create_scenario_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], scenario_price_data_temp[7], scenario_price_data_temp[8], (smr_lifetime + start_reactor))
        )

        push!(scenario_price_data_all, scenario_dict)
        empty!(scenario_price_data_temp)
    end

    # Resetting the temporary array
    scenario_price_data_temp = []

    for (index2, cost_array) in enumerate(ap1000_cost_vals)
        if index2 < 20
            smr_lifetime = Int64(cost_array[2])
            construction_duration = cost_array[7]
        else
            smr_lifetime = Int64(cost_array[2])
            construction_duration = cost_array[8]
        end

        start_reactor = Int(ceil((construction_duration)/12))

        for (index3, scenario) in enumerate(scenario_23_data_all)
            if length(scenario_price_data_temp) == 6
                scen_names_combined_index = Int((index3 - 1)/6)
                # Remove after testing
                scenario_dict = Dict(
                    "smr" =>  "$(ap1000_scenario_names[index2])",
                    "scenario" => "$(scenario_names_23cambium[scen_names_combined_index])",
                    "data" => create_scenario_interpolated_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], (smr_lifetime + start_reactor))
                )

                push!(scenario_price_data_all, scenario_dict)
                empty!(scenario_price_data_temp)
                push!(scenario_price_data_temp, scenario)
            else
                push!(scenario_price_data_temp, scenario)
                continue
            end
        end
        
        scenario_dict = Dict(
            "smr" =>  "$(ap1000_scenario_names[index2])",
            "scenario" => "$(last(scenario_names_23cambium))",
            "data" => create_scenario_interpolated_array(scenario_price_data_temp[1], scenario_price_data_temp[2], scenario_price_data_temp[3], scenario_price_data_temp[4], scenario_price_data_temp[5], scenario_price_data_temp[6], (smr_lifetime + start_reactor))
        )

        push!(scenario_price_data_all, scenario_dict)
        empty!(scenario_price_data_temp)
        
    end

    return scenario_price_data_all
end

# TODO: Replace with OneDrive links
"""
This function stores all the capacity market data for the AP1000
"""
function get_ap1000_cm_data()
    # Creating an array to hold dictionaries for all cases
    ap1000_cm_cases = []

    # Capacity Market Case 1: AP1000, $1.0/kW-month Capacity Market Price
    cm1_dict = Dict(
        "Scenario" => "AP1000, \$1.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 1.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm1_ap1000/cm1_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm1_ap1000/cm1_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm1_ap1000/cm1_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm1_ap1000/cm1_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm1_dict)

    # Capacity Market Case 2: AP1000, $2.0/kW-month Capacity Market Price
    cm2_dict = Dict(
        "Scenario" => "AP1000, \$2.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 2.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm2_ap1000/cm2_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm2_ap1000/cm2_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm2_ap1000/cm2_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm2_ap1000/cm2_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm2_dict)

    # Capacity Market Case 3: AP1000, $3.0/kW-month Capacity Market Price
    cm3_dict = Dict(
        "Scenario" => "AP1000, \$3.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 3.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm3_ap1000/cm3_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm3_ap1000/cm3_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm3_ap1000/cm3_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm3_ap1000/cm3_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm3_dict)

    # Capacity Market Case 4: AP1000, $4.0/kW-month Capacity Market Price
    cm4_dict = Dict(
        "Scenario" => "AP1000, \$4.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 4.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm4_ap1000/cm4_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm4_ap1000/cm4_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm4_ap1000/cm4_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm4_ap1000/cm4_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm4_dict)

    # Capacity Market Case 5: AP1000, $5.0/kW-month Capacity Market Price
    cm5_dict = Dict(
        "Scenario" => "AP1000, \$5.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 5.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm5_ap1000/cm5_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm5_ap1000/cm5_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm5_ap1000/cm5_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm5_ap1000/cm5_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm5_dict)

    # Capacity Market Case 6: AP1000, $6.0/kW-month Capacity Market Price
    cm6_dict = Dict(
        "Scenario" => "AP1000, \$6.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 6.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm6_ap1000/cm6_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm6_ap1000/cm6_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm6_ap1000/cm6_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm6_ap1000/cm6_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm6_dict)

    # Capacity Market Case 7: AP1000, $7.0/kW-month Capacity Market Price
    cm7_dict = Dict(
        "Scenario" => "AP1000, \$7.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 7.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm7_ap1000/cm7_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm7_ap1000/cm7_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm7_ap1000/cm7_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm7_ap1000/cm7_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm7_dict)

    # Capacity Market Case 8: AP1000, $8.0/kW-month Capacity Market Price
    cm8_dict = Dict(
        "Scenario" => "AP1000, \$8.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 8.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm8_ap1000/cm8_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm8_ap1000/cm8_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm8_ap1000/cm8_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm8_ap1000/cm8_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm8_dict)

    # Capacity Market Case 9: AP1000, $15.0/kW-month Capacity Market Price
    cm15_dict = Dict(
        "Scenario" => "AP1000, \$15.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 15.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm15_ap1000/cm15_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm15_ap1000/cm15_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm15_ap1000/cm15_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm15_ap1000/cm15_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm15_dict)

    # Capacity Market Case 10: AP1000, $16.0/kW-month Capacity Market Price
    cm16_dict = Dict(
        "Scenario" => "AP1000, \$16.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 16.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm16_ap1000/cm16_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm16_ap1000/cm16_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm16_ap1000/cm16_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm16_ap1000/cm16_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm16_dict)

    # Capacity Market Case 11: AP1000, $17.0/kW-month Capacity Market Price
    cm17_dict = Dict(
        "Scenario" => "AP1000, \$17.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 17.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm17_ap1000/cm17_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm17_ap1000/cm17_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm17_ap1000/cm17_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm17_ap1000/cm17_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm17_dict)

    # Capacity Market Case 12: AP1000, $18.0/kW-month Capacity Market Price
    cm18_dict = Dict(
        "Scenario" => "AP1000, \$18.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 18.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm18_ap1000/cm18_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm18_ap1000/cm18_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm18_ap1000/cm18_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm18_ap1000/cm18_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm18_dict)

    # Capacity Market Case 13: AP1000, $19.0/kW-month Capacity Market Price
    cm19_dict = Dict(
        "Scenario" => "AP1000, \$19.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 19.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm19_ap1000/cm19_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm19_ap1000/cm19_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm19_ap1000/cm19_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm19_ap1000/cm19_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm19_dict)

    # Capacity Market Case 14: AP1000, $20.0/kW-month Capacity Market Price
    cm20_dict = Dict(
        "Scenario" => "AP1000, \$20.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 20.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm20_ap1000/cm20_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm20_ap1000/cm20_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm20_ap1000/cm20_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm20_ap1000/cm20_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm20_dict)

    # Capacity Market Case 15: AP1000, $21.0/kW-month Capacity Market Price
    cm21_dict = Dict(
        "Scenario" => "AP1000, \$21.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 21.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm21_ap1000/cm21_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm21_ap1000/cm21_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm21_ap1000/cm21_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm21_ap1000/cm21_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm21_dict)

    # Capacity Market Case 16: AP1000, $22.0/kW-month Capacity Market Price
    cm22_dict = Dict(
        "Scenario" => "AP1000, \$22.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 22.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm22_ap1000/cm22_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm22_ap1000/cm22_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm22_ap1000/cm22_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm22_ap1000/cm22_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm22_dict)

    # Capacity Market Case 17: AP1000, $23.0/kW-month Capacity Market Price
    cm23_dict = Dict(
        "Scenario" => "AP1000, \$23.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 23.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm23_ap1000/cm23_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm23_ap1000/cm23_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm23_ap1000/cm23_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm23_ap1000/cm23_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm23_dict)

    # Capacity Market Case 18: AP1000, $25.0/kW-month Capacity Market Price
    cm25_dict = Dict(
        "Scenario" => "AP1000, \$25.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 25.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm25_ap1000/cm25_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm25_ap1000/cm25_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm25_ap1000/cm25_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm25_ap1000/cm25_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm25_dict)

    # Capacity Market Case 19: AP1000, $30.0/kW-month Capacity Market Price
    cm30_dict = Dict(
        "Scenario" => "AP1000, \$30.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 30.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm30_ap1000/cm30_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm30_ap1000/cm30_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm30_ap1000/cm30_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm30_ap1000/cm30_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm30_dict)

    # Capacity Market Case 20: AP1000, $35.0/kW-month Capacity Market Price
    cm35_dict = Dict(
        "Scenario" => "AP1000, \$35.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 35.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm35_ap1000/cm35_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm35_ap1000/cm35_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm35_ap1000/cm35_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm35_ap1000/cm35_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm35_dict)

    # Capacity Market Case 21: AP1000, $40.0/kW-month Capacity Market Price
    cm40_dict = Dict(
        "Scenario" => "AP1000, \$40.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 40.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm40_ap1000/cm40_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm40_ap1000/cm40_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm40_ap1000/cm40_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm40_ap1000/cm40_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm40_dict)

    # Capacity Market Case 22: AP1000, $45.0/kW-month Capacity Market Price
    cm45_dict = Dict(
        "Scenario" => "AP1000, \$45.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 45.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm45_ap1000/cm45_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm45_ap1000/cm45_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm45_ap1000/cm45_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm45_ap1000/cm45_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm45_dict)

    # Capacity Market Case 23: AP1000, $50.0/kW-month Capacity Market Price
    cm50_dict = Dict(
        "Scenario" => "AP1000, \$50.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 50.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm50_ap1000/cm50_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm50_ap1000/cm50_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm50_ap1000/cm50_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm50_ap1000/cm50_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm50_dict)

    # Capacity Market Case 24: AP1000, $55.0/kW-month Capacity Market Price
    cm55_dict = Dict(
        "Scenario" => "AP1000, \$55.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 55.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm55_ap1000/cm55_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm55_ap1000/cm55_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm55_ap1000/cm55_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm55_ap1000/cm55_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm55_dict)

    # Capacity Market Case 25: AP1000, $60.0/kW-month Capacity Market Price
    cm60_dict = Dict(
        "Scenario" => "AP1000, \$60.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 60.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm60_ap1000/cm60_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm60_ap1000/cm60_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm60_ap1000/cm60_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm60_ap1000/cm60_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm60_dict)

    # Capacity Market Case 26: AP1000, $65.0/kW-month Capacity Market Price
    cm65_dict = Dict(
        "Scenario" => "AP1000, \$65.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 65.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm65_ap1000/cm65_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm65_ap1000/cm65_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm65_ap1000/cm65_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm65_ap1000/cm65_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm65_dict)

    # Capacity Market Case 27: AP1000, $70.0/kW-month Capacity Market Price
    cm70_dict = Dict(
        "Scenario" => "AP1000, \$70.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 70.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm70_ap1000/cm70_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm70_ap1000/cm70_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm70_ap1000/cm70_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm70_ap1000/cm70_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm70_dict)

    # Capacity Market Case 28: AP1000, $75.0/kW-month Capacity Market Price
    cm75_dict = Dict(
        "Scenario" => "AP1000, \$75.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 75.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm75_ap1000/cm75_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm75_ap1000/cm75_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm75_ap1000/cm75_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm75_ap1000/cm75_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm75_dict)

    # Capacity Market Case 29: AP1000, $80.0/kW-month Capacity Market Price
    cm80_dict = Dict(
        "Scenario" => "AP1000, \$80.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 80.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm80_ap1000/cm80_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm80_ap1000/cm80_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm80_ap1000/cm80_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm80_ap1000/cm80_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm80_dict)

    # Capacity Market Case 30: AP1000, $85.0/kW-month Capacity Market Price
    cm85_dict = Dict(
        "Scenario" => "AP1000, \$85.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 85.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm85_ap1000/cm85_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm85_ap1000/cm85_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm85_ap1000/cm85_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm85_ap1000/cm85_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm85_dict)

    # Capacity Market Case 31: AP1000, $90.0/kW-month Capacity Market Price
    cm90_dict = Dict(
        "Scenario" => "AP1000, \$90.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 90.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm90_ap1000/cm90_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm90_ap1000/cm90_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm90_ap1000/cm90_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm90_ap1000/cm90_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm90_dict)

    # Capacity Market Case 32: AP1000, $95.0/kW-month Capacity Market Price
    cm95_dict = Dict(
        "Scenario" => "AP1000, \$95.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 95.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm95_ap1000/cm95_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm95_ap1000/cm95_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm95_ap1000/cm95_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm95_ap1000/cm95_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm95_dict)

    # Capacity Market Case 33: AP1000, $100.0/kW-month Capacity Market Price
    cm100_dict = Dict(
        "Scenario" => "AP1000, \$100.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 100.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm100_ap1000/cm100_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm100_ap1000/cm100_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm100_ap1000/cm100_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm100_ap1000/cm100_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm100_dict)

    # Capacity Market Case 34: AP1000, $105.0/kW-month Capacity Market Price
    cm105_dict = Dict(
        "Scenario" => "AP1000, \$105.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 105.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm105_ap1000/cm105_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm105_ap1000/cm105_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm105_ap1000/cm105_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm105_ap1000/cm105_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm105_dict)

    # Capacity Market Case 35: AP1000, $110.0/kW-month Capacity Market Price
    cm110_dict = Dict(
        "Scenario" => "AP1000, \$110.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 110.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm110_ap1000/cm110_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm110_ap1000/cm110_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm110_ap1000/cm110_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm110_ap1000/cm110_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm110_dict)

    # Capacity Market Case 36: AP1000, $115.0/kW-month Capacity Market Price
    cm115_dict = Dict(
        "Scenario" => "AP1000, \$115.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 115.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm115_ap1000/cm115_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm115_ap1000/cm115_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm115_ap1000/cm115_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm115_ap1000/cm115_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm115_dict)

    # Capacity Market Case 37: AP1000, $120.0/kW-month Capacity Market Price
    cm120_dict = Dict(
        "Scenario" => "AP1000, \$120.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 120.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm120_ap1000/cm120_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm120_ap1000/cm120_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm120_ap1000/cm120_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm120_ap1000/cm120_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm120_dict)

    # Capacity Market Case 38: AP1000, $125.0/kW-month Capacity Market Price
    cm125_dict = Dict(
        "Scenario" => "AP1000, \$125.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 125.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm125_ap1000/cm125_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm125_ap1000/cm125_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm125_ap1000/cm125_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm125_ap1000/cm125_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm125_dict)

    # Capacity Market Case 39: AP1000, $130.0/kW-month Capacity Market Price
    cm130_dict = Dict(
        "Scenario" => "AP1000, \$130.0/kW-month Capacity Market Price",
        "Capacity Market Price" => 130.0,
        "Construction Cost DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm130_ap1000/cm130_ap1000_construction_cost.csv")),
        "Breakeven DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm130_ap1000/cm130_ap1000_breakeven.csv")),
        "IRR DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm130_ap1000/cm130_ap1000_irr.csv")),
        "NPV DataFrame" => DataFrame(CSV.File("/Users/pradyrao/Desktop/thesis_plots/output_files/ap1000cases/ap1000_cm/cm130_ap1000/cm130_ap1000_npv_final.csv"))
    )
    push!(ap1000_cm_cases, cm130_dict)

    return ap1000_cm_cases
end