cd C:\Users\bkunkler\Documents\CEEM\repos\Belle-II\firmware\KLM_SCROD\conc_intfc\sim\

vlib conc_intfc_lib "./library/conc_intfc_lib.lib"

#IP Cores
vcom -work conc_intfc_lib .\..\..\ipcore\daq_fifo.vhd
vcom -work conc_intfc_lib .\..\..\ipcore\trig_fifo.vhd

#TDC Files
vcom -work conc_intfc_lib .\..\..\tdc\source\tdc_pkg.vhd
vcom -work conc_intfc_lib .\..\..\tdc\source\tdc_fifo.vhd
vcom -work conc_intfc_lib .\..\..\tdc\source\tdc_channel.vhd
vcom -work conc_intfc_lib .\..\..\tdc\source\tdc.vhd

#Time Order Files
vcom -work conc_intfc_lib .\..\..\time_order\source\time_order_pkg.vhd
vcom -work conc_intfc_lib .\..\..\time_order\source\tom_2_to_1.vhd
vcom -work conc_intfc_lib .\..\..\time_order\source\tom_3_to_1.vhd
vcom -work conc_intfc_lib .\..\..\time_order\source\tom_4_to_1.vhd
vcom -work conc_intfc_lib .\..\..\time_order\source\tom_10_to_1.vhd
vcom -work conc_intfc_lib .\..\..\time_order\source\time_order.vhd

vcom -work conc_intfc_lib .\..\source\conc_intfc_pkg.vhd
vcom -work conc_intfc_lib .\..\source\trig_chan_calc.vhd
vcom -work conc_intfc_lib .\..\source\conc_intfc.vhd
#vcom -work conc_intfc_lib .\..\source\conc_intfc0.vhd

vcom -work conc_intfc_lib .\source\b2tt.vhd
vcom -work conc_intfc_lib .\source\targetx.vhd
vcom -work conc_intfc_lib .\source\daq_stim.vhd
vcom -work conc_intfc_lib .\source\aurora_model.vhd
vcom -work conc_intfc_lib .\source\conc_intfc_tb.vhd

vsim conc_intfc_tb -t 1ps -ieee_nowarn


transcript off

#-------------------------------------------------------------
wave -divider "/---------------------------" -color 255,255,255
wave -divider "Testbench Signals" -color 255,255,255
wave -divider "/---------------------------" -color 255,255,255
#-------------------------------------------------------------
add wave -noreg -logic {/conc_intfc_tb/clk}
add wave -noreg -logic {/conc_intfc_tb/clk2x}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/ce}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/tb}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/tb16}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/fifo_re}
add wave -noreg -logic {/conc_intfc_tb/ce_bit}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/ce_cnt}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/full_reg}
add wave -noreg -logic {/conc_intfc_tb/stim_enable}
add wave -noreg -logic {/conc_intfc_tb/b2tt_runreset}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/b2tt_runreset2x}
add wave -noreg -logic {/conc_intfc_tb/b2tt_gtpreset}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/b2tt_trgtag}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/b2tt_ctime}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/b2tt_utime}
add wave -noreg -logic {/conc_intfc_tb/b2tt_trgout}
add wave -noreg -logic {/conc_intfc_tb/b2tt_fifordy}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/b2tt_fifodata}
add wave -noreg -logic {/conc_intfc_tb/b2tt_fifonext}
add wave -noreg -logic {/conc_intfc_tb/rx_dst_rdy_n}
add wave -noreg -logic {/conc_intfc_tb/rx_sof_n}
add wave -noreg -logic {/conc_intfc_tb/rx_eof_n}
add wave -noreg -logic {/conc_intfc_tb/rx_src_rdy_n}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/rx_data}
add wave -noreg -logic {/conc_intfc_tb/daq_dst_rdy_n}
add wave -noreg -logic {/conc_intfc_tb/daq_sof_n}
add wave -noreg -logic {/conc_intfc_tb/daq_eof_n}
add wave -noreg -logic {/conc_intfc_tb/daq_src_rdy_n}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/daq_data}
add wave -noreg -logic {/conc_intfc_tb/tx_dst_rdy_n}
add wave -noreg -logic {/conc_intfc_tb/tx_sof_n}
add wave -noreg -logic {/conc_intfc_tb/tx_eof_n}
add wave -noreg -logic {/conc_intfc_tb/tx_src_rdy_n}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/tx_data}
add wave -noreg -logic {/conc_intfc_tb/rcl_dst_rdy_n}
add wave -noreg -logic {/conc_intfc_tb/rcl_sof_n}
add wave -noreg -logic {/conc_intfc_tb/rcl_eof_n}
add wave -noreg -logic {/conc_intfc_tb/rcl_src_rdy_n}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/rcl_data}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/target_tb}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/target_tb16}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/status_regs}

