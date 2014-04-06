#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h> 
#include "irs3BControlClass.h"
#include "irs3BDataClass.h"
#include "TApplication.h"
#include "TCanvas.h"
#include "TAxis.h"

using namespace std;

//global TApplication object declared here for simplicity
TApplication *theApp;

//global variables for quick testing
//setting variables for readouts on row 0 col 2 ch 2
//set forced readout mode: registers 171 - 178, row 0 col 2 = register 175, lower 8 bits, set channel 2 for readout
int ForcedReadoutReg = 175; //Forced readout for row 0 col 2 ch 2
int ForcedReadoutVal = 0x0004; //Forced readout for row 0 col 2 ch 2
int rowNum = 0;
int colNum = 2;
int chNum = 2;

int main(int argc, char* argv[]){
	if (argc != 1) {
		cout << "irs3BControl_takeData " << endl;
		return 1;
	}

	//define application object
	theApp = new TApplication("App", &argc, argv);

	//define canvas
	TCanvas *c0 = new TCanvas("c0", "c0",1300,800);

	//create irs3b data object
	irs3BDataClass *data = new irs3BDataClass();

	//create irs3b interface object
	irs3BControlClass *control = new irs3BControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0x0;

	//set forced readout mode: registers 171 - 178
	//row 0 col 2 = register 175, lower 8 bits, set channel 2 for readout
	int regValReadback;
	control->registerWrite(board_id, ForcedReadoutReg, ForcedReadoutVal, regValReadback);

	//set minimum and maximum lookbacks
	control->registerWrite(board_id, 163, 59, regValReadback); //max lookback
	control->registerWrite(board_id, 164, 0, regValReadback); //minimum lookback

	//set first and last allowed windows
	control->registerWrite(board_id, 161, 0, regValReadback);
	control->registerWrite(board_id, 162, 59, regValReadback);

	char ct;
	if(1){
	//get pedestal waveforms	
	control->clearDataBuffer();
	control->selectCalibrationDestination(board_id, rowNum, colNum, chNum, 0);
	for( int nevt = 0 ; nevt < 200 ; nevt++){
		//send software trigger
		control->sendSoftwareTrigger(board_id);

		//get waveform data
		unsigned int wavedatabuf[8192];
		int wavedataSize = 0;
		control->getWaveformData(wavedatabuf,wavedataSize);
		data->grCh->Set(0);
		data->grChRef->Set(0);
		data->loadDataPacket(wavedatabuf, wavedataSize);
		data->fillPedestal();
	}
	//make pedestal
	data->getPedestalValues();

	/*
	TH1D *hProj = data->hPed->ProjectionY("hProj", 0,64*64,"");

	c0->Clear();
	c0->Divide(2);
	c0->cd(1);
	data->hPed->GetYaxis()->SetRangeUser(1000,2000);
	data->hPed->Draw("COLZ");
	c0->cd(2);
	hProj->GetXaxis()->SetRangeUser(1000,2000);
	hProj->Draw();
	c0->Update();
	std::cin >> ct;	
	
	delete hProj;
	*/

	}

	//reroute calibration signal to intended channel
	control->selectCalibrationDestination(board_id, rowNum, colNum, chNum, 1);

	//take waveform data, applying pedestal correction
	int nEvents = 0;
	//for( int nevt = 0 ; nevt < 10 ; nevt++){
	while( ct != 'Q' ){
		//send software trigger
		control->sendSoftwareTrigger(board_id);

		//get waveform data
		unsigned int wavedatabuf[8192];
		int wavedataSize = 0;
		control->getWaveformData(wavedatabuf,wavedataSize);
		data->grCh->Set(0);
		data->grChRef->Set(0);
		data->loadDataPacket(wavedatabuf, wavedataSize);

		//find pulse times
		//data->findPulseTimesFixedThreshold(100., 0, 767);
		//data->findPulseTimesFixedThreshold(100., 0, 3700);

		//if( data->pulseTimes.size() != 2 )
		//	continue;
		//std::cout << "Pulse 0 " << data->pulseTimes.at(0);
		//std::cout << "\tPulse 1 " << data->pulseTimes.at(1);
		//std::cout << "\tDifference " << data->pulseTimes.at(1) -  data->pulseTimes.at(0);
		//std::cout << std::endl;

		c0->Clear();
		//c0->Divide(2);
		//c0->cd(1);
		//data->grChRef->GetXaxis()->SetRangeUser(0,767);
		//data->grChRef->GetYaxis()->SetRangeUser(800,1600);
		//data->grChRef->Draw("ALP");
		//data->grCh->GetYaxis()->SetRangeUser(-100,300);
		//data->grCh->Draw("ALP");
		//c0->cd(2);
		data->grChRef->Draw("ALP");
		c0->Update();

		std::cin >> ct;
		if( nEvents % 100 == 0 )
			std::cout << nEvents << std::endl;
		nEvents++;
	}

	//close USB interface
        control->closeUSBInterface();

	//delete irs3b interface object
	delete control;
	delete data;

	return 1;
}
