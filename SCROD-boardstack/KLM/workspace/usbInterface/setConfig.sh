bin/target6Control_writeReg 5 128
bin/target6Control_writeReg 6 320
bin/target6Control_writeReg 48 2
bin/target6Control_writeReg 47 2

TrigThreshold="3100"
ASICno="0"
	bin/target6Control_writeDacReg $ASICno 0    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 2    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 4    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 6    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 8    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 10   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 12   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 14   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 16   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 18   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 20   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 22   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 24   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 26   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 28   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 30   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 1    985
	bin/target6Control_writeDacReg $ASICno 3    985
	bin/target6Control_writeDacReg $ASICno 5    985
	bin/target6Control_writeDacReg $ASICno 7    985
	bin/target6Control_writeDacReg $ASICno 9    985
	bin/target6Control_writeDacReg $ASICno 11   985
	bin/target6Control_writeDacReg $ASICno 13   985
	bin/target6Control_writeDacReg $ASICno 15   985
	bin/target6Control_writeDacReg $ASICno 17   985
	bin/target6Control_writeDacReg $ASICno 19   985
	bin/target6Control_writeDacReg $ASICno 21   985
	bin/target6Control_writeDacReg $ASICno 23   985
	bin/target6Control_writeDacReg $ASICno 25   985
	bin/target6Control_writeDacReg $ASICno 27   985
	bin/target6Control_writeDacReg $ASICno 29   985
	bin/target6Control_writeDacReg $ASICno 31   985
	bin/target6Control_writeDacReg $ASICno 48   1300 	# Sbbias
	bin/target6Control_writeDacReg $ASICno 49   0 		# Vdisch
	bin/target6Control_writeDacReg $ASICno 50   2650 	# Isel
	bin/target6Control_writeDacReg $ASICno 51   1100 	# Dbbias
	bin/target6Control_writeDacReg $ASICno 52   1500 	# Qbias
	bin/target6Control_writeDacReg $ASICno 53   1062 	# Vqbuf
	bin/target6Control_writeDacReg $ASICno 54   3500 	# VtrimT
	bin/target6Control_writeDacReg $ASICno 55   0		# Misc Digital Reg
	bin/target6Control_writeDacReg $ASICno 56   1152 	# VadjP
	bin/target6Control_writeDacReg $ASICno 57   0 		# VAPbuff
	bin/target6Control_writeDacReg $ASICno 58   2235 	# VadjN
	bin/target6Control_writeDacReg $ASICno 59   0 		# VANbuff
	bin/target6Control_writeDacReg $ASICno 61   900 	# Vbias
	bin/target6Control_writeDacReg $ASICno 62   1100 	# TRGGbias
	bin/target6Control_writeDacReg $ASICno 63   1100 	# Itbias
#	bin/target6Control_writeDacReg $ASICno 64   25	 	# SSPin LE
#	bin/target6Control_writeDacReg $ASICno 65   35	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 64   143	 	# SSPin LE
	bin/target6Control_writeDacReg $ASICno 65   163	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 66   13	 	# WR_ADDR_Inc1 LE
	bin/target6Control_writeDacReg $ASICno 67   33	 	# WR_ADDR_Inc1 TE
	bin/target6Control_writeDacReg $ASICno 68   35 		# WR_STRB1 LE
	bin/target6Control_writeDacReg $ASICno 69   45 		# WR_STRB1 TE
	bin/target6Control_writeDacReg $ASICno 70   35 		# WR_ADDR_Inc2 LE
	bin/target6Control_writeDacReg $ASICno 71   50 		# WR_ADDR_Inc2 TE
#	bin/target6Control_writeDacReg $ASICno 72   0	 	# WR_STRB2 LE
#	bin/target6Control_writeDacReg $ASICno 73   0	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 72   56	 	# WR_STRB2 LE
	bin/target6Control_writeDacReg $ASICno 73   12	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 74   40 		# MonTiming SEL
	bin/target6Control_writeDacReg $ASICno 75   58		# SSToutFB
	bin/target6Control_writeDacReg $ASICno 76   737 	# CMPbias2
	bin/target6Control_writeDacReg $ASICno 77   3112 	# Pubias
	bin/target6Control_writeDacReg $ASICno 78   1152 	# CMPbias
	bin/target6Control_writeDacReg $ASICno 79   2730 	# TPGreg

