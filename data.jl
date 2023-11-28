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
texasdf = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ER6qRc8BSptGryd1qBXXrCoBkxO3I5yC4NutrqrCaxZC0w")
texas_input_data = fifteen_minutes_to_hourly(texasdf,"Settlement Point Price", 4)

# DE-LU 2020 usage
de2020df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EY1LQ3vkqmFFqw4-AizUjWwBcAWJm4t-Up46YJxNil8ETQ")

# DE-LU 2022 usage
de2022df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EYX1aiuaKXVJjB5AWc72HA8BmVDnUUI7rgpxkBEG5gJOZA")

"""
Importing SMR data to the folder
"""

# SMR data import from OneDrive
smr_infodf = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EZ4zSrIazY9AlCuEO3KSacwB3olC3pY_ila47dhpSa_ApQ")

"""
Electrification Scenarios Data
"""

# Electrification 2024 prices
elec_2024df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ERPH8DkFnnVBpVWHmBQYk-sBgs_fEEOumPDnnUOLhFGehg")

# Electrification 2026 prices
elec_2026df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EU8atUzhbp9Ck3huiUturcIBBSuu-PJ0cW36cclTOOZ2QA")

# Electrification 2028 prices
elec_2028df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ERVSyaiiru1EtPwhFqkmkAMBU-exSUf-UudhuQTPbWb4xA")

# Electrification 2030 prices
elec_2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EfwzZ7YCNMBLq5FYTPEIg1oBI0UM_4pwV5MQ4a3UjBNnrA")

# Electrification 2035 prices
elec_2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ETRvRrd-hEZDqRtUqHY2duABIWloYTYcKooBLWJWW8PVVQ")

# Electrification 2040 prices
elec_2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EZqxfTEvWldIkH2eZ20G3ekBSoOTjwzOAfwD5yKaFx6Bsw")

# Electrification 2045 prices
elec_2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/Eb6x9qT8zxRBmh7qT8565BoBeAgj9GW9ln1OMKLGFUF73g")

# Electrification 2050 prices
elec_2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/Ebia0G9_ExBCnDxg9nGF8y4BPuWRHZbDDbFarxksozGMiw")

"""
High RE Cost Scenarios Data
"""

# High RE Cost 2024 prices
highRE_2024df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ETIox6tJ369JlrtBIk_JvhYByjraB_H-WNHC71kUM5sErw")

# High RE Cost 2026 prices
highRE_2026df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ETuDnqr6qylKh_WN9cW11ZcB1_T8vmflzTqcmIsbkhDTeA")

# High RE Cost 2028 prices
highRE_2028df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/Edbk9Aqa7xFOjAPLZeY1FK4BtxlGlqgLGLpsOyGWbyKYIQ")

# High RE Cost 2030 prices
highRE_2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EQsJkk9wkXxPnhx1tcJEDikBEvNiozIMWiV5m9-e_6_VLA")

# High RE Cost 2035 prices
highRE_2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EUd1DnFFUVJEo1pQTKd2GdwBPRaOeanA3JvkX63HSsCFZQ")

# High RE Cost 2040 prices
highRE_2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EetA2thaSvlDt1WTZIwsGN8BDQbyZ7q6Kr9-QnbAzU7new")

# High RE Cost 2045 prices
highRE_2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EZVO3eC8wd5Mkg1-pVFjNzkBCk4z8D1uXy62mUsPYlpbWQ")

# High RE Cost 2050 prices
highRE_2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EdWyKNSJ1TJMqup5-yeoxcABm2f53B5MC6-Uk80-hQDJ7Q")