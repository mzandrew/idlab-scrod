
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name scrod-boardstack-new-daq-interface -dir "C:/Users/isar/Documents/code2/TX9UMB/ise-project/planAhead_run_1" -part xc6slx150tfgg676-3
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property top scrod_top $srcset
set_param project.paUcfFile  "C:/Users/isar/Documents/code2/TX9UMB/src/pin_mappings_SCROD_revA3_TargetX_9UVME.ucf"
set hdlfile [add_files [list {ipcore_dir/s6_icon.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/aurora_interfaces/base_resources/aurora_interface_0_aurora_pkg.vhd}]]
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
add_files [list {ipcore_dir/s6_icon.ngc}]
set hdlfile [add_files [list {../src/utilities/utilities.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/usb_interfaces/usb_top.v}]]
set_property file_type Verilog $hdlfile
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
add_files [list {ipcore_dir/FIFO_OUT_0.ngc}]
set hdlfile [add_files [list {ipcore_dir/FIFO_OUT_0.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
add_files [list {ipcore_dir/FIFO_INP_0.ngc}]
set hdlfile [add_files [list {ipcore_dir/FIFO_INP_0.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
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
set hdlfile [add_files [list {../src/edge_detect.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/daq_fifo_layer.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir/clockgen_asic_A.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir/clockgen_asic_A/example_design/clockgen_asic_A_exdes.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir/clockgen/example_design/clockgen_exdes.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir/clockgen.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/TARGET6_DAC_CONTROL.vhd}]]
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
set hdlfile [add_files [list {../src/DigitizingLgc.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../src/clocking/clock_generation.vhd}]]
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
set hdlfile [add_files [list {../src/scrod_top.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
add_files "C:/Users/isar/Documents/code2/TX9UMB/src/pin_mappings_SCROD_revA3_TargetX_9UVME.ucf" -fileset [get_property constrset [current_run]]
add_files "ipcore_dir/buffer_fifo_wr32_rd32.ncf" "ipcore_dir/FIFO_INP_0.ncf" "ipcore_dir/FIFO_OUT_0.ncf" "ipcore_dir/FIFO_OUT_1.ncf" "ipcore_dir/fifo_wr16_rd32.ncf" "ipcore_dir/fifo_wr32_rd16.ncf" "ipcore_dir/s6_icon.ncf" "ipcore_dir/s6_vio.ncf" "ipcore_dir/waveform_fifo_wr32_rd32.ncf" -fileset [get_property constrset [current_run]]
open_rtl_design -part xc6slx150tfgg676-3
