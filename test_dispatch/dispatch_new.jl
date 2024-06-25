using JuMP
using Gurobi
using DataFrames
using CSV
using XLSX
using PowerGraphics
using InfrastructureSystems
using PowerSystems
const PSY = PowerSystems
using PowerSimulations
const PSI = PowerSimulations
using TimeSeries
using Dates
using PlotlyJS
using Logging
using JSON

# Load the data
texas_sys_one = System("/Users/pradyrao/VSCode/HodgeMSThesis/test_dispatch/texas_test_systems/dwpt-bpv-lvlr-A0_T0_sys.json")
texas_sys_ev = System("/Users/pradyrao/VSCode/HodgeMSThesis/test_dispatch/texas_test_systems/dwpt-hs-lvlr-A100_T100_sys.json")
texas_sys_base = System("/Users/pradyrao/VSCode/HodgeMSThesis/test_dispatch/texas_test_systems/tamu_DA_LVLr_BasePV_sys.json")


function tamuSimEx(run_spot, ex_only, ev_adpt_level, method, sim_name, nsteps, case, start_date)
    # Level of EV adoption (value from 0 to 1)
    if ev_adpt_level == 1
        Adopt = "A100_"
    elseif ev_adpt_level == 0
        Adopt = "A0_"
    else
        Adopt = string("A", split(string(ev_adpt_level), ".")[2], "_")
        if sizeof(Adopt) == 3
            Adopt = string(split(Adopt, "_")[1], "0", "_")
        end
    end
    tran_set = string(Adopt, method)
    # Link to system
    if run_spot == "HOME"
        home_dir = "C:/Users/antho/github/tamu_ercot_dwpt"
        main_dir = "C:\\Users\\antho\\OneDrive - UCB-O365\\Active Research\\ASPIRE\\CoSimulation Project\\Julia_Modeling"
        DATA_DIR = "C:/Users/antho/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/data"
        OUT_DIR = "D:/outputs"
        RES_DIR = "D:/results"
        active_dir = "D:/active"
    elseif run_spot == "SEEC"
        home_dir = "C:/Users/A.J. Sauter/github/tamu_ercot_dwpt"
        main_dir = "C:\\Users\\A.J. Sauter\\OneDrive - UCB-O365\\Active Research\\ASPIRE\\CoSimulation Project\\Julia_Modeling"
        DATA_DIR = "C:/Users/A.J. Sauter/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/data"
        OUT_DIR = "C:/Users/A.J. Sauter/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/outputs"
        RES_DIR = "C:/Users/A.J. Sauter/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/results"
        active_dir = "C:/Users/A.J. Sauter/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/active"
    elseif run_spot == "Desktop"
        home_dir = "A:/Users/Documents/ASPIRE_Simulators/tamu_ercot_dwpt"
        main_dir = "A:/Users/AJ/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling"
        DATA_DIR = "A:/Users/AJ/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/data"
        OUT_DIR = "A:/Users/AJ/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/outputs"
        RES_DIR = "A:/Users/AJ/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/results"
        active_dir = "A:/Users/AJ/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/active"
    elseif run_spot == "Alpine"
        home_dir = "/home/ansa1773/tamu_ercot_dwpt"
        main_dir = "/scratch/alpine/ansa1773/SIIP_Modeling"
        DATA_DIR = "/projects/ansa1773/SIIP_Modeling/data"
        OUT_DIR = "/scratch/alpine/ansa1773/SIIP_Modeling/outputs"
        RES_DIR = "/scratch/alpine/ansa1773/SIIP_Modeling/results"
        active_dir = "/scratch/alpine/ansa1773/SIIP_Modeling/active"
    elseif run_spot == "Summit"
        home_dir = "/home/ansa1773/tamu_ercot_dwpt"
        main_dir = "/scratch/summit/ansa1773/SIIP_Modeling"
        DATA_DIR = "/projects/ansa1773/SIIP_Modeling/data"
        OUT_DIR = "/scratch/summit/ansa1773/SIIP_Modeling/outputs"
        RES_DIR = "/scratch/summit/ansa1773/SIIP_Modeling/results"
        active_dir = "/scratch/summit/ansa1773/SIIP_Modeling/active"
    end

    if ex_only == true
        println("Ex Only")
        system = System(joinpath(active_dir, string(sim_name, tran_set, "_sys.json")))
    elseif occursin(method, "T0") || occursin(method, "H0")
        if case == "bpv"
            # BasePV System
            system = System(joinpath(active_dir, "tamu_DA_LVLr_BasePV_sys.json"))
        elseif case == "hs"
            # Reduced_LVL System
            system = System(joinpath(active_dir, "tamu_DA_sys_LVLred.json"))
        end
    else
        if case == "bpv"
            # BasePV System
            system = System(joinpath(active_dir, "tamu_DA_LVLr_BasePV_sys.json"))
        elseif case == "hs"
            # Reduced_LVL System
            system = System(joinpath(active_dir, "tamu_DA_sys_LVLred.json"))
        end
        # INITIALIZE LOADS:
        # Get Bus Names
        cd(main_dir)
        bus_details = CSV.read("bus_load_coords.csv", DataFrame)
        bus_names = bus_details[:,1]
        load_names = bus_details[:,2]
        dim_loads = size(load_names)
        num_loads = dim_loads[1]

        # Set dates for sim
        dates = DateTime(2018, 1, 1, 0):Hour(1):DateTime(2019, 1, 2, 23)
        # Set forecast resolution
        resolution = Dates.Hour(1)

        # ADD CONDITIONAL FOR HOME vs TRANSIT vs MIXED
        if occursin("T", method)
            df = DataFrame(XLSX.readtable(string("ABM_Energy_Output_Transit_v8.xlsx"), "load_demand")) #maybe add dots back
        elseif occursin("H", method)
            df = DataFrame(XLSX.readtable(string("ABM_Energy_Output_Home_v8.xlsx"), "load_demand"))
        else
            print("Mixed condition selected. Not yet available.")
        end

        # Read from Excel File
        for x = 1: num_loads
            # Extract power demand column
            load_data = df[!, x+1]*ev_adpt_level;
            peak_load = maximum(load_data);
            # Convert to TimeArray
            load_array = TimeArray(dates, load_data);
            # Create forecast dictionary
            forecast_data = Dict()
            for i = 1:365
                strt = (i-1)*24+1
                finish = i*24+12
                #peak_load = maximum(load_data[strt:finish])
                forecast_data[dates[strt]] = load_data[strt:finish]
            end
            # Create deterministic time series data
            time_series = Deterministic("max_active_power",forecast_data, resolution);
            l_name = string(load_names[x], "_DWPT");
            new_load = get_component(PowerLoad, system, l_name)
            try
                remove_component!(system, new_load)
            catch
            end
            # Create new load
            new_load = PowerLoad(
                name = string(l_name), # ADD '_DWPT' to each bus name
                available = true,
                bus = get_component(Bus, system, bus_names[x]), # USE BUS_LOAD_COORDS.CSV COLUMN 1
                model = "ConstantPower",
                active_power = 1,
                reactive_power = 1,
                base_power = 100.0,
                max_active_power = 1,
                max_reactive_power = 1,
                services = [],
            )
            # Add component to system
            add_component!(system, new_load)
            # Add deterministic forecast to the system
            add_time_series!(system, new_load, time_series)
        end
        to_json(system, joinpath(active_dir, string(sim_name, tran_set, "_sys.json")), force=true)
        println("New active system file has been created.")
    end

    # START EXECUTION:
    println("MADE IT TO EXECUTION")
    cd(home_dir)
    #Create empty template
    template_uc = ProblemTemplate(NetworkModel(
        DCPPowerModel,
        use_slacks = true,
        duals = [NodalBalanceActiveConstraint] #CopperPlateBalanceConstraint
    ))

    #Injection Device Formulations
    set_device_model!(template_uc, ThermalMultiStart, ThermalMultiStartUnitCommitment) #ThermalCompactUnitCommitment)
    set_device_model!(template_uc, RenewableDispatch, RenewableFullDispatch)
    set_device_model!(template_uc, PowerLoad, StaticPowerLoad)
    set_device_model!(template_uc, HydroDispatch, FixedOutput)
    set_device_model!(template_uc, Line, StaticBranchUnbounded)
    set_device_model!(template_uc, Transformer2W, StaticBranchUnbounded)
    set_device_model!(template_uc, TapTransformer, StaticBranchUnbounded)
    #Service Formulations
    set_service_model!(template_uc, VariableReserve{ReserveUp}, RangeReserve)
    set_service_model!(template_uc, VariableReserve{ReserveDown}, RangeReserve)

    UC = DecisionModel(
            StandardCommitmentCC,
            template_uc,
            system;
            name = "UC",
            # Determine optimizer parameters
            optimizer = optimizer_with_attributes(
                Gurobi.Optimizer,
                "MIPGap" => 1e-2,
            ),
            system_to_file = false,
            initialize_model = false,
            calculate_conflict = true, # used for debugging
            optimizer_solve_log_print = true, # used for debugging
            direct_mode_optimizer = true,
            initial_time = DateTime("2018-01-01T00:00:00"),
        )
    models = SimulationModels(UC)
    UC.ext["cc_restrictions"] = JSON.parsefile(joinpath(active_dir, "cc_restrictions.json"));

    DA_sequence = SimulationSequence(
        models = models,
        #intervals = intervals,
        ini_cond_chronology = InterProblemChronology()
    )

    sim = Simulation(
        name = string(sim_name, tran_set),
        steps = nsteps,
        models = models,
        sequence = DA_sequence,
        initial_time = DateTime(string(start_date,"T00:00:00")),
        simulation_folder = OUT_DIR,
    )

    # Use serialize = false only during development
    build_out = build!(sim, serialize = false; console_level = Logging.Error, file_level = Logging.Info)
    execute_status = execute!(sim)

    if execute_status == PSI.RunStatus.FAILED
        cd(OUT_DIR)
        uc = sim.models[1]
        conflict = sim.internal.container.infeasibility_conflict
        print(conflict)
        io = open("conflictOutput.txt", "w");
        write(io, conflict);
        close(io);
    else
        results = SimulationResults(sim);
    end
