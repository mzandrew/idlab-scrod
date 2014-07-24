cd C:\Users\bkunkler\Documents\CEEM\repos\Belle-II\firmware\KLM_SCROD\klm_scrod\sim


###########################################################
#FTSW
###########################################################
vlib ft2u_lib "./library/ft2u_lib"
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\tt_types.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\b2tt_ddr_v5.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\tt_utime.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\b2tt_8b10b.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\b2tt_symbols.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\x_decode.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\x_encode.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\m_fifo.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\m_count.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\m_decode.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\m_dumtrig.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\m_encode.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\m_genbusy.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\m_gentrig.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\m_pipeline.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\m_trgdelay.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\m_collect.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\tt_aux.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\tt_blink.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\tt_dump.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\tt_ictrl.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\tt_ioswitch.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\tt_jitterspi.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\tt_oack.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\tt_oclk.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\tt_orsv.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\tt_otrg.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\tt_phasedet.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\tt_regs.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\tt_tlu.vhd
vcom -work ft2u_lib .\..\..\..\integration\det_intfc\ft2u\ft2u\ft2u.vhd

###########################################################
#Concentrator Interface
###########################################################
vlib klm_scrod_tb "./library/klm_scrod_lib.lib"
###############################
#IP Cores
###############################
vcom -work klm_scrod_tb .\..\..\ipcore\daq_fifo.vhd
vcom -work klm_scrod_tb .\..\..\ipcore\trig_fifo.vhd
###############################
#TDC Files
###############################
vcom -work klm_scrod_tb .\..\..\tdc\source\tdc_pkg.vhd
vcom -work klm_scrod_tb .\..\..\tdc\source\tdc_fifo.vhd
vcom -work klm_scrod_tb .\..\..\tdc\source\tdc_channel.vhd
vcom -work klm_scrod_tb .\..\..\tdc\source\tdc.vhd
###############################
#Time Order Files
###############################
vcom -work klm_scrod_tb .\..\..\time_order\source\time_order_pkg.vhd
vcom -work klm_scrod_tb .\..\..\time_order\source\tom_2_to_1.vhd
vcom -work klm_scrod_tb .\..\..\time_order\source\tom_3_to_1.vhd
vcom -work klm_scrod_tb .\..\..\time_order\source\tom_4_to_1.vhd
vcom -work klm_scrod_tb .\..\..\time_order\source\tom_10_to_1.vhd
vcom -work klm_scrod_tb .\..\..\time_order\source\time_order.vhd

vcom -work klm_scrod_tb .\..\..\conc_intfc\source\conc_intfc_pkg.vhd
vcom -work klm_scrod_tb .\..\..\conc_intfc\source\trig_chan_calc.vhd
vcom -work klm_scrod_tb .\..\..\conc_intfc\source\conc_intfc.vhd

###############################
#Aurora Core
###############################
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\aurora_tile.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\transceiver_wrapper.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\aurora_pkg.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\chbond_count_dec.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\err_detect.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\lane_init_sm.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\sym_dec.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\sym_gen.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\aurora_lane.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\channel_err_detect.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\channel_init_sm.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\idle_and_ver_gen.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\global_logic.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\tx_ll_control.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\tx_ll_datapath.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\tx_ll.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\rx_ll_pdu_datapath.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\rx_ll.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\standard_cc_module.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\klm_aurora.vhd
vcom -work klm_scrod_tb .\..\..\klm_aurora\source\klm_aurora_intfc.vhd

###############################
#B2TT
###############################
vcom -work klm_scrod_tb .\..\..\b2tt\b2tt\b2tt_symbols.vhd
vcom -work klm_scrod_tb .\..\..\b2tt\b2tt\b2tt_ddr_s6.vhd
vcom -work klm_scrod_tb .\..\..\b2tt\b2tt\b2tt_clk_s6.vhd
vcom -work klm_scrod_tb .\..\..\b2tt\b2tt\b2tt_fifo_s6.vhd
vcom -work klm_scrod_tb .\..\..\b2tt\b2tt\b2tt_8b10b.vhd
vcom -work klm_scrod_tb .\..\..\b2tt\b2tt\b2tt_encode.vhd
vcom -work klm_scrod_tb .\..\..\b2tt\b2tt\b2tt_decode.vhd
vcom -work klm_scrod_tb .\..\..\b2tt\b2tt\b2tt.vhd

