#include "packet_interface.h"
#include <iostream>
#include <fstream>
#include <sstream>
#include <cstdlib>
#include "TFile.h"
#include "TTree.h"
#include "TSystem.h"
#include "TROOT.h"
#include "TApplication.h"
#include "TString.h"
#include "TObjArray.h"
#include "CRTPedestalLUT.hh"
#include "convertScrodIdToElectronicsModuleNumber.h"
#include <stdlib.h>
#include <map>
using namespace std;

#define COMPILEPARSEIRS3BCOPPERTRIGGERDATA_ROIBASEDOUTPUT_FULLCAMAC
//define global constants
#define MAX_SEGMENTS_PER_EVENT 512
#define POINTS_PER_WAVEFORM    64
#define MEMORY_DEPTH           64
#define NCOLS                  4
#define NROWS                  4
#define NCHS                   8
#define NWORDS_EVENT_HEADER    11
#define NWORDS_WAVE_PACKET     42
#define NELECTRONICSMODULES    5

void initializeRootTree(std::string inputFileName);
void processBuffer(unsigned int *buffer_uint, int sizeInUint32);
void parseDataPacket(unsigned int *buffer_uint, int bufPos, int sizeInUint32);
int processWaveform(unsigned int *buffer_uint, int bufPos, int sizeInUint32);
TString getOutputFileName(std::string inputFileName);
void getCamacEntry(Int_t IRS3BEventNum);
void cacheCamacEntries();
Int_t getRunNumber(TString fileName);

//Set tree variables as global for quick implementation
UInt_t scrodId;
UInt_t winId;
int electronicsModule;
int eventNum;
int asicCol;
int asicRow;
int asicCh;
int window;
Short_t referenceASICwindow;

const Int_t MaxROI(400);
const Int_t MaxSciFiHits(250);
const int windowsPerROI(4);
const int samplesPerROI(windowsPerROI*POINTS_PER_WAVEFORM);


TFile* outputFile;
TTree* newTree;
Int_t new_nROI;
Short_t new_camacTDC;
Int_t new_eventNum;
Int_t new_runNum;
Short_t new_referenceASICwindow[MaxROI];
UInt_t new_scrodId[MaxROI];
Short_t new_eModule[MaxROI];
Short_t new_asicRow[MaxROI];
Short_t new_asicCol[MaxROI];
Short_t new_asicCh[MaxROI];
Int_t new_ROI[MaxROI];
Short_t new_firstWindow[MaxROI];
Int_t new_nWindows[MaxROI];
Int_t new_nSamples[MaxROI];
Int_t new_samples[MaxROI][samplesPerROI];
Float_t new_PSsamples[MaxROI][samplesPerROI];
Float_t new_sampleErrors[MaxROI][samplesPerROI];
Short_t new_sampleNum[MaxROI][samplesPerROI];
Bool_t new_truncatedWaveform[MaxROI];

Int_t camac_eventNum;
Int_t camacTime_sec;
Int_t camacTime_msec;
Int_t trigS_tdc[2];
Int_t trigS_adc[2];
Int_t trigM_tdc[2];
Int_t trigM_adc[2];
Int_t timing_tdc;
Int_t timing_adc;
Int_t veto_adc[2];
Int_t ratemon;
Short_t ftsw;
Int_t rf[4];
Short_t eventtag;
Short_t c3377nhit;
Int_t nSciFi_hits;
Short_t c3377tdc[MaxSciFiHits];
Short_t c3377lt[MaxSciFiHits];
Short_t c3377ch[MaxSciFiHits];

bool writeCamacTDCValues(true);
TFile* camacFile;
TTree* camacTree;
bool camacEntriesCached(false);
std::map<Int_t, Long64_t> camacMap;
bool writeEvent(true);

Int_t lastEventNum = -1;
Int_t ROI = 0;
Int_t windowInROI = 0;
bool subtractPedestals(true);
CRTPedestalLUT* pedestal;
bool includeSampleNum(false);
bool includeRunNumber(true);
bool includeTruncatedWaveFormFlag(true);

	



void parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac() {
        std::cout << "Usage:  parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac(inputFileName, [pedestalFileName], [camacFileName])" << std::endl;
        std::cout << "        This script will convert a data file from the IRS3B readout to a root file based on a" << std::endl;
	std::cout << "        collection of ROIs for each trigger/event." << std::endl;
	std::cout << "        If a pedestal file name is provided then pedestal subtracted vales are errors are stored." << std::endl; 
        std::cout << "        If a camac file name is provided camacTDC values will be written." << std::endl;
}
void parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac(std::string inputFileName, TString pedestalFileName);
void parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac(std::string inputFileName, TString pedestalFileName, TString camacFileName);

void parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac(std::string inputFileName) {
  subtractPedestals = false;
  writeCamacTDCValues = false;
  parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac(inputFileName, "none", "none");  
}

void parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac(std::string inputFileName, TString pedestalFileName) {
  writeCamacTDCValues = false;
  parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac(inputFileName, pedestalFileName, "none");
}

void parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac(std::string inputFileName, TString pedestalFileName, TString camacFileName){

        if (""==pedestalFileName || "none"==pedestalFileName) {
          subtractPedestals = false;	  
        }
        if (""==camacFileName || "none"==camacFileName) {
          writeCamacTDCValues = false;	  
        }	
	
	
	//define input file and parsing
	ifstream infile;	
	std::cout << " inputFileName " << inputFileName << std::endl;
	infile.open(inputFileName.c_str(), std::ifstream::in | std::ifstream::binary);  
        new_runNum = getRunNumber(TString(inputFileName));

        if (infile.fail()) {
		std::cerr << "Error opening input file, exiting" << std::endl;
		exit(-1);
	}

        if (writeCamacTDCValues) {
	  std::cout << " camacFileName " << camacFileName << std::endl;
	  camacFile = new TFile(camacFileName);
  	  if (camacFile->IsZombie()) {
		std::cout << "Error opening camac file" << std::endl;
		exit(-1);
  	  }
  	  //initialize tree branches
  	  camacTree = (TTree*) camacFile->Get("camac");
	  if( !camacTree )
		exit(-1);
          camacTree->SetBranchAddress("event", &camac_eventNum);
  	  camacTree->SetBranchAddress("time1", &camacTime_sec);
  	  camacTree->SetBranchAddress("time2", &camacTime_msec);
          camacTree->SetBranchAddress("trigS_tdc", &trigS_tdc);
          camacTree->SetBranchAddress("trigS_adc", &trigS_adc);
          camacTree->SetBranchAddress("trigM_tdc", &trigM_tdc);
          camacTree->SetBranchAddress("trigM_adc", &trigM_adc);
          camacTree->SetBranchAddress("timing_tdc", &timing_tdc);
          camacTree->SetBranchAddress("timing_adc", &timing_adc);
          camacTree->SetBranchAddress("veto_adc", &veto_adc);	  
          camacTree->SetBranchAddress("ratemon", &ratemon);
          camacTree->SetBranchAddress("ftsw", &ftsw);
          camacTree->SetBranchAddress("rf", &rf);
          camacTree->SetBranchAddress("eventtag", &eventtag);
          camacTree->SetBranchAddress("c3377nhit", &c3377nhit);
          camacTree->SetBranchAddress("c3377tdc", &c3377tdc);
          camacTree->SetBranchAddress("c3377lt", &c3377lt);
          camacTree->SetBranchAddress("c3377ch", &c3377ch);
        }

    	// get length of file:
    	infile.seekg (0, infile.end);
    	int size_in_bytes = infile.tellg();
    	infile.seekg (0, infile.beg);

    	char * buffer = new char [size_in_bytes];
	unsigned int *buffer_uint = (unsigned int *) buffer;

    	std::cout << "Reading " << size_in_bytes << " bytes... ";

    	// read data as a block:
    	infile.read (buffer,size_in_bytes);
    	if (infile) {
      		std::cout << "all characters read successfully." << std::endl;
    	} else {
      		std::cout << "error: only " << infile.gcount() << " could be read" << std::endl;
	}
    	infile.close();

	//initialize tree to store trigger bit data
	initializeRootTree(inputFileName);

        if (subtractPedestals) {
	  std::cout << "Subtracting pedestals using: " << pedestalFileName << std::endl;
	  pedestal = new CRTPedestalLUT(pedestalFileName, NELECTRONICSMODULES, NROWS, NCOLS, NCHS, MEMORY_DEPTH, POINTS_PER_WAVEFORM);
          outputFile->cd();
        }

	//process file buffer
	processBuffer(buffer_uint,size_in_bytes/4);
        
	//fill final entry:
        //if (writeCamacTDCValues) {getCamacTDC(lastEventNum);}	
	//newTree->Fill();
	//write out tree
        newTree->Write();


        //Write out the settings used in creating the data tree:
        Int_t numberOfElectronicsModules(NELECTRONICSMODULES);
	Int_t numberOfAsicRows(NROWS);
	Int_t numberOfAsicColumns(NCOLS);
	Int_t numberOfAsicChannels(NCHS);
	Int_t numberOfWindows(MEMORY_DEPTH);
	Int_t numberOfSamples(POINTS_PER_WAVEFORM);
        Int_t windowsPerROIMeta(windowsPerROI);
        Int_t samplesPerROIMeta(samplesPerROI);
        TString dataFileName(inputFileName);
  
        TTree* MetaDataTree = new TTree("MetaData", "metadata");  
        MetaDataTree->Branch("nEModules", &numberOfElectronicsModules, "nEModules/I");   
        MetaDataTree->Branch("nAsicRows", &numberOfAsicRows, "nAsicRows/I");
        MetaDataTree->Branch("nAsicColumns", &numberOfAsicColumns, "nAsicColumns/I");
        MetaDataTree->Branch("nAsicChannels", &numberOfAsicChannels, "nAsicChannels/I");
        MetaDataTree->Branch("nWindows", &numberOfWindows, "nWindows/I");
        MetaDataTree->Branch("nSamples", &numberOfSamples, "nSamples/I");
        MetaDataTree->Branch("windowsPerROI", &windowsPerROIMeta, "windowsPerROI/I");
        MetaDataTree->Branch("samplesPerROI", &samplesPerROIMeta, "samplesPerROI/I");
        MetaDataTree->Branch("dataFile", "TString", &dataFileName);
        MetaDataTree->Branch("pedestalFile", "TString", &pedestalFileName);	
        MetaDataTree->Branch("camacFile", "TString", &pedestalFileName);
        MetaDataTree->Fill();
        MetaDataTree->Write();  

	outputFile->Close();
	return;
}

