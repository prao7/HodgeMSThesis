using HTTP
using CSV
using DataFrames

# Loading in the functions.jl so that 
@info("Loading in the functions file for data processing")
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

"""
High NG Scenarios Data
"""

# High NG 2024 prices
highNG_2024df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EYTxYZImGFRPpEnLVKqQLMYBkoe25xDQb1d_ywzHYT6JRw")

# High NG 2026 prices
highNG_2026df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ETgUwIuDriZAv_V6I_n7MzQBvGgj0_GI4IEFhusB7SAYww")

# High NG 2028 prices
highNG_2028df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EW3jGqs1pi1CoSwDz-j61WQBnMoQaHlF4CFJZwMweiwLiQ")

# High NG 2030 prices
highNG_2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EeFOzw_IZvZBjz8NfNB_ekUBjRFfMy1nXPMASwcbdwshag")

# High NG 2035 prices
highNG_2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EWIy_qmLhYNDq2pQ4XuZt-UBetpdr_cbvzUqZ_nPQ4akSg")

# High NG 2040 prices
highNG_2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ET_bEPi2rhhKgxtiy8Z028gBiu5dXCemIrW18kKPKydxSA")

# High NG 2045 prices
highNG_2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EcQNxuzYODZNnIaCiQOcMucBDDz2pX6KNbh0EoxB6Lo8eg")

# High NG 2050 prices
highNG_2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EVFLxQBXeeJOovTYUeblTJMBaXQZDMUCcH6eL6MQnHSNxQ")

"""
Low NG prices Scenarios Data
"""

# Low NG prices 2024
lowNG_2024df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EVz1EL7U-XVOiwSWuxwBD_YBGhON5Lx4yGp5fdxPNmmqnA")

# Low NG prices 2026
lowNG_2026df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EWYUFcjmQwJLqMf2qIRW3y4BlgXKd42KBOCsV4P9k1KU_A")

# Low NG prices 2028
lowNG_2028df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ESZhC9TxG-9PjoNy5JHFYxUBiHqm195IrdU7_oobmJYdZQ")

# Low NG prices 2030
lowNG_2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ESvuM-5pd_xFjp2HaAUOBw8BN6Le2VR9JC_BbZ50-8pPWA")

# Low NG prices 2035
lowNG_2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EXNvXnrdzFlFjMa5rSHhCv4Bau-kX_QitB4Jz7Z00p6ARw")

# Low NG prices 2040
lowNG_2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EahSONo8MMNJt0ZT9YLYhjcBUA2TUsTYZPx6AamVm6yM5w")

# Low NG prices 2045
lowNG_2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ERyHGoKVLvRBl-g4F4KZHTABCNlx4LX_5v8PesJrTX3XCQ")

# Low NG prices 2050
lowNG_2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EX0TC9OumNJKmcGb4VU0u9YBwZklZfFgBXegZgYnQa5nSA")

"""
Low RE Cost Scenarios Data
"""
