bin/target6Control_writeReg 5 128
bin/target6Control_writeReg 6 320
bin/target6Control_writeReg 48 2
bin/target6Control_writeReg 47 2

TrigThreshold="3000"
ASICno=$1

	bin/target6Control_writeDacReg $ASICno 0    $TrigThreshold
sleep 2s
	bin/target6Control_writeDacReg $ASICno 2    $TrigThreshold
sleep 2s
	bin/target6Control_writeDacReg $ASICno 4    $TrigThreshold
sleep 2s
	bin/target6Control_writeDacReg $ASICno 6    $TrigThreshold
sleep 2s
	bin/target6Control_writeDacReg $ASICno 8    $TrigThreshold
sleep 2s
	bin/target6Control_writeDacReg $ASICno 10   $TrigThreshold
sleep 2s
	bin/target6Control_writeDacReg $ASICno 12   $TrigThreshold
sleep 2s
	bin/target6Control_writeDacReg $ASICno 14   $TrigThreshold
sleep 2s
	bin/target6Control_writeDacReg $ASICno 16   $TrigThreshold
sleep 2s
	bin/target6Control_writeDacReg $ASICno 18   $TrigThreshold
sleep 2s
	bin/target6Control_writeDacReg $ASICno 20   $TrigThreshold
sleep 2s
	bin/target6Control_writeDacReg $ASICno 22   $TrigThreshold
sleep 2s
	bin/target6Control_writeDacReg $ASICno 24   $TrigThreshold
sleep 2s
	bin/target6Control_writeDacReg $ASICno 26   $TrigThreshold
sleep 2s
	bin/target6Control_writeDacReg $ASICno 28   $TrigThreshold
sleep 2s
	bin/target6Control_writeDacReg $ASICno 30   $TrigThreshold
sleep 2s
	bin/target6Control_writeDacReg $ASICno 1    985
sleep 2s
	bin/target6Control_writeDacReg $ASICno 3    985
sleep 2s
	bin/target6Control_writeDacReg $ASICno 5    985
sleep 2s
	bin/target6Control_writeDacReg $ASICno 7    985
sleep 2s
	bin/target6Control_writeDacReg $ASICno 9    985
sleep 2s
	bin/target6Control_writeDacReg $ASICno 11   985
sleep 2s
	bin/target6Control_writeDacReg $ASICno 13   985
sleep 2s
	bin/target6Control_writeDacReg $ASICno 15   985
sleep 2s
	bin/target6Control_writeDacReg $ASICno 17   985
sleep 2s
	bin/target6Control_writeDacReg $ASICno 19   985
sleep 2s
	bin/target6Control_writeDacReg $ASICno 21   985
sleep 2s
	bin/target6Control_writeDacReg $ASICno 23   985
sleep 2s
	bin/target6Control_writeDacReg $ASICno 25   985
sleep 2s
	bin/target6Control_writeDacReg $ASICno 27   985
sleep 2s
	bin/target6Control_writeDacReg $ASICno 29   985
sleep 2s
	bin/target6Control_writeDacReg $ASICno 31   985
sleep 2s
	bin/target6Control_writeDacReg $ASICno 48   1300 	# Sbbias
sleep 2s
	bin/target6Control_writeDacReg $ASICno 49   0 		# Vdisch
sleep 2s
	bin/target6Control_writeDacReg $ASICno 50   2650 	# Isel
sleep 2s
	bin/target6Control_writeDacReg $ASICno 51   1100 	# Dbbias
sleep 2s
	bin/target6Control_writeDacReg $ASICno 52   1500 	# Qbias
sleep 2s
	bin/target6Control_writeDacReg $ASICno 53   1062 	# Vqbuf
sleep 2s
	bin/target6Control_writeDacReg $ASICno 54   3500 	# VtrimT
sleep 2s
	bin/target6Control_writeDacReg $ASICno 55   0		# Misc Digital Reg
sleep 2s
	bin/target6Control_writeDacReg $ASICno 56   1152 	# VadjP
sleep 2s
	bin/target6Control_writeDacReg $ASICno 57   0 		# VAPbuff
sleep 2s
	bin/target6Control_writeDacReg $ASICno 58   2235 	# VadjN
sleep 2s
	bin/target6Control_writeDacReg $ASICno 59   0 		# VANbuff
sleep 2s
	bin/target6Control_writeDacReg $ASICno 61   1190 	# Vbias
sleep 2s
	bin/target6Control_writeDacReg $ASICno 62   1100 	# TRGGbias
sleep 2s
	bin/target6Control_writeDacReg $ASICno 63   1100 	# Itbias
sleep 2s
	bin/target6Control_writeDacReg $ASICno 64   143	 	# SSPin LE
sleep 2s
	bin/target6Control_writeDacReg $ASICno 65   163	 	# SSPin TE
sleep 2s
	bin/target6Control_writeDacReg $ASICno 66   13	 	# WR_ADDR_Inc1 LE
sleep 2s
	bin/target6Control_writeDacReg $ASICno 67   33	 	# WR_ADDR_Inc1 TE
sleep 2s
	bin/target6Control_writeDacReg $ASICno 68   20 		# WR_STRB1 LE
sleep 2s
	bin/target6Control_writeDacReg $ASICno 69   40 		# WR_STRB1 TE
sleep 2s
	bin/target6Control_writeDacReg $ASICno 70   33 		# WR_ADDR_Inc2 LE
sleep 2s
	bin/target6Control_writeDacReg $ASICno 71   53 		# WR_ADDR_Inc2 TE
sleep 2s
	bin/target6Control_writeDacReg $ASICno 72   56	 	# WR_STRB2 LE
sleep 2s
	bin/target6Control_writeDacReg $ASICno 73   12	 	# WR_STRB2 TE
sleep 2s
	bin/target6Control_writeDacReg $ASICno 74   40 		# MonTiming SEL
sleep 2s
	bin/target6Control_writeDacReg $ASICno 75   58		# SSToutFB
sleep 2s
	bin/target6Control_writeDacReg $ASICno 76   737 	# CMPbias2
sleep 2s
	bin/target6Control_writeDacReg $ASICno 77   3112 	# Pubias
sleep 2s
	bin/target6Control_writeDacReg $ASICno 78   1152 	# CMPbias
sleep 2s
	bin/target6Control_writeDacReg $ASICno 79   2730 	# TPGreg