//initialize tree to store trigger bit data
void initializeRootTree(std::string inputFileName){

  TString outputFileName(getOutputFileName(inputFileName));
  std::cout << " outputFileName " << outputFileName << std::endl;
  outputFile = new TFile(outputFileName, "recreate");

  newTree = new TTree("rawData", "rawData");
  if (includeRunNumber) {
    newTree->Branch("runNum", &new_runNum, "runNum/I");  
  }
  newTree->Branch("eventNum", &new_eventNum, "eventNum/I");
//  if (writeCamacTDCValues) {
//    newTree->Branch("camacTDC", &new_camacTDC, "camacTDC/S");   
//  }
  newTree->Branch("nROI", &new_nROI, "nROI/I");
  newTree->Branch("scrodId", &new_scrodId, "scrodId[nROI]/i");
  newTree->Branch("refWindow", &new_referenceASICwindow, "refWindow[nROI]/S");
  newTree->Branch("eModule", &new_eModule, "eModule[nROI]/S");
  newTree->Branch("asicRow", &new_asicRow, "asicRow[nROI]/S");      
  newTree->Branch("asicCol", &new_asicCol, "asicCol[nROI]/S");    
  newTree->Branch("asicCh", &new_asicCh, "asicCh[nROI]/S");  
  newTree->Branch("ROI", &new_ROI, "ROI[nROI]/I");
  newTree->Branch("firstWindow", &new_firstWindow, "firstWindow[nROI]/S");    
  //fixed size second dimension:
  TString samplesBranchLeafList("samples[nROI][");
  samplesBranchLeafList += samplesPerROI;
  samplesBranchLeafList += "]/I";   
  newTree->Branch("samples", &new_samples, samplesBranchLeafList);
  if (subtractPedestals) {
    TString PSsamplesBranchLeafList("PSsamples[nROI][");
    PSsamplesBranchLeafList += samplesPerROI;
    PSsamplesBranchLeafList += "]/F";   
    newTree->Branch("PSsamples", &new_PSsamples, PSsamplesBranchLeafList);
    TString sampleErrorsBranchLeafList("sampleErrors[nROI][");
    sampleErrorsBranchLeafList += samplesPerROI;
    sampleErrorsBranchLeafList += "]/F";   
    newTree->Branch("sampleErrors", &new_sampleErrors, sampleErrorsBranchLeafList);
  }
  if (includeSampleNum) {
    TString sampleNumBranchLeafList("sampleNum[nROI][");
    sampleNumBranchLeafList += samplesPerROI;
    sampleNumBranchLeafList += "]/S";   
    newTree->Branch("sampleNum", &new_sampleNum, sampleNumBranchLeafList);
  }
  if (includeTruncatedWaveFormFlag) {
    newTree->Branch("truncatedWaveform", &new_truncatedWaveform, "truncatedWaveform[nROI]/O");
  }
  if (writeCamacTDCValues) {
    newTree->Branch("unixTimeSeconds",&camacTime_sec,"unixTimeSeconds/I");
    newTree->Branch("unixTimeMilliSeconds",&camacTime_msec,"unixTimeMilliSeconds/I");
    newTree->Branch("camac_eventNum", &camac_eventNum, "camac_eventNum/I");
    newTree->Branch("trigS_tdc", trigS_tdc, "trigS_tdc[2]/I");
    newTree->Branch("trigS_adc", trigS_adc, "trigS_adc[2]/I");
    newTree->Branch("trigM_tdc", trigM_tdc, "trigM_tdc[2]/I");
    newTree->Branch("trigM_adc", trigM_adc, "trigM_adc[2]/I");
    newTree->Branch("timing_tdc" ,&timing_tdc, "timing_tdc/I");
    newTree->Branch("timing_adc", &timing_adc, "timing_adc/I");
    newTree->Branch("veto_adc", &veto_adc, "veto_adc[2]/I");    
    newTree->Branch("ratemon", &ratemon, "ratemon/I");
    newTree->Branch("ftsw", &ftsw, "ftsw/S");
    newTree->Branch("rf", rf, "rf[4]/I");
    newTree->Branch("eventtag", &eventtag, "eventtag/S");
    newTree->Branch("SciFi_nhit", &c3377nhit, "SciFi_nhit/S");
    newTree->Branch("SciFi_tdc", c3377tdc, "SciFi_tdc[SciFi_nhit]/S");
    newTree->Branch("SciFi_lt", c3377lt, "SciFi_lt[SciFi_nhit]/S");
    newTree->Branch("SciFi_ch", c3377ch, "SciFi_ch[SciFi_nhit]/S");
  }


  return;
}

