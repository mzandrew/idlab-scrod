
# PlanAhead Launch Script for Post-Synthesis pin planning, created by Project Navigator

create_project -name scrod-A4 -dir "C:/Users/isar/Documents/code4/TX9UMB-3/ise-project/planAhead_run_2" -part xc6slx150tfgg676-3
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/isar/Documents/code4/TX9UMB-3/ise-project/scrod_top_A4.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/isar/Documents/code4/TX9UMB-3/ise-project} {../../../../Google Drive/KLMdebug/TARGETX} {ipcore_dir} }
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
set_param project.pinAheadLayout  yes
set_property target_constrs_file "C:/Users/isar/Documents/code4/TX9UMB-3/src/pin_mappings_CSCFITracker-SCROD_revA4_V2.ucf" [current_fileset -constrset]
add_files [list {C:/Users/isar/Documents/code4/TX9UMB-3/src/pin_mappings_CSCFITracker-SCROD_revA4_V2.ucf}] -fileset [get_property constrset [current_run]]
link_design
