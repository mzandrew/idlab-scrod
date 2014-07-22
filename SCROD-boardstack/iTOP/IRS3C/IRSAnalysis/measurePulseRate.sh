#!/bin/bash

#Mandatory - Set binary directory
BINDIR=./

#set COPPER board working and data directories
WORKDIR=/home/copper/crt_data/20140708/
DATADIR=/export/home/copper/crt_data/20140708/data/
NUMEVENTS=2000

#Create script to send to COPPER for taking hardware triggers
rm copperCommands_hwt.sh
echo -e "#/bin/bash" >> copperCommands_hwt.sh
echo -e "cd "${WORKDIR} >> copperCommands_hwt.sh
echo -e "python ~/bin/crtdaq-hwt-run.py -n "${NUMEVENTS} >> copperCommands_hwt.sh
echo -e "exit" >> copperCommands_hwt.sh

#send command to COPPER to take hardware triggers
cat copperCommands_hwt.sh | ssh 192.168.1.203

#Get hardware trigger file name
DATAFILE=$( ls -t ${DATADIR} | head -n2 | grep hwt | grep dat )
echo $DATAFILE

#process data file with pedestal file
./processIRSDataNoPedNoCmc.sh ${DATADIR}${DATAFILE}

#get summary tree file name
TREEFILE=$( ls -t | head -n1 | grep summary )

#run analysis program on summary tree file - requires # of events as argument for rate calc.
./topDataClass_simpleDistributions ${TREEFILE} ${NUMEVENTS}
