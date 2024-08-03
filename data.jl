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
"Mid Case 95 2045", "Mid Case 95 2050"]

"""
This is the array of the names of the combined scenarios analyzed
"""
scenario_names_combined = ["Texas 2022", "DE-LU 2020", "DE-LU 2022", "Electrification", "High RE", "High NG", "Low NG", "Low RE",
"Low RE TC Expire", "Mid Case", "Mid Case 100", "Mid Case 95"]

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
Adding in all the rows of economic data of SMR's
"""

# Array to extract Capacity [MWel]  Lifetime [years]  Construction Cost [USD2020/MWel]  Fuel cost [USD2020/MWh]  O&M cost [USD2020/MWel] from SMR DataFrame
smr_cost_vals = extract_columns_from_third_to_end(smr_infodf)

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

test_cycle = capacity_market_misoseasonal_scenario(miso_new_cap_market_prices, 60)
println(test_cycle)
println(length(test_cycle))

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
# column_name = :Clearing_Price
# price_array = cycle_prices(lifetime_years, iso_ne_capacity_market, column_name)
# println(price_array)

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
# pjm_capacity_markets_prices = DataFrame(pjm_capacity_market)

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