###############################
#Top Level
###############################					   
vcom -work klm_scrod_tb .\..\source\klm_scrod_pkg.vhd
vcom -work klm_scrod_tb .\..\source\frame_gen.vhd
vcom -work klm_scrod_tb .\..\source\run_ctrl.vhd
vcom -work klm_scrod_tb .\..\source\sfp_stat_ctrl.vhd
vcom -work klm_scrod_tb .\..\source\timing_ctrl_pkg.vhd
vcom -work klm_scrod_tb .\..\source\timing_ctrl.vhd
vcom -work klm_scrod_tb .\..\source\klm_scrod.vhd

###########################################################
#Models and testbench
###########################################################
#vcom -work klm_scrod_tb .\source\frame_check.vhd;
#vcom -work klm_scrod_tb .\source\frame_gen.vhd;


vcom -work klm_scrod_tb .\source\targetx.vhd
vcom -work klm_scrod_tb .\source\run_ctrl_stim.vhd
#vcom -work klm_scrod_tb .\source\aurora_model.vhd

vcom -work klm_scrod_tb .\source\klm_scrod_tb.vhd;

vsim klm_scrod_tb -t 1ps -ieee_nowarn

@transcript off

#-----------------------------------------------------------------------------------------------------------
wave -divider "/---------------------------" -color 255,255,255
wave -divider "Testbench Signals" -color 255,255,255
wave -divider "/---------------------------" -color 255,255,255
#-----------------------------------------------------------------------------------------------------------
add wave -noreg -logic {/klm_scrod_tb/stim_enable}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/full_reg}
add wave -noreg -logic {/klm_scrod_tb/f2tu_f_led1y_b}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/f2tu_f_d}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/f2tu_f_a}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ads}
add wave -noreg -logic {/klm_scrod_tb/ft2u_wr}
add wave -noreg -logic {/klm_scrod_tb/ft2u_c_id1}
add wave -noreg -logic {/klm_scrod_tb/ft2u_c_id2}
add wave -noreg -logic {/klm_scrod_tb/ft2u_f_xen}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_f_ckmux}
add wave -noreg -logic {/klm_scrod_tb/ft2u_f_tck}
add wave -noreg -logic {/klm_scrod_tb/ft2u_f_tms}
add wave -noreg -logic {/klm_scrod_tb/ft2u_f_tdi}
add wave -noreg -logic {/klm_scrod_tb/ft2u_f_tdo}
add wave -noreg -logic {/klm_scrod_tb/ft2u_j_pd_b}
add wave -noreg -logic {/klm_scrod_tb/ft2u_j_plllock}
add wave -noreg -logic {/klm_scrod_tb/ft2u_j_spiclk}
add wave -noreg -logic {/klm_scrod_tb/ft2u_j_spile}
add wave -noreg -logic {/klm_scrod_tb/ft2u_j_spimiso}
add wave -noreg -logic {/klm_scrod_tb/ft2u_j_spimosi}
add wave -noreg -logic {/klm_scrod_tb/ft2u_j_testsync}
add wave -noreg -logic {/klm_scrod_tb/ft2u_f_ick_p}
add wave -noreg -logic {/klm_scrod_tb/ft2u_f_ick_n}
add wave -noreg -logic {/klm_scrod_tb/ft2u_f_lck_p}
add wave -noreg -logic {/klm_scrod_tb/ft2u_f_lck_n}
add wave -noreg -logic {/klm_scrod_tb/ft2u_s_jck_p}
add wave -noreg -logic {/klm_scrod_tb/ft2u_s_jck_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_o_aux_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_o_aux_p}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_i_aux_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_i_aux_p}
add wave -noreg -logic {/klm_scrod_tb/ft2u_i_trg_n}
add wave -noreg -logic {/klm_scrod_tb/ft2u_i_trg_p}
add wave -noreg -logic {/klm_scrod_tb/ft2u_i_ack_n}
add wave -noreg -logic {/klm_scrod_tb/ft2u_i_ack_p}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_o_clk_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_o_clk_p}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_o_trg_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_o_trg_p}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_o_ack_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_o_ack_p}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_o_rsv_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_o_rsv_p}
add wave -noreg -logic {/klm_scrod_tb/ft2u_i_ledy_b}
add wave -noreg -logic {/klm_scrod_tb/ft2u_i_ledg_b}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_o_ledy_b}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_o_ledg_b}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_m_a}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_m_d}
add wave -noreg -logic {/klm_scrod_tb/ft2u_m_wr}
add wave -noreg -logic {/klm_scrod_tb/ft2u_m_ads}
add wave -noreg -logic {/klm_scrod_tb/ft2u_m_lck}
add wave -noreg -logic {/klm_scrod_tb/target_reset}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/target_tb}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/target_tb16}
add wave -noreg -logic {/klm_scrod_tb/conc_user_clk}
add wave -noreg -logic {/klm_scrod_tb/conc_sync_clk}
add wave -noreg -logic {/klm_scrod_tb/conc_reset}
add wave -noreg -logic {/klm_scrod_tb/conc_gt_reset}
add wave -noreg -logic {/klm_scrod_tb/conc_plllock}
add wave -noreg -logic {/klm_scrod_tb/conc_tx_dst_rdy_n}
add wave -noreg -logic {/klm_scrod_tb/conc_tx_src_rdy_n}
add wave -noreg -logic {/klm_scrod_tb/conc_tx_sof_n}
add wave -noreg -logic {/klm_scrod_tb/conc_tx_eof_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/conc_tx_d}
add wave -noreg -logic {/klm_scrod_tb/conc_tx_rem}
add wave -noreg -logic {/klm_scrod_tb/conc_rx_src_rdy_n}
add wave -noreg -logic {/klm_scrod_tb/conc_rx_sof_n}
add wave -noreg -logic {/klm_scrod_tb/conc_rx_eof_n}
add wave -noreg -logic {/klm_scrod_tb/conc_rx_rem}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/conc_rx_d}
add wave -noreg -logic {/klm_scrod_tb/conc_gtlock}
add wave -noreg -logic {/klm_scrod_tb/conc_hard_err}
add wave -noreg -logic {/klm_scrod_tb/conc_soft_err}
add wave -noreg -logic {/klm_scrod_tb/conc_frame_err}
add wave -noreg -logic {/klm_scrod_tb/conc_channel_up}
add wave -noreg -logic {/klm_scrod_tb/conc_lane_up}
add wave -noreg -logic {/klm_scrod_tb/conc_warn_cc}
add wave -noreg -logic {/klm_scrod_tb/conc_do_cc}
add wave -noreg -logic {/klm_scrod_tb/conc_powerdown}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/conc_loopback}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/conc_err_count}
add wave -noreg -logic {/klm_scrod_tb/conc_rxp}
add wave -noreg -logic {/klm_scrod_tb/conc_rxn}
add wave -noreg -logic {/klm_scrod_tb/conc_txp}
add wave -noreg -logic {/klm_scrod_tb/conc_txn}
add wave -noreg -logic {/klm_scrod_tb/scrod_ttdclk_p}
add wave -noreg -logic {/klm_scrod_tb/scrod_ttdclk_n}
add wave -noreg -logic {/klm_scrod_tb/scrod_ttdtrg_p}
add wave -noreg -logic {/klm_scrod_tb/scrod_ttdtrg_n}
add wave -noreg -logic {/klm_scrod_tb/scrod_ttdack_p}
add wave -noreg -logic {/klm_scrod_tb/scrod_ttdack_n}
add wave -noreg -logic {/klm_scrod_tb/scrod_ttdrsv_p}
add wave -noreg -logic {/klm_scrod_tb/scrod_ttdrsv_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/scrod_target_tb}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/scrod_target_tb16}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/scrod_mgttxfault}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/scrod_mgtmod0}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/scrod_mgtlos}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/scrod_mgttxdis}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/scrod_mgtmod2}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/scrod_mgtmod1}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/scrod_mgtrate}
add wave -noreg -logic {/klm_scrod_tb/scrod_mgtrxp}
add wave -noreg -logic {/klm_scrod_tb/scrod_mgtrxn}
add wave -noreg -logic {/klm_scrod_tb/scrod_mgttxp}
add wave -noreg -logic {/klm_scrod_tb/scrod_mgttxn}
add wave -noreg -logic {/klm_scrod_tb/scrod_status}
add wave -noreg -logic {/klm_scrod_tb/scrod_control}



