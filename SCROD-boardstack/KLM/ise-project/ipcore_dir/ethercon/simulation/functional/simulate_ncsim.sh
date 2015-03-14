#!/bin/sh
mkdir work

echo "Compiling Core Simulation Models"
ncvhdl -v93 -work work ../../../ethercon.vhd

echo "Compiling Example Design"
ncvhdl -v93 -work work \
../../example_design/sync_block.vhd \
../../example_design/reset_sync.vhd \
../../example_design/transceiver/s6_gtpwizard_tile.vhd \
../../example_design/transceiver/s6_gtpwizard.vhd \
../../example_design/transceiver/transceiver_A.vhd \
../../example_design/tx_elastic_buffer.vhd \
../../example_design/ethercon_block.vhd \
../../example_design/ethercon_example_design.vhd

echo "Compiling Test Bench"
ncvhdl -v93 -work work ../stimulus_tb.vhd ../demo_tb.vhd

echo "Elaborating design"
ncelab -access +rw work.demo_tb:behav

echo "Starting simulation"
ncsim -gui work.demo_tb:behav -input @"simvision -input wave_ncsim.sv"
