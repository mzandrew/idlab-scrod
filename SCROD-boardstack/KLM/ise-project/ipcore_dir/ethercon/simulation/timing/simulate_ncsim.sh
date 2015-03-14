#!/bin/sh
mkdir work

echo "Compiling Core Simulation Models"
ncvhdl -v93 -work work ../../implement/results/routed.vhd

echo "Compiling Test Bench"
ncvhdl -v93 -work work ../stimulus_tb.vhd ../demo_tb.vhd

echo "Compiling SDF file"
ncsdfc ../../implement/results/routed.sdf -output ./routed.sdf.X

echo "Generating SDF command file"
echo 'COMPILED_SDF_FILE = "routed.sdf.X",' > sdf.cmd
echo 'SCOPE = behav.dut,' >> sdf.cmd
echo 'MTM_CONTROL = "MAXIMUM";' >> sdf.cmd

echo "Elaborating design"
ncelab -no_tchk_msg -no_vpd_msg -access +rw -sdf_cmd_file sdf.cmd work.demo_tb:behav

echo "Starting simulation"
ncsim -gui work.demo_tb:behav -input @"simvision -input wave_ncsim.sv"