#-----------------------------------------------------------------------------------------------------------
wave -divider "/---------------------------" -color 255,255,255
wave -divider "UUT" -color 255,255,255
wave -divider "/---------------------------" -color 255,255,255
#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------
wave -divider "/---------------------------" -color 255,255,255
wave -divider "Top Level" -color 255,255,255
wave -divider "/---------------------------" -color 255,255,255
#-----------------------------------------------------------------------------------
add wave -noreg -logic {/klm_scrod_tb/UUT/ttdclkp}
add wave -noreg -logic {/klm_scrod_tb/UUT/ttdclkn}
add wave -noreg -logic {/klm_scrod_tb/UUT/ttdtrgp}
add wave -noreg -logic {/klm_scrod_tb/UUT/ttdtrgn}
add wave -noreg -logic {/klm_scrod_tb/UUT/ttdrsvp}
add wave -noreg -logic {/klm_scrod_tb/UUT/ttdrsvn}
add wave -noreg -logic {/klm_scrod_tb/UUT/ttdackp}
add wave -noreg -logic {/klm_scrod_tb/UUT/ttdackn}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/target_tb}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/target_tb16}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/mgttxfault}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/mgtmod0}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/mgtlos}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/mgttxdis}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/mgtmod2}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/mgtmod1}
add wave -noreg -logic {/klm_scrod_tb/UUT/mgtrxp}
add wave -noreg -logic {/klm_scrod_tb/UUT/mgtrxn}
add wave -noreg -logic {/klm_scrod_tb/UUT/mgttxp}
add wave -noreg -logic {/klm_scrod_tb/UUT/mgttxn}
add wave -noreg -logic {/klm_scrod_tb/UUT/status_fake}
add wave -noreg -logic {/klm_scrod_tb/UUT/control_fake}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/mgttxfault_i}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/mgtmod0_i}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/mgtlos_i}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/mgttxdis_i}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/mgtmod2_i}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/mgtmod1_i}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/target_tb_i}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/target_tb16_i}
add wave -noreg -logic {/klm_scrod_tb/UUT/b2tt_ctime_i}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/status_vec_i}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/ctrl_vec_i}
add wave -noreg -logic {/klm_scrod_tb/UUT/status_fake_i}
add wave -noreg -logic {/klm_scrod_tb/UUT/control_fake_i}
add wave -noreg -logic {/klm_scrod_tb/UUT/sys_clk_ib}
add wave -noreg -logic {/klm_scrod_tb/UUT/sys_clk2x_ib}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/mgttxfault_qi}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/mgtmod0_qi}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/mgtlos_qi}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/mgttxdis_iq}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/mgtmod2_iq}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/mgtmod1_iq}
add wave -noreg -logic {/klm_scrod_tb/UUT/b2tt_ctime_iq}
add wave -noreg -logic {/klm_scrod_tb/UUT/status_fake_iq}
add wave -noreg -logic {/klm_scrod_tb/UUT/control_fake_iq}
add wave -noreg -logic {/klm_scrod_tb/UUT/b2tt_clkup}
add wave -noreg -logic {/klm_scrod_tb/UUT/b2tt_b2ttup}
add wave -noreg -logic {/klm_scrod_tb/UUT/b2tt_trg}
add wave -noreg -logic {/klm_scrod_tb/UUT/b2tt_b2plllk}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/b2tt_utime}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/b2tt_ctime}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/b2tt_divclk1}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/b2tt_divclk2}
add wave -noreg -logic {/klm_scrod_tb/UUT/b2tt_runreset}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/b2tt_runreset2x}
add wave -noreg -logic {/klm_scrod_tb/UUT/b2tt_feereset}
add wave -noreg -logic {/klm_scrod_tb/UUT/b2tt_gtpreset}
add wave -noreg -logic {/klm_scrod_tb/UUT/b2tt_b2linkup}
add wave -noreg -logic {/klm_scrod_tb/UUT/b2tt_b2linkwe}
add wave -noreg -logic {/klm_scrod_tb/UUT/b2tt_b2lreset}
add wave -noreg -logic {/klm_scrod_tb/UUT/b2tt_fifonext}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/b2tt_fifodata}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/b2tt_exprun}
add wave -noreg -logic {/klm_scrod_tb/UUT/rx_dst_rdy_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/rx_sof_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/rx_eof_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/rx_src_rdy_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/rx_data}
add wave -noreg -logic {/klm_scrod_tb/UUT/tx_dst_rdy_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/tx_sof_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/tx_eof_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/tx_src_rdy_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/tx_data}
add wave -noreg -logic {/klm_scrod_tb/UUT/gtlock}
add wave -noreg -logic {/klm_scrod_tb/UUT/hard_err}
add wave -noreg -logic {/klm_scrod_tb/UUT/soft_err}
add wave -noreg -logic {/klm_scrod_tb/UUT/frame_err}
add wave -noreg -logic {/klm_scrod_tb/UUT/channel_up}
add wave -noreg -logic {/klm_scrod_tb/UUT/lane_up}
add wave -noreg -logic {/klm_scrod_tb/UUT/warn_cc}
add wave -noreg -logic {/klm_scrod_tb/UUT/do_cc}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/tdc_ce}
add wave -noreg -logic {/klm_scrod_tb/UUT/b2tt_fifordy}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/status_regs}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/ctrl_regs}
add wave -noreg -logic {/klm_scrod_tb/UUT/daq_dst_rdy_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/daq_sof_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/daq_eof_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/daq_src_rdy_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/daq_data}
add wave -noreg -logic {/klm_scrod_tb/UUT/rcl_dst_rdy_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/rcl_sof_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/rcl_eof_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/rcl_src_rdy_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/rcl_data}
add wave -noreg -logic {/klm_scrod_tb/UUT/fault_flag}
add wave -noreg -logic {/klm_scrod_tb/UUT/los_flag}
add wave -noreg -logic {/klm_scrod_tb/UUT/mod_flag}


