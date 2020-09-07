# set the working dir, where all compiled verilog goes
vlib work

# compile all verilog modules in bgn_inputs.v to working dir
vlog se_inputs.v

#load simulation using control as the top level simulation module
vsim se_inputs

#log all signals and add some signals to waveform window
log -r {/*}
# add wave {/*} would add all items in top level simulation module
add wave {/*}

force {resetn} 0 0ns, 1 {20ns}
force {clk} 0 0ns, 1 {10ns} -r 20ns

force {go} 0 0ns, 1 20ns, 0 {40ns} 

run 400ns