return execute_status
end

function tamuSimRes(run_spot, ev_adpt_level, method, sim_name)
    # Level of EV adoption (value from 0 to 1)
    if ev_adpt_level == 1
        Adopt = "A100_"
    elseif ev_adpt_level == 0
        Adopt = "A0_"
    else
        Adopt = string("A", split(string(ev_adpt_level), ".")[2], "_")
        if sizeof(Adopt) == 3
            Adopt = string(split(Adopt, "_")[1], "0", "_")
        end
    end
    tran_set = string(Adopt, method)
    if run_spot == "HOME"
        home_dir = "C:/Users/antho/github/tamu_ercot_dwpt"
        main_dir = "C:\\Users\\antho\\OneDrive - UCB-O365\\Active Research\\ASPIRE\\CoSimulation Project\\Julia_Modeling"
        DATA_DIR = "C:/Users/antho/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/data"
        OUT_DIR = "D:/outputs"
        RES_DIR = "D:/results"
        active_dir = "D:/active"
    elseif run_spot == "SEEC"
        home_dir = "C:/Users/A.J. Sauter/github/tamu_ercot_dwpt"
        main_dir = "C:\\Users\\A.J. Sauter\\OneDrive - UCB-O365\\Active Research\\ASPIRE\\CoSimulation Project\\Julia_Modeling"
        DATA_DIR = "C:/Users/A.J. Sauter/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/data"
        OUT_DIR = "C:/Users/A.J. Sauter/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/outputs"
        RES_DIR = "C:/Users/A.J. Sauter/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/results"
        active_dir = "C:/Users/A.J. Sauter/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/active"
    elseif run_spot == "Desktop"
        home_dir = "A:/Users/Documents/ASPIRE_Simulators/tamu_ercot_dwpt"
        main_dir = "A:/Users/AJ/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling"
        DATA_DIR = "A:/Users/AJ/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/data"
        OUT_DIR = "A:/Users/AJ/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/outputs"
        RES_DIR = "A:/Users/AJ/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/Satellite_Execution/Result_Plots"
        active_dir = "A:/Users/AJ/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/active"
    elseif run_spot == "Alpine"
        home_dir = "/home/ansa1773/tamu_ercot_dwpt"
        main_dir = "/scratch/alpine/ansa1773/SIIP_Modeling"
        DATA_DIR = "/projects/ansa1773/SIIP_Modeling/data"
        OUT_DIR = "/scratch/alpine/ansa1773/SIIP_Modeling/outputs"
        RES_DIR = "/scratch/alpine/ansa1773/SIIP_Modeling/results"
        active_dir = "/scratch/alpine/ansa1773/SIIP_Modeling/active"
    elseif run_spot == "Summit"
        home_dir = "/home/ansa1773/tamu_ercot_dwpt"
        main_dir = "/scratch/alpine/ansa1773/SIIP_Modeling"
        DATA_DIR = "/projects/ansa1773/SIIP_Modeling/data"
        OUT_DIR = "/scratch/summit/ansa1773/SIIP_Modeling/outputs"
        RES_DIR = "/scratch/summit/ansa1773/SIIP_Modeling/results"
        active_dir = "/scratch/summit/ansa1773/SIIP_Modeling/active"
    end

    if !@isdefined(system)
        system = System(joinpath(active_dir, string(sim_name, tran_set, "_sys.json")))
    end
    if !@isdefined(results)
        # WHAT TO DO IF YOU ALREADY HAVE A RESULTS FOLDER:
        sim_folder = joinpath(OUT_DIR, string(sim_name, tran_set))
        sim_folder = joinpath(sim_folder, "$(maximum(parse.(Int64,readdir(sim_folder))))")
        results = SimulationResults(sim_folder);
    end

    uc_results = get_decision_problem_results(results, "UC");
    set_system!(uc_results, system)
    timestamps = get_realized_timestamps(uc_results);
    variables = read_realized_variables(uc_results);

    #NOTE: ALL READ_XXXX VARIABLES ARE IN NATURAL UNITS
    renPwr = read_realized_variable(uc_results, "ActivePowerVariable__RenewableDispatch");
    #thermPwr = read_realized_variable(uc_results, "ActivePowerVariable__ThermalMultiStart")
    thermPwr = read_realized_aux_variables(uc_results)["PowerOutput__ThermalMultiStart"];
    load_param = read_realized_parameter(uc_results, "ActivePowerTimeSeriesParameter__PowerLoad");
    resUp_param = read_realized_parameter(uc_results, "RequirementTimeSeriesParameter__VariableReserve__ReserveUp__REG_UP");
    resDown_param = read_realized_parameter(uc_results, "RequirementTimeSeriesParameter__VariableReserve__ReserveDown__REG_DN");
    resSpin_param = read_realized_parameter(uc_results, "RequirementTimeSeriesParameter__VariableReserve__ReserveUp__SPIN");
    slackup_var = read_realized_variable(uc_results, "SystemBalanceSlackUp__Bus");
    slackdwn_var = read_realized_variable(uc_results, "SystemBalanceSlackDown__Bus");
    thermPcost = read_realized_expression(uc_results, "ProductionCostExpression__ThermalMultiStart");

    # FOR HANDLING SLACK VARIABLES (UNRESERVED LOAD)
    # Current number of buses
    bus_num = size(slackup_var[1,:])[1]
    sys_slackup = zeros(size(slackup_var[!,1])[1])
    sys_slackdwn = zeros(size(slackup_var[!,1])[1])
    for x in 1:size(slackup_var[!,1])[1]
        sys_slackup[x] = sum(slackup_var[x, 2:bus_num])
        sys_slackdwn[x] = sum(slackdwn_var[x, 2:bus_num])
    end
    slackdf = DataFrame()
    insertcols!(slackdf, 1, :DateTime => slackdwn_var[!,1])
    insertcols!(slackdf, 2, :SlackUp => sys_slackup)
    insertcols!(slackdf, 3, :SlackDown => sys_slackdwn)

    # SYSTEM PRODUCTION COST CALCULATION
    sys_cost = zeros(size(thermPcost[!,1])[1])
    gen_num = size(thermPcost[1,:])[1]
    for x = 1:size(sys_cost)[1]
        sys_cost[x] = sum(thermPcost[x, 2:gen_num])
    end
    sysCost = DataFrame()
    insertcols!(sysCost, 1, :DateTime => thermPcost[!,1])
    insertcols!(sysCost, 2, :ProductionCost => sys_cost)

    # SYSTEM DEMAND
    load_num = size(load_param[1, :])[1];
    sys_demand = zeros(size(load_param[!, 1])[1]);
    for x=1:size(sys_demand)[1]
       sys_demand[x] = sum(load_param[x, 2:load_num])
    end
    sysDemand = DataFrame()
    insertcols!(sysDemand, 1, :DateTime => load_param[!, 1]);
    insertcols!(sysDemand, 2, :SystemDemand => -sys_demand);

    # Write Excel Output Files
    cd(string(RES_DIR))
    xcelname = string("_Output_", sim_name, tran_set, ".xlsx")
    # Simple XLSX file output with ability to overwrite
    XLSX.writetable(
        string("PROD_COST", xcelname),
        sysCost,
        overwrite=true,
        sheetname="Prod_Cost",
        anchor_cell="A1"
    )
    XLSX.writetable(
        string("RE_GEN", xcelname),
        renPwr,
        overwrite=true,
        sheetname="RE_Dispatch",
        anchor_cell="A1"
    )
    XLSX.writetable(
        string("TH_GEN", xcelname),
        thermPwr,
        overwrite=true,
        sheetname="TH_Dispatch",
        anchor_cell="A1"
    )
    XLSX.writetable(
        string("Slack", xcelname),
        slackdf,
        overwrite=true,
        sheetname="Slack",
        anchor_cell="A1"
    )

    XLSX.writetable(
        string("DEMAND", xcelname),
        load_param,
        overwrite=true,
        sheetname="Demand",
        anchor_cell = "A1"
    )
    XLSX.writetable(
        string("SysDemand", xcelname),
        sysDemand,
        overwrite=true,
        sheetname="sys demand MWh",
        anchor_cell="A1"
    )