ASICno="1"
	bin/target6Control_writeDacReg $ASICno 0    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 2    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 4    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 6    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 8    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 10   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 12   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 14   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 16   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 18   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 20   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 22   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 24   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 26   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 28   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 30   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 1    985
	bin/target6Control_writeDacReg $ASICno 3    985
	bin/target6Control_writeDacReg $ASICno 5    985
	bin/target6Control_writeDacReg $ASICno 7    985
	bin/target6Control_writeDacReg $ASICno 9    985
	bin/target6Control_writeDacReg $ASICno 11   985
	bin/target6Control_writeDacReg $ASICno 13   985
	bin/target6Control_writeDacReg $ASICno 15   985
	bin/target6Control_writeDacReg $ASICno 17   985
	bin/target6Control_writeDacReg $ASICno 19   985
	bin/target6Control_writeDacReg $ASICno 21   985
	bin/target6Control_writeDacReg $ASICno 23   985
	bin/target6Control_writeDacReg $ASICno 25   985
	bin/target6Control_writeDacReg $ASICno 27   985
	bin/target6Control_writeDacReg $ASICno 29   985
	bin/target6Control_writeDacReg $ASICno 31   985
	bin/target6Control_writeDacReg $ASICno 48   1300 	# Sbbias
	bin/target6Control_writeDacReg $ASICno 49   0 		# Vdisch
	bin/target6Control_writeDacReg $ASICno 50   2650 	# Isel
	bin/target6Control_writeDacReg $ASICno 51   1100 	# Dbbias
	bin/target6Control_writeDacReg $ASICno 52   1500 	# Qbias
	bin/target6Control_writeDacReg $ASICno 53   1062 	# Vqbuf
	bin/target6Control_writeDacReg $ASICno 54   3500 	# VtrimT
	bin/target6Control_writeDacReg $ASICno 55   0		# Misc Digital Reg
	bin/target6Control_writeDacReg $ASICno 56   1152 	# VadjP
	bin/target6Control_writeDacReg $ASICno 57   0 		# VAPbuff
	bin/target6Control_writeDacReg $ASICno 58   2235 	# VadjN
	bin/target6Control_writeDacReg $ASICno 59   0 		# VANbuff
	bin/target6Control_writeDacReg $ASICno 61   900 	# Vbias
	bin/target6Control_writeDacReg $ASICno 62   1100 	# TRGGbias
	bin/target6Control_writeDacReg $ASICno 63   1100 	# Itbias
#	bin/target6Control_writeDacReg $ASICno 64   25	 	# SSPin LE
#	bin/target6Control_writeDacReg $ASICno 65   35	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 64   143	 	# SSPin LE
	bin/target6Control_writeDacReg $ASICno 65   163	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 66   13	 	# WR_ADDR_Inc1 LE
	bin/target6Control_writeDacReg $ASICno 67   33	 	# WR_ADDR_Inc1 TE
	bin/target6Control_writeDacReg $ASICno 68   35 		# WR_STRB1 LE
	bin/target6Control_writeDacReg $ASICno 69   45 		# WR_STRB1 TE
	bin/target6Control_writeDacReg $ASICno 70   35 		# WR_ADDR_Inc2 LE
	bin/target6Control_writeDacReg $ASICno 71   50 		# WR_ADDR_Inc2 TE
#	bin/target6Control_writeDacReg $ASICno 72   0	 	# WR_STRB2 LE
#	bin/target6Control_writeDacReg $ASICno 73   0	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 72   56	 	# WR_STRB2 LE
	bin/target6Control_writeDacReg $ASICno 73   12	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 74   40 		# MonTiming SEL
	bin/target6Control_writeDacReg $ASICno 75   58		# SSToutFB
	bin/target6Control_writeDacReg $ASICno 76   737 	# CMPbias2
	bin/target6Control_writeDacReg $ASICno 77   3112 	# Pubias
	bin/target6Control_writeDacReg $ASICno 78   1152 	# CMPbias
	bin/target6Control_writeDacReg $ASICno 79   2730 	# TPGreg

ASICno="2"
	bin/target6Control_writeDacReg $ASICno 0    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 2    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 4    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 6    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 8    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 10   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 12   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 14   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 16   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 18   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 20   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 22   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 24   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 26   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 28   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 30   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 1    985
	bin/target6Control_writeDacReg $ASICno 3    985
	bin/target6Control_writeDacReg $ASICno 5    985
	bin/target6Control_writeDacReg $ASICno 7    985
	bin/target6Control_writeDacReg $ASICno 9    985
	bin/target6Control_writeDacReg $ASICno 11   985
	bin/target6Control_writeDacReg $ASICno 13   985
	bin/target6Control_writeDacReg $ASICno 15   985
	bin/target6Control_writeDacReg $ASICno 17   985
	bin/target6Control_writeDacReg $ASICno 19   985
	bin/target6Control_writeDacReg $ASICno 21   985
	bin/target6Control_writeDacReg $ASICno 23   985
	bin/target6Control_writeDacReg $ASICno 25   985
	bin/target6Control_writeDacReg $ASICno 27   985
	bin/target6Control_writeDacReg $ASICno 29   985
	bin/target6Control_writeDacReg $ASICno 31   985
	bin/target6Control_writeDacReg $ASICno 48   1300 	# Sbbias
	bin/target6Control_writeDacReg $ASICno 49   0 		# Vdisch
	bin/target6Control_writeDacReg $ASICno 50   2650 	# Isel
	bin/target6Control_writeDacReg $ASICno 51   1100 	# Dbbias
	bin/target6Control_writeDacReg $ASICno 52   1500 	# Qbias
	bin/target6Control_writeDacReg $ASICno 53   1062 	# Vqbuf
	bin/target6Control_writeDacReg $ASICno 54   3500 	# VtrimT
	bin/target6Control_writeDacReg $ASICno 55   0		# Misc Digital Reg
	bin/target6Control_writeDacReg $ASICno 56   1152 	# VadjP
	bin/target6Control_writeDacReg $ASICno 57   0 		# VAPbuff
	bin/target6Control_writeDacReg $ASICno 58   2235 	# VadjN
	bin/target6Control_writeDacReg $ASICno 59   0 		# VANbuff
	bin/target6Control_writeDacReg $ASICno 61   900 	# Vbias
	bin/target6Control_writeDacReg $ASICno 62   1100 	# TRGGbias
	bin/target6Control_writeDacReg $ASICno 63   1100 	# Itbias
