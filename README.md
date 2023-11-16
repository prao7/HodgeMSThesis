# SMR Capacity and Production Cost Modeling
This is the public repository for all code in fulfillment for the M.S. Thesis for [Pradyumna Rao](https://www.linkedin.com/in/rao-pradyumna/). The thesis is advised by [Professor Bri-Mathias Hodge](https://www.colorado.edu/ecee/bri-mathias-hodge) of the [Renewable and Sustainable Energy Institute](https://www.colorado.edu/rasei/) and the [National Renewable Energy Laboratory](https://www.nrel.gov/).

Research explored in this repository pertains to exploration of penetration of Small Modular Reactors (SMR's) in power grids with high-renewable penetration using [MGA (Models to Generate Alternatives)](https://www.sciencedirect.com/science/article/pii/S1364815215301080).

# Research Questions
1. What cost scenario of SMR expansion in high-renewable systems with a carbon cap of zero can beat H<sub>2</sub> and DAC total system costs?
2. What mix of NR-HES and SMR + thermal storage has a lower system cost than a pure SMR mix in a high-renewable system with a carbon cap of zero?
3. How do current market structures affect capacity payouts and profitability for low carbon generators? Do we need to amend current structures to improve incentives for low to zero carbon generation?

# Production Cost Modeling for H<sub>2</sub> and DAC
Building on the work of [Anne Barlas](https://www.colorado.edu/faculty/hodge/anne-barlas) during her M.S. Thesis, the first aspect of the thesis is understanding the production cost modeling of an optimal system including H<sub>2</sub> and DAC in a zero carbon cap. This will serve as a baseline comparison for modeling scenarios for SMR penetration.

The production cost modeling takes the outputs of capacity expansion modeling by Anne Barlas using NREL's [ReEDS](https://www.nrel.gov/analysis/reeds/) to model annual operations using [PowerSimulations.jl](https://github.com/NREL-Sienna/PowerSimulations.jl).