#    XLSX.writetable(
#        string("RESERVES", xcelname),
#        resUp_param,
#        overwrite=true,
#        sheetname="ResUP",
#        anchor_cell = "A1"
#    )
#    XLSX.writetable(
#        string("RESERVES", xcelname),
#        resDown_param,
#        overwrite=true,
#        sheetname="ResDWN",
#        anchor_cell = "A1"
#    )
#    XLSX.writetable(
#        string("RESERVES", xcelname),
#        resSpin_param,
#        overwrite=true,
#        sheetname="ResSPIN",
#        anchor_cell = "A1"
#    )
    # XLSX.writetable(
    #     string("DUALS", xcelname),
    #     duals,
    #     overwrite=true,
    #     sheetname="Duals Outputs",
    #     anchor_cell = "A1"
    # )

    tamuCurt(case, ev_adpt_level)

    ngCCList = []
    ngCC_pwr = 0
    ngCTList = []
    ngCT_pwr = 0
    ngSTList = []
    ngST_pwr = 0
    ng_List = []
    ng_pwr = 0
    coList = []
    co_pwr = 0
    nucList = []
    nuc_pwr = 0
    thermList = collect(get_components(ThermalMultiStart, system));
    for x = 1:size(thermList)[1]
        if "NATURAL_GAS" == string(thermList[x].fuel)
            if "CC" == string(thermList[x].prime_mover)
                append!(ngCCList, [thermList[x].name])
                ngCC_pwr = ngCC_pwr + sum(thermPwr[!,thermList[x].name])
            elseif "CT" == string(thermList[x].prime_mover)
                append!(ngCTList, [thermList[x].name])
                ngCT_pwr = ngCT_pwr + sum(thermPwr[!, thermList[x].name])
            elseif "ST" == string(thermList[x].prime_mover)
                append!(ngSTList, [thermList[x].name])
                ngST_pwr = ngST_pwr + sum(thermPwr[!, thermList[x].name])
            else
                append!(ng_List, [thermList[x].name])
                ng_pwr = ng_pwr + sum(thermPwr[!, thermList[x].name])
            end
        elseif "COAL" == string(thermList[x].fuel)
            append!(coList, [thermList[x].name])
            co_pwr = co_pwr + sum(thermPwr[!, thermList[x].name])
        elseif "NUCLEAR" == string(thermList[x].fuel)
            append!(nucList, [thermList[x].name])
            nuc_pwr = nuc_pwr + sum(thermPwr[!, thermList[x].name])
        end
    end
    ngCC = DataFrame();
    ngCT = DataFrame();
    ngST = DataFrame();
    insertcols!(ngCC, 1, :DateTime => thermPwr[!, 1]);
    insertcols!(ngCT, 1, :DateTime => thermPwr[!, 1]);
    insertcols!(ngST, 1, :DateTime => thermPwr[!, 1]);
    for x=1:size(ngCCList)[1]
        insertcols!(ngCC, ngCCList[x] => thermPwr[!, ngCCList[x]]);
    end
    for x=1:size(ngCTList)[1]
        insertcols!(ngCT, ngCTList[x] => thermPwr[!, ngCTList[x]]);
    end
    for x=1:size(ngSTList)[1]
        insertcols!(ngST, ngSTList[x] => thermPwr[!, ngSTList[x]]);
    end
    ngCC_hourly = []
    ngCT_hourly = []
    ngST_hourly = []
    for x=1:8760
        append!(ngCC_hourly, sum(ngCC[x, 2:size(ngCCList)[1]]))
        append!(ngCT_hourly, sum(ngCT[x, 2:size(ngCTList)[1]]))
        append!(ngST_hourly, sum(ngST[x, 2:size(ngSTList)[1]]))
    end
    thermPwrByType = DataFrame()
    insertcols!(thermPwrByType, 1, :DateTime => thermPwr[!, 1]);
    insertcols!(thermPwrByType, 2, :ngCC => ngCC_hourly);
    insertcols!(thermPwrByType, 3, :ngCT => ngCT_hourly);
    insertcols!(thermPwrByType, 4, :ngST => ngST_hourly);
    cd(string(RES_DIR))
    xcelname = string("_Output_", sim_name, tran_set, ".xlsx")
    # Simple XLSX file output with ability to overwrite
    XLSX.writetable(
        string("Therm_By_Type_", xcelname),
        thermPwrByType,
        overwrite=true,
        sheetname="Thermal",
        anchor_cell="A1"
    )

    # Total Hydropowr
    hydPwr = read_realized_parameter(uc_results, "ActivePowerTimeSeriesParameter__HydroDispatch");
    hydPwr2 = hydPwr[!, 2:34]
    tot_hydPwr = sum(sum(eachcol(hydPwr2)))

    renPwr = read_realized_variable(uc_results, "ActivePowerVariable__RenewableDispatch");
    # Split between Solar and Wind
    windList = []
    wind_pwr = 0
    pvList = []
    pv_pwr = 0
    renList = collect(get_components(RenewableDispatch, system));
    for x = 1:size(renList)[1]
        if renList[x].available == true
            if "WT" == string(renList[x].prime_mover)
                append!(windList, [renList[x].name])
                wind_pwr = wind_pwr + sum(renPwr[!,renList[x].name])
            elseif "PVe" == string(renList[x].prime_mover)
                append!(pvList, [renList[x].name])
                pv_pwr = pv_pwr + sum(renPwr[!, renList[x].name])
            end
        end
    end

    AnnGen = DataFrame()
    insertcols!(AnnGen, 1, :Nuclear => nuc_pwr);
    insertcols!(AnnGen, 2, :Coal => co_pwr);
    insertcols!(AnnGen, 3, :NG_Other => ng_pwr);
    insertcols!(AnnGen, 4, :NG_ST => ngST_pwr);
    insertcols!(AnnGen, 5, :NG_CT => ngCT_pwr);
    insertcols!(AnnGen, 6, :NG-CC => ngCC_pwr);
    insertcols!(AnnGen, 7, :Hydro => tot_hydPwr);
    insertcols!(AnnGen, 8, :Wind => wind_pwr);
    insertcols!(AnnGen, 9, :PV => pv_pwr);

    XLSX.writetable(
        string("Ann_Generation_", xcelname),
        AnnGen,
        overwrite=true,
        sheetname="Thermal",
        anchor_cell="A1"
    )

    # Execute Plotting
