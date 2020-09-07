# set the working dir, where all compiled verilog goes
vlib work

# compile all verilog modules in gameofsquares.v to working dir
vlog gameofsquares.v

#load simulation using control as the top level simulation module
vsim control

#log all signals and add some signals to waveform window
log -r {/*}
# add wave {/*} would add all items in top level simulation module
add wave {/*}

force {clk} 0 0ns, 1 {10ns} -r 20ns
force {resetn} 0 0ns, 1 {20ns}
force {enter} 0 
force {left} 1 


run 2000000 ns