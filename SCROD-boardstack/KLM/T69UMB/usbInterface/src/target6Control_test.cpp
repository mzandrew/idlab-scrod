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


using namespace std;

int main(int argc, char* argv[]){
	if (argc != 1){
    		std::cout << "wrong number of arguments: usage ./target6Control_test" << std::endl;
    		return 0;
  	}

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
	control->registerWriteReadback(board_id, 10, 0, regValReadback); //Start sampling
	control->registerWriteReadback(board_id, 20, 0, regValReadback); //Digitization OFF
	control->registerWriteReadback(board_id, 30, 0, regValReadback); //Serial readout OFF
	// //SAMPLESEL_ANY OFF

	//STOP SAMPLING
	control->registerWriteReadback(board_id, 10, 1, regValReadback); //Stop sampling

	//Set RD ROWSEL and COLSEL based on current value of MAIN_CNT
	int mainCnt = regValReadback;
	int readAddress = mainCnt - 1;
	if( readAddress < 0)
		readAddress = 512 - readAddress;
	control->registerWriteReadback(board_id, 21, readAddress, regValReadback);

	//Start Digitization
	control->registerWriteReadback(board_id, 20, 1, regValReadback);

	//start serial readout
	control->registerWriteReadback(board_id, 30, 1, regValReadback); //serial readout ON
	control->registerWriteReadback(board_id, 30, 0, regValReadback); //serial readout OFF

	//start event builder
	control->registerWrite(board_id, 44, 1, regValReadback); //Start event builder
	
	//parse the data packet, look for event packets
	unsigned int eventdatabuf[65536];
	int eventdataSize = 0;
	control->getEventData(eventdatabuf, eventdataSize);

	//print data buffer
	std::cout << "RESPONSE PACKET " << std::endl;
	for(int j=0;j<eventdataSize; j++)
		std::cout << "\t" << std::hex << eventdatabuf[j] << std::endl;
	std::cout << "END RESPONSE PACKET " << std::endl;
	std::cout << std::endl;

	//save data to file
	ofstream myfile;
  	myfile.open ("output_target6Control_test.dat", ios::out | ios::binary );
	myfile.write(reinterpret_cast<char*>(&eventdatabuf), eventdataSize*sizeof(unsigned int));
  	myfile.close();

	//control->printPacketFromUSBFifo();//optionally just print the data packet

	//stop and reset event builder
	control->registerWrite(board_id, 44, 0, regValReadback); //Stop event builder
	control->registerWrite(board_id, 45, 1, regValReadback); //Reset Event builder
	control->registerWrite(board_id, 45, 0, regValReadback); //Reset Event builder

	//RESET
	control->registerWriteReadback(board_id, 10, 0, regValReadback); //Start sampling
	control->registerWriteReadback(board_id, 20, 0, regValReadback); //Digitization OFF
	control->registerWriteReadback(board_id, 30, 0, regValReadback); //Serial readout OFF

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
