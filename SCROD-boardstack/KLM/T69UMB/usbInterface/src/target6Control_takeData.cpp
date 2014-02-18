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
	control->registerWriteReadback(board_id, 10, 0, regValReadback); //Start sampling
	control->registerWriteReadback(board_id, 20, 0, regValReadback); //Digitization OFF
	control->registerWriteReadback(board_id, 30, 0, regValReadback); //Serial readout OFF
	control->registerWriteReadback(board_id, 52, 1, regValReadback); //veto hardware triggers
	control->registerWriteReadback(board_id, 53, 8, regValReadback); //set trigger delay
	control->registerWriteReadback(board_id, 54, 4, regValReadback); //set digitization window offset

	char ct = 0;
	while(ct != 'Q'){

		//make sure readout is off
		control->registerWriteReadback(board_id, 50, 0, regValReadback); //readout control start is 0
		control->registerWriteReadback(board_id, 52, 1, regValReadback); //veto hardware triggers
		control->registerWrite(board_id, 55, 1, regValReadback); //make sure readout is reset
		control->registerWrite(board_id, 55, 0, regValReadback); //make sure readout is reset

		//do software trigger
		control->registerWrite(board_id, 50, 1, regValReadback); //readout control start is 0
		//do harware trigger, presumably trigger will occur shortly after hardware veto is disable
		//control->registerWrite(board_id, 52, 0, regValReadback); //enable hardware triggers

		//std::cout << "Send trigger, then enter character" << std::endl;
		//std::cin >> ct;

		//delay, just in case readout is still in progress
		usleep(50);
	
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
			//std::cout << "\t" << std::hex << eventdatabuf[j] << std::dec;
			//std::cout << "\t" << bitNum;
			//std::cout << "\t" << sampNum;
			//std::cout << std::endl;
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
		//	std::cout << samples[i] << std::endl;
			gPlot->SetPoint(i,i,samples[i]);
  		}

		c0->Clear();
		gPlot->GetYaxis()->SetRangeUser(0,4100);
  		gPlot->Draw("AP");
  		c0->Update();

		//check main_cnt variable
		control->registerRead(board_id, 256, regValReadback); //Start sampling
		std::cout << std::dec << "MAIN_CNT " << regValReadback << std::endl;
		control->registerRead(board_id, 260, regValReadback); //Start sampling
		std::cout << std::dec << "DIG MAIN_CNT " << regValReadback << std::endl;

		//reset readout
		control->registerWriteReadback(board_id, 50, 0, regValReadback); //readout control start is 0
		control->registerWriteReadback(board_id, 52, 1, regValReadback); //veto hardware triggers
		control->registerWrite(board_id, 55, 1, regValReadback); //make sure readout is reset
		control->registerWrite(board_id, 55, 0, regValReadback); //make sure readout is reset

		std::cout << "Please enter character, Q to quit" << std::endl;
		std::cin >> ct;

		//save data to file
		//ofstream myfile;
  		//myfile.open ("output_target6Control_test.dat", ios::out | ios::binary );
		//myfile.write(reinterpret_cast<char*>(&eventdatabuf), eventdataSize*sizeof(unsigned int));
  		///myfile.close();

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