#    gr() # Loads the GR backend
#    plotlyjs() # Loads the JS backend
    # STACKED GENERATION PLOT:
    #dem_name = string("PowerLoadDemand", sim_name, tran_set)
    #plot_demand(load_param, slackup_var, stack = true; title = dem_name, save = string(RES_DIR, date_folder), format = "svg");
    #plot_dataframe(load_param, slackup_var, stack = true; title = dem_name, save = string(RES_DIR, date_folder), format = "svg");
    # Stacked Gen by Fuel Type:
    p2 = plot_fuel(uc_results);
    PlotlyJS.savefig(p2, string("FuelPlot_", sim_name, tran_set, ".pdf"), width = 400*5, height = 400 )
    #To Specify Window: initial_time = DateTime("2018-01-01T00:00:00"), count = 168
    #plot_dataframe(renPwr, thermPwr, stack = true; title = fuelgen, save = string(RES_DIR, date_folder), format = "svg");
    # Reserves Plot
    #resgen = string("Reserves", sim_name, tran_set)
    #plot_dataframe(resUp_param, resDown_param; title = resgen, save = string(RES_DIR, date_folder), format = "svg");

end

function tamuProd(case, ev_adpt_level)
    home_dir = "C:/Users/antho/github/tamu_ercot_dwpt"
    OUT_DIR = "D:/outputs/CompactThermal Set 1"
    RES_DIR = "C:/Users/antho/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/Satellite_Execution/Result_Plots"
    if ev_adpt_level == 1
        Adopt = "A100"
    else
        Adopt = string("A", split(string(ev_adpt_level), ".")[2], "_")
        if sizeof(Adopt) == 3
            Adopt = string(split(Adopt, "_")[1], "0", "_")
        end
    end
    method = "T100"
    tran_set = string(Adopt, method)
    sim_name = string("dwpt-", case, "-lvlr-")
    sim_folder = joinpath(OUT_DIR, string(sim_name, tran_set))
    sim_folder = joinpath(sim_folder, "$(maximum(parse.(Int64,readdir(sim_folder))))")
    results = SimulationResults(sim_folder; ignore_status=true);
    uc_results = get_decision_problem_results(results, "UC")

    thermPcost = read_realized_expression(uc_results, "ProductionCostExpression__ThermalMultiStart");
    # SYSTEM PRODUCTION COST CALCULATION
    sys_cost = zeros(size(thermPcost[!,1])[1]);
    gen_num = size(thermPcost[1,:])[1];
    for x = 1:size(sys_cost)[1]
        sys_cost[x] = sum(thermPcost[x, 2:gen_num]);
    end
    sysCost = DataFrame()
    insertcols!(sysCost, 1, :DateTime => thermPcost[!,1]);
    insertcols!(sysCost, 2, :ProductionCost => sys_cost);

    date_folder = "/Mar29_22"
    cd(string(RES_DIR, date_folder))
    xcelname = string("_Output", sim_name, tran_set, ".xlsx")
    XLSX.writetable(
        string("PROD_COST_NEW", xcelname),
        sysCost,
        overwrite=true,
        sheetname="Prod_Cost",
        anchor_cell="A1"
    )