#	bin/target6Control_writeDacReg $ASICno 64   25	 	# SSPin LE
#	bin/target6Control_writeDacReg $ASICno 65   35	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 64   143	 	# SSPin LE
	bin/target6Control_writeDacReg $ASICno 65   163	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 66   13	 	# WR_ADDR_Inc1 LE
	bin/target6Control_writeDacReg $ASICno 67   33	 	# WR_ADDR_Inc1 TE
	bin/target6Control_writeDacReg $ASICno 68   35 		# WR_STRB1 LE
	bin/target6Control_writeDacReg $ASICno 69   45 		# WR_STRB1 TE
	bin/target6Control_writeDacReg $ASICno 70   35 		# WR_ADDR_Inc2 LE
	bin/target6Control_writeDacReg $ASICno 71   50 		# WR_ADDR_Inc2 TE
#	bin/target6Control_writeDacReg $ASICno 72   0	 	# WR_STRB2 LE
#	bin/target6Control_writeDacReg $ASICno 73   0	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 72   56	 	# WR_STRB2 LE
	bin/target6Control_writeDacReg $ASICno 73   12	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 74   40 		# MonTiming SEL
	bin/target6Control_writeDacReg $ASICno 75   58		# SSToutFB
	bin/target6Control_writeDacReg $ASICno 76   737 	# CMPbias2
	bin/target6Control_writeDacReg $ASICno 77   3112 	# Pubias
	bin/target6Control_writeDacReg $ASICno 78   1152 	# CMPbias
	bin/target6Control_writeDacReg $ASICno 79   2730 	# TPGreg

ASICno="3"
	bin/target6Control_writeDacReg $ASICno 0    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 2    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 4    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 6    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 8    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 10   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 12   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 14   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 16   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 18   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 20   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 22   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 24   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 26   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 28   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 30   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 1    985
	bin/target6Control_writeDacReg $ASICno 3    985
	bin/target6Control_writeDacReg $ASICno 5    985
	bin/target6Control_writeDacReg $ASICno 7    985
	bin/target6Control_writeDacReg $ASICno 9    985
	bin/target6Control_writeDacReg $ASICno 11   985
	bin/target6Control_writeDacReg $ASICno 13   985
	bin/target6Control_writeDacReg $ASICno 15   985
	bin/target6Control_writeDacReg $ASICno 17   985
	bin/target6Control_writeDacReg $ASICno 19   985
	bin/target6Control_writeDacReg $ASICno 21   985
	bin/target6Control_writeDacReg $ASICno 23   985
	bin/target6Control_writeDacReg $ASICno 25   985
	bin/target6Control_writeDacReg $ASICno 27   985
	bin/target6Control_writeDacReg $ASICno 29   985
	bin/target6Control_writeDacReg $ASICno 31   985
	bin/target6Control_writeDacReg $ASICno 48   1300 	# Sbbias
	bin/target6Control_writeDacReg $ASICno 49   0 		# Vdisch
	bin/target6Control_writeDacReg $ASICno 50   2650 	# Isel
	bin/target6Control_writeDacReg $ASICno 51   1100 	# Dbbias
	bin/target6Control_writeDacReg $ASICno 52   1500 	# Qbias
	bin/target6Control_writeDacReg $ASICno 53   1062 	# Vqbuf
	bin/target6Control_writeDacReg $ASICno 54   3500 	# VtrimT
	bin/target6Control_writeDacReg $ASICno 55   0		# Misc Digital Reg
	bin/target6Control_writeDacReg $ASICno 56   1152 	# VadjP
	bin/target6Control_writeDacReg $ASICno 57   0 		# VAPbuff
	bin/target6Control_writeDacReg $ASICno 58   2235 	# VadjN
	bin/target6Control_writeDacReg $ASICno 59   0 		# VANbuff
	bin/target6Control_writeDacReg $ASICno 61   900 	# Vbias
	bin/target6Control_writeDacReg $ASICno 62   1100 	# TRGGbias
	bin/target6Control_writeDacReg $ASICno 63   1100 	# Itbias
#	bin/target6Control_writeDacReg $ASICno 64   25	 	# SSPin LE
#	bin/target6Control_writeDacReg $ASICno 65   35	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 64   143	 	# SSPin LE
	bin/target6Control_writeDacReg $ASICno 65   163	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 66   13	 	# WR_ADDR_Inc1 LE
	bin/target6Control_writeDacReg $ASICno 67   33	 	# WR_ADDR_Inc1 TE
	bin/target6Control_writeDacReg $ASICno 68   35 		# WR_STRB1 LE
	bin/target6Control_writeDacReg $ASICno 69   45 		# WR_STRB1 TE
	bin/target6Control_writeDacReg $ASICno 70   35 		# WR_ADDR_Inc2 LE
	bin/target6Control_writeDacReg $ASICno 71   50 		# WR_ADDR_Inc2 TE