//function loops through file buffers, extracts trigger bits from data packet and organizes by event
void processBuffer(unsigned int *buffer_uint, int sizeInUint32){

    	// loop through entire file
	for(int pos = 0 ; pos < sizeInUint32 ; pos++ )
		parseDataPacket(buffer_uint,pos,sizeInUint32);
		
    	delete[] buffer_uint;
	return;
}	

//function parses data packet and returns trigger bit, lots of hardcoded parameters here that will be removed in final implmentation
void parseDataPacket(unsigned int *buffer_uint, int bufPos, int sizeInUint32){

        //std::cout << std::hex << buffer_uint[bufPos] << std::endl;

	//check for buffer overflow
	if( bufPos+7 >= sizeInUint32 )
		return;


	//Detect header word
	if( buffer_uint[bufPos] != PACKET_HEADER )
		return;

	//Detect waveform word
	if( buffer_uint[bufPos+2] != PACKET_TYPE_WAVEFORM )
		return;

	//get packet header info
	scrodId = buffer_uint[bufPos+3];
        referenceASICwindow = buffer_uint[bufPos+4];
	eventNum = buffer_uint[bufPos+5];
        //With only one module set this to zero for limited backwards compatibility:
        if (1==NELECTRONICSMODULES) {electronicsModule = 0;}
	else {electronicsModule = convertScrodIdToElectronicsModuleNumber(scrodId);}
        
        if (eventNum != lastEventNum) {
          static bool eventNumberWarning(true);
          if (lastEventNum > eventNum && eventNumberWarning) {
	    std::cerr << "Warning: Event numbers do not appear in consecutive order in the input data file!" << std::endl;
	    std::cerr << "         Each entry in the output root tree will not correspond to one event." << std::endl; 
            eventNumberWarning = false;
	  }
	  if (lastEventNum != -1) {
	    new_nROI = ROI;	    
	    if (writeCamacTDCValues) {getCamacEntry(lastEventNum);}	    
	    if (writeEvent) {newTree->Fill();}
	    writeEvent = true;
            ROI = 0;
            
	  }
	} 

        new_eventNum = eventNum;
	lastEventNum = eventNum;  

	//keep track of number of waveforms and position in buffer
	int numWaveforms = buffer_uint[bufPos+6];
	if( numWaveforms > MEMORY_DEPTH ) //impossible to have more than 512 waveforms in a packet
		return;
	int waveformStartPos = bufPos + 7;
	//loop through all waveform segments
	for(int i = 0 ; i < numWaveforms ; i++)
		waveformStartPos = processWaveform(buffer_uint, waveformStartPos, sizeInUint32);

	return;
}

