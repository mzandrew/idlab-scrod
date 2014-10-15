
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name scrod-A4 -dir "C:/Users/isar/Documents/code4/TX9UMB-3/ise-project/planAhead_run_1" -part xc6slx150tfgg676-3
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "C:/Users/isar/Documents/code4/TX9UMB-3/src/pin_mappings_SCROD_revA4-Interconnect-TX_MB_RevA.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/time_order/source/time_order_pkg.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/base_resources/aurora_interface_0_aurora_pkg.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/time_order/source/tom_2_to_1.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/gt/aurora_interface_0_tile.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/base_resources/aurora_interface_0_sym_gen_4byte.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/base_resources/aurora_interface_0_sym_dec_4byte.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/base_resources/aurora_interface_0_lane_init_sm_4byte.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/base_resources/aurora_interface_0_idle_and_ver_gen.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/base_resources/aurora_interface_0_err_detect_4byte.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/base_resources/aurora_interface_0_chbond_count_dec_4byte.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/base_resources/aurora_interface_0_channel_init_sm.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/base_resources/aurora_interface_0_channel_err_detect.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/usb_interfaces/USB_IFCLK_XC3S400.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/time_order/source/tom_4_to_1.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/time_order/source/tom_3_to_1.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/tdc/source/tdc_pkg.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/tdc/source/tdc_fifo.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/tx_ll_datapath.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/tx_ll_control.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/sym_gen.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/sym_dec.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/rx_ll_pdu_datapath.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/lane_init_sm.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/idle_and_ver_gen.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/err_detect.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/chbond_count_dec.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/channel_init_sm.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/channel_err_detect.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/aurora_tile.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/gt/aurora_interface_0_transceiver_wrapper.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/base_resources/aurora_interface_0_tx_stream.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/base_resources/aurora_interface_0_rx_stream.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/base_resources/aurora_interface_0_ll_to_axi.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/base_resources/aurora_interface_0_global_logic.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/base_resources/aurora_interface_0_axi_to_ll.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/base_resources/aurora_interface_0_aurora_lane_4byte.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/usb_interfaces/usb_slave_fifo_interface_io.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/usb_interfaces/usb_slave_fifo_interface.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/usb_interfaces/usb_init.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/time_order/source/tom_10_to_1.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/tdc/source/tdc_channel.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/tx_ll.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/transceiver_wrapper.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/rx_ll.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/global_logic.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/aurora_lane.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/b2tt/b2tt/b2tt_symbols.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/b2tt/b2tt/b2tt_ddr_s6.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/b2tt/b2tt/b2tt_8b10b.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/clock_module/aurora_interface_0_clock_module.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/cc_manager/aurora_interface_0_standard_cc_module.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/aurora_interface_0.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir/s6_vio.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
add_files [list {ipcore_dir/s6_vio.ngc}]
set hdlfile [add_files [list {ipcore_dir/s6_icon.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
add_files [list {ipcore_dir/s6_icon.ngc}]
set hdlfile [add_files [list {../src/utilities/utilities.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/usb_interfaces/usb_top.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/time_order/source/time_order.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/tdc/source/tdc.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_scrod/source/timing_ctrl_pkg.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/standard_cc_module.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/klm_aurora.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/conc_intfc/source/trig_chan_calc.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/conc_intfc/source/conc_intfc_pkg.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/b2tt/b2tt/b2tt_fifo_s6.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/b2tt/b2tt/b2tt_encode.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/b2tt/b2tt/b2tt_decode.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/b2tt/b2tt/b2tt_clk_s6.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/detect_usb.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/two_lane_aurora_interface.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/asic_interfaces/asic_definitions_irs2_carrier_revA.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
add_files [list {ipcore_dir/trig_fifo.ngc}]
set hdlfile [add_files [list {ipcore_dir/trig_fifo.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir/fifo_wr32_rd16.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
add_files [list {ipcore_dir/fifo_wr32_rd16.ngc}]
set hdlfile [add_files [list {ipcore_dir/fifo_wr16_rd32.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
add_files [list {ipcore_dir/fifo_wr16_rd32.ngc}]
set hdlfile [add_files [list {ipcore_dir/FIFO_OUT_1.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
add_files [list {ipcore_dir/FIFO_OUT_1.ngc}]
set hdlfile [add_files [list {ipcore_dir/FIFO_OUT_0.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
add_files [list {ipcore_dir/FIFO_OUT_0.ngc}]
set hdlfile [add_files [list {ipcore_dir/FIFO_INP_0.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
add_files [list {ipcore_dir/FIFO_INP_0.ngc}]
set hdlfile [add_files [list {ipcore_dir/daq_fifo.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
add_files [list {ipcore_dir/daq_fifo.ngc}]
set hdlfile [add_files [list {../src/utilities/edge_to_pulse_converter.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/utilities/clock_enable_generator.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/TDC_MPPC_DAC.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/readout_definitions.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/picoblaze/kcpsm6.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/picoblaze/command_interpreter/command_interpreter.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/peripherals/Module_ADC_MCP3221_I2C_new.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_scrod/source/timing_ctrl.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_scrod/source/sfp_stat_ctrl.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_scrod/source/run_ctrl.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_scrod/source/klm_scrod_pkg.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_scrod/source/frame_gen.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_aurora/source/klm_aurora_intfc.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/conc_intfc/source/conc_intfc.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/b2tt/b2tt/b2tt.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/edge_detect.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/daq_fifo_layer.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/update_status_regs.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/TARGETX_DAC_CONTROL.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/SerialDataRout.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/SamplingLgc.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/readout_interface.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/ReadoutControl.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/pulse_transition.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/OutputBufferControl.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/mppc_dacs.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/KLM_SCROD_baseline/klm_scrod/source/klm_scrod.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/DigitizingLgcTX.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/clocking/clock_gen_A4.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/asic_interfaces/trigger_scalers.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/asic_interfaces/event_builder.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir/waveform_fifo_wr32_rd32.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
add_files [list {ipcore_dir/waveform_fifo_wr32_rd32.ngc}]
set hdlfile [add_files [list {ipcore_dir/buffer_fifo_wr32_rd32.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
add_files [list {ipcore_dir/buffer_fifo_wr32_rd32.ngc}]
set hdlfile [add_files [list {../src/scrod_top_A4.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set_property top scrod_top_A4 $srcset
add_files [list {C:/Users/isar/Documents/code4/TX9UMB-3/src/pin_mappings_SCROD_revA4-Interconnect-TX_MB_RevA.ucf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/buffer_fifo_wr32_rd32.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/daq_fifo.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/ether2.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/ethercon.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/FIFO_INP_0.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/FIFO_OUT_0.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/FIFO_OUT_1.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/fifo_wr16_rd32.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/fifo_wr32_rd16.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/runctrl_fifo_wr16_rd32.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/s6_icon.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/s6_vio.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/trig_fifo.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/waveform_fifo_wr32_rd32.ncf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc6slx150tfgg676-3