#-----------------------------------------------------------------------------------
wave -divider "/---------------------------" -color 255,255,255
wave -divider "Data Concentrator Interface" -color 255,255,255
wave -divider "/---------------------------" -color 255,255,255
#-----------------------------------------------------------------------------------
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/sys_clk}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/tdc_clk}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/ce}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/b2tt_runreset}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/b2tt_runreset2x}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/b2tt_gtpreset}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/b2tt_fifordy}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/b2tt_fifodata}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/b2tt_fifonext}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/target_tb}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/target_tb16}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/status_regs}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/rx_dst_rdy_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/rx_sof_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/rx_eof_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/rx_src_rdy_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/rx_data}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/daq_dst_rdy_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/daq_sof_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/daq_eof_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/daq_src_rdy_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/daq_data}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/tx_dst_rdy_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/tx_sof_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/tx_eof_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/tx_src_rdy_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/tx_data}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/rcl_dst_rdy_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/rcl_sof_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/rcl_eof_n}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/rcl_src_rdy_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/rcl_data}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/tdc_rden}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/tdc_epty}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/tdc_dout}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/to_dst_we}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/to_dout}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/to_valid}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/trg_fifo_we}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/trg_fifo_di}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/trg_fifo_re}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/trg_fifo_do}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/trg_fifo_afull}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/trg_fifo_epty}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/trg_fifo_aepty}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/trg_fifo_full}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/daq_fifo_we}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/daq_fifo_di}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/daq_fifo_re}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/daq_fifo_do}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/daq_fifo_afull}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/daq_fifo_epty}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/daq_fifo_aepty}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/daq_fifo_full}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/axis_bit}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/trg_ch}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/trg_valid}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/daq_sof_q}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/daq_eof_q}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/daq_data_q}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/daq_valid}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/daq_di_addr}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/daq_cnt}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/pkttp_ctr_ld}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/pkttp_ctr_tc}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/pkttp_ctr}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/trgpkt_ctr_ld}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/trgpkt_ctr_tc}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/trgpkt_ctr}
add wave -noreg -literal {/klm_scrod_tb/UUT/conc_intfc_ins/tx_fsm_cs}
add wave -noreg -literal {/klm_scrod_tb/UUT/conc_intfc_ins/tx_fsm_ns}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/to_ln}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/to_ch}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/to_tdc}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/UUT/conc_intfc_ins/trgtag}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/trg_sof}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/trg_eof}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/daq_sof}
add wave -noreg -logic {/klm_scrod_tb/UUT/conc_intfc_ins/daq_eof}