end


function tamuCurt(case, ev_adpt_level)
    # Level of EV adoption (value from 0 to 1)
    if ev_adpt_level == 1
        Adopt = "A100_"
    elseif ev_adpt_level == 0
        Adopt = "A0_"
    else
        Adopt = string("A", split(string(ev_adpt_level), ".")[2], "_")
        if sizeof(Adopt) == 3
            Adopt = string(split(Adopt, "_")[1], "0", "_")
        end
    end
    method = "T100"
    tran_set = string(Adopt, method)
    sim_name = string("dwpt-", case, "-lvlr-")
    system = System(joinpath(active_dir, string(sim_name, tran_set, "_sys.json")));
    sim_folder = joinpath(OUT_DIR, string(sim_name, tran_set))
    sim_folder = joinpath(sim_folder, "$(maximum(parse.(Int64,readdir(sim_folder))))")
    results = SimulationResults(sim_folder; ignore_status=true);
    uc_results = get_decision_problem_results(results, "UC")
    renPwr = read_realized_variable(uc_results, "ActivePowerVariable__RenewableDispatch");

    # CURTAILMENT CALCULATION
    renList = collect(get_components(RenewableDispatch, system));
    ren_tot = zeros(8760);
    for x = 1:size(renList)[1]
        if renList[x].name in names(renPwr)
            new_ren = get_component(RenewableDispatch, system, renList[x].name)
            ren_data = get_time_series(Deterministic, new_ren, "max_active_power", count = 365).data;
            for d = 1:365
                for h in 1:24
                    forecast_window_hr = collect(ren_data)[d][2][h]
                    forecast_window_hr *= get_max_active_power(new_ren)*100
                    ren_tot[((d-1)*24)+h] = ren_tot[((d-1)*24)+h] + forecast_window_hr
                end
            end
        else
            print(renList[x].name)
        end
    end

    print(sum(ren_tot))
    ren_tot = ren_tot[1:size(renPwr[!,1])[1]];
    ren_pwr = zeros(size(renPwr[!,1])[1]);
    curt = zeros(size(renPwr[!,1])[1]);
    ren_num = size(renPwr[1,:])[1];
    for x = 1:size(ren_pwr)[1]
        ren_pwr[x] = sum(renPwr[x, 2:ren_num])
        curt[x] = ren_tot[x] - ren_pwr[x]#ren_tot_2w[x] - ren_pwr[x]
    end

    Curtail = DataFrame()
    insertcols!(Curtail, 1, :DateTime => renPwr[!, 1]);
    insertcols!(Curtail, 2, :Curtailment => curt);

    cd(RES_DIR)
    xcelname = string("_Output_", sim_name, tran_set, ".xlsx")
    XLSX.writetable(
        string("Curtailment", xcelname),
        Curtail,
        overwrite=true,
        sheetname="Curtailment",
        anchor_cell="A1"
    )

    return Curtail
