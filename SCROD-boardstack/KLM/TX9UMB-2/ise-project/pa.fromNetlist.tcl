
# PlanAhead Launch Script for Post-Synthesis pin planning, created by Project Navigator

create_project -name scrod-boardstack-new-daq-interface -dir "C:/Users/isar/Documents/code2/TX9UMB/ise-project/planAhead_run_1" -part xc6slx150tfgg676-3
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/isar/Documents/code2/TX9UMB/ise-project/scrod_top.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/isar/Documents/code2/TX9UMB/ise-project} {ipcore_dir} }
add_files "ipcore_dir/buffer_fifo_wr32_rd32.ncf" "ipcore_dir/FIFO_INP_0.ncf" "ipcore_dir/FIFO_OUT_0.ncf" "ipcore_dir/FIFO_OUT_1.ncf" "ipcore_dir/fifo_wr16_rd32.ncf" "ipcore_dir/fifo_wr32_rd16.ncf" "ipcore_dir/s6_icon.ncf" "ipcore_dir/s6_vio.ncf" "ipcore_dir/waveform_fifo_wr32_rd32.ncf" -fileset [get_property constrset [current_run]]
set_param project.pinAheadLayout  yes
set_param project.paUcfFile  "C:/Users/isar/Documents/code2/TX9UMB/src/pin_mappings_SCROD_revA3_TargetX_9UVME.ucf"
add_files "C:/Users/isar/Documents/code2/TX9UMB/src/pin_mappings_SCROD_revA3_TargetX_9UVME.ucf" -fileset [get_property constrset [current_run]]
open_netlist_design
