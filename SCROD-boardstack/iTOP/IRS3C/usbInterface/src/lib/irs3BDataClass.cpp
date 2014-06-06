#include <iostream>
#include <fstream>
#include <sstream>
#include <cstdlib>
#include <vector>
#include <TFile.h>
#include "TTree.h"
#include "TSystem.h"
#include "TROOT.h"
#include "TApplication.h"
#include <math.h>
#include <TH1F.h> 
#include <TH2S.h> 
#include <TH2F.h> 
#include <TF1.h>
#include <TMath.h> 
#include <TGraph.h>
#include "TCanvas.h"
#include "irs3BDataClass.h"
using namespace std;

irs3BDataClass::irs3BDataClass(){
	firstWindowNum = -1;
	grCh = new TGraph();
	grChRef = new TGraph();
	hPed = new TH2S("hPed","",64*64,0,64*64,4096,0,4096);
	cData = new TCanvas("cData", "cData",1300,800);
	for(int i = 0 ; i < 64*64 ; i++)
		ped[i] = 0;
}

irs3BDataClass::~irs3BDataClass(){
	delete grCh;
	delete grChRef;
	delete hPed;
	delete cData;
}

//parse the data packet
int irs3BDataClass::loadDataPacket(unsigned int wavedatabuf[], int wavedataSize){

	//initialize variables
	firstWindowNum = -1;

	//detect packet header word
	for(int j=0;j<wavedataSize; j++){
		if( wavedatabuf[j] != 0x00BE11E2 )
			continue;
		//check that there are at least 2 more lines in buffer
		if( j >= wavedataSize - 2 )
			continue;
		int packetStartPos = j;
		unsigned int packetSize = wavedatabuf[packetStartPos+1]+2;
		//check that the packet is entirely contained within buffer
		if( j >= wavedataSize - packetSize )
			continue;
		//check that packet is waveform type
		unsigned int packetType = wavedatabuf[packetStartPos+2];
		if( packetType != 0x77617665 )
			continue;
		
		unsigned int scrodId = wavedatabuf[packetStartPos+3];
        	unsigned int referenceASICwindow = wavedatabuf[packetStartPos+4];
		unsigned int eventNum = wavedatabuf[packetStartPos+5];
       	 	unsigned int numWaveforms = wavedatabuf[packetStartPos+6];
		if( numWaveforms > MEMORY_DEPTH ) //impossible to have more than 512 waveforms in a packet
			continue;
		int waveformStartPos = packetStartPos+7;
		//loop through all waveform segments
		for(int i = 0 ; i < numWaveforms ; i++)
			waveformStartPos = processWaveform(wavedatabuf, waveformStartPos, wavedataSize);

		//increment buffer position past waveform packet
		//j = j + waveformStartPos - 4;
	}

	return 1;
}

//function parses data packet and returns trigger bit, lots of hardcoded parameters here that will be removed in final implmentation
int irs3BDataClass::processWaveform(unsigned int *buffer_uint, int bufPos, int sizeInUint32){
	//check for buffer overflow
	if( bufPos+1 >= sizeInUint32 )
		return 2;

	if( !grCh ) return 2;

	//update window ID
	unsigned int winId = buffer_uint[bufPos];	
	unsigned int asicCol = ( buffer_uint[bufPos] >> 14 ) & 0x3;
	unsigned int asicRow = ( buffer_uint[bufPos] >> 12 ) & 0x3;
	unsigned int asicCh = ( buffer_uint[bufPos] >> 9 ) & 0x7;
	unsigned int window = ( buffer_uint[bufPos] >> 0 ) & 0x1FF;
	if( firstWindowNum < 0 )
		firstWindowNum = window;

	//clear tree sample variable
	unsigned int samples[POINTS_PER_WAVEFORM];
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
	
	for(int j = 0 ; j < numSamples ; j++){
		//std::cout << std::hex << "\t\t" <<  samples[j] << std::endl;
		double pedVal = 0;
		if( window*POINTS_PER_WAVEFORM + j < 64*64 )
			pedVal = ped[window*POINTS_PER_WAVEFORM + j];
		grCh->SetPoint( grCh->GetN() , window*POINTS_PER_WAVEFORM + j , samples[j] - pedVal );
		grChRef->SetPoint( grChRef->GetN() , (firstWindowNum % 2)*64 + grChRef->GetN() , samples[j] - pedVal );
	}
	//update buffer position at the end of the waveform the next waveform start position
	//32 bit - length of waveform header + length of sample words
	return 2+numSamples/2;
}


int irs3BDataClass::fillPedestal(){
	for( int i = 0 ; i < grCh->GetN() ; i++){
		double tempX, tempY;
		grCh->GetPoint(i,tempX,tempY);
		hPed->Fill(tempX,tempY);
	}

	return 1;
}

int irs3BDataClass::getPedestalValues(){

	//get slices from 2D histogram
  	int numBins = hPed->GetNbinsX();
  	TH1D *hBins[numBins];
  	char name[100];
  	for( int b = 0 ; b < numBins ; b++ ){
		memset(name,0,sizeof(char)*100 );
		sprintf(name,"bin_%.2i",b);
		hBins[b] = hPed->ProjectionY(name,b+1,b+1);
	}

	//get pedestal values
 	for( int b = 0 ; b < numBins ; b++ ){
		ped[b] = 0;
		if( hBins[b]->GetEntries() < 50 )
			continue;
		double posMax = hBins[b]->GetBinCenter( hBins[b]->GetMaximumBin() );
		hBins[b]->GetXaxis()->SetRangeUser(posMax-10,posMax+10);
		double peakMean = hBins[b]->GetMean(1);
		ped[b] = peakMean;
  	}

	return 1;
}

int irs3BDataClass::resetPedestalValues(){
	for(int i = 0 ; i < 64*64 ; i++)
		ped[i] = 0;
	hPed->Reset("");	

	return 1;	
}

int irs3BDataClass::findPulseTimesFixedThreshold(double threshold, int minSamp, int maxSamp){
	//look for fixed threshold
	pulseTimes.clear();
	pulseFallTimes.clear();
	for( int i = 0 ; i < grChRef->GetN() ; i++){
		double posX, posY;
		grChRef->GetPoint(i,posX,posY);
		double posXNext, posYNext;
		grChRef->GetPoint(i+1,posXNext,posYNext);

		//look for pulse within range
		if( posX < minSamp || posX >= maxSamp )
			continue;

		//only accept rising edge
		//if( posYNext < posY )
		//	continue;

		//check if pulse exceeds threshold
		if( (posY-threshold)*(posYNext-threshold) > 0. )
			continue;

		//interpolate between samples to find threshold time
		double dy = posYNext-posY;
      		double dx = posXNext-posX;
		if( dx <= 0 )
			continue;
      		double slope = dy/dx;
		if( slope > 0 )
			pulseTimes.push_back(posX + (threshold-posY)/slope);
		if( slope < 0 )
			pulseFallTimes.push_back(posX + (threshold-posY)/slope);
	}

	return 1;
}
