vlib work
vmap work work

echo "Compiling Core Simulation Models"
vcom -work work ../../../ethercon.vhd

echo "Compiling Example Design"
vcom -work work \
../../example_design/sync_block.vhd \
../../example_design/reset_sync.vhd \
../../example_design/transceiver/s6_gtpwizard_tile.vhd \
../../example_design/transceiver/s6_gtpwizard.vhd \
../../example_design/transceiver/transceiver_A.vhd \
../../example_design/tx_elastic_buffer.vhd \
../../example_design/ethercon_block.vhd \
../../example_design/ethercon_example_design.vhd

echo "Compiling Test Bench"
vcom -work work -novopt ../stimulus_tb.vhd ../demo_tb.vhd

echo "Starting simulation"
vsim -voptargs="+acc" -t ps work.demo_tb
do wave_mti.do
run -all