#	bin/target6Control_writeDacReg $ASICno 72   0	 	# WR_STRB2 LE
#	bin/target6Control_writeDacReg $ASICno 73   0	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 72   56	 	# WR_STRB2 LE
	bin/target6Control_writeDacReg $ASICno 73   12	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 74   40 		# MonTiming SEL
	bin/target6Control_writeDacReg $ASICno 75   58		# SSToutFB
	bin/target6Control_writeDacReg $ASICno 76   737 	# CMPbias2
	bin/target6Control_writeDacReg $ASICno 77   3112 	# Pubias
	bin/target6Control_writeDacReg $ASICno 78   1152 	# CMPbias
	bin/target6Control_writeDacReg $ASICno 79   2730 	# TPGreg

ASICno="4"
	bin/target6Control_writeDacReg $ASICno 0    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 2    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 4    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 6    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 8    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 10   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 12   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 14   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 16   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 18   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 20   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 22   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 24   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 26   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 28   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 30   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 1    985
	bin/target6Control_writeDacReg $ASICno 3    985
	bin/target6Control_writeDacReg $ASICno 5    985
	bin/target6Control_writeDacReg $ASICno 7    985
	bin/target6Control_writeDacReg $ASICno 9    985
	bin/target6Control_writeDacReg $ASICno 11   985
	bin/target6Control_writeDacReg $ASICno 13   985
	bin/target6Control_writeDacReg $ASICno 15   985
	bin/target6Control_writeDacReg $ASICno 17   985
	bin/target6Control_writeDacReg $ASICno 19   985
	bin/target6Control_writeDacReg $ASICno 21   985
	bin/target6Control_writeDacReg $ASICno 23   985
	bin/target6Control_writeDacReg $ASICno 25   985
	bin/target6Control_writeDacReg $ASICno 27   985
	bin/target6Control_writeDacReg $ASICno 29   985
	bin/target6Control_writeDacReg $ASICno 31   985
	bin/target6Control_writeDacReg $ASICno 48   1300 	# Sbbias
	bin/target6Control_writeDacReg $ASICno 49   0 		# Vdisch
	bin/target6Control_writeDacReg $ASICno 50   2650 	# Isel
	bin/target6Control_writeDacReg $ASICno 51   1100 	# Dbbias
	bin/target6Control_writeDacReg $ASICno 52   1500 	# Qbias
	bin/target6Control_writeDacReg $ASICno 53   1062 	# Vqbuf
	bin/target6Control_writeDacReg $ASICno 54   3500 	# VtrimT
	bin/target6Control_writeDacReg $ASICno 55   0		# Misc Digital Reg
	bin/target6Control_writeDacReg $ASICno 56   1152 	# VadjP
	bin/target6Control_writeDacReg $ASICno 57   0 		# VAPbuff
	bin/target6Control_writeDacReg $ASICno 58   2235 	# VadjN
	bin/target6Control_writeDacReg $ASICno 59   0 		# VANbuff
	bin/target6Control_writeDacReg $ASICno 61   900 	# Vbias
	bin/target6Control_writeDacReg $ASICno 62   1100 	# TRGGbias
	bin/target6Control_writeDacReg $ASICno 63   1100 	# Itbias
#	bin/target6Control_writeDacReg $ASICno 64   25	 	# SSPin LE
#	bin/target6Control_writeDacReg $ASICno 65   35	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 64   143	 	# SSPin LE
	bin/target6Control_writeDacReg $ASICno 65   163	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 66   13	 	# WR_ADDR_Inc1 LE
	bin/target6Control_writeDacReg $ASICno 67   33	 	# WR_ADDR_Inc1 TE
	bin/target6Control_writeDacReg $ASICno 68   35 		# WR_STRB1 LE
	bin/target6Control_writeDacReg $ASICno 69   45 		# WR_STRB1 TE
	bin/target6Control_writeDacReg $ASICno 70   35 		# WR_ADDR_Inc2 LE
	bin/target6Control_writeDacReg $ASICno 71   50 		# WR_ADDR_Inc2 TE
#	bin/target6Control_writeDacReg $ASICno 72   0	 	# WR_STRB2 LE
#	bin/target6Control_writeDacReg $ASICno 73   0	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 72   56	 	# WR_STRB2 LE
	bin/target6Control_writeDacReg $ASICno 73   12	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 74   40 		# MonTiming SEL
	bin/target6Control_writeDacReg $ASICno 75   58		# SSToutFB
	bin/target6Control_writeDacReg $ASICno 76   737 	# CMPbias2
	bin/target6Control_writeDacReg $ASICno 77   3112 	# Pubias
	bin/target6Control_writeDacReg $ASICno 78   1152 	# CMPbias
	bin/target6Control_writeDacReg $ASICno 79   2730 	# TPGreg

