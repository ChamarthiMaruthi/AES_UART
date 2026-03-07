## Generated SDC file "aes_uart_top.out.sdc"

## Copyright (C) 2020  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details, at
## https://fpgasoftware.intel.com/eula.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 20.1.0 Build 711 06/05/2020 SJ Lite Edition"

## DATE    "Thu Mar  5 12:24:50 2026"

##
## DEVICE  "5CGXFC9E6F35I7"
##


set_time_format -unit ns -decimal_places 3


#**************************************************************
# Create Clock
# FIX #1: Corrected clock periods to match actual frequencies
#   clk_100     = 100 MHz  -> period = 10.000 ns
#   clk_3125_tx = 3.125 MHz -> period = 320.000 ns
#   clk_3125_rx = 3.125 MHz -> period = 320.000 ns
#**************************************************************

create_clock -name {clk_100}     -period 10.000  -waveform { 0.000 5.000   } [get_ports {clk_100}]
create_clock -name {clk_3125_tx} -period 320.000 -waveform { 0.000 160.000 } [get_ports {clk_3125_tx}]
create_clock -name {clk_3125_rx} -period 320.000 -waveform { 0.000 160.000 } [get_ports {clk_3125_rx}]


#**************************************************************
# Create Generated Clock
# (Add here if any clocks are derived from clk_100 via logic dividers)
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
# (Retaining existing values - these are reasonable)
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {clk_3125_rx}] -rise_to [get_clocks {clk_3125_rx}] -setup 0.100
set_clock_uncertainty -rise_from [get_clocks {clk_3125_rx}] -rise_to [get_clocks {clk_3125_rx}] -hold  0.060
set_clock_uncertainty -rise_from [get_clocks {clk_3125_rx}] -fall_to [get_clocks {clk_3125_rx}] -setup 0.100
set_clock_uncertainty -rise_from [get_clocks {clk_3125_rx}] -fall_to [get_clocks {clk_3125_rx}] -hold  0.060
set_clock_uncertainty -fall_from [get_clocks {clk_3125_rx}] -rise_to [get_clocks {clk_3125_rx}] -setup 0.100
set_clock_uncertainty -fall_from [get_clocks {clk_3125_rx}] -rise_to [get_clocks {clk_3125_rx}] -hold  0.060
set_clock_uncertainty -fall_from [get_clocks {clk_3125_rx}] -fall_to [get_clocks {clk_3125_rx}] -setup 0.100
set_clock_uncertainty -fall_from [get_clocks {clk_3125_rx}] -fall_to [get_clocks {clk_3125_rx}] -hold  0.060

set_clock_uncertainty -rise_from [get_clocks {clk_100}] -rise_to [get_clocks {clk_100}] -setup 0.100
set_clock_uncertainty -rise_from [get_clocks {clk_100}] -rise_to [get_clocks {clk_100}] -hold  0.060
set_clock_uncertainty -rise_from [get_clocks {clk_100}] -fall_to [get_clocks {clk_100}] -setup 0.100
set_clock_uncertainty -rise_from [get_clocks {clk_100}] -fall_to [get_clocks {clk_100}] -hold  0.060
set_clock_uncertainty -fall_from [get_clocks {clk_100}] -rise_to [get_clocks {clk_100}] -setup 0.100
set_clock_uncertainty -fall_from [get_clocks {clk_100}] -rise_to [get_clocks {clk_100}] -hold  0.060
set_clock_uncertainty -fall_from [get_clocks {clk_100}] -fall_to [get_clocks {clk_100}] -setup 0.100
set_clock_uncertainty -fall_from [get_clocks {clk_100}] -fall_to [get_clocks {clk_100}] -hold  0.060

set_clock_uncertainty -rise_from [get_clocks {clk_3125_tx}] -rise_to [get_clocks {clk_3125_tx}] -setup 0.100
set_clock_uncertainty -rise_from [get_clocks {clk_3125_tx}] -rise_to [get_clocks {clk_3125_tx}] -hold  0.060
set_clock_uncertainty -rise_from [get_clocks {clk_3125_tx}] -fall_to [get_clocks {clk_3125_tx}] -setup 0.100
set_clock_uncertainty -rise_from [get_clocks {clk_3125_tx}] -fall_to [get_clocks {clk_3125_tx}] -hold  0.060
set_clock_uncertainty -fall_from [get_clocks {clk_3125_tx}] -rise_to [get_clocks {clk_3125_tx}] -setup 0.100
set_clock_uncertainty -fall_from [get_clocks {clk_3125_tx}] -rise_to [get_clocks {clk_3125_tx}] -hold  0.060
set_clock_uncertainty -fall_from [get_clocks {clk_3125_tx}] -fall_to [get_clocks {clk_3125_tx}] -setup 0.100
set_clock_uncertainty -fall_from [get_clocks {clk_3125_tx}] -fall_to [get_clocks {clk_3125_tx}] -hold  0.060


#**************************************************************
# Set Clock Groups
# FIX #2: Declare all 3 clocks as asynchronous to each other
# This eliminates false cross-domain setup/hold violations
#**************************************************************

set_clock_groups -asynchronous \
    -group { clk_100     } \
    -group { clk_3125_tx } \
    -group { clk_3125_rx }


#**************************************************************
# Set False Path
# FIX #3: Async resets, I/O pins, or any other static paths
#**************************************************************

## Example: If rst_n is asynchronous (driven from a button, not synchronized)
## set_false_path -from [get_ports {rst_n}]

## Example: If there are output/input ports that don't need timing
## set_false_path -to   [get_ports {led[*]}]
## set_false_path -from [get_ports {sw[*]}]


#**************************************************************
# Set Multicycle Path
# FIX #4: AES round logic takes more than 1 cycle combinationally
# If AES state machine holds inputs stable for N cycles, declare it:
#**************************************************************

## Example: AES datapath combinational logic is too deep for 10ns
## If the AES FSM holds state for 2 cycles before sampling:
## set_multicycle_path -from [get_registers {*u_aes*}] \
##                    -to   [get_registers {*u_aes*}] \
##                    -setup 2
## set_multicycle_path -from [get_registers {*u_aes*}] \
##                    -to   [get_registers {*u_aes*}] \
##                    -hold 1


#**************************************************************
# Set Input/Output Delay (Optional - add if needed for I/O timing)
#**************************************************************

## set_input_delay  -clock {clk_100} -max 2.000 [get_ports {plaintext[*]}]
## set_input_delay  -clock {clk_100} -min 0.500 [get_ports {plaintext[*]}]
## set_output_delay -clock {clk_100} -max 2.000 [get_ports {ciphertext[*]}]
## set_output_delay -clock {clk_100} -min 0.500 [get_ports {ciphertext[*]}]