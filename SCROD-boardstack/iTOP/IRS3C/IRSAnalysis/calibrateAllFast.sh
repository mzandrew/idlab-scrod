#!/bin/bash

#Set binary directory
BINDIR=./

#set data directory
CURDIR=$(pwd)
WORKDIR=/home/copper/crt_data/20140708/
DATADIR=/export/home/copper/crt_data/20140708/data/
NUMEVENTS=1000

PEDTREE=$1
echo "Calibrating system, using pedestal file " ${PEDTREE}

#Create script to send to COPPER for taking pedestal + hardware triggers
rm copperCommands_pedhwt.sh
echo -e "#/bin/bash" >> copperCommands_pedhwt.sh
echo -e "cd "${WORKDIR} >> copperCommands_pedhwt.sh
#echo -e "scrod-disable-calib.py" >> copperCommands_pedhwt.sh
#echo -e "crtdaq-swt-run.py -f 001 -n 250" >> copperCommands_pedhwt.sh
#echo -e "crtdaq-swt-run.py -f 011 -n 250" >> copperCommands_pedhwt.sh
#echo -e "crtdaq-swt-run.py -f 021 -n 250" >> copperCommands_pedhwt.sh
#echo -e "crtdaq-swt-run.py -f 031 -n 250" >> copperCommands_pedhwt.sh
#echo -e "crtdaq-swt-run.py -f 101 -n 250" >> copperCommands_pedhwt.sh
#echo -e "crtdaq-swt-run.py -f 111 -n 250" >> copperCommands_pedhwt.sh
#echo -e "crtdaq-swt-run.py -f 121 -n 250" >> copperCommands_pedhwt.sh
#echo -e "crtdaq-swt-run.py -f 131 -n 250" >> copperCommands_pedhwt.sh
#echo -e "crtdaq-swt-run.py -f 201 -n 250" >> copperCommands_pedhwt.sh
#echo -e "crtdaq-swt-run.py -f 211 -n 250" >> copperCommands_pedhwt.sh
#echo -e "crtdaq-swt-run.py -f 221 -n 250" >> copperCommands_pedhwt.sh
#echo -e "crtdaq-swt-run.py -f 231 -n 250" >> copperCommands_pedhwt.sh
#echo -e "crtdaq-swt-run.py -f 301 -n 250" >> copperCommands_pedhwt.sh
#echo -e "crtdaq-swt-run.py -f 311 -n 250" >> copperCommands_pedhwt.sh
#echo -e "crtdaq-swt-run.py -f 321 -n 250" >> copperCommands_pedhwt.sh
#echo -e "crtdaq-swt-run.py -f 331 -n 250" >> copperCommands_pedhwt.sh
#echo -e "python ~/bin/crtdaq-hwt-run.py -n "${NUMEVENTS} >> copperCommands_pedhwt.sh
echo -e "python ~/bin/crtdaq-cal-run.py -n "${NUMEVENTS} >> copperCommands_pedhwt.sh
echo -e "exit" >> copperCommands_pedhwt.sh

#send command to COPPER to take software + hardware triggers
cat copperCommands_pedhwt.sh | ssh 192.168.1.203

#cd ${DATADIR}
#rm temp_ped.root
#cat `ls -t "${DATADIR}" | head -n18 | grep swt` > temp_ped.root
#cd ${CURDIR}

#Get pedestal file name
#PEDFILE=$( ls -t ${DATADIR} | head -n3 | grep swt )
#echo $PEDFILE

#Get hardware trigger file name
DATAFILE=$( ls -t ${DATADIR} | head -n2 | grep cal | grep dat )
echo $DATAFILE

#process pedestal file - create pedestal tree file in local directory
#./processPedestalData.sh ${DATADIR}${PEDFILE}

#get pedestal tree file name
#PEDTREE=$( ls -t | head -n1 | grep _Pedestal.root )
#echo ${PEDTREE}

#process data file with pedestal file
./processIRSDataNoCmc.sh ${DATADIR}${DATAFILE} ${PEDTREE}

#get summary tree file name
TREEFILE=$( ls -t | head -n3 | grep summary )

#delete old script
rm copperCommands_adjustVadjNValues.sh

#run analysis program on summary tree file
${BINDIR}topDataClass_adjustVadjN ${TREEFILE}

#get VadjN update script
cat copperCommands_adjustVadjNValues.sh | ssh 192.168.1.203