ASICno="5"
	bin/target6Control_writeDacReg $ASICno 0    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 2    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 4    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 6    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 8    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 10   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 12   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 14   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 16   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 18   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 20   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 22   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 24   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 26   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 28   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 30   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 1    985
	bin/target6Control_writeDacReg $ASICno 3    985
	bin/target6Control_writeDacReg $ASICno 5    985
	bin/target6Control_writeDacReg $ASICno 7    985
	bin/target6Control_writeDacReg $ASICno 9    985
	bin/target6Control_writeDacReg $ASICno 11   985
	bin/target6Control_writeDacReg $ASICno 13   985
	bin/target6Control_writeDacReg $ASICno 15   985
	bin/target6Control_writeDacReg $ASICno 17   985
	bin/target6Control_writeDacReg $ASICno 19   985
	bin/target6Control_writeDacReg $ASICno 21   985
	bin/target6Control_writeDacReg $ASICno 23   985
	bin/target6Control_writeDacReg $ASICno 25   985
	bin/target6Control_writeDacReg $ASICno 27   985
	bin/target6Control_writeDacReg $ASICno 29   985
	bin/target6Control_writeDacReg $ASICno 31   985
	bin/target6Control_writeDacReg $ASICno 48   1300 	# Sbbias
	bin/target6Control_writeDacReg $ASICno 49   0 		# Vdisch
	bin/target6Control_writeDacReg $ASICno 50   2650 	# Isel
	bin/target6Control_writeDacReg $ASICno 51   1100 	# Dbbias
	bin/target6Control_writeDacReg $ASICno 52   1500 	# Qbias
	bin/target6Control_writeDacReg $ASICno 53   1062 	# Vqbuf
	bin/target6Control_writeDacReg $ASICno 54   3500 	# VtrimT
	bin/target6Control_writeDacReg $ASICno 55   0		# Misc Digital Reg
	bin/target6Control_writeDacReg $ASICno 56   1152 	# VadjP
	bin/target6Control_writeDacReg $ASICno 57   0 		# VAPbuff
	bin/target6Control_writeDacReg $ASICno 58   2235 	# VadjN
	bin/target6Control_writeDacReg $ASICno 59   0 		# VANbuff
	bin/target6Control_writeDacReg $ASICno 61   900 	# Vbias
	bin/target6Control_writeDacReg $ASICno 62   1100 	# TRGGbias
	bin/target6Control_writeDacReg $ASICno 63   1100 	# Itbias
#	bin/target6Control_writeDacReg $ASICno 64   25	 	# SSPin LE
#	bin/target6Control_writeDacReg $ASICno 65   35	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 64   143	 	# SSPin LE
	bin/target6Control_writeDacReg $ASICno 65   163	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 66   13	 	# WR_ADDR_Inc1 LE
	bin/target6Control_writeDacReg $ASICno 67   33	 	# WR_ADDR_Inc1 TE
	bin/target6Control_writeDacReg $ASICno 68   35 		# WR_STRB1 LE
	bin/target6Control_writeDacReg $ASICno 69   45 		# WR_STRB1 TE
	bin/target6Control_writeDacReg $ASICno 70   35 		# WR_ADDR_Inc2 LE
	bin/target6Control_writeDacReg $ASICno 71   50 		# WR_ADDR_Inc2 TE
#	bin/target6Control_writeDacReg $ASICno 72   0	 	# WR_STRB2 LE
#	bin/target6Control_writeDacReg $ASICno 73   0	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 72   56	 	# WR_STRB2 LE
	bin/target6Control_writeDacReg $ASICno 73   12	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 74   40 		# MonTiming SEL
	bin/target6Control_writeDacReg $ASICno 75   58		# SSToutFB
	bin/target6Control_writeDacReg $ASICno 76   737 	# CMPbias2
	bin/target6Control_writeDacReg $ASICno 77   3112 	# Pubias
	bin/target6Control_writeDacReg $ASICno 78   1152 	# CMPbias
	bin/target6Control_writeDacReg $ASICno 79   2730 	# TPGreg