//function parses data packet and returns trigger bit, lots of hardcoded parameters here that will be removed in final implmentation
int processWaveform(unsigned int *buffer_uint, int bufPos, int sizeInUint32){
	//check for buffer overflow
	if( bufPos+1 >= sizeInUint32 )
		return 2;


        

	//update window ID
	winId = buffer_uint[bufPos];	
	asicCol = ( buffer_uint[bufPos] >> 14 ) & 0x3;
	asicRow = ( buffer_uint[bufPos] >> 12 ) & 0x3;
	asicCh = ( buffer_uint[bufPos] >> 9 ) & 0x7;
	window = ( buffer_uint[bufPos] >> 0 ) & 0x1FF;

        new_scrodId[ROI] = scrodId;
        new_referenceASICwindow[ROI] = referenceASICwindow;
        new_eModule[ROI] = electronicsModule;
	new_asicCol[ROI] = asicCol;
	new_asicRow[ROI] = asicRow;
	new_asicCh[ROI] = asicCh;
	new_ROI[ROI] = ROI;
	if (0 == windowInROI) {new_firstWindow[ROI] = window;}
        new_nWindows[ROI] = windowsPerROI;
        new_nSamples[ROI] = samplesPerROI;
        new_truncatedWaveform[ROI] = kFALSE;


	//get number of samples in waveform
	unsigned int numSamples = buffer_uint[bufPos+1];
	if( numSamples > POINTS_PER_WAVEFORM )
		return 2;
	
	//check for buffer overflow
	if( int( bufPos+1+numSamples/2) >= sizeInUint32 )
		return 2;

	//for each window get samples from 32 bit word
	for(int j = 0 ; j < int(numSamples)/2 ; j++){
                if (0xbe11e2 == buffer_uint[bufPos+2+j]) {
		  std::cerr << "Warning :  Incomplete wavepacket found for event " << eventNum << " ROI " << ROI << " window " << window << " (scrod " << scrodId%256 << ")" <<std::endl;
		  //WavePacket is truncated trigger writing now:
		  windowInROI = windowsPerROI-1;
                  new_truncatedWaveform[ROI] = kTRUE;
		}
		int word0 = buffer_uint[bufPos+2+j] & 0xFFF;
		int word1 = (buffer_uint[bufPos+2+j] >> 16) & 0xFFF;
		if( j*2 < POINTS_PER_WAVEFORM ) {
                        new_samples[ROI][64*windowInROI + j*2] = word0;
                        new_sampleNum[ROI][64*windowInROI + j*2] = 64*windowInROI + j*2;
                        if (subtractPedestals) {
			  new_PSsamples[ROI][64*windowInROI + j*2] = new_samples[ROI][64*windowInROI + j*2] - pedestal->GetMean(electronicsModule, asicRow, asicCol, asicCh, window, j*2); 
			  new_sampleErrors[ROI][64*windowInROI + j*2] = pedestal->GetRMS(electronicsModule, asicRow, asicCol, asicCh, window, j*2);
			}
		}
		if( j*2+1 < POINTS_PER_WAVEFORM ) {
                        new_samples[ROI][64*windowInROI + j*2+1] = word1;
                        new_sampleNum[ROI][64*windowInROI + j*2+1] = 64*windowInROI + j*2+1;
                        if (subtractPedestals) {
			  new_PSsamples[ROI][64*windowInROI + j*2+1] = new_samples[ROI][64*windowInROI + j*2+1] - pedestal->GetMean(electronicsModule, asicRow, asicCol, asicCh, window, j*2+1); 
			  new_sampleErrors[ROI][64*windowInROI + j*2+1] = pedestal->GetRMS(electronicsModule, asicRow, asicCol, asicCh, window, j*2+1);
			}

		}
	}


        ++windowInROI;
	if (windowsPerROI==windowInROI) {
	  windowInROI = 0;
	  ++ROI;  
          if (ROI >= MaxROI) {
	    std::cerr << "Error: This event has at least " << ROI << " ROIs.  Proceeding further would cause a segmentation violation."  << std::endl;
            std::cerr << "       Please increase the value of MaxROI (on line 48 of this script) to avoid this, and re-run." << std::endl;
	    std::exit(EXIT_FAILURE);
	  }
	}



	//update buffer position at the end of the waveform the next waveform start position
	//32 bit - length of waveform header + length of sample words
	return 2+numSamples/2;
}

