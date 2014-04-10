#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h> 
#include <math.h>
#include "irs3BControlClass.h"
#include "irs3BDataClass.h"
#include "TApplication.h"
#include "TCanvas.h"
#include "TAxis.h"
#include "TF1.h"
#include "TMath.h"
#include "TFile.h"
#include "TGraphErrors.h"

using namespace std;

//global TApplication object declared here for simplicity
TApplication *theApp;

//function
int scanVadjNDAC( int board_id, irs3BControlClass *control, irs3BDataClass *data, int rowNum, int colNum, int chNum );
void processGraph_sineFit(TGraph *grIn, double &chiSquare);
Double_t fitf(Double_t *t, Double_t *par);

//global data objects for quick testing
TCanvas *c0;
TH1F *h1D;
TH2F *h2D;
TGraph *g2D;

int main(int argc, char* argv[]){
	if (argc != 4) {
		cout << "irs3BControl_configureSampRateVoltage <rowNum> <colNum> <chNum> " << endl;
		return 1;
	}

	int rowNum = atoi(argv[1]);
        if( rowNum < 0 || rowNum > 3 ){
                std::cout << "Invalid row number requested, exiting" << std::endl;
                return 0;
        }

	int colNum = atoi(argv[2]);
        if( colNum < 0 || colNum > 3 ){
                std::cout << "Invalid col number requested, exiting" << std::endl;
                return 0;
        }

	int chNum = atoi(argv[3]);
        if( chNum < 0 || chNum > 7 ){
                std::cout << "Invalid ch number requested, exiting" << std::endl;
                return 0;
        }

	//define application object
	theApp = new TApplication("App", &argc, argv);

	//define canvas
	c0 = new TCanvas("c0","c0",1300,800);

	//define global data objects
	h1D = new TH1F("h1D","",128,0,128);
	h2D = new TH2F("h2D","",128,0,128,128,0,128);
	g2D = new TGraph();

	//create irs3b data object
	irs3BDataClass *data = new irs3BDataClass();

	//create irs3b interface object
	irs3BControlClass *control = new irs3BControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0x0;
	int regValReadback;

	//initialize certain overall data taking variables
	//set minimum and maximum lookbacks
	control->registerWrite(board_id, 163, 7, regValReadback); //max lookback
	control->registerWrite(board_id, 164, 0, regValReadback); //minimum lookback

	//set first and last allowed windows
	control->registerWrite(board_id, 161, 0, regValReadback);
	control->registerWrite(board_id, 162, 59, regValReadback);

	//run test loop functions
	scanVadjNDAC( board_id, control, data, rowNum, colNum, chNum );

	//close USB interface
        control->closeUSBInterface();

	//delete irs3b interface object
	delete control;
	delete data;

	return 1;
}

//simple program loops over VadjN values, takes data each time
int scanVadjNDAC( int board_id, irs3BControlClass *control, irs3BDataClass *data, int rowNum, int colNum, int chNum ){

	int regValReadback;

	//set forced readout mode for channel of interest
	control->setForcedReadoutRegister(board_id, rowNum, colNum, chNum );

	//reroute calibration signal to intended channel
	control->selectCalibrationDestination(board_id, rowNum, colNum, chNum, 1); //enable calibration signal

	//set # of tests and # of software triggers per test
	int numTests = 10;
	int numEventsPerTest = 100;

	//set initial VadjN DAC value
	int dacReg = 267 + rowNum + 4*colNum; //VadjN register
	int dacValInit = 24800; //VadjN
	int dacValStep = 200;
	int dacVal = dacValInit;
	control->registerWrite(board_id, dacReg, dacValInit, regValReadback);  //set DAC

	//run tests - vary VadjN, take data with new sampling rate and evaluate sine waves
	std::cout << "SCANNING VadjN for ASIC row # " << rowNum << "\tcol # " << colNum << "\tchannel # " << chNum << std::endl;
	for( int test = 0 ; test < numTests ; test++){

		//set DAC specific for each test - pause to allow for any settling
		double dacVal = dacValInit + dacValStep*test;
		control->registerWrite(board_id, dacReg, dacVal, regValReadback);  //set VadjN
		std::cout << "Set VadjN to " << dacVal << std::endl;
		sleep(1);
	
		//optionally take pedestal data for each new sampling rate setting
		if(0){
			//get pedestal waveforms
			control->selectCalibrationDestination(board_id, rowNum, colNum, chNum, 0); //disable calibration signal
			control->clearDataBuffer();
			std::cout << "\tTaking pedestal data " << std::endl;

			for( int nevt = 0 ; nevt < 800 ; nevt++){
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

			//reroute calibration signal to intended channel
			control->selectCalibrationDestination(board_id, rowNum, colNum, chNum, 1); //enable calibration signal
		}

		//loop over numEventsPerTest 
		std::cout << "Taking sine wave data " << std::endl;
		for( int evt = 0 ; evt < numEventsPerTest  ; evt++){
		
			//send software trigger
			control->sendSoftwareTrigger(board_id);

			//get waveform data
			unsigned int wavedatabuf[8192];
			int wavedataSize = 0;
			control->getWaveformData(wavedatabuf,wavedataSize);
			data->grCh->Set(0);
			data->grChRef->Set(0);
			data->loadDataPacket(wavedatabuf, wavedataSize);

			//draw data packet			
			c0->Clear();
			data->grChRef->Draw("ALP");
			c0->Update();
			//char ct;
			//std::cin >> ct;

			//do something with data packet
			//double chiSquare = 0;
			//processGraph_sineFit(data->grChRef, chiSquare);
			//std::cout << chiSquare << std::endl;
		}
	}//end of test loop

	return 1;
}


//plot graph for current value of "window" in the tree, should be called after makeGraph()
void processGraph_sineFit(TGraph *grIn, double &chiSquare){
	//c1->Clear();

	//fit for pulse height
	TF1 *func = new TF1("func",fitf, 0+5, grIn->GetN() -5,4);
	//par[0] = baseline, par[1] = A, par[2] = freq, par[3] = phase
	func->SetParameters(1500, 500, 0.07, 0 ); //test setup
	//func->SetParameters(-250, 45, 0.2, 0 ); //RCO scan
	//func->SetParLimits(0,-5000,5000);
	///func->SetParLimits(1,0,10000);
	//func->SetParLimits(2,0,100);
	grIn->Fit("func","RMQ");

	//get fit results
	double inputFreq = 33.;
	double baseline = func->GetParameter(0);
	double amplitude = func->GetParameter(1);
	double freq = func->GetParameter(2);
	chiSquare =  func->GetChisquare();
	double sampFreq = -1;
	if( freq > 0 )
		sampFreq = 1./freq*2*TMath::Pi()*inputFreq/1000.;

	double rChiSq = 1000;
	if( func->GetNDF() > 0)
		rChiSq = func->GetChisquare() / func->GetNDF();

	c0->Clear();
	grIn->Draw("ALP");
	c0->Update();
	char ct;
	std::cin >> ct;

	//plotGraph(grIn); insertPause();	
	delete func;	
}

//funtion to fit rising pulse edge
Double_t fitf(Double_t *t, Double_t *par){
	//par[0] = baseline, par[1] = A, par[2] = freq, par[3] = phase
	Double_t fitval = par[0] + par[1]*TMath::Sin(t[0]*par[2] + par[3]);
	return fitval;
} 