ASICno="6"
	bin/target6Control_writeDacReg $ASICno 0    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 2    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 4    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 6    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 8    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 10   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 12   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 14   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 16   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 18   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 20   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 22   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 24   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 26   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 28   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 30   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 1    985
	bin/target6Control_writeDacReg $ASICno 3    985
	bin/target6Control_writeDacReg $ASICno 5    985
	bin/target6Control_writeDacReg $ASICno 7    985
	bin/target6Control_writeDacReg $ASICno 9    985
	bin/target6Control_writeDacReg $ASICno 11   985
	bin/target6Control_writeDacReg $ASICno 13   985
	bin/target6Control_writeDacReg $ASICno 15   985
	bin/target6Control_writeDacReg $ASICno 17   985
	bin/target6Control_writeDacReg $ASICno 19   985
	bin/target6Control_writeDacReg $ASICno 21   985
	bin/target6Control_writeDacReg $ASICno 23   985
	bin/target6Control_writeDacReg $ASICno 25   985
	bin/target6Control_writeDacReg $ASICno 27   985
	bin/target6Control_writeDacReg $ASICno 29   985
	bin/target6Control_writeDacReg $ASICno 31   985
	bin/target6Control_writeDacReg $ASICno 48   1300 	# Sbbias
	bin/target6Control_writeDacReg $ASICno 49   0 		# Vdisch
	bin/target6Control_writeDacReg $ASICno 50   2650 	# Isel
	bin/target6Control_writeDacReg $ASICno 51   1100 	# Dbbias
	bin/target6Control_writeDacReg $ASICno 52   1500 	# Qbias
	bin/target6Control_writeDacReg $ASICno 53   1062 	# Vqbuf
	bin/target6Control_writeDacReg $ASICno 54   3500 	# VtrimT
	bin/target6Control_writeDacReg $ASICno 55   0		# Misc Digital Reg
	bin/target6Control_writeDacReg $ASICno 56   1152 	# VadjP
	bin/target6Control_writeDacReg $ASICno 57   0 		# VAPbuff
	bin/target6Control_writeDacReg $ASICno 58   2235 	# VadjN
	bin/target6Control_writeDacReg $ASICno 59   0 		# VANbuff
	bin/target6Control_writeDacReg $ASICno 61   900 	# Vbias
	bin/target6Control_writeDacReg $ASICno 62   1100 	# TRGGbias
	bin/target6Control_writeDacReg $ASICno 63   1100 	# Itbias
#	bin/target6Control_writeDacReg $ASICno 64   25	 	# SSPin LE
#	bin/target6Control_writeDacReg $ASICno 65   35	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 64   143	 	# SSPin LE
	bin/target6Control_writeDacReg $ASICno 65   163	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 66   13	 	# WR_ADDR_Inc1 LE
	bin/target6Control_writeDacReg $ASICno 67   33	 	# WR_ADDR_Inc1 TE
	bin/target6Control_writeDacReg $ASICno 68   35 		# WR_STRB1 LE
	bin/target6Control_writeDacReg $ASICno 69   45 		# WR_STRB1 TE
	bin/target6Control_writeDacReg $ASICno 70   35 		# WR_ADDR_Inc2 LE
	bin/target6Control_writeDacReg $ASICno 71   50 		# WR_ADDR_Inc2 TE
#	bin/target6Control_writeDacReg $ASICno 72   0	 	# WR_STRB2 LE
#	bin/target6Control_writeDacReg $ASICno 73   0	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 72   56	 	# WR_STRB2 LE
	bin/target6Control_writeDacReg $ASICno 73   12	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 74   40 		# MonTiming SEL
	bin/target6Control_writeDacReg $ASICno 75   58		# SSToutFB
	bin/target6Control_writeDacReg $ASICno 76   737 	# CMPbias2
	bin/target6Control_writeDacReg $ASICno 77   3112 	# Pubias
	bin/target6Control_writeDacReg $ASICno 78   1152 	# CMPbias
	bin/target6Control_writeDacReg $ASICno 79   2730 	# TPGreg

ASICno="7"
	bin/target6Control_writeDacReg $ASICno 0    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 2    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 4    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 6    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 8    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 10   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 12   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 14   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 16   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 18   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 20   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 22   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 24   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 26   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 28   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 30   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 1    985
	bin/target6Control_writeDacReg $ASICno 3    985
	bin/target6Control_writeDacReg $ASICno 5    985
	bin/target6Control_writeDacReg $ASICno 7    985
	bin/target6Control_writeDacReg $ASICno 9    985
	bin/target6Control_writeDacReg $ASICno 11   985
	bin/target6Control_writeDacReg $ASICno 13   985
	bin/target6Control_writeDacReg $ASICno 15   985
	bin/target6Control_writeDacReg $ASICno 17   985
	bin/target6Control_writeDacReg $ASICno 19   985
	bin/target6Control_writeDacReg $ASICno 21   985
	bin/target6Control_writeDacReg $ASICno 23   985
	bin/target6Control_writeDacReg $ASICno 25   985
	bin/target6Control_writeDacReg $ASICno 27   985
	bin/target6Control_writeDacReg $ASICno 29   985
	bin/target6Control_writeDacReg $ASICno 31   985
	bin/target6Control_writeDacReg $ASICno 48   1300 	# Sbbias
	bin/target6Control_writeDacReg $ASICno 49   0 		# Vdisch
	bin/target6Control_writeDacReg $ASICno 50   2650 	# Isel
	bin/target6Control_writeDacReg $ASICno 51   1100 	# Dbbias
	bin/target6Control_writeDacReg $ASICno 52   1500 	# Qbias
	bin/target6Control_writeDacReg $ASICno 53   1062 	# Vqbuf
	bin/target6Control_writeDacReg $ASICno 54   3500 	# VtrimT
	bin/target6Control_writeDacReg $ASICno 55   0		# Misc Digital Reg
	bin/target6Control_writeDacReg $ASICno 56   1152 	# VadjP
	bin/target6Control_writeDacReg $ASICno 57   0 		# VAPbuff
	bin/target6Control_writeDacReg $ASICno 58   2235 	# VadjN
	bin/target6Control_writeDacReg $ASICno 59   0 		# VANbuff
	bin/target6Control_writeDacReg $ASICno 61   900 	# Vbias
	bin/target6Control_writeDacReg $ASICno 62   1100 	# TRGGbias
	bin/target6Control_writeDacReg $ASICno 63   1100 	# Itbias
