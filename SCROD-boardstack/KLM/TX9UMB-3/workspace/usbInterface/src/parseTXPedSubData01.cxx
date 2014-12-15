//compile independently with: g++ -o parseTarget6Data parseTarget6Data.cxx `root-config --cflags --glibs`
#include <iostream>
#include <fstream>
#include <sstream>
#include <cstdlib>

#include "TROOT.h"
#include "TApplication.h"
#include <TFile.h>
#include "TTree.h"
#include "TSystem.h"	
#include "TString.h"
#include "TObjArray.h"

#define bitn(x,n) ((x>>n)&1)
#define set_bitn(x,n,v) x=(x&(~(1<<n)) | (v&1)<<n)

using namespace std;

void initializeRootTree();
void processBuffer(unsigned int *buffer_uint, int sizeInUint32);
void parseDataPacket(unsigned int *buffer_uint, int bufPos, int sizeInUint32);
void resetWaveformArray();
void saveWaveformArrayToTree();
TString getOutputFileName(std::string inputFileName);

//array to store motherboard event waveform data, very crude
const int numDC = 10;
const int numCHAN = 16;//only channel 16 is needed- which is connected to the signal gen
int ActiveChs[numCHAN]={0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15};
const int numADDR = 512;
const int numSAMP = 32*2;

class MBevent
{
public:
	unsigned int no;//event number
	signed int samples[numSAMP];
	bool isValid;
	unsigned int dc,ch,digwin,wrwin;//daughter card, channel,...
	unsigned int t,c;//time and charge
	void Copy(MBevent e) {
		for(int i=0;i<numSAMP;i++) samples[i]=e.samples[i];
		no=e.no;isValid=e.isValid;dc=e.dc;ch=e.ch;digwin=e.digwin;wrwin=e.wrwin;
		t=e.t;c=e.c;
	}
};


//bool waveformValid[numDC][numCHAN][numADDR]; //DC, CHANNEL, ADDRESS
//signed int waveformArray[numDC][numCHAN][numADDR][numSAMP]; //DC, CHANNEL, ADDRESS, SAMPLE

int currentEventNumber;

//Define output tree
#define POINTS_PER_WAVEFORM    32*4
#define MEMORY_DEPTH           512
#define NASICS                 10
#define NCHS                   numCHAN //only 1 channel is being parsed
const Int_t MaxROI(400);
TTree *tree;
Int_t eventNum;
Int_t nROI;
UInt_t scrodId[MaxROI];
Int_t asicNum[MaxROI];
Int_t asicCh[MaxROI];
Int_t windowNum[MaxROI];
Int_t WRwinNum[MaxROI];
Int_t samples[MaxROI][POINTS_PER_WAVEFORM];
bool DecodeTPGflag;

MBevent evts[MaxROI];



//global TApplication object declared here for simplicity
TApplication *theApp;

