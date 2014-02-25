#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h> 
#include "target6ControlClass.h"

#include <fstream>

#include <TGraph.h>
#include <TH1.h>
#include "TApplication.h"
#include "TCanvas.h"
#include "TAxis.h"
#include "TF1.h"
#include "TMath.h"
#include "TFile.h"
#include "TGraphErrors.h"

//global TApplication object declared here for simplicity
TApplication *theApp;

using namespace std;

int main(int argc, char* argv[]){
	if (argc != 1){
    		std::cout << "wrong number of arguments: usage ./target6Control_test" << std::endl;
    		return 0;
  	}

	//define application object
	theApp = new TApplication("App", &argc, argv);

	int regValReadback;

	//create target6 interface object
	target6ControlClass *control = new target6ControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0;

	//make simple sample histogram
	TCanvas *c0 = new TCanvas("c0","c0",1300,800);
	TH1F *hSampDist = new TH1F("hSampDist","",110,3000,4100);

	//Initialize
	control->registerWriteReadback(board_id, 11, 1, regValReadback); //Start sampling
	control->registerWriteReadback(board_id, 20, 0, regValReadback); //Digitization OFF
	control->registerWriteReadback(board_id, 30, 0, regValReadback); //Serial readout OFF
	control->registerWriteReadback(board_id, 50, 0, regValReadback); //readout control start is 0
	control->registerWrite(board_id, 44, 0, regValReadback); //Stop event builder
	control->registerWrite(board_id, 45, 1, regValReadback); //Reset Event builder
	control->registerWrite(board_id, 45, 0, regValReadback); //Reset Event builder
	control->registerWriteReadback(board_id, 52, 0, regValReadback); //veto hardware triggers
	control->registerWriteReadback(board_id, 53, 8, regValReadback); //set trigger delay
	control->registerWriteReadback(board_id, 54, 0, regValReadback); //set digitization window offset
	control->registerWriteReadback(board_id, 55, 1, regValReadback); //reset readout
	control->registerWriteReadback(board_id, 55, 0, regValReadback); //reset readout
	control->registerWriteReadback(board_id, 56, 0, regValReadback); //select readout control module signals
	control->registerWriteReadback(board_id, 57, 2, regValReadback); //set # of windows to read

	//define output file		
	ofstream dataFile;
  	dataFile.open ("output_target6Control_takeData.dat", ios::out | ios::binary );

	char ct = 0;
	int digOffset = 20;
	control->registerWriteReadback(board_id, 54, digOffset, regValReadback); //set digitization window offset
	while(ct != 'Q'){
	//for( int numEv = 0 ; numEv < 10 ; numEv++ ){
		//std::cout << "Event # " << numEv << std::endl;

		//make sure readout is off digOffset
		control->registerWrite(board_id, 50, 0, regValReadback); //readout control start is 0
		control->registerWrite(board_id, 52, 0, regValReadback); //veto hardware triggers
		control->registerWrite(board_id, 55, 1, regValReadback); //make sure readout is reset
		control->registerWrite(board_id, 55, 0, regValReadback); //make sure readout is reset

		//do software trigger
		if(1){
			control->registerWrite(board_id, 50, 1, regValReadback); //readout control start is 0
		}
		//do harware trigger, presumably trigger will occur shortly after hardware veto is disable
		if(0){
			control->registerWrite(board_id, 52, 1, regValReadback); //enable hardware triggers
			std::cout << "Send trigger, then enter character" << std::endl;
			std::cin >> ct;
		}

		unsigned int eventdatabuf[65536];
		int eventdataSize = 20;
		int numIter = 0;

		unsigned int samples[512][32];
  		for(int i = 0 ; i < 512 ; i++)
  		for(int j = 0 ; j < 32 ; j++)
			samples[i][j] = 0;

		while(eventdataSize > 10 && numIter < 50){
		//while( numIter < 4){
			//delay, just in case readout is still in progress
			usleep(10);

			//toggle continue bit
			control->registerWrite(board_id, 58, 1, regValReadback); //allow readout to continue
			control->registerWrite(board_id, 58, 0, regValReadback); //allow readout to continue
	
			//parse the data packet, look for event packets
			control->readPacketFromUSBFifo( eventdatabuf, 65536, eventdataSize );
		
			//increment iterate count
			numIter++;

			//save data to file
			//myfile.write(reinterpret_cast<char*>(&eventdatabuf), eventdataSize*sizeof(unsigned int));
			if( eventdataSize > 10 )
				control->writeEventToFile(eventdatabuf, eventdataSize, dataFile );

			
			//print out packet
			unsigned int bitNum = 0;
			unsigned int addrNum = 0;
			unsigned int asicNum = 0;
			unsigned int sampNum = 0;
			for(int j=0;j<eventdataSize; j++){
				//std::cout << "RAW DATA\t" << std::hex << eventdatabuf[j] << std::dec << std::endl;
				//detect packet header
				if( eventdatabuf[j] == 0x00be11e2){
					std::cout << "\tPacket Header " << std::hex << eventdatabuf[j] << std::endl;
					continue;
				}
				//detect sample packet header
				if( (0xFFF00000 & eventdatabuf[j]) == 0xABC00000 ){
					std::cout << "\tSample Packet Header " << std::hex << eventdatabuf[j] << std::endl;
					addrNum = ( (eventdatabuf[j] >> 10) & 0x000001FF );
					asicNum = ( (eventdatabuf[j] >> 6) & 0x0000000F );
					sampNum = (eventdatabuf[j] & 0x0000001F);
					continue;
				}
				if( (0xFFF00000 & eventdatabuf[j]) != 0xDEF00000 )
					continue;
				bitNum = ( (eventdatabuf[j] >> 16) & 0x0000000F );
				std::cout << "\t" << std::hex << eventdatabuf[j] << std::dec;
				std::cout << "\t\t" << addrNum;			
				std::cout << "\t" << asicNum;
				std::cout << "\t" << sampNum;
				std::cout << "\t" << bitNum;
				std::cout << std::endl;
				if( addrNum < 0 || addrNum > 511 || bitNum < 0 || bitNum > 11 || sampNum < 0 || sampNum > 31 || asicNum < 0 || asicNum > 10)
					continue;
				//samples[sampNum] = (samples[sampNum] | (((eventdatabuf[j] >> 15) & 0x1) <<bitNum) );
				samples[addrNum][sampNum] = ((samples[addrNum][sampNum] << 1) & 0xFFF) | ((( eventdatabuf[j] & 0x00008000) >> 15) & 0x1);
				//samples[winNum-1][sampNum] = ((samples[winNum-1][sampNum] << 1) & 0xFFF) | ((( eventdatabuf[j] & 0x00008000) >> 15) & 0x1);
			}
			

			//std::cout << "Please enter character, Q to quit data readout loop" << std::endl;
			//std::cin >> ct;
			//if( ct == 'Q' )
			//	break;
		}

		
		//plot samples
  		TGraph *gPlot = new TGraph();
  		gPlot->SetMarkerColor(2);
  		gPlot->SetMarkerStyle(21);
  		gPlot->SetMarkerSize(1.5);
		int numPoint = 0;
		for(int i = 0 ; i < 512 ; i++)
		for(int j = 0 ; j < 32 ; j++){
			if( samples[i][j] > 10){
				//std::cout << std::dec << samples[i][j] << std::endl;
				gPlot->SetPoint(numPoint,32*i + j,samples[i][j]);
				numPoint++;
			}
  		}

		c0->Clear();
		gPlot->GetYaxis()->SetRangeUser(0,4100);
  		gPlot->Draw("AP");
  		c0->Update();

		//check main_cnt variable
		control->registerRead(board_id, 261, regValReadback);
		std::cout << std::dec << "LATCH MAIN_CNT " << regValReadback << std::endl;
		control->registerRead(board_id, 260, regValReadback);
		std::cout << std::dec << "DIG MAIN_CNT " << regValReadback << std::endl;
		std::cout << std::dec << "DIG OFFSET " << digOffset << std::endl;

		std::cout << "Please enter character, Q to quit" << std::endl;
		std::cin >> ct;
		
	}

	//reset readout
	control->registerWriteReadback(board_id, 50, 0, regValReadback); //readout control start is 0
	control->registerWriteReadback(board_id, 52, 0, regValReadback); //veto hardware triggers
	control->registerWrite(board_id, 55, 1, regValReadback); //make sure readout is reset
	control->registerWrite(board_id, 55, 0, regValReadback); //make sure readout is reset

	//close output file
  	dataFile.close();

	//close USB interface
        control->closeUSBInterface();

	//delete target6 interface object
	delete control;

	return 1;

	c0->Clear();
	hSampDist->Draw();
	c0->Update();

	TFile *f = new TFile( "output_target6Control_test.root" , "RECREATE");
	hSampDist->Write();
  	f->Close();
	delete f;

	return 1;
}	