#	bin/target6Control_writeDacReg $ASICno 64   25	 	# SSPin LE
#	bin/target6Control_writeDacReg $ASICno 65   35	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 64   143	 	# SSPin LE
	bin/target6Control_writeDacReg $ASICno 65   163	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 66   13	 	# WR_ADDR_Inc1 LE
	bin/target6Control_writeDacReg $ASICno 67   33	 	# WR_ADDR_Inc1 TE
	bin/target6Control_writeDacReg $ASICno 68   35 		# WR_STRB1 LE
	bin/target6Control_writeDacReg $ASICno 69   45 		# WR_STRB1 TE
	bin/target6Control_writeDacReg $ASICno 70   35 		# WR_ADDR_Inc2 LE
	bin/target6Control_writeDacReg $ASICno 71   50 		# WR_ADDR_Inc2 TE
#	bin/target6Control_writeDacReg $ASICno 72   0	 	# WR_STRB2 LE
#	bin/target6Control_writeDacReg $ASICno 73   0	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 72   56	 	# WR_STRB2 LE
	bin/target6Control_writeDacReg $ASICno 73   12	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 74   40 		# MonTiming SEL
	bin/target6Control_writeDacReg $ASICno 75   58		# SSToutFB
	bin/target6Control_writeDacReg $ASICno 76   737 	# CMPbias2
	bin/target6Control_writeDacReg $ASICno 77   3112 	# Pubias
	bin/target6Control_writeDacReg $ASICno 78   1152 	# CMPbias
	bin/target6Control_writeDacReg $ASICno 79   2730 	# TPGreg

ASICno="8"
	bin/target6Control_writeDacReg $ASICno 0    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 2    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 4    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 6    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 8    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 10   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 12   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 14   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 16   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 18   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 20   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 22   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 24   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 26   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 28   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 30   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 1    985
	bin/target6Control_writeDacReg $ASICno 3    985
	bin/target6Control_writeDacReg $ASICno 5    985
	bin/target6Control_writeDacReg $ASICno 7    985
	bin/target6Control_writeDacReg $ASICno 9    985
	bin/target6Control_writeDacReg $ASICno 11   985
	bin/target6Control_writeDacReg $ASICno 13   985
	bin/target6Control_writeDacReg $ASICno 15   985
	bin/target6Control_writeDacReg $ASICno 17   985
	bin/target6Control_writeDacReg $ASICno 19   985
	bin/target6Control_writeDacReg $ASICno 21   985
	bin/target6Control_writeDacReg $ASICno 23   985
	bin/target6Control_writeDacReg $ASICno 25   985
	bin/target6Control_writeDacReg $ASICno 27   985
	bin/target6Control_writeDacReg $ASICno 29   985
	bin/target6Control_writeDacReg $ASICno 31   985
	bin/target6Control_writeDacReg $ASICno 48   1300 	# Sbbias
	bin/target6Control_writeDacReg $ASICno 49   0 		# Vdisch
	bin/target6Control_writeDacReg $ASICno 50   2650 	# Isel
	bin/target6Control_writeDacReg $ASICno 51   1100 	# Dbbias
	bin/target6Control_writeDacReg $ASICno 52   1500 	# Qbias
	bin/target6Control_writeDacReg $ASICno 53   1062 	# Vqbuf
	bin/target6Control_writeDacReg $ASICno 54   3500 	# VtrimT
	bin/target6Control_writeDacReg $ASICno 55   0		# Misc Digital Reg
	bin/target6Control_writeDacReg $ASICno 56   1152 	# VadjP
	bin/target6Control_writeDacReg $ASICno 57   0 		# VAPbuff
	bin/target6Control_writeDacReg $ASICno 58   2235 	# VadjN
	bin/target6Control_writeDacReg $ASICno 59   0 		# VANbuff
	bin/target6Control_writeDacReg $ASICno 61   900 	# Vbias
	bin/target6Control_writeDacReg $ASICno 62   1100 	# TRGGbias
	bin/target6Control_writeDacReg $ASICno 63   1100 	# Itbias
#	bin/target6Control_writeDacReg $ASICno 64   25	 	# SSPin LE
#	bin/target6Control_writeDacReg $ASICno 65   35	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 64   143	 	# SSPin LE
	bin/target6Control_writeDacReg $ASICno 65   163	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 66   13	 	# WR_ADDR_Inc1 LE
	bin/target6Control_writeDacReg $ASICno 67   33	 	# WR_ADDR_Inc1 TE
	bin/target6Control_writeDacReg $ASICno 68   35 		# WR_STRB1 LE
	bin/target6Control_writeDacReg $ASICno 69   45 		# WR_STRB1 TE
	bin/target6Control_writeDacReg $ASICno 70   35 		# WR_ADDR_Inc2 LE
	bin/target6Control_writeDacReg $ASICno 71   50 		# WR_ADDR_Inc2 TE
