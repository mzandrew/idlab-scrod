#!/bin/bash

#Current SCROD to fibre map
#a:0 :: d003b - Mod 0
#b:0 :: d0042 - Mod 1
#c:0 :: d0041 - Mod 2
#d:0 :: d0043 - Mod 3

#Register writing command
#./registerWrite.sh REG REGVAL FIBRE

#VadjP Study variables
NUMSTEP=6
DACBASE=43500 #Low-end VadjP
DACSTEP=200
REGBASE=251 #Register base for VadjP values

#LOOP OVER DAC VALUES - write registers, take and process data
for ((i=1, DACVAL=${DACBASE} ; i <= ${NUMSTEP} ; i++, DACVAL=DACVAL+${DACSTEP}))
do
 echo "Step Number $i: Setting registers to value " ${DACVAL}

 #Write registers
 for ((j=0, REG=${REGBASE} ; j < 16 ; j++, REG=REG+1))
 do
  echo "	Write register " ${REG} " to " ${DACVAL}
  ./registerWrite.sh ${REG} ${DACVAL}
 done

 #Take data
 ./checkAll.sh
 SUMMARYTREE=$( ls -t | head -n1 | grep summary )
 echo "Summary tree file is " ${SUMMARYTREE}

 #Process data
 ./topDataClass_processScanDACRun ${SUMMARYTREE} ${REGBASE} ${DACVAL}
done
