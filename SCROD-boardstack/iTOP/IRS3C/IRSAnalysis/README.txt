Instructions - March 14, 2014

This set of programs is intended to provide a simple way to measure time resolution for a single IRS3 ASIC channel. It should be straightforward to modify and test different methods. There are three types of data:

-Raw data: binary SCROD or CAMAC data packets
-Processed waveform data tree: ROI sampled waveforms organized in a TTree structure, output by parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac.cxx
-Summary trees: tree containing pulse time and charge information, output by RecTOProot_dev6.cc


Setting up analysis programs:
-assumes initial working directory is IRSAnalysis

1) Compile basic data parser program: 
g++ -o parseIRS3BCopperTriggerData src/parseIRS3BCopperTriggerData.cxx `root-config --cflags --glibs`

2) Compile sample pedestal value measurement program:
-go to src directory: 
cd src
make -f GNUmakefile.GetMeanAndRMSFromIRS3BCopperTriggerData
-go up back one directory: 
cd ../

3) Modify and recompile CAMAC conversion program:
g++ -o ConvertCAMAC_hawaiiTestSetup src/ConvertCAMAC_hawaiiTestSetup.cc `root-config --cflags --glibs`
-may need to modify the program with the current crate controller ID #, #define HEADER 0x00ccXXXX

4) Compile ROI data parser program:
g++ -o parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac src/parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac.cxx `root-config --cflags --glibs`

5) Compile summary tree creator: 
g++ -o RecTOProot_dev6 src/RecTOProot_dev6.cc `root-config --cflags --glibs`

6) Compile simple analysis program
g++ -o topDataClass_doAnalysis src/topDataClass_doAnalysis.cpp `root-config --cflags --glibs`


Processing Data:

1) Measure pedestal values:
-produce parsed pedestal data file: 
./parseIRS3BCopperTriggerData <raw dat pedestal file>
-run pedestal measurement program on parsed pedestal data:
./src/GetMeanAndRMSFromIRS3BCopperTriggerData <output of parser for pedestal file>
-produces "pedestal file"

2) Process the ROI data:
-parse the CAMAC data file:
./ConvertCAMAC_hawaiiTestSetup <raw CAMAC file> <desired output file name>
-parse the ROI data, apply pedestal correction, integrating the CAMAC data:
./parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac <raw ROI data file> <pedestal file name> <processed CAMAC file name>
-produce the waveform data tree file
-the processIRS3BData.sh script shows how to run these programs and can be used to automatically process a run after the pedestal file is specified

3) Produce the summary tree
-run the summary tree conversion program:
./RecTOProot_dev6 <ROI waveform data tree file> <desired output file name>


Analyzing the Summary Tree

1) Run the simple analysis program
-program topDataClass_doAnalysis.cpp has a hard-coded "windowTime" variable that needs to be set, defines pulse time window
-run the analysis program on summary-tree file
./topDataClass_doAnalysis summaryTree__281.root 0 0 0 2
-output should contain histograms that can be used to measure system time resolution