#	bin/target6Control_writeDacReg $ASICno 72   0	 	# WR_STRB2 LE
#	bin/target6Control_writeDacReg $ASICno 73   0	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 72   56	 	# WR_STRB2 LE
	bin/target6Control_writeDacReg $ASICno 73   12	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 74   40 		# MonTiming SEL
	bin/target6Control_writeDacReg $ASICno 75   58		# SSToutFB
	bin/target6Control_writeDacReg $ASICno 76   737 	# CMPbias2
	bin/target6Control_writeDacReg $ASICno 77   3112 	# Pubias
	bin/target6Control_writeDacReg $ASICno 78   1152 	# CMPbias
	bin/target6Control_writeDacReg $ASICno 79   2730 	# TPGreg

ASICno="9"
	bin/target6Control_writeDacReg $ASICno 0    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 2    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 4    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 6    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 8    $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 10   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 12   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 14   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 16   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 18   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 20   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 22   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 24   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 26   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 28   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 30   $TrigThreshold
	bin/target6Control_writeDacReg $ASICno 1    985
	bin/target6Control_writeDacReg $ASICno 3    985
	bin/target6Control_writeDacReg $ASICno 5    985
	bin/target6Control_writeDacReg $ASICno 7    985
	bin/target6Control_writeDacReg $ASICno 9    985
	bin/target6Control_writeDacReg $ASICno 11   985
	bin/target6Control_writeDacReg $ASICno 13   985
	bin/target6Control_writeDacReg $ASICno 15   985
	bin/target6Control_writeDacReg $ASICno 17   985
	bin/target6Control_writeDacReg $ASICno 19   985
	bin/target6Control_writeDacReg $ASICno 21   985
	bin/target6Control_writeDacReg $ASICno 23   985
	bin/target6Control_writeDacReg $ASICno 25   985
	bin/target6Control_writeDacReg $ASICno 27   985
	bin/target6Control_writeDacReg $ASICno 29   985
	bin/target6Control_writeDacReg $ASICno 31   985
	bin/target6Control_writeDacReg $ASICno 48   1300 	# Sbbias
	bin/target6Control_writeDacReg $ASICno 49   0 		# Vdisch
	bin/target6Control_writeDacReg $ASICno 50   2650 	# Isel
	bin/target6Control_writeDacReg $ASICno 51   1100 	# Dbbias
	bin/target6Control_writeDacReg $ASICno 52   1500 	# Qbias
	bin/target6Control_writeDacReg $ASICno 53   1062 	# Vqbuf
	bin/target6Control_writeDacReg $ASICno 54   3500 	# VtrimT
	bin/target6Control_writeDacReg $ASICno 55   0		# Misc Digital Reg
	bin/target6Control_writeDacReg $ASICno 56   1152 	# VadjP
	bin/target6Control_writeDacReg $ASICno 57   0 		# VAPbuff
	bin/target6Control_writeDacReg $ASICno 58   2235 	# VadjN
	bin/target6Control_writeDacReg $ASICno 59   0 		# VANbuff
	bin/target6Control_writeDacReg $ASICno 61   900 	# Vbias
	bin/target6Control_writeDacReg $ASICno 62   1100 	# TRGGbias
	bin/target6Control_writeDacReg $ASICno 63   1100 	# Itbias
#	bin/target6Control_writeDacReg $ASICno 64   25	 	# SSPin LE
#	bin/target6Control_writeDacReg $ASICno 65   35	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 64   143	 	# SSPin LE
	bin/target6Control_writeDacReg $ASICno 65   163	 	# SSPin TE
	bin/target6Control_writeDacReg $ASICno 66   13	 	# WR_ADDR_Inc1 LE
	bin/target6Control_writeDacReg $ASICno 67   33	 	# WR_ADDR_Inc1 TE
	bin/target6Control_writeDacReg $ASICno 68   35 		# WR_STRB1 LE
	bin/target6Control_writeDacReg $ASICno 69   45 		# WR_STRB1 TE
	bin/target6Control_writeDacReg $ASICno 70   35 		# WR_ADDR_Inc2 LE
	bin/target6Control_writeDacReg $ASICno 71   50 		# WR_ADDR_Inc2 TE
#	bin/target6Control_writeDacReg $ASICno 72   0	 	# WR_STRB2 LE
#	bin/target6Control_writeDacReg $ASICno 73   0	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 72   56	 	# WR_STRB2 LE
	bin/target6Control_writeDacReg $ASICno 73   12	 	# WR_STRB2 TE
	bin/target6Control_writeDacReg $ASICno 74   40 		# MonTiming SEL
	bin/target6Control_writeDacReg $ASICno 75   58		# SSToutFB
	bin/target6Control_writeDacReg $ASICno 76   737 	# CMPbias2
	bin/target6Control_writeDacReg $ASICno 77   3112 	# Pubias
	bin/target6Control_writeDacReg $ASICno 78   1152 	# CMPbias
	bin/target6Control_writeDacReg $ASICno 79   2730 	# TPGreg