//void parseTarget6Data(std::string inputFileName){
int main(int argc, char* argv[]){
	//check # arguments
	if (argc != 3 && argc != 2 ){
    		std::cout << "wrong number of arguments: usage ./parseTarget6Data <filename> [options: -TPG]" << std::endl;
    		return 0;
  	}

	DecodeTPGflag=false;

	if (argc==3)
	{
		if (0==strcmp(argv[2],"-TPG"))
		{
			DecodeTPGflag=true;

		}
		else
		{
	   		std::cout << "wrong argument option number of arguments: usage ./parseTarget6Data <filename> [options: -TPG]" << std::endl;
	    		return 0;
		}

	}

	//define input file and parsing
	std::string inputFileName = argv[1];
	std::cout << " inputFileName " << inputFileName << std::endl;
	ifstream infile;
	infile.open(argv[1], std::ifstream::in | std::ifstream::binary);  

        if (infile.fail()) {
		std::cout << "Error opening input file, exiting" << std::endl;
		return 0;
	}

	//define application object
	theApp = new TApplication("App", &argc, argv);

    	// get length of file:
    	infile.seekg (0, infile.end);
    	int size_in_bytes = infile.tellg();
    	infile.seekg (0, infile.beg);

	//define buffer
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

	//define output file name
	TString outputFileName(getOutputFileName(inputFileName));
	FILE*of=fopen("wave1.txt","wt");

	std::cout << " outputFileName " << outputFileName << std::endl;
	TFile g(outputFileName , "RECREATE");

	//initialize tree to store trigger bit data
	initializeRootTree();

	//intialize waveform array
	currentEventNumber = -1;
	
	//process file buffer
	processBuffer(buffer_uint,size_in_bytes/4);

	//write tree to file
	g.cd();
	tree->Write();


        //Write out the settings used in creating the data tree:
	Int_t numberOfAsics(NASICS);
	Int_t numberOfAsicChannels(NCHS);
	Int_t numberOfWindows(MEMORY_DEPTH);
	Int_t numberOfSamples(POINTS_PER_WAVEFORM);
        TTree* MetaDataTree = new TTree("MetaData", "metadata");  
        MetaDataTree->Branch("nAsics", &numberOfAsics, "nAsics/I");
        MetaDataTree->Branch("nAsicChannels", &numberOfAsicChannels, "nAsicChannels/I");
        MetaDataTree->Branch("nWindows", &numberOfWindows, "nWindows/I");
        MetaDataTree->Branch("nSamples", &numberOfSamples, "nSamples/I");
        MetaDataTree->Fill();
        MetaDataTree->Write();  





	g.Close();
	return 0;
}

//initialize tree to store trigger bit data
void initializeRootTree(){
	tree = new TTree("T","TARGET6_Data");
	tree->Branch("eventNum", &eventNum, "eventNum/I");
	tree->Branch("nROI", &nROI, "nROI/I");
	tree->Branch("scrodId", &scrodId, "scrodId[nROI]/I");
	tree->Branch("asicNum", &asicNum, "asicNum[nROI]/I");
	tree->Branch("asicCh", &asicCh, "asicCh[nROI]/I");
	tree->Branch("windowNum", &windowNum, "windowNum[nROI]/I");
        //set array size to store in root file:
        TString samplesBranchLeafList("samples[nROI][");
	samplesBranchLeafList += POINTS_PER_WAVEFORM;
	samplesBranchLeafList += "]/I";
	tree->Branch("samples", &samples, samplesBranchLeafList);
	return;
}

unsigned int DecodeTPG(unsigned int i)
{
	unsigned int o=0,t=0,m=0;

//#define bitn(x,n) ((x>>n)&1)
//#define set_bitn(x,n,v) x=(x&(!(1<<n)) | v<<n)

	set_bitn(t,0 ,1 & ~  bitn(i,0));
	set_bitn(t,1 ,1 & ~ (bitn(i,2)  ^ bitn(i,1)));
	set_bitn(t,2 ,1 & ~ (bitn(i,3)  ^ bitn(i,2)));
	set_bitn(t,3 ,1 & ~ (bitn(i,4)  ^ bitn(i,3)));
	set_bitn(t,4 ,1 & ~ (bitn(i,5)  ^ bitn(i,4)));
	set_bitn(t,5 ,1 & ~ (bitn(i,6)  ^ bitn(i,5)));
	set_bitn(t,6 ,1 & ~ (bitn(i,7)  ^ bitn(i,6)));
	set_bitn(t,7 ,1 & ~ (bitn(i,8)  ^ bitn(i,7)));
	set_bitn(t,8 ,1 & ~ (bitn(i,9)  ^ bitn(i,8)));
	set_bitn(t,9 ,1 & ~ (bitn(i,10) ^ bitn(i,9)));
	set_bitn(t,10,1 & ~ (bitn(i,11) ^ bitn(i,10)));
	set_bitn(t,11,1 & ~  bitn(i,11));

	m=0x0fff & ~ t;

	set_bitn(o,11,1 & ~  bitn(m,11));
	set_bitn(o,10, (bitn(o,11) ^ (1 & ~bitn(m,10))));
	set_bitn(o,9 , (bitn(o,10) ^ (1 & ~bitn(m,9))));
	set_bitn(o,8 , (bitn(o,9)  ^ (1 & ~bitn(m,8))));
	set_bitn(o,7 , (bitn(o,8)  ^ (1 & ~bitn(m,7))));
	set_bitn(o,6 , (bitn(o,7)  ^ (1 & ~bitn(m,6))));
	set_bitn(o,5 , (bitn(o,6)  ^ (1 & ~bitn(m,5))));
	set_bitn(o,4 , (bitn(o,5)  ^ (1 & ~bitn(m,4))));
	set_bitn(o,3 , (bitn(o,4)  ^ (1 & ~bitn(m,3))));
	set_bitn(o,2 , (bitn(o,3)  ^ (1 & ~bitn(m,2))));
	set_bitn(o,1 , (bitn(o,2)  ^ (1 & ~bitn(m,1))));
	set_bitn(o,0 ,1 & ~  bitn(m,0));

	return o;
}

