
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name chpscp2 -dir "C:/Users/isar/Documents/code2/TX9UMB/chpscp2/planAhead_run_1" -part xc6slx150tfgg676-3
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/isar/Documents/code2/TX9UMB/ise-project/scrod_top_ChpScp.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/isar/Documents/code2/TX9UMB/chpscp2} {../ise-project} }
set_param project.paUcfFile  "C:/Users/isar/Documents/code2/TX9UMB/src/pin_mappings_SCROD_revA3_TargetX_9UVME.ucf"
add_files "C:/Users/isar/Documents/code2/TX9UMB/src/pin_mappings_SCROD_revA3_TargetX_9UVME.ucf" -fileset [get_property constrset [current_run]]
open_netlist_design