end
function tamuGen(case, ev_adpt_level)
    home_dir = "C:/Users/antho/github/tamu_ercot_dwpt"
    OUT_DIR = "D:/outputs/High-Solar/In-Transit"
    RES_DIR = "C:/Users/antho/OneDrive - UCB-O365/Active Research/ASPIRE/CoSimulation Project/Julia_Modeling/Satellite_Execution/Result_Plots"
    if ev_adpt_level == 1
        Adopt = "A100"
    else
        Adopt = string("A", split(string(ev_adpt_level), ".")[2], "_")
        if sizeof(Adopt) == 3
            Adopt = string(split(Adopt, "_")[1], "0", "_")
        end
    end
    method = "T100"
    tran_set = string(Adopt, method)
    sim_name = string("dwpt-", case, "-lvlr-")
    sim_folder = joinpath(OUT_DIR, string(sim_name, tran_set))
    sim_folder = joinpath(sim_folder, "$(maximum(parse.(Int64,readdir(sim_folder))))")
    results = SimulationResults(sim_folder; ignore_status=true);
    uc_results = get_decision_problem_results(results, "UC")

    thermPwr = read_realized_aux_variables(uc_results)["PowerOutput__ThermalMultiStart"];
    sys_pwr = zeros(size(renPwr[!,1])[1]);
    therm_num = size(thermPwr[1,:])[1];
    for x = 1:size(sys_pwr)[1]
#        sys_pwr[x] = (sum(renPwr[x, 2:ren_num]) + sum(thermPwr[x, 2:therm_num]))*100
        sys_pwr[x] = sum(thermPwr[x, 2:therm_num])*100
    end

    ThPwr = DataFrame()
    insertcols!(ThPwr, 1, :DateTime => thermPwr[!, 1]);
    insertcols!(ThPwr, 2, :ThermPower => sys_pwr);
    date_folder = "/Mar29_22"
    cd(string(RES_DIR, date_folder))
    xcelname = string("_Output", sim_name, tran_set, ".xlsx")

    XLSX.writetable(
        string("TH_GEN", xcelname),
        ThPwr,
        overwrite=true,
        sheetname="TH_Dispatch",
        anchor_cell="A1"
    )
end