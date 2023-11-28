using DataFrame
using Statistics
using CSV
using HTTP

include("data.jl")
include("smrsimulationfunctions.jl")

"""
The following function runs a NPV calculation for implementation of a 
"""

# Project   Type     Capacity [MWel]  Lifetime [years]  Construction Cost [USD2020/MWel]  Fuel cost [USD2020/MWh]  O&M cost [USD2020/MWel] 