#-----------------------------------------------------------------------------------------------------------
wave -divider "/---------------------------" -color 255,255,255
wave -divider "FT2U" -color 255,255,255
wave -divider "/---------------------------" -color 255,255,255
#-----------------------------------------------------------------------------------------------------------
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_led1y_b}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_led1g}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_led1y}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_led2g}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_led2y}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/f_d}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/f_a}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_ads}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_wr}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_irq}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/c_id1}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/c_id2}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_xen}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/f_ckmux}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_tck}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_tms}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_tdi}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_tdo}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/j_pd_b}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/j_plllock}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/j_spiclk}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/j_spile}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/j_spimiso}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/j_spimosi}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/j_testsync}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_ick_p}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_ick_n}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_lck_p}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_lck_n}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/s_jck_p}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/s_jck_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/o_aux_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/o_aux_p}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/i_aux_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/i_aux_p}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/i_trg_n}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/i_trg_p}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/i_ack_n}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/i_ack_p}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/i_rsv_n}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/i_rsv_p}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/o_clk_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/o_clk_p}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/o_trg_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/o_trg_p}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/o_ack_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/o_ack_p}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/o_rsv_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/o_rsv_p}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/i_ledy_b}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/i_ledg_b}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/o_ledy_b}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/o_ledg_b}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/m_a}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/m_d}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/m_wr}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/m_ads}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/m_lck}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/f_enable}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/f_entck}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_ftop}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_query}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/f_prsnt_b}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/e_rst_b}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/e_txen}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_lck}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_ick}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_sck}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/clk_l}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/clk_i}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/clk_s}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_blink}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/cnt_lckfreq}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/buf_utim0}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/cnt_trgout}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_trgstart}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/seq_id}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_pdb}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_utime}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_ctime}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_tdi}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_tck}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_tms}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_xbit2}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_xsub2}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_xdum2}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_trgin}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_trg2}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_sub2}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_revo}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_frame}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sta_frame3}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sta_frame9}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_ctimer}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_utimer}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/cnt_clk}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_oackp}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_oackn}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_xackp}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_xackn}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_autorst}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_runreset}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sta_runreset}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_errreset}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_tagdone}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_trig}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_trgtyp}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_trgraw1}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_trgsrc1}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_trgsrc2}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_dumtrg}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_idbg}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_oaux}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_iaux}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_tluin}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_tluout}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_dump2}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/cnt_dump2}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_dumpo}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_dumpk}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/cnt_dumpo}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_dump}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/open_dbg}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/set_reg}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/get_reg}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/buf_reg}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_reg}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_din}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_dout}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_id}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/set_utime}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_utime}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_clkfreq}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_snapshot}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/buf_utime}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/buf_ctime}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sta_frozen}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_exprun}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_query}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_selcpr}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_xorclk}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_xmask}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_selo}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_omask}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_link}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_s3}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_fliptdo}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_tck}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_tms}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_tdi}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_seljtag}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_autojtag}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_enjtag}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_tdo}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_jspi}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/set_jspi}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_jspi}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_pd}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_jreset}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_jphase}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sta_jpll}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sta_jdcm}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_ckmux}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_jphase}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_jretry}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_jcount}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_nofifo}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_autorst}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_tluno1st}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_tludelay}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_usetlu}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_ebup}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_paused}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_running}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_busy}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/clr_ictrl}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/set_incdelay}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/set_caldelay}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/set_gtpreset}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/set_feereset}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/set_b2lreset}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/set_errreset}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/set_cntreset}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/set_trgstop}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_genbor}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/set_trgstart}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/set_runreset}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_rstutim}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_rstctim}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_rstsrc}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_errutim}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_errctim}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_errport}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/cnt_linkup}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/set_rateval}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_trgopt}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_rateval}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_rateexp}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_notrgclr}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_seltrg}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_trglimit}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/cnt_trgin}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/cnt_trgoutl}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/cnt_trglast}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sta_fifoful}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sta_fifoorun}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sta_fifoemp}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_fifoahi}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sta_trgen}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_fiford}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/buf_fifo}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/cnt_payload}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/cnt_bit2}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/cnt_octet}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/set_revopos}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_revopos}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/cnt_revocand}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_revocand}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/cnt_badrevo}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/cnt_norevo}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_baddr}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/set_baddr}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_lckfreq}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sta_fifoerr}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sta_pipebusy}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_busy}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sta_busy}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_xnwff}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_xbusy}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_obusy}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_xbusy}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_obusy}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_olinkdn}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_xalive}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_oalive}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_xlinkup}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_olinkup}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_b2ldn}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_plldn}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sta_err}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_errin}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sta_clkerr}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sta_trigshort}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_xerr}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_oerr}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_b2lup}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_plllk}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sta_linkerr}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_b2lor}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_ictrl}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/buf_elinkup}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_odecode}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_xdecode}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_maxtrig}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_latency}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_tlumon}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sta_tlubsy}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sta_nontlu}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_tlutrg}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/sig_tlurst}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/cnt_tlurst}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_tlutag}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_tluutim}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_tluctim}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_udead}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_cdead}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_pdead}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_edead}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_fdead}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_rdead}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_odead}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_xdead}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_xbcnt}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_ostac}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_xdbg}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_omanual}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_oregslip}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_oclrdelay}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_osigdelay}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_xdbgsel}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_xmanual}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_xregslip}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_xclrdelay}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_xsigdelay}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_dbg}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_dbg2}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/buf_dump8}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/buf_dumpk}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/set_dump}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/buf_dumpi}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_xackq}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sig_oackq}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/buf_dump2}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_idump}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/reg_autodump}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_dumpwait}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/buf_crc8}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_busysrc}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/sta_errsrc}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_itrgsel}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_irsvsel}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/reg_trgdelay}


