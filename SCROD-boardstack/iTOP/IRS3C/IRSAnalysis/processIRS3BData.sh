#!/bin/bash

#Instructions
# Program accepts run number of files to process, assuming there is a .dat file, .cmc file and pedestal file
#0) Produce pedestal file:
#   compile basic parser program: g++ -o parseIRS3BCopperTriggerData src/parseIRS3BCopperTriggerData.cxx `root-config --cflags --glibs`
#   produce parsed data file: ./parseIRS3BCopperTriggerData <raw dat pedestal file>
#   go to src directory: cd src
#   make -f GNUmakefile.GetMeanAndRMSFromIRS3BCopperTriggerData
#   go up back one directory: cd ../
#   ./src/GetMeanAndRMSFromIRS3BCopperTriggerData <output of parser for pedestal file>
#1) Modify and recompile CAMAC conversion program: g++ -o ConvertCAMAC_hawaiiTestSetup src/ConvertCAMAC_hawaiiTestSetup.cc `root-config --cflags --glibs`
#2) Recompile integrated parser program: 
#   g++ -o parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac src/parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac.cxx `root-config --cflags --glibs`
#3) Recompile summary tree creator: g++ -o RecTOProot_dev6 src/RecTOProot_dev6.cc `root-config --cflags --glibs`

RUN=$1

echo $RUN

PEDFILE=output_topcrt-pulser-e000062r000281-f000_Pedestal.root

DATFILE=topcrt-*${RUN}-f000.dat
CMCFILE=topcrt-*${RUN}-f000.cmc
CMCROOTFILE="cmc_"${RUN}".root"

./ConvertCAMAC_hawaiiTestSetup ${CMCFILE} ${CMCROOTFILE}
./parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac ${DATFILE} ${PEDFILE} ${CMCROOTFILE}

RAWDATAFILE=output_topcrt-*${RUN}*-f000.root
TREEFILE="summaryTree_"${DATAID}"_"${RUN}".root"
./RecTOProot_dev6 ${RAWDATAFILE} ${TREEFILE}

exit 0
