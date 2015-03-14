#!/bin/sh
mkdir work

echo "Compiling Tri-Mode Ethernet MAC Core Simulation Models"
ncvhdl -v93 -work work ../../../ether2.vhd

echo "Compiling Example Design"
ncvhdl -v93 -work work \
../../example_design/fifo/ether2_tx_client_fifo.vhd \
../../example_design/fifo/ether2_rx_client_fifo.vhd \
../../example_design/fifo/ether2_ten_100_1g_eth_fifo.vhd \
../../example_design/common/ether2_reset_sync.vhd \
../../example_design/common/ether2_sync_block.vhd \
../../example_design/pat_gen/ether2_address_swap.vhd \
../../example_design/pat_gen/ether2_axi_mux.vhd \
../../example_design/pat_gen/ether2_axi_pat_gen.vhd \
../../example_design/pat_gen/ether2_axi_pat_check.vhd \
../../example_design/pat_gen/ether2_axi_pipe.vhd \
../../example_design/pat_gen/ether2_basic_pat_gen.vhd \
../../example_design/physical/ether2_gmii_if.vhd \
../../example_design/statistics/ether2_vector_decode.vhd \
../../example_design/axi_lite/ether2_axi_lite_sm.vhd \
../../example_design/ether2_clk_wiz.vhd \
../../example_design/ether2_block.vhd \
../../example_design/ether2_fifo_block.vhd \
../../example_design/ether2_example_design.vhd

ncvhdl -v93 -work work \
../../example_design/axi_ipif/ether2_ipif_pkg.vhd \
../../example_design/axi_ipif/ether2_counter_f.vhd \
../../example_design/axi_ipif/ether2_pselect_f.vhd 

ncvhdl -v93 -work work \
../../example_design/axi_ipif/ether2_address_decoder.vhd \
../../example_design/axi_ipif/ether2_slave_attachment.vhd \
../../example_design/axi_ipif/ether2_axi_lite_ipif.vhd

ncvhdl -v93 -work work \
../../example_design/axi_ipif/ether2_axi4_lite_ipif_wrapper.vhd

echo "Compiling Test Bench"
ncvhdl -v93 -work work ../demo_tb.vhd

echo "Elaborating design"
ncelab -access +r work.demo_tb:behav

echo "Starting simulation"
ncsim -gui work.demo_tb:behav -input @"simvision -input wave_ncsim.sv"
