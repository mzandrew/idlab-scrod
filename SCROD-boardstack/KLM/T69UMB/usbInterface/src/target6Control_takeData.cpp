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

	char ct = 0;
	int digOffset = 6;
	while(ct != 'Q'){

		//make sure readout is off digOffset
		control->registerWriteReadback(board_id, 50, 0, regValReadback); //readout control start is 0
		control->registerWriteReadback(board_id, 52, 0, regValReadback); //veto hardware triggers
		control->registerWriteReadback(board_id, 54, digOffset, regValReadback); //set digitization window offset
		control->registerWrite(board_id, 55, 1, regValReadback); //make sure readout is reset
		control->registerWrite(board_id, 55, 0, regValReadback); //make sure readout is reset

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

		//delay, just in case readout is still in progress
		usleep(200);
	
		//parse the data packet, look for event packets
		unsigned int eventdatabuf[65536];
		int eventdataSize = 0;
		control->getEventData(eventdatabuf, eventdataSize);

		//print data buffer
		std::cout << "RESPONSE PACKET " << std::endl;
		for(int j=0;j<eventdataSize; j++)
			std::cout << "PACKET" << "\t" << std::hex << eventdatabuf[j] << std::endl;
		std::cout << "END RESPONSE PACKET " << std::endl;
		std::cout << std::endl;

		//Get samples from data packet
		unsigned int samples[512][32];
  		for(int i = 0 ; i < 512 ; i++)
  		for(int j = 0 ; j < 32 ; j++)
			samples[i][j] = 0;
		unsigned int addrNum = 1001;
		for(int j=0;j<eventdataSize; j++){
			if( eventdatabuf[j] == 0x00be11e2)
				std::cout << "Packet Header " << std::hex << eventdatabuf[j] << std::endl;
			if( eventdatabuf[j] == 0x065766e74 ){
				addrNum = ((0x000001FF & eventdatabuf[j+1]) >> 0 );
				std::cout << "Address number " << addrNum << std::endl;
			}
			//std::cout << "\t" << std::hex << eventdatabuf[j] << std::dec;
			//	std::cout << std::endl;
			if( (0xF0000000 & eventdatabuf[j]) != 0xD0000000 )
				continue;
			unsigned int bitNum = ((0x0F000000 & eventdatabuf[j]) >> 24 );
			unsigned int sampNum = ((0x001F0000 & eventdatabuf[j]) >> 16 );
			unsigned int winNum = ((0x00E00000 & eventdatabuf[j]) >> 21 );
			std::cout << "\t" << std::hex << eventdatabuf[j] << std::dec;
			std::cout << "\t\t" << addrNum;			
			std::cout << "\t" << bitNum;
			std::cout << "\t" << sampNum;
			std::cout << "\t" << winNum;
			std::cout << std::endl;
			if( addrNum < 0 || addrNum > 511 || bitNum < 0 || bitNum > 11 || sampNum < 0 || sampNum > 31 || winNum < 1 || winNum > 4)
				continue;
			//samples[sampNum] = (samples[sampNum] | (((eventdatabuf[j] >> 15) & 0x1) <<bitNum) );
			//samples[addrNum][sampNum] = ((samples[addrNum][sampNum] << 1) & 0xFFF) | ((( eventdatabuf[j] & 0x00008000) >> 15) & 0x1);
			samples[winNum-1][sampNum] = ((samples[winNum-1][sampNum] << 1) & 0xFFF) | ((( eventdatabuf[j] & 0x00008000) >> 15) & 0x1);
		}

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

		//reset readout
		control->registerWriteReadback(board_id, 50, 0, regValReadback); //readout control start is 0
		control->registerWriteReadback(board_id, 52, 0, regValReadback); //veto hardware triggers
		control->registerWrite(board_id, 55, 1, regValReadback); //make sure readout is reset
		control->registerWrite(board_id, 55, 0, regValReadback); //make sure readout is reset

		std::cout << "Please enter character, Q to quit" << std::endl;
		std::cin >> ct;

		

		//digOffset = ct - '0';
		//if( digOffset < 0 || digOffset > 50)
		//	digOffset = 0;
		//digOffset = digOffset + 10;

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
