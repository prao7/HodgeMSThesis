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

# Low RE Cost 2024
lowRECost_2024df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EelyFEyo69BJpDV86ObjNT0B9CP6TfS5kZcbZTFU_MZBDw")

# Low RE Cost 2026
lowRECost_2026df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EfSEKfUgpLFAmI1tBqM_LhQBJsnETa2tY0o4jv59-Cad5A")

# Low RE Cost 2028
lowRECost_2028df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ES_qTZL5oPhEp8U3JjeAIrMBueMKPzQoKH5FyBVq-gvpjQ")

# Low RE Cost 2030
lowRECost_2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ESO_H8WaIclHpC89Nu9jM_cBWdr2pg83bMp18H4teTEdWg")

# Low RE Cost 2035
lowRECost_2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EYq36K11Fn1IovfXTkzPxCABVbbbqL424cyf7Ox1rbnwaQ")

# Low RE Cost 2040
lowRECost_2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EdW3PqsFCk5IsTZBROG-NWUBk23ia6vqsbthXjXkzdHzyA")

# Low RE Cost 2045
lowRECost_2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EdaHcdiGDQZPu0OduOVtIdMB7u7NGdaZ94AfjDbnxou6cA")

# Low RE Cost 2050
lowRECost_2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EXvT0HhvM-dEikIbzanWUbEBAvIzdQPbLDlLeViwWnpTfw")

"""
Low RE Cost TC Expire Scenarios Data
"""

# Low RE Cost TC Expire 2024
lowRECostTCE_2024df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EQFIEzfraMxDjiuJHwVykukB8euH9cvRJ0ZuJk7tzvO_TA")

# Low RE Cost TC Expire 2026
lowRECostTCE_2026df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EeM7Eu7n9NdJlEzL0GOZ2o4Bb97IS1BeqKsCQGWYSiBgtA")

# Low RE Cost TC Expire 2028
lowRECostTCE_2028df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/Ebg96qc11VBAmIGXXXnKyZ4BkqPLCddU6yh32It-uTQqNA")

# Low RE Cost TC Expire 2030
lowRECostTCE_2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EW2XCkZhb3VGiPClCkWL4DMBrsjQ067M1DUlrtnBczXu6g")

# Low RE Cost TC Expire 2035
lowRECostTCE_2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EdH8bM_UTqdIrgxwZUQZhVsBLaC_PZTHoNcVy2DWb4euCg")

# Low RE Cost TC Expire 2040
lowRECostTCE_2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ET-ALZRihnVGtPfQ1K3RHn4BH7EZWi_8ESA3-ghmJLlh5A")

# Low RE Cost TC Expire 2045
lowRECostTCE_2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EQtZYgRFTP1FgUPcs6Wmig8BTqWkSQ6Cq5Lzi7IPu9DLqQ")

# Low RE Cost TC Expire 2050
lowRECostTCE_2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EfP6cXZVmwhAs5XKIOcbtcoB0gXrGFmEARPlcuGHdEqtuQ")

"""
Mid Case Scenarios Data
"""

# Mid Case 2024
midcase_2024df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EU0MhHgaBj5EtTu2g22BXw8B9jUpbdZZ0uLU0gKkpKDOmQ")

# Mid Case 2026
midcase_2026df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ETQBwwx3w3tJnmpOyH_ioBoBebXuzSljjGt66Jz5yExP8g")

# Mid Case 2028
midcase_2028df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ETmg7jlxPSlDnlws4Lg0gGYB8ULV8hTdEo4lFhMe5KERKQ")

# Mid Case 2030
midcase_2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EQ11BQVSdoZKlStCsgbNAggBhqB_tAmWsYOmwRE50aparg")

# Mid Case 2035
midcase_2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EaZwdInAMrNClKwcObEOU30BiFVZ5UI7r0mATOolv6x4XQ")

# Mid Case 2040
midcase_2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EWxIOhdu2U1Nkmp9Mb9U_NMBqAxVope16to3IdnpxqtM6Q")

# Mid Case 2045
midcase_2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EXupfDNVYIpCnByp0HHXIXYBYeWvVKRlGAPlUP1j_vp8DQ")

# Mid Case 2050
midcase_2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EYdNXYEoJs9Gonl91c2Y5SsB8dKlYzBADVDRdgF7McFYBw")

"""
Mid Case 100 by 2035 Scenarios Data
"""

# Mid Case 100 2024
midcase100_2024df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EaJhSteK1bhDmFGyG_19K3EB-X9CGXXSouppUXhRcJcq_A")

# Mid Case 100 2026
midcase100_2026df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EXbK74g8pEdGkKOwP9oUOBABAY4F2l_XBJu5jqXfz-cgcQ")

# Mid Case 100 2028
midcase100_2028df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EYs5MxIKSttNhlMxIGF2BUIBhJd_B1mAHL-cp4UZVeAkIQ")

# Mid Case 100 2030
midcase100_2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EUKN9XQ-74BAgixylxmQwlYBEhW86vACOGARCYZZGcPdPA")

# Mid Case 100 2035
midcase100_2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ERtBJuXSwsBBp2hH63AslzoB7sCnK6bQZYNPtiLnCz6p1w")

# Mid Case 100 2040
midcase100_2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EfgeTMzKSj5Nr5WhbwgOTeMBkcTvT4MFHCpn8T8PQrN0bA")

# Mid Case 100 2045
midcase100_2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EdmWiQi0PclIn8ieapldzAoBuEj8YU_3MMHa_ELDSKFPMA")

# Mid Case 100 2050
midcase100_2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EU8hXGsSDOJOmbtgub28kD4Bbfl2ebJFev_nJo09vNljhg")

"""
Mid Case 95 by 2035 Scenarios Data
"""

# Mid Case 95 2024
midcase95_2024df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EXJQOUib6TVGmDNpRFiaCwcBVJaQGAEHWan_X65UMPXH8Q")

# Mid Case 95 2026
midcase95_2026df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EcY1X3Y5QjNEv0T-j0uADEkBEm3Vu8Z-qxCsHbqkcsdLwA")

# Mid Case 95 2028
midcase95_2028df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EcttazbTz9REr5swD1K20NwBdv_cJQn2Krr-x5mDwQitZw")

# Mid Case 95 2030
midcase95_2030df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EfKRtGz2rT9KjSTe2JgdT1cBo8GDRVryBD2IW3Mlu_AWaQ")

# Mid Case 95 2035
midcase95_2035df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EaRublfEzHpHknzxSCv0YPUBEuRGlQdNZuZwkT5BUotSUQ")

# Mid Case 95 2040
midcase95_2040df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EZ0WsVtzRWtMoOCZFIJ8PBEBL7R5NgIaNBHmwsYAygjZ8A")

# Mid Case 95 2045
midcase95_2045df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/EXKBdutb3WVElbgrv8x6eLQBMGcTMmT0nqDKU807Zr6ryQ")

# Mid Case 95 2050
midcase95_2050df = df_from_url("https://o365coloradoedu-my.sharepoint.com/:x:/g/personal/prra8307_colorado_edu/ESxZILpDkH5InMhMy5npH30B1vvj5JhAEoriW4cTUfN8bA")