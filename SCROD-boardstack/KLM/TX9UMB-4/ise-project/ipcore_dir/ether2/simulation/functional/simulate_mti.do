vlib work
vmap work work

echo "Compiling Core Simulation Model"
vcom -work work ../../../ether2.vhd

echo "Compiling Example Design"
vcom -work work \
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

vcom -work work \
../../example_design/axi_ipif/ether2_ipif_pkg.vhd \
../../example_design/axi_ipif/ether2_counter_f.vhd \
../../example_design/axi_ipif/ether2_pselect_f.vhd 

vcom -work work \
../../example_design/axi_ipif/ether2_address_decoder.vhd \
../../example_design/axi_ipif/ether2_slave_attachment.vhd \
../../example_design/axi_ipif/ether2_axi_lite_ipif.vhd

vcom -work work \
../../example_design/axi_ipif/ether2_axi4_lite_ipif_wrapper.vhd

echo "Compiling Test Bench"
vcom -work work ../demo_tb.vhd

echo "Starting simulation"
vsim -t ps work.demo_tb -voptargs="+acc+demo_tb+/demo_tb/dut+/demo_tb/dut/trimac_fifo_block"
do wave_mti.do
run -all