#-----------------------------------------------------------------------------------
wave -divider "/---------------------------" -color 255,255,255
wave -divider "OTRG" -color 255,255,255
wave -divider "/---------------------------" -color 255,255,255
#-----------------------------------------------------------------------------------
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_otrg/sig_tdi}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_otrg/sig_cprd}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_otrg/sig_otrg}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_otrg/open_ddr}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_otrg/clock}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_otrg/trg2}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_otrg/sub2}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_otrg/cprbit2}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_otrg/cprsub2}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_otrg/cprdum2}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_otrg/trg_p}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_otrg/trg_n}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_otrg/discpr}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_otrg/selcpr}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_otrg/disable}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_otrg/selo}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_otrg/autojtag}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_otrg/enjtag}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_otrg/tdi}


#-----------------------------------------------------------------------------------
wave -divider "/---------------------------" -color 255,255,255
wave -divider "GENTRIG" -color 255,255,255
wave -divider "/---------------------------" -color 255,255,255
#-----------------------------------------------------------------------------------
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/sig_trgin}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/sig_trig}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_gentrig/cnt_last}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_gentrig/seq_start}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/sta_en}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_gentrig/cnt_dbg1}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_gentrig/cnt_dbg2}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_gentrig/cnt_dbg3}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_gentrig/cnt_dbg4}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/seq_trgsrc1}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/seq_trgsrc2}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/seq_trgsrc3}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/clock}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/reset}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/busy}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/err}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/start}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/stop}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_gentrig/limit}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_gentrig/last}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_gentrig/seltrg}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/genbor}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/trgsrc1}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/trgsrc2}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/trgsrc3}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/dumtrg}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/en}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/trgin}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_gentrig/trig}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_gentrig/trgtyp}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_gentrig/dbg}


#-----------------------------------------------------------------------------------
wave -divider "/---------------------------" -color 255,255,255
wave -divider "TRGDELAY" -color 255,255,255
wave -divider "/---------------------------" -color 255,255,255
#-----------------------------------------------------------------------------------
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_trgdelay/sig_trig}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_trgdelay/seq_trig}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_trgdelay/seq_trig2}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_trgdelay/sig_wra}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_trgdelay/cnt_in}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_trgdelay/cnt_out}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_trgdelay/sta_adiff}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_trgdelay/cnt_tim}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_trgdelay/sta_tim}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_trgdelay/sta_tdiff}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_trgdelay/sig_delayed}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_trgdelay/open_unused}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_trgdelay/clock}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_trgdelay/runreset}
add wave -noreg -hexadecimal -literal {/klm_scrod_tb/ft2u_ins/map_trgdelay/delay}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_trgdelay/trgin}
add wave -noreg -logic {/klm_scrod_tb/ft2u_ins/map_trgdelay/trgout}


@transcript off

#run 3 ms;
run 125 us;