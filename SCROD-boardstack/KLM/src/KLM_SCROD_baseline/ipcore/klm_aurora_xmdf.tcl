# The package naming convention is <core_name>_xmdf
package provide klm_aurora_xmdf 1.0

# This includes some utilities that support common XMDF operations
package require utilities_xmdf

# Define a namespace for this package. The name of the name space
# is <core_name>_xmdf
namespace eval ::klm_aurora_xmdf {
# Use this to define any statics
}

# Function called by client to rebuild the params and port arrays
# Optional when the use context does not require the param or ports
# arrays to be available.
proc ::klm_aurora_xmdf::xmdfInit { instance } {
# Variable containg name of library into which module is compiled
# Recommendation: <module_name>
# Required
utilities_xmdf::xmdfSetData $instance Module Attributes Name klm_aurora
}
# ::klm_aurora_xmdf::xmdfInit

# Function called by client to fill in all the xmdf* data variables
# based on the current settings of the parameters
proc ::klm_aurora_xmdf::xmdfApplyParams { instance } {

set fcount 0
# Array containing libraries that are assumed to exist
# Examples include unisim and xilinxcorelib
# Optional
# In this example, we assume that the unisim library will
# be magically
# available to the simulation and synthesis tool
utilities_xmdf::xmdfSetData $instance FileSet $fcount type logical_library
utilities_xmdf::xmdfSetData $instance FileSet $fcount logical_library unisim
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
utilities_xmdf::xmdfSetData $instance FileSet $fcount toplevel true
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/example_design/klm_aurora_example_design.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/simulation/demo_tb.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdlsim
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/simulation/functional/simulate_mti.do
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/simulation/functional/wave_mti.do
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/simulation/functional/simulate_isim.sh
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/simulation/functional/simulate_isim.bat
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/simulation/functional/wave_isim.tcl
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/simulation/functional/simulate_ncsim.sh
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/simulation/functional/simulate_ncsim.bat
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora_xmdf.tcl
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora.xco
utilities_xmdf::xmdfSetData $instance FileSet $fcount type xco
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora.vho
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vho
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_aurora_lane.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_aurora_lane.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_aurora_lane.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_aurora_pkg.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/example_design/klm_aurora_example_design.ucf
utilities_xmdf::xmdfSetData $instance FileSet $fcount type ucf
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_channel_err_detect.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_channel_init_sm.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_chbond_count_dec.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_chbond_count_dec.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/example_design/clock_module/klm_aurora_clock_module.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_err_detect.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_err_detect.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_err_detect.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/example_design/traffic_gen_check/klm_aurora_frame_check.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/example_design/traffic_gen_check/klm_aurora_frame_gen.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_global_logic.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_idle_and_ver_gen.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_lane_init_sm.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_lane_init_sm.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_lane_init_sm.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/example_design/klm_aurora_reset_logic.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/example_design/gt/klm_aurora_transceiver_wrapper.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/example_design/gt/klm_aurora_tile.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_rx_ll_pdu_datapath.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_rx_ll.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/example_design/cc_manager/klm_aurora_standard_cc_module.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_sym_dec.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_sym_gen.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_tx_ll_control.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_tx_ll_datapath.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/src/klm_aurora_tx_ll.vhd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type vhdl
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/implement/s6_icon.ngc
utilities_xmdf::xmdfSetData $instance FileSet $fcount type ngc
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/implement/s6_vio.ngc
utilities_xmdf::xmdfSetData $instance FileSet $fcount type ngc
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/implement/planAhead_ise.sh
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/implement/planAhead_ise.bat
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/implement/planAhead_ise.tcl
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/implement/implement.sh
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/implement/implement.bat
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/implement/xst.prj
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path klm_aurora/implement/xst.scr
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount
}
# ::gen_comp_name_xmdf::xmdfApplyParams