//reset the array storing waveform data
void saveWaveformArrayToTree(){
	//loop over all ASICs/channels
	eventNum = currentEventNumber;
	Int_t ROI = 0;
    /*	for(int d = 0 ; d < numDC ; d++)
	for(int c = 0 ; c < numCHAN ; c++)
  	for(int a = 0 ; a < numADDR ; a++){
		if( waveformValid[d][c][a] == 0 )
			continue;
		scrodId[ROI] = 0;
		asicNum[ROI] = d;
		asicCh[ROI] = ActiveChs[c];
		windowNum[ROI] = a;
		if (ActiveChs[c]==15) printf("%d",a);
 		for(int s = 0 ; s < numSAMP ; s++)
  		{
  			if (DecodeTPGflag==true)
  			{
  				samples[ROI][s] = DecodeTPG(waveformArray[d][c][a][s]);
  			}
  			else
  			{
  				samples[ROI][s] = waveformArray[d][c][a][s];
  			}
  			if (ActiveChs[c]==15)
  			{
//  				printf("ROI=%d, s=%d, wave=%d, sample=%d \n",ROI,s,waveformArray[d][c][a][s],samples[ROI][s]);
  				//only output ch:15
  				printf(", %d",samples[ROI][s]);
  			}
  		}
 		if (ActiveChs[c]==15) printf("\n");

		ROI++;
		
	}//end of numADDR loop*/
	nROI = ROI;
	tree->Fill();
	return;
}	

//reset the array storing waveform data

//function loops through file buffers, extracts trigger bits from data packet and organizes by event
void processBuffer(unsigned int *buffer_uint, int sizeInUint32){

    	// loop through entire file
	for(int pos = 0 ; pos < sizeInUint32 ; pos++ )
		parseDataPacket(buffer_uint,pos,sizeInUint32);

	saveWaveformArrayToTree();
				//reset waveform array
				//resetWaveformArray();

    	delete[] buffer_uint;
	return;
}	

