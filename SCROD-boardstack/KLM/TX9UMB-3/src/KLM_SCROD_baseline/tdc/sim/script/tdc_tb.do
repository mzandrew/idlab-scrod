cd C:\Users\bkunkler\Documents\CEEM\repos\Belle-II\firmware\KLM_SCROD\tdc\sim\
vlib tdc_lib ".\library\tdc_lib.lib"

vcom -work tdc_lib .\..\source\tdc_pkg.vhd
vcom -work tdc_lib .\..\source\tdc_fifo.vhd
vcom -work tdc_lib .\..\source\tdc_channel.vhd
vcom -work tdc_lib .\..\source\tdc.vhd
vcom -work tdc_lib .\source\tdc_tb.vhd

vsim tdc_tb -t 10ps -ieee_nowarn

transcript off
#------------------------------------------------------------- 
wave -divider "/---------------------------" -color 255,255,255
wave -divider "Testbench Signals" -color 255,255,255			
wave -divider "/---------------------------" -color 255,255,255
#-------------------------------------------------------------
add wave -noreg -logic {/tdc_tb/clk}
add wave -noreg -logic {/tdc_tb/clk2x}
add wave -noreg -hexadecimal -literal {/tdc_tb/ce}
add wave -noreg -logic {/tdc_tb/run_reset}
add wave -noreg -hexadecimal -literal {/tdc_tb/tb}
add wave -noreg -hexadecimal -literal {/tdc_tb/tb16}
add wave -noreg -hexadecimal -literal {/tdc_tb/fifo_re}
add wave -noreg -hexadecimal -literal {/tdc_tb/fifo_ept}
add wave -noreg -hexadecimal -literal {/tdc_tb/tdc_dout}
add wave -noreg -hexadecimal -literal {/tdc_tb/tb_ctr}
add wave -noreg -hexadecimal -literal {/tdc_tb/tb_prng}

#-------------------------------------------------------------
wave -divider "/---------------------------" -color 255,255,255
wave -divider "UUT Top Level" -color 255,255,255
wave -divider "/---------------------------" -color 255,255,255
wave -divider "Ports"  -color 255,255,255
#-------------------------------------------------------------
add wave -noreg -logic {/tdc_tb/UUT/tdc_clk}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/ce}
add wave -noreg -logic {/tdc_tb/UUT/reset}
add wave -noreg -logic {/tdc_tb/UUT/tdc_clr}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/tb}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/tb16}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/fifo_re}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/fifo_ept}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/tdc_dout}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/tdc_clr_qn}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/tdc_clr_dlyln}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/fifo_ept_q0}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/fifo_ept_q1}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/tdc_dout_q0}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/tdc_dout_q1}

#-------------------------------------------------------------
wave -divider "/---------------------------" -color 255,255,255
wave -divider "TDC Channel 1" -color 255,255,255
wave -divider "/---------------------------" -color 255,255,255
wave -divider "Ports"  -color 255,255,255
#-------------------------------------------------------------
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/tdc_clk}
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/reset}
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/tdc_clr}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/tb}
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/tb16}
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/fifo_re}
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/fifo_ept}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/tdc_dout}
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/tdc_rst_q0}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/tb_q0}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/tb_q1}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/tb_q2}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/tb_q3}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/tb_q4}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/counter}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/counter_q0}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/counter_q1}
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/fifo_full}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/fifo_din}
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/fifo_we_q0}
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/trig_q0}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/chan_q0}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__1/tdc_ch_ins/chan_q1}

#-------------------------------------------------------------
wave -divider "/---------------------------" -color 255,255,255
wave -divider "TDC Channel 10" -color 255,255,255
wave -divider "/---------------------------" -color 255,255,255
wave -divider "Ports"  -color 255,255,255
#-------------------------------------------------------------
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/tdc_clk}
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/reset}
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/tdc_clr}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/tb}
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/tb16}
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/fifo_re}
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/fifo_ept}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/tdc_dout}
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/tdc_rst_q0}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/tb_q0}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/tb_q1}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/tb_q2}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/tb_q3}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/tb_q4}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/counter}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/counter_q0}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/counter_q1}
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/fifo_full}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/fifo_din}
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/fifo_we_q0}
add wave -noreg -logic {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/trig_q0}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/chan_q0}
add wave -noreg -hexadecimal -literal {/tdc_tb/UUT/TDC_CH_GEN__10/tdc_ch_ins/chan_q1}



#--------------------------------------------------
#-------------------------------------------
transcript on

run 500 ns;