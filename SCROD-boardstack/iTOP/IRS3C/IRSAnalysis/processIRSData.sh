#!/bin/bash

#Instructions - simple script processes IRS3C data
#Usage - ./processIRSData.sh <data file> <pedestal tree file> <camac tree file>

#Mandatory - set binary directory
BINDIR=./

#set data directory + raw data file name
RAWDATAFILE=$1

#set pedestal tree file name
PEDTREE=$2

#set CAMAC tree file name
CAMACFILE=$3

#parse the CAMAC file
${BINDIR}ConvertCAMAC_CRTSetup ${CAMACFILE} "output_ConvertCAMAC_CRTSetup.root"

#parse raw data file
${BINDIR}parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac ${RAWDATAFILE} ${PEDTREE} "output_ConvertCAMAC_CRTSetup.root"

#Get parse data file name
DATAFILE=$( ls -t | head -n1 | grep output_topcrt | grep root )

#Run summary tree on parsed data file
${BINDIR}RecTOProot_dev6 ${DATAFILE} "summary_"${DATAFILE}

#Run simple summary distributions program
#${BINDIR}topDataClass_simpleDistributions "summary_"${DATAFILE} 1000

exit 0
