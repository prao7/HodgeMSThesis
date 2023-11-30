using HTTP
using CSV
using DataFrames

# Loading in the functions.jl so that 
@info("Loading in the functions file for data processing")
include("dataprocessingfunctions.jl")

"""
Empty array for all scenario data to be input. This will contain all price data to be analyzed on.
"""
scenario_data_all = []

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