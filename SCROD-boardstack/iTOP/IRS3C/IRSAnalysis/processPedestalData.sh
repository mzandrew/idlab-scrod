#!/bin/bash

#Instructions - simple program that runs pedestal file processing programs
#Usage - ./processPedestalData.sh <pedestal file>

#MANDATORY - set binary directory
BINDIR=./

#set raw pedestal file name
RAWPEDFILE=$1

#parse pedestal file
${BINDIR}parseIRS3BCopperTriggerData ${RAWPEDFILE}

#Get parsed pedestal file name
PEDFILE=$( ls -t | head -n1 | grep output_parseIRS3BCopperTriggerData )

#Process pedestal file into pedestal tree
${BINDIR}makePedestalFile ${PEDFILE}

exit 0
