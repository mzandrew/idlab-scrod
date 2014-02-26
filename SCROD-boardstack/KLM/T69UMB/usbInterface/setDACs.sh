#!/bin/bash

#Threshold Ch. 1(PCLK_1)
./bin/target6Control_writeDacReg $1 0 2000
#Threshold Ch. 2 (PCLK_2)
./bin/target6Control_writeDacReg $1 1 2000
#Threshold Ch. 3 (PCLK_3)
./bin/target6Control_writeDacReg $1 2 2000
#Threshold Ch. 4 (PCLK_4)
./bin/target6Control_writeDacReg $1 3 2000
#Threshold Ch. 5 (PCLK_5)
./bin/target6Control_writeDacReg $1 4 2000
#Threshold Ch. 6 (PCLK_6)
./bin/target6Control_writeDacReg $1 5 2000
#Threshold Ch. 7 (PCLK_7)
./bin/target6Control_writeDacReg $1 6 2000
#Threshold Ch. 8 (PCLK_8)
./bin/target6Control_writeDacReg $1 7 2000
#Threshold Ch. 9 (PCLK_9)
./bin/target6Control_writeDacReg $1 8 2000
#Threshold Ch. 10 (PCLK_10)
./bin/target6Control_writeDacReg $1 9 2000
#Threshold Ch. 11 (PCLK_11)
./bin/target6Control_writeDacReg $1 10 2000
#Threshold Ch. 12 (PCLK_12)
./bin/target6Control_writeDacReg $1 11 2000
#Threshold Ch. 13 (PCLK_13)
./bin/target6Control_writeDacReg $1 12 2000
#Threshold Ch. 14 (PCLK_14)
./bin/target6Control_writeDacReg $1 13 2000
#Threshold Ch. 15 (PCLK_15)
./bin/target6Control_writeDacReg $1 14 2000
#Threshold Ch. 16 (PCLK_16)
./bin/target6Control_writeDacReg $1 15 2000

#ITBias (PCLK_17)
./bin/target6Control_writeDacReg $1 16 1300
#SPAREbias (PCLK_18)
./bin/target6Control_writeDacReg $1 17 1300
#Vbias (PCLK_19)
./bin/target6Control_writeDacReg $1 18 1200
#GGbias (PCLK_20)
./bin/target6Control_writeDacReg $1 19 1600
#TRGbias (PCLK_21)
./bin/target6Control_writeDacReg $1 20 1800
#Wbias (PCLK_22)
./bin/target6Control_writeDacReg $1 21 700

#SBbuff = 2047  (PCLK_38)
./bin/target6Control_writeDacReg $1 37 1400
#SBbias  (PCLK_39)
./bin/target6Control_writeDacReg $1 38 1400
#MonTRGThresh (PCLK_40)
./bin/target6Control_writeDacReg $1 39 0

#WCBuff (PCLK_41)
./bin/target6Control_writeDacReg $1 40 1400
#CMPbias (PCLK_42)
./bin/target6Control_writeDacReg $1 41 1300
#PUbias  (PCLK_43)
./bin/target6Control_writeDacReg $1 42 2400

#Misc Digital Reg  (PCLK_44)
./bin/target6Control_writeDacReg $1 43 0 
#--NEEDS to be SET!

#VAbuff  (PCLK_45)
#./bin/target6Control_writeDacReg $1 44 1500
./bin/target6Control_writeDacReg $1 44 985
#VAdjN (PCLK_46)
#./bin/target6Control_writeDacReg $1 45 2000
./bin/target6Control_writeDacReg $1 45 2275
#VAdjP (PCLK_47)
#./bin/target6Control_writeDacReg $1 46 2050
./bin/target6Control_writeDacReg $1 46 1616

#DBbias (DAC buffer bias) (PCLK_48)
./bin/target6Control_writeDacReg $1 47 1500
#ISEL (PCLK_49)
./bin/target6Control_writeDacReg $1 48 2300
#Vdischarge (PCLK_50)
./bin/target6Control_writeDacReg $1 49 800

#PROBIAS (Vdly DAC bias) (PCLK_51)
./bin/target6Control_writeDacReg $1 50 1400
#VDLY (PCLK_52)
./bin/target6Control_writeDacReg $1 51 3400
