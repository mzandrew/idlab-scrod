#!/bin/bash

#Set binary directory
BINDIR=./

#set data directory
WORKDIR=/home/copper/crt_data/20140708/
DATADIR=/export/home/copper/crt_data/20140708/data/
NUMEVENTS=500

#set row, col, ch
ROW=$1
COL=$2
CH=$3

if [ "$ROW" -gt 3 ] || [ "$ROW" -lt 0 ] ; then
	echo "Invalid row number, exiting"
	exit 0
fi
if [ "$COL" -gt 3 ] || [ "$COL" -lt 0 ] ; then
	echo "Invalid col number, exiting"
	exit 0
fi
if [ "$CH" -gt 7 ] || [ "$CH" -lt 0 ] ; then
	echo "Invalid ch number, exiting"
	exit 0
fi

#Create script to send to COPPER for taking pedestal + hardware triggers
rm copperCommands_pedhwt.sh
echo -e "#/bin/bash" >> copperCommands_pedhwt.sh
echo -e "cd "${WORKDIR} >> copperCommands_pedhwt.sh
echo -e "scrod-disable-calib.py" >> copperCommands_pedhwt.sh
echo -e "crtdaq-swt-run.py -f "${ROW}${COL}${CH}" -n 250" >> copperCommands_pedhwt.sh
echo -e "scrod-route-calib.py "${ROW}" "${COL}" "${CH} >> copperCommands_pedhwt.sh
echo -e "python ~/bin/crtdaq-hwt-run.py -n "${NUMEVENTS} >> copperCommands_pedhwt.sh
echo -e "exit" >> copperCommands_pedhwt.sh

#send command to COPPER to take software + hardware triggers
cat copperCommands_pedhwt.sh | ssh 192.168.1.203

#Get pedestal file name
PEDFILE=$( ls -t ${DATADIR} | head -n3 | grep swt )
echo $PEDFILE

#Get hardware trigger file name
DATAFILE=$( ls -t ${DATADIR} | head -n3 | grep hwt | grep dat )
echo $DATAFILE

#process pedestal file - create pedestal tree file in local directory
./processPedestalData.sh ${DATADIR}${PEDFILE}

#get pedestal tree file name
PEDTREE=$( ls -t | head -n1 | grep _Pedestal.root )
echo ${PEDTREE}

sleep 1

#process data file with pedestal file
./processIRSDataNoCmc.sh ${DATADIR}${DATAFILE} ${PEDTREE}

sleep 1

#get summary tree file name
TREEFILE=$( ls -t | head -n3 | grep summary )

echo ${TREEFILE}

#delete old script
rm copperCommands_adjustVadjNValues.sh

#run analysis program on summary tree file
${BINDIR}topDataClass_adjustVadjN ${TREEFILE}

#get VadjN update script
cat copperCommands_adjustVadjNValues.sh | ssh 192.168.1.203
