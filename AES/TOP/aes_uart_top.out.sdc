set_time_format -unit ns -decimal_places 3

#**************************************************************
# 1. CREATE CLOCKS
#**************************************************************

create_clock -name clk_100 \
    -period 10.000 \
    -waveform {0.000 5.000} \
    [get_ports clk_100]

create_clock -name clk_25 \
    -period 40.000 \
    -waveform {0.000 20.000} \
    [get_ports clk_25]



#**************************************************************
# 2. CLOCK UNCERTAINTY (VERY IMPORTANT)
# Models jitter + skew (makes timing realistic)
#**************************************************************

# Setup uncertainty
#set_clock_uncertainty -setup 2.00 -from [get_clocks clk_100] -to [get_clocks clk_100]
#set_clock_uncertainty -setup 0.50 -from [get_clocks clk_25] -to [get_clocks clk_25]
#set_clock_uncertainty -setup 2.00 -from [get_clocks clk_100] -to [get_clocks clk_25]


# Hold uncertainty
set_clock_uncertainty -hold 1.00 -from [get_clocks clk_100] -to [get_clocks clk_100]
set_clock_uncertainty -hold 0.10 -from [get_clocks clk_25] -to [get_clocks clk_25]


#**************************************************************
# 3. CLOCK GROUPING (USE CAREFULLY)
#**************************************************************

# ONLY keep this IF clocks are truly asynchronous (external sources)
# If clk_3125_* are derived from clk_100, REMOVE THIS SECTION

set_clock_groups -asynchronous \
    -group {clk_100} \
    -group {clk_25}
	 


#**************************************************************
# 4. RESET & STATIC PATHS
#**************************************************************

# Async reset (very likely in your design)
set_false_path -from [get_ports rst]

# Optional: ignore debug I/O if timing not critical
# set_false_path -to   [get_ports {led[*]}]
# set_false_path -from [get_ports {sw[*]}]


#**************************************************************
# 5. INPUT / OUTPUT DELAYS (ESSENTIAL FOR REAL DESIGN)
#**************************************************************

# These are assumptions — adjust based on board/system

# Inputs to FPGA
set_input_delay  -clock clk_100 -max 2.0 [get_ports {in}]
set_input_delay  -clock clk_100 -min 0.5 [get_ports {in}]
set_input_delay  -clock clk_100 -max 2.0 [get_ports {rst}]
set_input_delay  -clock clk_100 -min 0.5 [get_ports {rst}]

# Outputs from FPGA
set_output_delay -clock clk_100 -max 2.0 [get_ports {out}]
set_output_delay -clock clk_100 -min 0.5 [get_ports {out}]
set_output_delay -clock clk_100 -max 2.0 [get_ports {done}]
set_output_delay -clock clk_100 -min 0.5 [get_ports {done}]


#**************************************************************
# 6. MULTICYCLE PATH (ONLY IF ARCHITECTURE SUPPORTS IT)
#**************************************************************

# ⚠️ ENABLE ONLY if AES is multi-cycle by design
# set_multicycle_path 2 -setup \
#     -from [get_registers *aes*] \
#     -to   [get_registers *aes*]

# set_multicycle_path 1 -hold \
#     -from [get_registers *aes*] \
#     -to   [get_registers *aes*]


#**************************************************************
# 7. GENERATED CLOCKS (IF USING CLOCK DIVIDERS / PLL)
#**************************************************************

# ⚠️ ADD ONLY if clk_3125_* are internally generated

# Example:
# create_generated_clock -name clk_25_tx \
#     -source [get_ports clk_100] \
#     -divide_by 4 \
#     [get_pins <divider_output>]


#**************************************************************
# 8. OPTIONAL: MINIMIZE CDC RISK (ADVANCED)
#**************************************************************

# If using synchronizers:
# set_false_path -from [get_registers *sync_ff1*] \
#                -to   [get_registers *sync_ff2*]