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

	//clear data buffer
	control->clearDataBuffer();

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
	control->registerWriteReadback(board_id, 51, 0x3FF, regValReadback); //enable ASICs for readout
	control->registerWriteReadback(board_id, 52, 0, regValReadback); //veto hardware triggers
	control->registerWriteReadback(board_id, 53, 8, regValReadback); //set trigger delay
	control->registerWriteReadback(board_id, 54, 0, regValReadback); //set digitization window offset
	control->registerWriteReadback(board_id, 55, 1, regValReadback); //reset readout
	control->registerWriteReadback(board_id, 55, 0, regValReadback); //reset readout
	control->registerWriteReadback(board_id, 56, 0, regValReadback); //select readout control module signals
	control->registerWriteReadback(board_id, 57, 2, regValReadback); //set # of windows to read
	control->registerWrite(board_id, 58, 0, regValReadback); //reset packet request

	//define output file		
	ofstream dataFile;
  	dataFile.open ("output_target6Control_takeData.dat", ios::out | ios::binary );

	unsigned int eventdatabuf[65536];
	int eventdataSize = 0;
	int numIter = 0;

	char ct = 0;
	//while(ct != 'Q'){
	for( int numEv = 0 ; numEv < 100 ; numEv++ ){
		std::cout << "Event # " << numEv << std::endl;

		//clear data buffer
		//control->clearDataBuffer();
		//usleep(500);

		//make sure readout is off digOffset
		control->registerWrite(board_id, 50, 0, regValReadback); //readout control start is 0
		control->registerWriteReadback(board_id, 52, 0, regValReadback); //veto hardware triggers
		control->registerWrite(board_id, 55, 1, regValReadback); //make sure readout is reset
		control->registerWrite(board_id, 55, 0, regValReadback); //make sure readout is reset
		control->registerWrite(board_id, 58, 0, regValReadback); 

		//do software trigger
		if(1){
			control->registerWrite(board_id, 50, 1, regValReadback); //readout control start is 0
		}
		//do harware trigger, presumably trigger will occur shortly after hardware veto is disable
		if(0){
			control->registerWrite(board_id, 52, 1, regValReadback); //enable hardware triggers
			//std::cout << "Send trigger, then enter character" << std::endl;
			//std::cin >> ct;
		}

		//give the trigger some time
		//usleep(50);

		int first = 1;
		//while(1){
		while(eventdataSize > 100 || first ==  1){
		//while( numIter < 4){
			//delay, just in case readout is still in progress
			
			//toggle continue bit
			control->registerWrite(board_id, 58, 0, regValReadback); //allow readout to continue
			control->registerWrite(board_id, 58, 1, regValReadback); //allow readout to continue

			//usleep(100);
	
			//parse the data packet, look for event packets
			control->readPacketFromUSBFifo( eventdatabuf, 65536, eventdataSize );
		
			//increment iterate count
			numIter++;

			//save data to file
			//myfile.write(reinterpret_cast<char*>(&eventdatabuf), eventdataSize*sizeof(unsigned int));
			if( eventdataSize > 100 ){
				first = 0;
				control->writeEventToFile(eventdatabuf, eventdataSize, dataFile );
			}
		}
	}

	//reset readout
	control->registerWriteReadback(board_id, 50, 0, regValReadback); //readout control start is 0
	control->registerWriteReadback(board_id, 52, 0, regValReadback); //veto hardware triggers
	control->registerWrite(board_id, 55, 1, regValReadback); //make sure readout is reset
	control->registerWrite(board_id, 55, 0, regValReadback); //make sure readout is reset
	control->registerWrite(board_id, 58, 0, regValReadback); 

	//close output file
  	dataFile.close();

	//close USB interface
        control->closeUSBInterface();

	//delete target6 interface object
	delete control;

	return 1;
}	
