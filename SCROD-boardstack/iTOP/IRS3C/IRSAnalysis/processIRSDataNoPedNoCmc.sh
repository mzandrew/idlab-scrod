#!/bin/bash

#Instructions - simple script processes IRS3C data
#Usage - ./processIRSDataNoPedNoCmc.sh <data file> <pedestal tree file>
#Note - not currently using CAMAC information

#set binary directory
BINDIR=./

#set data directory + raw data file name
RAWDATAFILE=$1

#parse raw data file
${BINDIR}parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac ${RAWDATAFILE} "none" "none"

#Get parse data file name
DATAFILE=$( ls -t | head -n1 | grep output_topcrt | grep root )

#Run summary tree on parsed data file
${BINDIR}RecTOProot_dev6 ${DATAFILE} "summary_"${DATAFILE}

#Run simple summary distributions program
${BINDIR}topDataClass_simpleDistributions "summary_"${DATAFILE} 1000

exit 0
