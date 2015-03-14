vlib work
vmap work work

echo "Compiling Core Simulation Models"
vcom -work work ../../implement/results/routed.vhd

echo "Compiling Test Bench"
vcom -work work -novopt ../stimulus_tb.vhd ../demo_tb.vhd

echo "Starting simulation"
vsim -voptargs="+acc" +no_glitch_msg -t ps -sdfmax /dut=../../implement/results/routed.sdf work.demo_tb
add log -r *
do wave_mti.do
run -all

