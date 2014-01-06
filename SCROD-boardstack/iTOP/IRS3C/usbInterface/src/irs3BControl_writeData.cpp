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
#include "TF1.h"
#include "TGraphErrors.h"
#include "TMath.h"

using namespace std;

//global TApplication object declared here for simplicity
TApplication *theApp;
int measurePedestal( int board_id, irs3BControlClass *control, irs3BDataClass *data );

//global variables for quick testing
//setting variables for readouts on row 0 col 2 ch 2
//set forced readout mode: registers 171 - 178, row 0 col 2 = register 175, lower 8 bits, set channel 2 for readout
int ForcedReadoutReg = 175; //Forced readout for row 0 col 2 ch 2
int ForcedReadoutVal = 0x0; //Forced readout for row 0 col 2 ch 2
int TriggerReg = 79; //Trigger DAC for row 0 col 2 ch 2
int TriggerRegVal = 1896; //Trigger DAC for row 0 col 2 ch 2
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
	unsigned int board_id = 0x00A20021;

	//set forced readout mode: registers 171 - 178
	//row 0 col 2 = register 175, lower 8 bits, set channel 2 for readout
	int regValReadback;
	control->registerWrite(board_id, ForcedReadoutReg, ForcedReadoutVal, regValReadback);

	//set trigger DAC register:
	//row 0 col 2 = register 79
	control->registerWrite(board_id, TriggerReg, TriggerRegVal, regValReadback);

	//set minimum and maximum lookbacks
	control->registerWrite(board_id, 163, 59, regValReadback); //max lookback
	control->registerWrite(board_id, 164, 4, regValReadback); //minimum lookback

	//set first and last allowed windows
	control->registerWrite(board_id, 161, 0, regValReadback);
	control->registerWrite(board_id, 162, 63, regValReadback);

	char ct;
	//measure pedestal values
	measurePedestal( board_id, control, data );

	//reroute calibration signal to intended channel
	control->selectCalibrationDestination(board_id, rowNum, colNum, chNum, 1);

	TH2F *hTimeDiffVsSmp = new TH2F("hTimeDiffVsSmp","",128,0,128,200,900,1000);
	TH1F *hTimeDiff = new TH1F("hTimeDiff","",1000,940,960);
	TH2F *hWidthVsSmp = new TH2F("hWidthVsSmp","",128,0,128,200,0,100);
	TH1F *hWidthSameWin = new TH1F("hWidthSameWin","",500,0,100);
	TH1F *hWidthDiffWin = new TH1F("hWidthDiffWin","",500,0,100);
	hWidthDiffWin->SetLineColor(kRed);
	TGraphErrors *gWindowTimeOffsetVsTime = new TGraphErrors();

	//get start time
	time_t startTime = time(0);

	//take waveform data, applying pedestal correction
	int nEvents = 0;
	//for( int nevt = 0 ; nevt < 10 ; nevt++){
	while( ct != 'Q' ){
		//send software trigger
		control->sendSoftwareTrigger(board_id);

		//get waveform data
		unsigned int wavedatabuf[65536];
		int wavedataSize = 0;
		control->getWaveformData(wavedatabuf,wavedataSize);

		if( wavedataSize == 0 )
			continue;
		
		data->grCh->Set(0);
		data->grChRef->Set(0);
		data->loadDataPacket(wavedatabuf, wavedataSize);

		//find pulse times
		data->findPulseTimesFixedThreshold(100., 0, 4095);

		//measure pulse widths
		if( data->pulseTimes.size() > 0 && data->pulseTimes.size() == data->pulseFallTimes.size() ){
			for( int i = 0 ; i < data->pulseTimes.size() ; i++ ){
				double riseTime = data->pulseTimes.at(i);
				double fallTime = data->pulseFallTimes.at(i);
				double pulseWidth = fallTime - riseTime;

				//cut sample numbers with weird width measurements
				if(( int(riseTime) % 128 ) > 126 )
					continue;
					
				hWidthVsSmp->Fill( ( int(riseTime) % 128 ), pulseWidth );
				if( int(riseTime) % 128 < int(fallTime) % 128 )
					hWidthSameWin->Fill(pulseWidth);
				else
					hWidthDiffWin->Fill(pulseWidth);
			}
		}

		//measure time difference between adjacent pulses (if any)
		if(  data->pulseTimes.size() == 2 ){
			double timeDiff = data->pulseTimes.at(1) -  data->pulseTimes.at(0);
			if( timeDiff < 0 )
				timeDiff = 64*64 + timeDiff;
			if( (int(data->pulseTimes.at(0)) % 128) < 40 && (int(data->pulseTimes.at(1)) % 128) < 80 ){
				hTimeDiffVsSmp->Fill(( int(data->pulseTimes.at(0)) % 128 ) ,timeDiff);
				hTimeDiff->Fill(timeDiff);
			}
		}


		//measure window time offset
		if( hWidthDiffWin->GetEntries() > 400 ){
			double meanWidthSameWin = hWidthSameWin->GetMean(1);
			double meanWidthDiffWin = hWidthDiffWin->GetMean(1);
			double meanWidthSameWinErr = hWidthSameWin->GetRMS(1);
			double meanWidthDiffWinErr = hWidthDiffWin->GetRMS(1);

			TF1 *f1Same = new TF1("f1Same","gaus",meanWidthSameWin-3*meanWidthSameWinErr, meanWidthSameWin+3*meanWidthSameWinErr);
        		hWidthSameWin->Fit("f1Same","QR");
			meanWidthSameWin = f1Same->GetParameter(1);
			meanWidthSameWinErr = f1Same->GetParError(1);

			TF1 *f1Diff = new TF1("f1Diff","gaus",meanWidthDiffWin-3*meanWidthDiffWinErr, meanWidthDiffWin+3*meanWidthDiffWinErr);
        		hWidthDiffWin->Fit("f1Diff","QR");
			meanWidthDiffWin = f1Diff->GetParameter(1);
			meanWidthDiffWinErr = f1Diff->GetParError(1);

			double windowTimeOffset = meanWidthDiffWin - meanWidthSameWin;
			double windowTimeOffsetErr = TMath::Sqrt(meanWidthDiffWinErr*meanWidthDiffWinErr+meanWidthSameWinErr*meanWidthSameWinErr);
			double seconds_since_start = difftime( time(0), startTime);

			gWindowTimeOffsetVsTime->SetPoint(gWindowTimeOffsetVsTime->GetN(), seconds_since_start, windowTimeOffset);
			gWindowTimeOffsetVsTime->SetPointError(gWindowTimeOffsetVsTime->GetN()-1,0.5, windowTimeOffsetErr);

			hWidthSameWin->Reset();
			hWidthDiffWin->Reset();

			//compare current window time offset with target, change VadjN if necessary
			//read current VadjN
			int VadjN = 0;
			control->registerRead(board_id, 275, VadjN); //max lookback
			std::cout << "Orignal VadjN " << VadjN;
			//assume target is 2.75, include 0.05 sample deadband
			if( windowTimeOffset > 2.80 ){
				control->registerWrite(board_id, 275, VadjN+1, regValReadback);
				std::cout << "\tNew VadjN " <<  VadjN+1;
			}
			if( windowTimeOffset < 2.70 ){
				control->registerWrite(board_id, 275, VadjN-1, regValReadback);
				std::cout << "\tNew VadjN " <<  VadjN-1;
			}
			std::cout << std::endl;

			delete f1Same;
			delete f1Diff;
		}

		c0->Clear();
		c0->Divide(2,3);
		c0->cd(1);
		data->grCh->Draw("ALP");
		c0->cd(2);
		hWidthVsSmp->Draw("COLZ");
		c0->cd(3);
		hWidthSameWin->Draw();
		hWidthDiffWin->Draw("same");
		c0->cd(4);
		hTimeDiff->Draw();
		c0->cd(5);
		hTimeDiffVsSmp->Draw("COLZ");
		c0->cd(6);
		if( gWindowTimeOffsetVsTime->GetN() > 0 )
			gWindowTimeOffsetVsTime->Draw("ALP");
		c0->Update();

		//std::cin >> ct;
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

int measurePedestal( int board_id, irs3BControlClass *control, irs3BDataClass *data ){
	//get pedestal waveforms
	std::cout << "Measuring pedestal values " << std::endl;
	control->clearDataBuffer();

	//turn off calibration input
	control->selectCalibrationDestination(board_id, rowNum, colNum, chNum, 0); //disable signal routed to row 2, col 2 ch 0

	//force readout for pedestal values
	int regValReadback;
	control->registerWrite(board_id, ForcedReadoutReg, 0x0004, regValReadback);

	//reset pedestal values
	data->resetPedestalValues();
	for( int nevt = 0 ; nevt < 400 ; nevt++){
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

	//unforce readout for pedestal values
	control->registerWrite(board_id, ForcedReadoutReg, 0x0000, regValReadback);

	return 1;
}