//function parses data packet and returns trigger bit, lots of hardcoded parameters here that will be removed in final implmentation
void parseDataPacket(unsigned int *buffer_uint, int bufPos, int sizeInUint32){
	//std::cout << std::hex << buffer_uint[bufPos] << std::dec;
	//std::cout << std::endl;

	unsigned int addrNum = 0;
	unsigned int wraddrNum = 0;
	unsigned int asicNum = 0;
	unsigned int sampNum = 0;
	unsigned int dataWord = 0;
	unsigned int winNum=0;
	unsigned int packetEventNum = 0;

	//check for packet header
	if( (0xFFFFFFFF & buffer_uint[bufPos]) != 0x00be11e2 )
		return;
	//check for ?
	if( (0xFFFFFFFF & buffer_uint[bufPos+1]) != 0x00000013 )
		return;
	//check for waveform type 
	if( (0xFFFFFFFF & buffer_uint[bufPos+2]) != 0x65766e74 )
		return;
	//check for SCROD-ID
	if( (0xFFFFFFFF & buffer_uint[bufPos+3]) != 0x00a3002c )
		return;
	//check for data/version identifier
	if( (0xFFFFFFFF & buffer_uint[bufPos+4]) != 0x20121128 )
		return;

	//check to see if this is an event header packet produced by SCROD
	if( (0xFFFFFFFF & buffer_uint[bufPos+7]) == 0x65766e74 ){
		packetEventNum = ( buffer_uint[bufPos+5] & 0xFFFFFFFF );

		//check if this is the first event packet
		int old_currentEventNumber=0;
		if( currentEventNumber == -1 ){
			old_currentEventNumber=-1;
			currentEventNumber = packetEventNum;
			return;
		}

		//check if new event - if new event then save old event and reset waveform data storage
		if( packetEventNum != currentEventNumber && old_currentEventNumber!=-1){
			//save event
			saveWaveformArrayToTree();
			//reset waveform array
			currentEventNumber = packetEventNum;
			//resetWaveformArray();
		}
		return;
	}

	//check to see if window packet - should be the case at this point
	//here starts a window of 4 windows for 16 channels
	MBevent mbe;

	if ((buffer_uint[bufPos+5]& 0xFF000000)!=0xFE000000) return;//some info on start of package and where rd/wr pointers where located
	//at this point should have window data - loop over window data until encounter end of window packet
	int count = 0,chanNum=0, offset=6;

	if( (0xFF000000 & buffer_uint[bufPos+5]) == 0xFE000000 ){
						std::cout << "\nHeader Val:" << std::hex << buffer_uint[bufPos+5] << std::dec << std::endl;
						addrNum = ( (buffer_uint[bufPos+5] ) & 0x000001FF );
						wraddrNum = ( (buffer_uint[bufPos+5] >> 9) & 0x000001FF );
						asicNum = ( (buffer_uint[bufPos+5] >> 20) & 0x0000000F )-1;
						std::cout << "\nDig Address, Wr addr, Asic: ";
						std::cout << "\t" << addrNum;
						std::cout << "\t" << wraddrNum;
						std::cout << "\t" << asicNum;
						//std::cout << "\t" << sampNum;
						std::cout << std::endl;
	}

	while( (buffer_uint[bufPos+offset+count]& 0xFF000000)==0xBD000000){
		//std::cout << std::hex << buffer_uint[bufPos+5+count] << std::dec;
		
		//Check for sample packet header

			chanNum = (buffer_uint[bufPos+offset+count]>>19) & 0x0000000F;
			winNum =  (buffer_uint[bufPos+offset+count]>>17) & 0x00000003 ;
			sampNum = (buffer_uint[bufPos+offset+count]>>12) & 0x0000007F;
			int BDval=(buffer_uint[bufPos+offset+count]>>24) & 0x000000FF;
	/*		std::cout << "\t" << count;
			std::cout << ", " << asicNum;
			std::cout << ", " << chanNum;
			std::cout << ", " << addrNum;
			std::cout << ", " << sampNum;
			//std::cout << std::endl;
*/
			mbe.digwin=addrNum;
			mbe.wrwin=wraddrNum;
			mbe.dc=asicNum;

		//check if errors
		if( addrNum >= numADDR  || asicNum > numDC || sampNum >= numSAMP || BDval!=0xBD){
			std::cout << "INVALID SAMPLE INFO, SKIPPING ";
			std::cout << "\t" << count;
			std::cout << "\t" << addrNum;
			std::cout << "\t" << asicNum;
			std::cout << "\t" << sampNum;
			std::cout << "\t" << BDval;
			std::cout << std::endl;
			count++;
			continue;
		}
		
		//check for sample packet data
//if (chanNum==15)//only save ch 15 which is hooked to the scope
{
int sa_val=(buffer_uint[bufPos+offset+count]) & 0x00000FFF;
///int v2=0;for (int c=0;c<12;c++) v2=(v2<<1) | ((sa_val>>c) & 1);//reverse the bits if needed- no more

			//at this point have sample bit word, save to waveform array
				mbe.samples[sampNum]=sa_val;
				//waveformValid[asicNum][chanNum][addrNum] = true;
				//waveformArray[asicNum][chanNum][addrNum][sampNum] =sa_val;//(buffer_uint[bufPos+offset+count]) & 0x00000FFF;
}

		//increment position
		count++;
	}

	mbe.isValid=true;
	mbe.no=currentEventNumber;



	return;
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
