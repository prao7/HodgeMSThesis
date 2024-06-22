using JuMP
using Gurobi
using DataFrames
using CSV
using PowerSystems
const PSY = PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using TimeSeries
using Dates

# Load the data
texas_sys_one = System("/Users/pradyrao/VSCode/HodgeMSThesis/test_dispatch/texas_test_systems/dwpt-bpv-lvlr-A0_T0_sys.json")
texas_sys_ev = System("/Users/pradyrao/VSCode/HodgeMSThesis/test_dispatch/texas_test_systems/dwpt-hs-lvlr-A100_T100_sys.json")
texas_sys_base = System("/Users/pradyrao/VSCode/HodgeMSThesis/test_dispatch/texas_test_systems/tamu_DA_LVLr_BasePV_sys.json")