#-------------------------------------------------------------
wave -divider "/---------------------------" -color 255,255,255
wave -divider "UUT Signals" -color 255,255,255
wave -divider "/---------------------------" -color 255,255,255
#-------------------------------------------------------------
add wave -noreg -logic {/conc_intfc_tb/UUT/sys_clk}
add wave -noreg -logic {/conc_intfc_tb/UUT/tdc_clk}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/ce}
add wave -noreg -logic {/conc_intfc_tb/UUT/b2tt_runreset}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/b2tt_runreset2x}
add wave -noreg -logic {/conc_intfc_tb/UUT/b2tt_gtpreset}
add wave -noreg -logic {/conc_intfc_tb/UUT/b2tt_fifordy}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/b2tt_fifodata}
add wave -noreg -logic {/conc_intfc_tb/UUT/b2tt_fifonext}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/target_tb}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/target_tb16}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/status_regs}
add wave -noreg -logic {/conc_intfc_tb/UUT/rx_dst_rdy_n}
add wave -noreg -logic {/conc_intfc_tb/UUT/rx_sof_n}
add wave -noreg -logic {/conc_intfc_tb/UUT/rx_eof_n}
add wave -noreg -logic {/conc_intfc_tb/UUT/rx_src_rdy_n}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/rx_data}
add wave -noreg -logic {/conc_intfc_tb/UUT/daq_dst_rdy_n}
add wave -noreg -logic {/conc_intfc_tb/UUT/daq_sof_n}
add wave -noreg -logic {/conc_intfc_tb/UUT/daq_eof_n}
add wave -noreg -logic {/conc_intfc_tb/UUT/daq_src_rdy_n}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/daq_data}
add wave -noreg -logic {/conc_intfc_tb/UUT/tx_dst_rdy_n}
add wave -noreg -logic {/conc_intfc_tb/UUT/tx_sof_n}
add wave -noreg -logic {/conc_intfc_tb/UUT/tx_eof_n}
add wave -noreg -logic {/conc_intfc_tb/UUT/tx_src_rdy_n}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/tx_data}
add wave -noreg -logic {/conc_intfc_tb/UUT/rcl_dst_rdy_n}
add wave -noreg -logic {/conc_intfc_tb/UUT/rcl_sof_n}
add wave -noreg -logic {/conc_intfc_tb/UUT/rcl_eof_n}
add wave -noreg -logic {/conc_intfc_tb/UUT/rcl_src_rdy_n}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/rcl_data}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/tdc_rden}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/tdc_epty}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/tdc_dout}
add wave -noreg -logic {/conc_intfc_tb/UUT/to_dst_we}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/to_dout}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/to_valid}
add wave -noreg -logic {/conc_intfc_tb/UUT/trg_fifo_we}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/trg_fifo_di}
add wave -noreg -logic {/conc_intfc_tb/UUT/atrg_sof}
add wave -noreg -logic {/conc_intfc_tb/UUT/atrg_eof}
add wave -noreg -logic {/conc_intfc_tb/UUT/daq_sof}
add wave -noreg -logic {/conc_intfc_tb/UUT/daq_eof}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/daq_pause}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/sts_pause}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/idl_pause}
add wave -noreg -logic {/conc_intfc_tb/UUT/trg_fifo_re}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/trg_fifo_do}
add wave -noreg -logic {/conc_intfc_tb/UUT/trg_fifo_afull}
add wave -noreg -logic {/conc_intfc_tb/UUT/trg_fifo_epty}
add wave -noreg -logic {/conc_intfc_tb/UUT/trg_fifo_aepty}
add wave -noreg -logic {/conc_intfc_tb/UUT/trg_fifo_full}
add wave -noreg -logic {/conc_intfc_tb/UUT/daq_fifo_we}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/daq_fifo_di}
add wave -noreg -logic {/conc_intfc_tb/UUT/daq_fifo_re}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/daq_fifo_do}
add wave -noreg -logic {/conc_intfc_tb/UUT/daq_fifo_afull}
add wave -noreg -logic {/conc_intfc_tb/UUT/daq_fifo_epty}
add wave -noreg -logic {/conc_intfc_tb/UUT/daq_fifo_aepty}
add wave -noreg -logic {/conc_intfc_tb/UUT/daq_fifo_full}
add wave -noreg -logic {/conc_intfc_tb/UUT/fsm_sof}
add wave -noreg -logic {/conc_intfc_tb/UUT/axis_bit}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/trg_ch}
add wave -noreg -logic {/conc_intfc_tb/UUT/trg_ch_valid}
add wave -noreg -logic {/conc_intfc_tb/UUT/strg_eof}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/trg_valid}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/trgsof_ctr}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/trgeof_ctr}
add wave -noreg -logic {/conc_intfc_tb/UUT/zrlentrg}
add wave -noreg -logic {/conc_intfc_tb/UUT/ftrgtag}
add wave -noreg -logic {/conc_intfc_tb/UUT/daq_sof_d}
add wave -noreg -logic {/conc_intfc_tb/UUT/daq_eof_d}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/daq_sof_q}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/daq_eof_q}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/daq_src_rdy_q}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/daq_data_q}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/daq_valid}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/daq_di_addr}

add wave -noreg -logic {/conc_intfc_tb/UUT/pkttp_ctr_ld}
add wave -noreg -logic {/conc_intfc_tb/UUT/pkttp_ctr_tc}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/pkttp_ctr}
add wave -noreg -logic {/conc_intfc_tb/UUT/trgpkt_ctr_ld}
add wave -noreg -logic {/conc_intfc_tb/UUT/trgpkt_ctr_en}
add wave -noreg -logic {/conc_intfc_tb/UUT/trgpkt_ctr_tc}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/trgpkt_ctr}
add wave -noreg -logic {/conc_intfc_tb/UUT/stspkt_ctr_ld}
add wave -noreg -logic {/conc_intfc_tb/UUT/stspkt_ctr_en}
add wave -noreg -logic {/conc_intfc_tb/UUT/stspkt_ctr_tc}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/stspkt_ctr}
add wave -noreg -logic {/conc_intfc_tb/UUT/sts_sof}
add wave -noreg -logic {/conc_intfc_tb/UUT/sts_sof_q}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/sts_data}
add wave -noreg -literal {/conc_intfc_tb/UUT/tx_fsm_cs}
add wave -noreg -literal {/conc_intfc_tb/UUT/tx_fsm_ns}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/to_ln}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/to_ch}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/to_tdc}
add wave -noreg -hexadecimal -literal {/conc_intfc_tb/UUT/trgtag}



transcript on

run 50 us;
