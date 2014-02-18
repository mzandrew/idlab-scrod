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

	char ct = 0;
	while(ct != 'Q'){

	//Initialize
	control->registerWriteReadback(board_id, 10, 0, regValReadback); //Start sampling
	control->registerWriteReadback(board_id, 20, 0, regValReadback); //Digitization OFF
	control->registerWriteReadback(board_id, 30, 0, regValReadback); //Serial readout OFF
	control->registerWriteReadback(board_id, 52, 1, regValReadback); //veto hardware triggers
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
	
	//control->printPacketFromUSBFifo();//optionally just print the data packet
	
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

	//Get samples from data packet
	unsigned int samples[32];
  	for(int i = 0 ; i < 32 ; i++)
		samples[i] = 0;
	for(int j=0;j<eventdataSize; j++){
		if( (0xF0000000 & eventdatabuf[j]) != 0xD0000000 )
			continue;
		unsigned int bitNum = ((0x0F000000 & eventdatabuf[j]) >> 24 );
		unsigned int sampNum = ((0x003F0000 & eventdatabuf[j]) >> 16 );
		std::cout << "\t" << std::hex << eventdatabuf[j] << std::dec;
		std::cout << "\t" << bitNum;
		std::cout << "\t" << sampNum;
		std::cout << std::endl;
		if( bitNum < 0 || bitNum > 11 || sampNum < 0 || sampNum > 31 )
			continue;
		//samples[sampNum] = (samples[sampNum] | (((eventdatabuf[j] >> 15) & 0x1) <<bitNum) );
		samples[sampNum] = (samples[sampNum] << 1) | ((( eventdatabuf[j] & 0x00008000) >> 15) & 0x1);
	}

  	TGraph *gPlot = new TGraph();
  	gPlot->SetMarkerColor(2);
  	gPlot->SetMarkerStyle(21);
  	gPlot->SetMarkerSize(1.5);
	for(int i = 0 ; i < 32 ; i++){
		std::cout << samples[i] << std::endl;
		gPlot->SetPoint(i,i,samples[i]);
  	}
 	std::cout << "HERE" << std::endl;

	c0->Clear();
	gPlot->GetYaxis()->SetRangeUser(0,4100);
  	gPlot->Draw("AP");
  	c0->Update();

	std::cout << "Please enter character, Q to quit" << std::endl;
	std::cin >> ct;

	//save data to file
	//ofstream myfile;
  	//myfile.open ("output_target6Control_test.dat", ios::out | ios::binary );
	//myfile.write(reinterpret_cast<char*>(&eventdatabuf), eventdataSize*sizeof(unsigned int));
  	///myfile.close();

	//stop and reset event builder
	control->registerWrite(board_id, 44, 0, regValReadback); //Stop event builder
	control->registerWrite(board_id, 45, 1, regValReadback); //Reset Event builder
	control->registerWrite(board_id, 45, 0, regValReadback); //Reset Event builder

	//RESET
	control->registerWriteReadback(board_id, 10, 0, regValReadback); //Start sampling
	control->registerWriteReadback(board_id, 20, 0, regValReadback); //Digitization OFF
	control->registerWriteReadback(board_id, 30, 0, regValReadback); //Serial readout OFF

	}

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
