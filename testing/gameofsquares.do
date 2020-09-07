# set the working dir, where all compiled verilog goes
vlib work

# compile all verilog modules in gameofsquares.v to working dir
vlog gameofsquares.v



#load simulation using control as the top level simulation module
vsim vgainputs


#log all signals and add some signals to waveform window
log -r {/*}
# add wave {/*} would add all items in top level simulation module
add wave {/*}

force {clk} 0 0ns, 1 {10ns} -r 20ns
force {resetn} 0 0ns, 1 {20ns}
force {enter} 0 0ns, 1 20ns, 0 40ns, 1 340ns, 0 360ns, 1 720ns, 0 740ns, 1 1100ns, 0 1120ns, 1 1480ns, 0 1500ns, 1 1860ns, 0 {1880ns}
force {left} 0 0ns, 1 140ns, 0 160ns, 1 1280ns, 0 1300ns, 1 1380ns, 0 {1400ns}
force {right} 0 0ns, 1 520ns, 0 540ns, 1 620ns, 0 640ns, 1 1660ns, 0 {1680ns}
force {up} 0 0ns, 1 240ns, 0 260ns, 1 1760ns, 0 {1780ns}
force {down} 0 0ns, 1 900ns, 0 920ns, 1 1000ns, 0 {1020ns}


run 2100 ns