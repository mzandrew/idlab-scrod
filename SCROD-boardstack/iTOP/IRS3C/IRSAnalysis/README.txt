Instructions - July 7, 2014

This set of programs is intended to provide a simple way to process IRS3 RevC/D carrier data quickly. It should be straightforward to modify and test different methods. It is not intended to replace TOPCAF, and should not be developed further. There are three types of data:

-Raw data: binary SCROD or CAMAC data packets
-Processed waveform data tree: ROI sampled waveforms organized by event in a TTree structure, output by program parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac.cxx
-Summary trees: tree containing pulse time and charge information, output by program RecTOProot_dev6.cc

Setting up analysis programs:
-commands assume working directory is IRSAnalysis

1) Compile programs:
g++ -o parseIRS3BCopperTriggerData src/parseIRS3BCopperTriggerData.cxx `root-config --cflags --glibs`
g++ -o makePedestalFile src/makePedestalFile.cpp `root-config --cflags --glibs`
g++ -o ConvertCAMAC_CRTSetup src/ConvertCAMAC_CRTSetup.cc `root-config --cflags --glibs`
g++ -o parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac src/parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac.cxx `root-config --cflags --glibs`
g++ -o RecTOProot_dev6 src/RecTOProot_dev6.cc `root-config --cflags --glibs`
g++ -o topDataClass_simpleDistributions src/topDataClass_simpleDistributions.cpp `root-config --cflags --glibs`
g++ -o topDataClass_doAnalysis src/topDataClass_doAnalysis.cpp `root-config --cflags --glibs`

-Note: may need to modify the "ConvertCAMAC_CRTSetup" program with the current crate controller ID #, #define HEADER 0x00ccXXXX

Processing Data:

1) Measure pedestal values:
-produce parsed pedestal data file: 
./parseIRS3BCopperTriggerData <raw dat pedestal file>
-run pedestal measurement program on parsed pedestal data:
./src/GetMeanAndRMSFromIRS3BCopperTriggerData <output of parser for pedestal file>
-produces "pedestal file"
-script processPedestalData.sh automates this procedure, usage: ./processPedestalData.sh <pedestal file>

2) Process the ROI waveform data, produce waveform data tree file
-parse the CAMAC data file:
./ConvertCAMAC_CRTSetup <raw CAMAC file> <desired output file name>
-parse the ROI data, apply pedestal correction, integrate CAMAC data:
./parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac <raw ROI data file> <pedestal file name> <processed CAMAC file name>
-script processIRSData.sh automates this procedure, usage:
./processIRSData.sh <data file> <pedestal tree file> <camac tree file>
-script processIRSDataNoCmc.sh automates this procedure, no CAMAC data required
-script processIRSDataNoPedNoCmc.sh automates this procedure, no CAMAC/pedestal data required

3) Produce the summary tree file
-run the summary tree conversion program:
./RecTOProot_dev6 <ROI waveform data tree file> <desired output file name>
-this step is included automatically in the processIRSData.sh and related scripts

Analyzing the Summary Tree

1) Run the simple summary distribution program
./topDataClass_simpleDistributions <summary tree file>
-this step is included automatically in the processIRSData.sh and related scripts
