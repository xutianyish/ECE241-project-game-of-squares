# set the working dir, where all compiled verilog goes
vlib work

# compile all verilog modules in gameofsquares.v to working dir
vlog gameofsquares.v

#load simulation using datapath as the top level simulation module
vsim datapath

#log all signals and add some signals to waveform window
log -r {/*}
# add wave {/*} would add all items in top level simulation module
add wave {/*}

force {clk} 0 0ns, 1 {10ns} -r 20ns
force {resetn} 0 0ns, 1 {20ns}

#test initialize
#force {initialize} 1

#test ld_new_cursor_pos
#force {ld_new_cursor_pos} 1, 0 {40ns}
#force {ld_old_cursor_pos} 0
#force {left} 1
#force {right} 1
#force {up} 1
#force {down} 1

#draw cursor
#force {draw_cursor} 1 {40ns}

#test change_adjacent
#force {ld_board_colour} 1 40ns, 0 {60ns}
#force {change_adjacent} 1 40ns, 0 {60ns}

#test update
#force {update_board} 1 {60ns}
#force {end_display} 1
force {start_display} 1

run 2000000 ns