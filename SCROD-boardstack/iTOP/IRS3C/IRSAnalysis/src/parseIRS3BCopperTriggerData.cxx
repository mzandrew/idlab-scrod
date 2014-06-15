#include <iostream>
#include <fstream>
#include <sstream>
#include <cstdlib>
#include "TROOT.h"
#include "TFile.h"
#include "TTree.h"
#include "TSystem.h"
#include "TApplication.h"
#include "TString.h"
#include "TObjArray.h"
#include "convertScrodIdToElectronicsModuleNumber.h"
#include "packet_interface.h"

using namespace std;

//define global constants
#define MAX_SEGMENTS_PER_EVENT 512
#define POINTS_PER_WAVEFORM    64
#define MEMORY_DEPTH           64
#define NCOLS                  4
#define NROWS                  4
#define NCHS                   8
#define NWORDS_EVENT_HEADER    11
#define NWORDS_WAVE_PACKET     42
#define NELECTRONICSMODULES    4

void initializeRootTree();
void processBuffer(unsigned int *buffer_uint, int sizeInUint32);
void parseDataPacket(unsigned int *buffer_uint, int bufPos, int sizeInUint32);
int processWaveform(unsigned int *buffer_uint, int bufPos, int sizeInUint32);
TString getOutputFileName(std::string inputFileName);

//Set tree variables as global for quick implementation
TTree *tree;
UInt_t scrodId;
UInt_t winId;
int electronicsModule;
int eventNum;
int asicCol;
int asicRow;
int asicCh;
int window;
int samples[POINTS_PER_WAVEFORM];

void parseIRS3BCopperTriggerData() {
        std::cout << "Usage:  parseIRS3BCopperTriggerData(inputFileName)" << std::endl;
}

void parseIRS3BCopperTriggerData(std::string inputFileName){
	//define input file and parsing
	ifstream infile;
	
	std::cout << " inputFileName " << inputFileName << std::endl;
	infile.open(inputFileName.c_str(), std::ifstream::in | std::ifstream::binary);  

    if (infile.fail()) {
		std::cout << "Error opening input file, exiting" << std::endl;
		exit(-1);
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
	initializeRootTree();

	//process file buffer
	processBuffer(buffer_uint,size_in_bytes/4);

	//define output file name, write out tree data
	TString outputFileName(getOutputFileName(inputFileName));

	std::cout << " outputFileName " << outputFileName << std::endl;
	TFile g(outputFileName , "RECREATE");
	tree->Write();

    //Write out the settings used in creating the data tree:
    Int_t numberOfElectronicsModules(NELECTRONICSMODULES);
	Int_t numberOfAsicRows(NROWS);
	Int_t numberOfAsicColumns(NCOLS);
	Int_t numberOfAsicChannels(NCHS);
	Int_t numberOfWindows(MEMORY_DEPTH);
	Int_t numberOfSamples(POINTS_PER_WAVEFORM);

    TTree* MetaDataTree = new TTree("MetaData", "metadata");  
    MetaDataTree->Branch("nEModules", &numberOfElectronicsModules, "nEModules/I");   
    MetaDataTree->Branch("nAsicRows", &numberOfAsicRows, "nAsicRows/I");
    MetaDataTree->Branch("nAsicColumns", &numberOfAsicColumns, "nAsicColumns/I");
    MetaDataTree->Branch("nAsicChannels", &numberOfAsicChannels, "nAsicChannels/I");
    MetaDataTree->Branch("nWindows", &numberOfWindows, "nWindows/I");
    MetaDataTree->Branch("nSamples", &numberOfSamples, "nSamples/I");
    MetaDataTree->Fill();
    MetaDataTree->Write();  

	g.Close();
	return;
}

//initialize tree to store trigger bit data
void initializeRootTree(){
	tree = new TTree("T","IRS3B Waveform");
	tree->Branch("scrodId", &scrodId, "scrodId/i");
	tree->Branch("winId", &winId, "winId/i");
    tree->Branch("eModule", &electronicsModule, "eModule/I");
	tree->Branch("eventNum", &eventNum, "eventNum/I");
	tree->Branch("asicCol", &asicCol, "asicCol/I");
	tree->Branch("asicRow", &asicRow, "asicRow/I");
	tree->Branch("asicCh", &asicCh, "asicCh/I");
	tree->Branch("window", &window, "window/I");
    //set array size to store in root file:
    TString samplesBranchLeafList("samples[");
	samplesBranchLeafList += POINTS_PER_WAVEFORM;
	samplesBranchLeafList += "]/I";
	tree->Branch("samples", &samples, samplesBranchLeafList);
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
	eventNum = buffer_uint[bufPos+5];
    //With only one module set this to zero for limited backwards compatibility:
    if (1==NELECTRONICSMODULES) {electronicsModule = 0;}
	else {electronicsModule = convertScrodIdToElectronicsModuleNumber(scrodId);	
	}
	//std::cout << electronicsModule << std::endl;

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

	//clear tree sample variable
	memset(samples,-1,sizeof(samples[0])*POINTS_PER_WAVEFORM );

	//get number of samples in waveform
	unsigned int numSamples = buffer_uint[bufPos+1];
	if( numSamples > POINTS_PER_WAVEFORM )
		return 2;
	
	//check for buffer overflow
	if( int( bufPos+1+numSamples/2) >= sizeInUint32 )
		return 2;

	//for each window get samples from 32 bit word
	for(int j = 0 ; j < int(numSamples)/2 ; j++){
		int word0 = buffer_uint[bufPos+2+j] & 0xFFF;
		int word1 = (buffer_uint[bufPos+2+j] >> 16) & 0xFFF;
		if( j*2 < POINTS_PER_WAVEFORM ) {
                	samples[j*2] = word0;
		}
		if( j*2+1 < POINTS_PER_WAVEFORM ) {
		        samples[j*2+1] = word1;
		}
	}

	//fill root tree for each window, note tree variables set in parseDataPacket funciton
	tree->Fill();

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
    TString defaultFileName("output_parseIRS3BCopperTriggerData_datFile.root");    
    TString fileName(inputFileName);
    TObjArray* strings = fileName.Tokenize("/");
    TObjString* objstring = (TObjString*) strings->At(strings->GetLast());
	if( objstring->Sizeof() == 0 ){
    	std::cout << "Error getting file name, token string size is " << objstring->Sizeof() << std::endl;
		return defaultFileName;
	}
    
	TString string(objstring->GetString());
    if( string.Sizeof() == 0 ){
         std::cout << "Error getting file name, string size is " << string.Sizeof() << std::endl;
         return defaultFileName;
	}
	
	TString outputFileName("output_parseIRS3BCopperTriggerData_");
    outputFileName += string;
    outputFileName.ReplaceAll(".dat", ".root");
    outputFileName.ReplaceAll(".rawdata", ".root");
	strings->SetOwner(kTRUE);
	delete strings;
	return outputFileName;
}

int main(int argc, char *argv[]) {
  if (argc != 2) {
    std::cout << "Wrong # of arguments" << std::endl;
    return 0;
  }
  std::string dataFile(argv[1]);
  std::cout << "dataFile = " << dataFile << std::endl; 
  parseIRS3BCopperTriggerData(dataFile);

  return 1;
}
