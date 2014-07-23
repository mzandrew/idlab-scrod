#!/bin/bash

#Current SCROD to fibre map
#a:0 :: d003b - Mod 0
#b:0 :: d0042 - Mod 1
#c:0 :: d0041 - Mod 2
#d:0 :: d0043 - Mod 3

#Register writing command
#./registerWrite.sh REG REGVAL FIBRE

FIBRE=a:0 #MOD 0
ROW=0
COL=0
CH=1

#VadjP Study variables
REG=251 #VADJP for row 0 col 0
NUMSTEP=5
DACBASE=43500 #Default VadjP = 44000
DACSTEP=250

for ((i=1, DACVAL=${DACBASE} ; i <= ${NUMSTEP} ; i++, DACVAL=DACVAL+${DACSTEP}))
do
 echo "Step Number $i: Setting register " ${REG} " to value " ${DACVAL}
 continue;
 #./registerWrite.sh ${REG} ${DACVAL} ${FIBRE}
 ./checkChannel.sh ${ROW} ${COL} ${CH}
 SUMMARYTREE=$( ls -t | head -n1 | grep summary )
 echo ${SUMMARYTREE}
 ./topDataClass_processScanDACRun ${SUMMARYTREE} ${REG} ${DACVAL}
done