//get specific bit from char
bool extractBit(char byte, int pos) {
	if( ((byte >> pos) & 0x01) == 1 )
		return true;
	else
		return false;
}

TString getOutputFileName(std::string inputFileName) {

        TString fileName(inputFileName);
        TObjArray* strings = fileName.Tokenize("/");
        TObjString* objstring = (TObjString*) strings->At(strings->GetLast());
        TString string(objstring->GetString());
        TString outputFileName("output_");
        outputFileName += string;
        outputFileName.ReplaceAll(".dat", ".root");
        outputFileName.ReplaceAll(".rawdata", ".root");
	strings->SetOwner(kTRUE);
	delete strings;
	return outputFileName;
}

Int_t getRunNumber(TString fileName) {

  TObjArray* strings = fileName.Tokenize("-");
  TObjString* objstring = (TObjString*) strings->At(2);
  TString string(objstring->GetString());
  TObjArray* strings2 = string.Tokenize("r");
  TObjString* objstring2 = (TObjString*) strings2->At(1);
  TString string2(objstring2->GetString());  
  return string2.Atoi();
}

void getCamacEntry(Int_t IRS3BEventNum) {
  if (!camacEntriesCached) {
    cacheCamacEntries();
    camacEntriesCached = true;
  }

  if (camacMap.find(IRS3BEventNum) != camacMap.end()) {
    camacTree->GetEntry(camacMap[IRS3BEventNum]);
  } else {
    std::cerr << "Warning: Unable to find matching camac event number for IRS3B event number " << IRS3BEventNum << std::endl;
    writeEvent = false;
  }
}

void cacheCamacEntries() {
  Long64_t camacEntries(camacTree->GetEntries());
  for(Long64_t camacEntry(0); camacEntry<camacEntries; ++camacEntry) { 
    camacTree->GetEntry(camacEntry);    
    camacMap[camac_eventNum] = camacEntry;
  }
}


#ifdef COMPILEPARSEIRS3BCOPPERTRIGGERDATA_ROIBASEDOUTPUT_FULLCAMAC
int main(int argc, char *argv[]) {
  if (argc != 4) {
    parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac();
    return EXIT_FAILURE;
  }
  std::string dataFile(argv[1]);
  TString pedestalFile(argv[2]);    
  TString camacFile(argv[3]);
  std::cout << "dataFile = " << dataFile << "\tpedestalFile = " << pedestalFile << "\tcamacFile = " << camacFile << std::endl; 
  parseIRS3BCopperTriggerData_ROIBasedOutput_FullCamac(dataFile, pedestalFile, camacFile);

  return EXIT_SUCCESS;
}

#endif
