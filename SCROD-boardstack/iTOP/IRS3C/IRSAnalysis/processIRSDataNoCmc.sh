#!/bin/bash

#Instructions - simple script processes IRS3C data
#Usage - ./processIRSData.sh <data file> <pedestal tree file>
#Note - not currently using CAMAC information

#Mandatory - set binary directory
BINDIR=./

#set data directory + raw data file name
RAWDATAFILE=$1

#set pedestal tree file name
PEDTREE=$2

#parse raw data file
${BINDIR}parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac ${RAWDATAFILE} ${PEDTREE} "none"

#Get parse data file name
DATAFILE=$( ls -t | head -n1 | grep output_topcrt | grep root )

#Run summary tree on parsed data file
${BINDIR}RecTOProot_dev6 ${DATAFILE} "summary_"${DATAFILE}

exit 0
