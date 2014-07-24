####################################################################################
## (c) Copyright 2010 - 2011 Xilinx, Inc. All rights reserved.
##
## This file contains confidential and proprietary information
## of Xilinx, Inc. and is protected under U.S. and
## international copyright and other intellectual property
## laws.
##
## DISCLAIMER
## This disclaimer is not a license and does not grant any
## rights to the materials distributed herewith. Except as
## otherwise provided in a valid license issued to you by
## Xilinx, and to the maximum extent permitted by applicable
## law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
## WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
## AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
## BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
## INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
## (2) Xilinx shall not be liable (whether in contract or tort,
## including negligence, or under any other theory of
## liability) for any loss or damage of any kind or nature
## related to, arising under or in connection with these
## materials, including for any direct, or any indirect,
## special, incidental, or consequential loss or damage
## (including loss of data, profits, goodwill, or any type of
## loss or damage suffered as a result of any action brought
## by a third party) even if such damage or loss was
## reasonably foreseeable or Xilinx had been advised of the
## possibility of the same.
##
## CRITICAL APPLICATIONS
## Xilinx products are not designed or intended to be fail-
## safe, or for use in any application requiring fail-safe
## performance, such as life-support or safety devices or
## systems, Class III medical devices, nuclear facilities,
## applications related to the deployment of airbags, or any
## other applications that could lead to death, personal
## injury, or severe property or environmental damage
## (individually and collectively, "Critical
## Applications"). Customer assumes the sole risk and
## liability of any use of Xilinx products in Critical
## Applications, subject only to applicable laws and
## regulations governing limitations on product liability.
##
## THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
## PART OF THIS FILE AT ALL TIMES.
####################################################################################
##
## SIMULATE_ISIM.SH 
##
##
## Description: A .sh file to run a simulation using the klm_aurora_example_design module, 
##              an example design which instantiates klm_aurora.
##
##
##############################################################################

# Create work directory 
mkdir work
# Compile the Aurora package in the work directory
vhpcomp -work work ../../src/klm_aurora_aurora_pkg.vhd;
# Compile testbench source
vhpcomp -work work ../../simulation/demo_tb.vhd;
# Compile the HDL for the Device Under Test
# Aurora Lane Modules  
vhpcomp -work work ../../src/klm_aurora_chbond_count_dec.vhd;
vhpcomp -work work ../../src/klm_aurora_err_detect.vhd;
vhpcomp -work work ../../src/klm_aurora_lane_init_sm.vhd;
vhpcomp -work work ../../src/klm_aurora_sym_dec.vhd;
vhpcomp -work work ../../src/klm_aurora_sym_gen.vhd;
vhpcomp -work work ../../src/klm_aurora_aurora_lane.vhd;
# Global Logic Modules
vhpcomp -work work ../../src/klm_aurora_channel_err_detect.vhd;
vhpcomp -work work ../../src/klm_aurora_channel_init_sm.vhd;
vhpcomp -work work ../../src/klm_aurora_idle_and_ver_gen.vhd;
vhpcomp -work work ../../src/klm_aurora_global_logic.vhd; 
# TX LocalLink User Interface modules
vhpcomp -work work ../../src/klm_aurora_tx_ll_control.vhd;
vhpcomp -work work ../../src/klm_aurora_tx_ll_datapath.vhd;
vhpcomp -work work ../../src/klm_aurora_tx_ll.vhd;
# RX_LL Pdu Modules
vhpcomp -work work ../../src/klm_aurora_rx_ll_pdu_datapath.vhd;
# RX_LL top level
vhpcomp -work work ../../src/klm_aurora_rx_ll.vhd;
# Top Level Modules and wrappers
vhpcomp -work work ../../example_design/clock_module/klm_aurora_clock_module.vhd;
vhpcomp -work work ../../example_design/cc_manager/klm_aurora_standard_cc_module.vhd;
vhpcomp -work work ../../example_design/gt/klm_aurora_transceiver_wrapper.vhd;
vhpcomp -work work ../../example_design/gt/klm_aurora_tile.vhd;
vhpcomp -work work ../../../klm_aurora.vhd;
vhpcomp -work work ../../example_design/traffic_gen_check/klm_aurora_frame_check.vhd;
vhpcomp -work work ../../example_design/traffic_gen_check/klm_aurora_frame_gen.vhd;    
vhpcomp -work work ../../example_design/klm_aurora_reset_logic.vhd;
vhpcomp -work work ../../example_design/klm_aurora_example_design.vhd;
# Begin the test
fuse work.EXAMPLE_TB -L unisim -L secureip -o example_tb.exe
# To run in batch mode, invoke the following command without -gui option
./example_tb.exe -gui -tclbatch wave_isim.tcl -wdb wave_isim  
