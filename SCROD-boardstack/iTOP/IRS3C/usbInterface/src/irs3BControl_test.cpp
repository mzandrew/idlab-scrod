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

//function to run test loops
int measurePedestal( int board_id, irs3BControlClass *control, irs3BDataClass *data );
int measureTimeRes( int board_id, irs3BControlClass *control, irs3BDataClass *data, double &timeMean, double &timeMeanErr, double &timeSig, double &timeSigErr, double 		&timeOffset, double &timeOffsetErr, double &numPulsesMean);

int scanDAC( int board_id, irs3BControlClass *control, irs3BDataClass *data );
int scanVadjNWinTimeOffsets( int board_id, irs3BControlClass *control, irs3BDataClass *data );
int plotAdjacentTimes( int board_id, irs3BControlClass *control, irs3BDataClass *data);
int measurePulseWidths( int board_id, irs3BControlClass *control, irs3BDataClass *data);
int measurePulseWidthsVsTime( int board_id, irs3BControlClass *control, irs3BDataClass *data);
int measureRcoVsVadjN( int board_id, irs3BControlClass *control, irs3BDataClass *data);
int measureRcoVsTime( int board_id, irs3BControlClass *control, irs3BDataClass *data);
int measureSampRateVsTime( int board_id, irs3BControlClass *control, irs3BDataClass *data );

//global data objects
TCanvas *c0;
TH1F *h1D;
TH2F *h2D;
TGraphErrors *g2D;

//global variables for quick testing
//setting variables for readouts on row 0 col 2 ch 2
//set forced readout mode: registers 171 - 178, row 0 col 2 = register 175, lower 8 bits, set channel 2 for readout
int VadjNReg = 275; //VadjN for row 0 col 2
int VadjNFBReg = 584; //VadjN feedback for row 0 col 2
int RCOCounterReg = 568; //RCO counter for row 0 col 2
int ForcedReadoutReg = 175; //Forced readout for row 0 col 2 ch 2
int ForcedReadoutVal = 0x0004; //Forced readout for row 0 col 2 ch 2
int rowNum = 0;
int colNum = 2;
int chNum = 2;

int main(int argc, char* argv[]){
	if (argc != 1) {
		cout << "irs3BControl_test " << endl;
		return 1;
	}

	//define application object
	theApp = new TApplication("App", &argc, argv);

	//define canvas
	c0 = new TCanvas("c0","c0",1300,800);

	//define global data objects
	h1D = new TH1F("h1D","",128,0,128);
	h2D = new TH2F("h2D","",128,0,128,128,0,128);
	g2D = new TGraphErrors();

	//create irs3b data object
	irs3BDataClass *data = new irs3BDataClass();

	//create irs3b interface object
	irs3BControlClass *control = new irs3BControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0x00A20021;

	//run test loop functions
	//scanVadjNWinTimeOffsets(board_id, control, data);
	//scanDAC( board_id, control, data );
	//plotAdjacentTimes(board_id, control, data);
	measurePulseWidths(board_id, control, data);
	//measurePulseWidthsVsTime(board_id, control, data);
	//measureRcoVsVadjN(board_id, control, data);
	//measureRcoVsTime(board_id, control, data);
	//measureSampRateVsTime(board_id, control, data);

	//close USB interface
        control->closeUSBInterface();

	//delete irs3b interface object
	delete control;
	delete data;

	return 1;
}

int measurePulseWidths( int board_id, irs3BControlClass *control, irs3BDataClass *data ){

	//setup objects needed for test
	TH2F *hWidthVsSmp = new TH2F("hWidthVsSmp","",128,0,128,100,0,50);
	TH1F *hWidthSameWin = new TH1F("hWidthSameWin","",200,0,50);
	TH1F *hWidthDiffWin = new TH1F("hWidthDiffWin","",200,0,50);
	TGraphErrors *g2D_pulseTimeOffsetVsDAC = new TGraphErrors();
	TGraphErrors *g2D_pulseWidthVsDAC = new TGraphErrors();
	TGraphErrors *g2D_RCOVsVadjN = new TGraphErrors();
	int upperBound = 768;

	//setup DACs needed for tests
	int regValReadback;
	control->registerWrite(board_id, ForcedReadoutReg, ForcedReadoutVal, regValReadback); 	//force readout for row 0 col 2 ch 2
	control->registerWrite(board_id, 142, 0x0000, regValReadback);  //turn off feedbacks, VadjN Scan only
	int dacReg = 275; //VadjN for row 0 col 2
	int dacValInit = 24800; //VadjN
	int dacValStep = 50;
	control->registerWrite(board_id, dacReg, dacValInit, regValReadback);  //set DAC

	//get start time
	time_t startTime = time(0);

	//run tests
	int numTests = 4;
	for( int test = -1*numTests / 2 ; test <= numTests / 2 ; test++){

		//set DAC specific for each test
		double dacVal = dacValInit + dacValStep*test;
		control->registerWrite(board_id, dacReg, dacVal, regValReadback);  //set VadjN

		sleep(1);

		//measure pedestal values
		measurePedestal( board_id, control, data );

		//reroute calibration signal to intended channel
		control->selectCalibrationDestination(board_id, rowNum, colNum, chNum, 1); //enable signal routed to row 2, col 2 ch 0

		//reset width measurement histograms
		hWidthSameWin->Reset();
		hWidthDiffWin->Reset();
		hWidthVsSmp->Reset();

		int nEvents = 0;
		for( int nevt = 0 ; nevt < 2000 ; nevt++){
			if( nEvents % 50 == 0 )
				std::cout << nEvents << std::endl;
			nEvents++;

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
			data->findPulseTimesFixedThreshold(40., 0, upperBound);

			if( data->pulseTimes.size() != 1 || data->pulseFallTimes.size() != 1 )
				continue;

			double riseTime = data->pulseTimes.at(0);
			double fallTime = data->pulseFallTimes.at(0);

			if( fallTime < riseTime )
				continue;
			if( fallTime > upperBound - 10 )
				continue;

			double width = fallTime - riseTime;
			
			if( int(riseTime) % 128 < int(fallTime) % 128 )
				hWidthSameWin->Fill(width);
			else
				hWidthDiffWin->Fill(width);

			//c0->Clear();
			//data->grChRef->GetXaxis()->SetRangeUser(0,768);
			//data->grChRef->Draw("ALP");
			//c0->Update();

			hWidthVsSmp->Fill(int(riseTime) % 128 , width);

			//sleep(1);
		}//end of events loop

		//get elapsed time
		double seconds_since_start = difftime( time(0), startTime);
		
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

		double widthOffset = meanWidthDiffWin - meanWidthSameWin;
		double widthOffsetErr = TMath::Sqrt( meanWidthSameWinErr*meanWidthSameWinErr + meanWidthDiffWinErr*meanWidthDiffWinErr );

		g2D_pulseTimeOffsetVsDAC->SetPoint(g2D_pulseTimeOffsetVsDAC->GetN(), dacVal, widthOffset );
		g2D_pulseTimeOffsetVsDAC->SetPointError(g2D_pulseTimeOffsetVsDAC->GetN()-1, 0.5, widthOffsetErr );

		g2D_pulseWidthVsDAC->SetPoint( g2D_pulseWidthVsDAC->GetN(), dacVal , meanWidthSameWin );
		g2D_pulseWidthVsDAC->SetPointError( g2D_pulseWidthVsDAC->GetN()-1, 0.5 , meanWidthSameWinErr );

		//Get RCO value
		control->registerRead(board_id, RCOCounterReg, regValReadback);
		g2D_RCOVsVadjN->SetPoint( g2D_RCOVsVadjN->GetN(), dacVal, regValReadback);
		g2D_RCOVsVadjN->SetPointError( g2D_RCOVsVadjN->GetN()-1, 0.5, 1);

		std::cout << "DAC " << dacVal;
		std::cout << "\tRCO " << regValReadback;
		std::cout << "\tsame win width " << meanWidthSameWin;	
		std::cout << "\tdiff win width " << meanWidthDiffWin;
		std::cout << "\twidth " << widthOffset;
		std::cout << "\terr " << widthOffsetErr;
		std::cout << std::endl;

		c0->Clear();
		hWidthVsSmp->Draw("COLZ");
		c0->Update();
		//char ct;
		//std::cin >> ct;

		delete f1Same;
		delete f1Diff;
	}//end of test loop

	TFile *f = new TFile( "output_irs3BControl_measurePulseWidths.root" , "RECREATE");
	hWidthVsSmp->Write();
	hWidthSameWin->Write();
	hWidthDiffWin->Write();
	g2D_pulseTimeOffsetVsDAC->Write("g2D_pulseTimeOffsetVsDAC");
	g2D_pulseWidthVsDAC->Write("g2D_pulseWidthVsDAC");
	g2D_RCOVsVadjN->Write("g2D_RCOVsVadjN");
  	f->Close();
	delete f;

	return 1;
}

int measurePulseWidthsVsTime( int board_id, irs3BControlClass *control, irs3BDataClass *data ){

	//setup objects needed for test
	TH2F *hWidthVsSmp = new TH2F("hWidthVsSmp","",128,0,128,100,0,50);
	TH1F *hWidthSameWin = new TH1F("hWidthSameWin","",200,0,50);
	TH1F *hWidthDiffWin = new TH1F("hWidthDiffWin","",200,0,50);
	TH1F *hPulseWidthOffset = new TH1F("hPulseWidthOffset","",1000,-5,5);
	TGraphErrors *g2D_pulseTimeOffsetVsDAC = new TGraphErrors();
	TGraphErrors *g2D_pulseWidthVsDAC = new TGraphErrors();
	TGraphErrors *g2D_pulseTimeOffsetVsTime = new TGraphErrors();
	int upperBound = 768;

	//setup DACs needed for tests
	int regValReadback;
	control->registerWrite(board_id, ForcedReadoutReg, ForcedReadoutVal, regValReadback); 	//force readout for row 0 col 2 ch 2
	//control->registerWrite(board_id, 142, 0x0000, regValReadback);  //turn off feedbacks, VadjN Scan only
	//int dacReg = 275; //VadjN for row 0 col 2
	//int dacValInit = 24300; //VadjN
	//int dacValStep = 50;
	//control->registerWrite(board_id, dacReg, dacValInit, regValReadback);  //set DAC

	//get start time
	time_t startTime = time(0);

	//run tests
	int numTests = 10;
	for( int test = 0 ; test < numTests ; test++){

		//set DAC specific for each test
		//double dacVal = dacValInit + dacValStep*test;
		//control->registerWrite(board_id, dacReg, dacVal, regValReadback);  //set VadjN
		double dacVal = 24300;

		//measure pedestal values
		measurePedestal( board_id, control, data );

		//reroute calibration signal to intended channel
		control->selectCalibrationDestination(board_id, rowNum, colNum, chNum, 1); //enable signal routed to row 2, col 2 ch 0

		//reset width measurement histograms
		hWidthSameWin->Reset();
		hWidthDiffWin->Reset();
		hWidthVsSmp->Reset();

		int nEvents = 0;
		for( int nevt = 0 ; nevt < 2000 ; nevt++){
			if( nEvents % 50 == 0 )
				std::cout << nEvents << std::endl;
			nEvents++;

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
			data->findPulseTimesFixedThreshold(40., 0, upperBound);

			if( data->pulseTimes.size() != 1 || data->pulseFallTimes.size() != 1 )
				continue;

			double riseTime = data->pulseTimes.at(0);
			double fallTime = data->pulseFallTimes.at(0);

			if( fallTime < riseTime )
				continue;
			if( fallTime > upperBound - 10 )
				continue;

			double width = fallTime - riseTime;
			
			if( int(riseTime) % 128 < int(fallTime) % 128 )
				hWidthSameWin->Fill(width);
			else
				hWidthDiffWin->Fill(width);

			//c0->Clear();
			//data->grChRef->GetXaxis()->SetRangeUser(0,768);
			//data->grChRef->Draw("ALP");
			//c0->Update();

			hWidthVsSmp->Fill(int(riseTime) % 128 , width);

			//sleep(1);
		}//end of events loop

		//get elapsed time
		double seconds_since_start = difftime( time(0), startTime);
		
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

		double widthOffset = meanWidthDiffWin - meanWidthSameWin;
		double widthOffsetErr = TMath::Sqrt( meanWidthSameWinErr*meanWidthSameWinErr + meanWidthDiffWinErr*meanWidthDiffWinErr );

		hPulseWidthOffset->Fill(widthOffset );

		g2D_pulseTimeOffsetVsDAC->SetPoint(g2D_pulseTimeOffsetVsDAC->GetN(), dacVal, widthOffset );
		g2D_pulseTimeOffsetVsDAC->SetPointError(g2D_pulseTimeOffsetVsDAC->GetN()-1, 0.5, widthOffsetErr );

		g2D_pulseWidthVsDAC->SetPoint( g2D_pulseWidthVsDAC->GetN(), dacVal , meanWidthSameWin );
		g2D_pulseWidthVsDAC->SetPointError( g2D_pulseWidthVsDAC->GetN()-1, 0.5 , meanWidthSameWinErr );

		g2D_pulseTimeOffsetVsTime->SetPoint( g2D_pulseTimeOffsetVsTime->GetN(), seconds_since_start, widthOffset );
		g2D_pulseTimeOffsetVsTime->SetPointError( g2D_pulseTimeOffsetVsTime->GetN() - 1 , 0.5, widthOffsetErr );

		std::cout << "DAC " << dacVal;
		std::cout << "\tsame win width " << meanWidthSameWin;	
		std::cout << "\tdiff win width " << meanWidthDiffWin;
		std::cout << "\twidth " << widthOffset;
		std::cout << "\terr " << widthOffsetErr;
		std::cout << std::endl;

		c0->Clear();
		hWidthVsSmp->Draw("COLZ");
		c0->Update();
		//char ct;
		//std::cin >> ct;

		delete f1Same;
		delete f1Diff;
	}//end of test loop

	TFile *f = new TFile( "output_irs3BControl_measurePulseWidthsVsTime.root" , "RECREATE");
	hWidthVsSmp->Write();
	hWidthSameWin->Write();
	hWidthDiffWin->Write();
	hPulseWidthOffset->Write();
	g2D_pulseTimeOffsetVsDAC->Write("g2D_pulseTimeOffsetVsDAC");
	g2D_pulseWidthVsDAC->Write("g2D_pulseWidthVsDAC");
	g2D_pulseTimeOffsetVsTime->Write("g2D_pulseTimeOffsetVsTime");
  	f->Close();
	delete f;

	return 1;
}

int measureSampRateVsTime( int board_id, irs3BControlClass *control, irs3BDataClass *data ){

	//setup objects needed for test
	TGraphErrors *g2D_RCOVsTime = new TGraphErrors();
	TGraphErrors *g2D_VadjNFBVsTime = new TGraphErrors();
	TGraphErrors *g2D_sampRateVsTime = new TGraphErrors();
	TGraphErrors *g2D_timeResVsTime = new TGraphErrors();
	TGraphErrors *g2D_timeOffsetVsTime = new TGraphErrors();
	TGraphErrors *g2D_tempVsTime = new TGraphErrors();
	TGraphErrors *g2D_sampRateVsTemp = new TGraphErrors();
	TGraphErrors *g2D_sampRateVsRCO = new TGraphErrors();
	TGraphErrors *g2D_timeResVsRCO = new TGraphErrors();
	TH1F *hRcoCounters = new TH1F("hRcoCounters","",70000,0,70000);

	//setup DACs needed for tests
	int regValReadback;
	control->registerWrite(board_id, ForcedReadoutReg, ForcedReadoutVal, regValReadback); 	//force readout for row 0 col 2 ch 2
	//control->registerWrite(board_id, 142, 0x0000, regValReadback);  //turn off feedbacks, VadjN Scan only

	//measure pedestal values
	measurePedestal( board_id, control, data );

	//reroute calibration signal to intended channel
	control->selectCalibrationDestination(board_id, rowNum, colNum, chNum, 1); //enable signal routed to row 2, col 2 ch 0

	//get start time
	time_t startTime = time(0);

	//run tests
	int numTests = 10;
	//for( int test = 0 ; test < numTests ; test++){
	for( int test = 0 ; test < numTests ; test++){
		//measure sampling rate
		double timeMean = 0;
		double timeMeanErr = 0;
		double timeSig = 0;
		double timeSigErr = 0;
		double timeOffset = 0;
		double timeOffsetErr = 0;
		double numPulses = 0;
		measureTimeRes( board_id, control, data, timeMean, timeMeanErr, timeSig, timeSigErr, timeOffset, timeOffsetErr, numPulses);

		//measure RCO counter values
		control->registerRead(board_id, RCOCounterReg, regValReadback);
		double rcoCounter =  regValReadback;

		//measure VadjNFB value
		control->registerRead(board_id, VadjNFBReg, regValReadback);
		double vadjNFB =  regValReadback;

		//measure temperature
		int temperature = -1;
		control->readTemperature( board_id, rowNum, colNum, temperature);
	
		//get elapsed time
		double seconds_since_start = difftime( time(0), startTime);

		//calculate sampling rate
		double trueTimeDiff = 23.0; //ns
		double sampRate = -1;
		double sampRateErr = -1;
		if( trueTimeDiff > 0 ){
			sampRate = timeMean / trueTimeDiff;
			sampRateErr = timeMeanErr / trueTimeDiff;
		}

		g2D_RCOVsTime->SetPoint(g2D_RCOVsTime->GetN(), seconds_since_start, rcoCounter);
		g2D_RCOVsTime->SetPointError(g2D_RCOVsTime->GetN()-1, 0.1, 1);

		g2D_VadjNFBVsTime->SetPoint(g2D_VadjNFBVsTime->GetN(), seconds_since_start, vadjNFB);
		g2D_VadjNFBVsTime->SetPointError(g2D_VadjNFBVsTime->GetN()-1, 0.1, 0.5);

		g2D_sampRateVsTime->SetPoint(g2D_sampRateVsTime->GetN(), seconds_since_start, sampRate);
		g2D_sampRateVsTime->SetPointError(g2D_sampRateVsTime->GetN()-1, 0.1, sampRateErr);
		
		g2D_timeResVsTime->SetPoint(g2D_timeResVsTime->GetN(), seconds_since_start, timeSig/TMath::Sqrt(2.));
		g2D_timeResVsTime->SetPointError(g2D_timeResVsTime->GetN()-1, 0.1, timeSigErr/TMath::Sqrt(2.));

		g2D_tempVsTime->SetPoint(g2D_tempVsTime->GetN(), seconds_since_start, temperature);
		g2D_tempVsTime->SetPointError(g2D_tempVsTime->GetN()-1, 0.1, 0.5 );
	
		g2D_timeOffsetVsTime->SetPoint(g2D_timeOffsetVsTime->GetN(), seconds_since_start, timeOffset);
		g2D_timeOffsetVsTime->SetPointError(g2D_timeOffsetVsTime->GetN()-1, 0.1, timeOffsetErr );

		g2D_sampRateVsTime->SetPoint(g2D_sampRateVsTime->GetN(), seconds_since_start,sampRate);
		g2D_sampRateVsTime->SetPointError(g2D_sampRateVsTime->GetN()-1, 0.1, sampRateErr );

		g2D_sampRateVsTemp->SetPoint(g2D_sampRateVsTemp->GetN(), temperature, sampRate);
		g2D_sampRateVsTemp->SetPointError(g2D_sampRateVsTemp->GetN()-1, 0.5, sampRateErr);

		g2D_sampRateVsRCO->SetPoint(g2D_sampRateVsRCO->GetN(), rcoCounter, sampRate);
		g2D_sampRateVsRCO->SetPointError(g2D_sampRateVsRCO->GetN()-1, 1., sampRateErr);

		g2D_timeResVsRCO->SetPoint(g2D_timeResVsRCO->GetN(), rcoCounter, timeSig/TMath::Sqrt(2.) );
		g2D_timeResVsRCO->SetPointError(g2D_timeResVsRCO->GetN()-1, 1., timeSigErr/TMath::Sqrt(2.) );

		hRcoCounters->Fill(rcoCounter);

		std::cout << "Test number: " << test;
		std::cout << "\ttime elapsed " << seconds_since_start;
		std::cout << "\tRCO counter " << regValReadback;
		std::cout << "\ttemperature " << temperature;
		std::cout << std::endl;

		sleep(1);
	}//end of test loop

	if(1){
		char cf;
		c0->Clear();
		g2D_sampRateVsTime->Draw("ALP");
		c0->Update();
		std::cin >> cf;
	}

	TFile *f = new TFile( "output_irs3BControl_measureSampRateVsTime.root" , "RECREATE");
 	g2D_RCOVsTime->Write("g2D_RCOVsTime");
	g2D_VadjNFBVsTime->Write("g2D_VadjNFBVsTime");
	g2D_timeResVsTime->Write("g2D_timeResVsTime");
	g2D_sampRateVsTime->Write("g2D_sampRateVsTime");
	g2D_timeOffsetVsTime->Write("g2D_timeOffsetVsTime");
	g2D_tempVsTime->Write("g2D_tempVsTime");
	g2D_sampRateVsTemp->Write("g2D_sampRateVsTemp");
	g2D_sampRateVsRCO->Write("g2D_sampRateVsRCO");
	g2D_timeResVsRCO->Write("g2D_timeResVsRCO");
	hRcoCounters->Write();
  	f->Close();
	delete f;

	return 1;
}


int measureRcoVsVadjN( int board_id, irs3BControlClass *control, irs3BDataClass *data){
	control->clearDataBuffer();

	//setup objects needed for test
	TGraphErrors *g2D_RCOVsVadjN = new TGraphErrors();
	TH1F *hRcoCounters = new TH1F("hRcoCounters","",70000,0,70000);

	//setup DACs needed for tests
	int regValReadback;
	//int dacValInit = 5000;
	//int dacValStep = 1000;
	int dacValInit = 24300;
	int dacValStep = 10;
	control->registerWrite(board_id, 142, 0x0000, regValReadback);  //turn off feedbacks
	control->registerWrite(board_id, VadjNReg, dacValInit, regValReadback);  //set VadjN

	//run tests
	int numTests = 30;
	for( int test = -1*numTests / 2 ; test <= numTests / 2 ; test++){
		//set DAC specific for each test
		double dacVal = dacValInit + dacValStep*test;
		control->registerWrite(board_id, VadjNReg, dacVal, regValReadback);  //set VadjN
		
		//record RCO counter values
		hRcoCounters->Reset();
		for(int i = 0 ; i < 10 ; i++ ){
			control->registerRead(board_id, RCOCounterReg, regValReadback);
			hRcoCounters->Fill(regValReadback);
			usleep(2000);
		}
		//RCO counter vs sampling rate study
		double rcoMean = hRcoCounters->GetMean(1);
		double rcoRMS = hRcoCounters->GetRMS(1);

		g2D_RCOVsVadjN->SetPoint( g2D_RCOVsVadjN->GetN(), dacVal, rcoMean);
		g2D_RCOVsVadjN->SetPointError( g2D_RCOVsVadjN->GetN()-1, 0.5, rcoRMS);
	}//end of test loop

	TFile *f = new TFile( "output_irs3BControl_measureRcoVsVadjN.root" , "RECREATE");
 	g2D_RCOVsVadjN->Write("g2D_RCOVsVadjN");
  	f->Close();
	delete f;
	delete g2D_RCOVsVadjN;
	delete hRcoCounters;

	return 1;
}

int measureRcoVsTime( int board_id, irs3BControlClass *control, irs3BDataClass *data){
	control->clearDataBuffer();

	//setup objects needed for test
	TGraphErrors *g2D_RCOVsTime = new TGraphErrors();
	TH1F *hRcoCounters = new TH1F("hRcoCounters","",70000,0,70000);

	//setup DACs needed for tests
	int regValReadback;

	time_t startTime = time(0);

	//run tests
	int numTests = 300;
	for( int test = 0 ; test < numTests ; test++){
		
		//get RCO counter value
		control->registerRead(board_id, RCOCounterReg, regValReadback);
		//get elapsed time
		double seconds_since_start = difftime( time(0), startTime);

		g2D_RCOVsTime->SetPoint( g2D_RCOVsTime->GetN(), seconds_since_start, regValReadback);
		g2D_RCOVsTime->SetPointError( g2D_RCOVsTime->GetN()-1, 0.1, 0.5);

		hRcoCounters->Fill(regValReadback);

		std::cout << "time elapsed " << seconds_since_start;
		std::cout << "\tRCO counter " << regValReadback;
		std::cout << std::endl;

		sleep(1);
	}//end of test loop

	TFile *f = new TFile( "output_irs3BControl_measureRcoVsTime.root" , "RECREATE");
 	g2D_RCOVsTime->Write("g2D_RCOVsTime");
	hRcoCounters->Write();
  	f->Close();
	delete f;
	delete g2D_RCOVsTime;
	delete hRcoCounters;

	return 1;
}

int plotAdjacentTimes( int board_id, irs3BControlClass *control, irs3BDataClass *data){

	//graph of adjacent pulse times
	TGraphErrors *g2D_timeNextVsTime = new TGraphErrors();
	TGraphErrors *g2D_timeDiffVsTime = new TGraphErrors();
	TGraphErrors *g2D_timeDiffVsBinNum = new TGraphErrors();
	TH1F *h1D_numPulses = new TH1F("h1D_numPulses","",128,0,128);
	TH2F *h2D_timeDiffVsBinNum = new TH2F("h2D_timeDiffVsBinNum","",128,0,128,128,0,128);

	//measure pedestal values
	measurePedestal( board_id, control, data );

	//reroute calibration signal to intended channel
	control->selectCalibrationDestination(board_id, rowNum, colNum, chNum, 1); //enable signal routed to row 2, col 2 ch 0

	//take waveform data, applying pedestal correction
	int nEvents = 0;
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

		//find pulse times
		//data->findPulseTimesFixedThreshold(0., 0, 12*64);
		data->findPulseTimesFixedThreshold(0., 0, 768);

		//record pulse times in histograms
		for(int i = 0 ; i < data->pulseTimes.size() - 1 ; i++){
			double time = data->pulseTimes.at(i);
			double timeNext = data->pulseTimes.at(i+1);
			int binNum = int(time) % int(128);

			g2D_timeNextVsTime->SetPoint( g2D_timeNextVsTime->GetN() , time , timeNext );
			g2D_timeNextVsTime->SetPointError( g2D_timeNextVsTime->GetN()-1 , 0.5 , 0.5 );

			g2D_timeDiffVsTime->SetPoint( g2D_timeDiffVsTime->GetN() , time , timeNext - time );
			g2D_timeDiffVsTime->SetPointError( g2D_timeDiffVsTime->GetN()-1 , 0.5 , 0.5 );

			g2D_timeDiffVsBinNum->SetPoint( g2D_timeDiffVsBinNum->GetN() , binNum , timeNext - time );
			g2D_timeDiffVsBinNum->SetPointError( g2D_timeDiffVsBinNum->GetN()-1 , 0.5 , 0.5 );

			if( time >= 128 && time < 640 )
				h1D_numPulses->Fill(binNum);
			h2D_timeDiffVsBinNum->Fill( binNum , timeNext - time );
		}
		if( nEvents % 50 == 0 )
			std::cout << nEvents << std::endl;
		nEvents++;
	}//end of event loop

	char cf;
	c0->Clear();
	g2D_timeNextVsTime->Draw("AP");
	c0->Update();
	std::cin >> cf;

	TFile *f = new TFile( "output_irs3BControl_plotAdjacentTimes.root" , "RECREATE");
 	g2D_timeNextVsTime->Write("g2D_timeNextVsTime");
	g2D_timeDiffVsTime->Write("g2D_timeDiffVsTime");
	g2D_timeDiffVsBinNum->Write("g2D_timeDiffVsBinNum");
	h1D_numPulses->Write();
	h2D_timeDiffVsBinNum->Write();
  	f->Close();
	delete g2D_timeNextVsTime;

	return 1;
}

int scanDAC( int board_id, irs3BControlClass *control, irs3BDataClass *data ){

	//setup objects needed for test
	TGraphErrors *g2D_timeMeanVsDAC = new TGraphErrors();
	TGraphErrors *g2D_timeSigVsDAC = new TGraphErrors();			
	TGraphErrors *g2D_timeOffsetVsDAC = new TGraphErrors();		
	TGraphErrors *g2D_rcoCounterVsDAC = new TGraphErrors();
	TGraphErrors *g2D_timeSigVsRCO = new TGraphErrors();
	TGraphErrors *g2D_sampRateVsDAC = new TGraphErrors();
 	TGraphErrors *g2D_numPulsesVsDAC = new TGraphErrors();
	TH1F *hRcoCounters = new TH1F("hRcoCounters","",70000,0,70000);

	//setup DACs needed for tests
	int regValReadback;
	int dacReg = 275; //VadjN for row 0 col 2
	//int dacReg = 307; //TIMING_SSP_base for row 0 col 2
	int dacValInit = 24900; //VadjN
	//int dacValInit = 0x1060; //TIMING_SSP_base 
	int dacValStep = 50;
	control->registerWrite(board_id, dacReg, dacValInit, regValReadback);  //set DAC

	control->registerWrite(board_id, 142, 0x0000, regValReadback);  //turn off feedbacks, VadjN Scan only
	control->registerWrite(board_id, ForcedReadoutReg, ForcedReadoutVal, regValReadback); 	//force readout for row 0 col 2 ch 2

	//run tests
	int numTests = 2;
	//for( int test = 0 ; test < numTests ; test++){
	for( int test = -1*numTests / 2 ; test <= numTests / 2 ; test++){
		//set DAC specific for each test
		double dacVal = dacValInit + dacValStep*test;
		control->registerWrite(board_id, dacReg, dacVal, regValReadback);  //set VadjN

		sleep(1);

		//measure pedestal values
		measurePedestal( board_id, control, data );

		//reroute calibration signal to intended channel
		control->selectCalibrationDestination(board_id, rowNum, colNum, chNum, 1); //enable signal routed to row 2, col 2 ch 0

		double timeMean = 0;
		double timeMeanErr = 0;
		double timeSig = 0;
		double timeSigErr = 0;
		double timeOffset = 0;
		double timeOffsetErr = 0;
		double numPulses = 0;
		measureTimeRes( board_id, control, data, timeMean, timeMeanErr, timeSig, timeSigErr, timeOffset, timeOffsetErr, numPulses);
		g2D_timeMeanVsDAC->SetPoint(g2D_timeMeanVsDAC->GetN(), dacVal, timeMean);
		g2D_timeMeanVsDAC->SetPointError(g2D_timeMeanVsDAC->GetN()-1, 0.5, timeMeanErr);

		g2D_timeSigVsDAC->SetPoint(g2D_timeSigVsDAC->GetN(), dacVal, timeSig/TMath::Sqrt(2.));
		g2D_timeSigVsDAC->SetPointError(g2D_timeSigVsDAC->GetN()-1, 0.5, timeSigErr/TMath::Sqrt(2.));

		g2D_timeOffsetVsDAC->SetPoint(g2D_timeOffsetVsDAC->GetN(), dacVal, timeOffset);
		g2D_timeOffsetVsDAC->SetPointError(g2D_timeOffsetVsDAC->GetN()-1, 0.5, timeOffsetErr);

		g2D_numPulsesVsDAC->SetPoint(g2D_numPulsesVsDAC->GetN(), dacVal, numPulses);
		g2D_numPulsesVsDAC->SetPointError(g2D_numPulsesVsDAC->GetN()-1,0.5,0.1);
		
		//record RCO counter values
		hRcoCounters->Reset();
		for(int i = 0 ; i < 20 ; i++ ){
			control->registerRead(board_id, RCOCounterReg, regValReadback);
			g2D_rcoCounterVsDAC->SetPoint( g2D_rcoCounterVsDAC->GetN(), dacVal, regValReadback );
			g2D_rcoCounterVsDAC->SetPointError( g2D_rcoCounterVsDAC->GetN()-1, 0.5, 2 );
			hRcoCounters->Fill(regValReadback);
		}
		//RCO counter vs sampling rate study
		double trueTimeDiff = 23.0; //ns
		double sampRate = -1;
		double sampRateErr = -1;
		if( trueTimeDiff > 0 ){
			sampRate = timeMean / trueTimeDiff;
			sampRateErr = timeMeanErr / trueTimeDiff;
		}

		g2D_sampRateVsDAC->SetPoint(g2D_sampRateVsDAC->GetN(), dacVal, sampRate);
		g2D_sampRateVsDAC->SetPointError(g2D_sampRateVsDAC->GetN()-1, 0.5, sampRateErr);

		double rcoMean = hRcoCounters->GetMean(1);
		double rcoRMS = hRcoCounters->GetRMS(1);

		g2D_timeSigVsRCO->SetPoint( g2D_timeSigVsRCO->GetN(), rcoMean, timeSig/TMath::Sqrt(2.));
		g2D_timeSigVsRCO->SetPointError( g2D_timeSigVsRCO->GetN()-1, rcoRMS, timeSigErr/TMath::Sqrt(2.));
	}//end of test loop

	if(0){
		char cf;
		c0->Clear();
		g2D_timeSigVsDAC->Draw("ALP");
		c0->Update();
		std::cin >> cf;
	}

	TFile *f = new TFile( "output_irs3BControl_scanDac.root" , "RECREATE");
 	g2D_timeMeanVsDAC->Write("g2D_timeMeanVsDAC");
	g2D_timeSigVsDAC->Write("g2D_timeSigVsDAC");
	g2D_rcoCounterVsDAC->Write("g2D_rcoCounterVsDAC");
	g2D_timeOffsetVsDAC->Write("g2D_timeOffsetVsDAC");
	g2D_sampRateVsDAC->Write("g2D_sampRateVsDAC");
	g2D_timeSigVsRCO->Write("g2D_timeSigVsRCO");
	g2D_numPulsesVsDAC->Write("g2D_numPulsesVsDAC");
  	f->Close();
	delete f;

	return 1;
}

int measurePedestal( int board_id, irs3BControlClass *control, irs3BDataClass *data ){

	//get pedestal waveforms
	std::cout << "Measuring pedestal values " << std::endl;
	control->clearDataBuffer();
	control->selectCalibrationDestination(board_id, rowNum, colNum, chNum, 0); //disable signal routed to row 2, col 2 ch 0
	data->resetPedestalValues();
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

	return 1;
}

int measureTimeRes( int board_id, irs3BControlClass *control, irs3BDataClass *data, double &timeMean, double &timeMeanErr, double &timeSig, double &timeSigErr, 
		double &timeOffset, double &timeOffsetErr, double &numPulsesMean){

	//setup objects needed for test
	TH1F *h1D_timeDiff = new TH1F("h1D_timeDiff","",500,0,200);
	TH1F *h1D_timeDiff_sameWin = new TH1F("h1D_timeDiff_sameWin","",512,-128,128);
	TH1F *h1D_timeDiff_diffWin = new TH1F("h1D_timeDiff_diffWin","",512,-128,128);
	TH1F *h1D_numPulses = new TH1F("h1D_numPulses","",20,1,21);

	//take waveform data, applying pedestal correction
	int nEvents = 0;
	for( int nevt = 0 ; nevt < 400 ; nevt++){
		if( nEvents % 50 == 0 )
			std::cout << nEvents << std::endl;
		nEvents++;

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
		data->findPulseTimesFixedThreshold(10., 0, 768);
		h1D_numPulses->Fill( data->pulseTimes.size() );

		if( data->pulseTimes.size() < 2 )
			continue;

		//record pulse times in histograms
		for(int i = 0 ; i < data->pulseTimes.size() - 1 ; i++){
			double time = data->pulseTimes.at(i);
			double timeNext = data->pulseTimes.at(i+1);
			int binNum = int(time) % int(128);

			if( timeNext < 768 && time < 768 )
				h1D_timeDiff->Fill( timeNext - time );
			if( int(time) % 128 < 5 || int(time) % 128 > 123 || int(timeNext) % 128 < 5 || int(timeNext) % 128 > 123 )
				continue;
			if( int(time) / 128 == int(timeNext) / 128 )
				h1D_timeDiff_sameWin->Fill( timeNext - time );
			if( int(time) / 128 != int(timeNext) / 128 )
				h1D_timeDiff_diffWin->Fill( timeNext - time );
		}
	}//end of event loop

	//measure overall time difference
	double posMax = h1D_timeDiff->GetBinCenter( h1D_timeDiff->GetMaximumBin() );
	h1D_timeDiff->GetXaxis()->SetRangeUser(posMax-10, posMax+10);
	double peakMean = h1D_timeDiff->GetMean(1);

	//measure time difference between pulses within the same and different windows
	double posMax_sameWin = h1D_timeDiff_sameWin->GetBinCenter( h1D_timeDiff_sameWin->GetMaximumBin() );
	h1D_timeDiff_sameWin->GetXaxis()->SetRangeUser(posMax_sameWin-10, posMax_sameWin+10);
	double peakMean_sameWin = h1D_timeDiff_sameWin->GetMean(1);
	double peakRms_sameWin = h1D_timeDiff_sameWin->GetRMS(1);

	double posMax_diffWin = h1D_timeDiff_diffWin->GetBinCenter( h1D_timeDiff_diffWin->GetMaximumBin() );
	h1D_timeDiff_diffWin->GetXaxis()->SetRangeUser(posMax_diffWin-10, posMax_diffWin+10);
	double peakMean_diffWin = h1D_timeDiff_diffWin->GetMean(1);
	double peakRms_diffWin = h1D_timeDiff_diffWin->GetRMS(1);

	timeOffset = peakMean_diffWin - peakMean_sameWin;
	timeOffsetErr = TMath::Sqrt( peakRms_sameWin*peakRms_sameWin + peakRms_diffWin*peakRms_diffWin );

	TF1 *f1 = new TF1("f1","gaus",posMax-10, posMax+10);
        h1D_timeDiff->Fit("f1","QR");
	timeMean = f1->GetParameter(1);
	timeMeanErr = f1->GetParError(1);
	timeSig = f1->GetParameter(2);
	timeSigErr = f1->GetParError(2);

	//measure average number of pulses
	numPulsesMean = h1D_numPulses->GetMean(1);

	if(0){
		std::cout << "\tmean " << timeMean;
		std::cout << "\tsigma " << timeSig;
		std::cout << std::endl;
		char ct;
		c0->Clear();	
		//h1D_timeDiff->Draw();
		//h1D_timeDiff_sameWin->SetLineColor(kBlue);
		//h1D_timeDiff_diffWin->SetLineColor(kRed);
		//h1D_timeDiff_sameWin->Draw();
		//h1D_timeDiff_diffWin->Draw("same");
		h1D_numPulses->Draw();
		c0->Update();
		std::cin >> ct;
	}

	delete h1D_timeDiff;
	delete f1;
	delete h1D_timeDiff_diffWin;
	delete h1D_timeDiff_sameWin;
	delete h1D_numPulses;

	return 1;
}

int scanVadjNWinTimeOffsets( int board_id, irs3BControlClass *control, irs3BDataClass *data ){

	//setup objects needed for test
	TH1F *h1D_sameWin = new TH1F("h1D_sameWin","",256,-128,128);
	TH1F *h1D_diffWin = new TH1F("h1D_diffWin","",256,-128,128);
	TGraphErrors *g2D_diffVsVadjN = new TGraphErrors();
	TGraphErrors *g2D_RcoCounterVsVadjN = new TGraphErrors();

	//setup DACs needed for tests
	//set forced readout mode: registers 171 - 178
	//row 0 col 2 = register 175, lower 8 bits, set channel 2 for readout
	int regValReadback;
	int vadjNValInit = 24200;
	int vadjNValStep = 50;
	control->registerWrite(board_id, ForcedReadoutReg, ForcedReadoutVal, regValReadback); 	//force readout
	control->registerWrite(board_id, 142, 0x0000, regValReadback);  //turn off feedbacks
	control->registerWrite(board_id, VadjNReg, vadjNValInit, regValReadback);  //set VadjN

	//run tests
	int numTests = 5;
	for( int test = 0 ; test < numTests ; test++){

		//set DAC specific for each test
		double vadjNVal = vadjNValInit + vadjNValStep*test;
		control->registerWrite(board_id, VadjNReg, vadjNVal, regValReadback);  //set VadjN

		//get pedestal waveforms
		control->clearDataBuffer();
		control->selectCalibrationDestination(board_id, rowNum, colNum, chNum, 0); //disable signal routed to row 2, col 2 ch 0
		data->resetPedestalValues();
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

		//reroute calibration signal to intended channel
		control->selectCalibrationDestination(board_id, rowNum, colNum, chNum, 1); //enable signal routed to row 2, col 2 ch 0

		//initialize waveform data histograms
		h1D_sameWin->Reset();
		h1D_diffWin->Reset();

		char ct;
		//take waveform data, applying pedestal correction
		int nEvents = 0;
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

			//find pulse times
			//data->findPulseTimesFixedThreshold(0., 0, 256);
			data->findPulseTimesFixedThreshold(0., 0, 768);

			//record pulse times in histograms
			for(int i = 0 ; i < data->pulseTimes.size() - 1 ; i++){
				double time = data->pulseTimes.at(i);
				double timeNext = data->pulseTimes.at(i+1);

				if( int(time) / 128 == int(timeNext) / 128 )
					h1D_sameWin->Fill( timeNext - time );

				if( int(time) / 128 != int(timeNext) / 128 )
					h1D_diffWin->Fill( timeNext - time );

				//std::cout << "\ttime " << time;
				//std::cout << "\ttimeNext " << timeNext;
				//std::cout << std::endl;
			}
			if( nEvents % 50 == 0 ){
				control->registerRead(board_id, RCOCounterReg, regValReadback);
				g2D_RcoCounterVsVadjN->SetPoint( g2D_RcoCounterVsVadjN->GetN(), vadjNVal, regValReadback );
				g2D_RcoCounterVsVadjN->SetPointError( g2D_RcoCounterVsVadjN->GetN()-1, 0, 5 );
				std::cout << nEvents << "\tVadjN " << vadjNVal << "\tRCO counter " << regValReadback << std::endl;
			}
			nEvents++;

			if(0){
				c0->Clear();
				c0->Divide(2);
				c0->cd(1);
				//data->grChRef->GetXaxis()->SetRangeUser(0,256+128);
				//data->grChRef->GetYaxis()->SetRangeUser(-400,400);
				//data->grChRef->Draw("ALP");
				data->grCh->Draw("ALP");
				c0->cd(2);
				data->grChRef->Draw("ALP");
				c0->Update();	
				std::cin >> ct;
			}
		}//end of event loop

		//same window
		double posMax_same = h1D_sameWin->GetBinCenter( h1D_sameWin->GetMaximumBin() );
		h1D_sameWin->GetXaxis()->SetRangeUser(posMax_same-5, posMax_same+5);
		double peakMean_same = h1D_sameWin->GetMean(1);
		if( peakMean_same <= 0 )
			continue;
		//different window
		double posMax_diff = h1D_diffWin->GetBinCenter( h1D_diffWin->GetMaximumBin() );
		h1D_diffWin->GetXaxis()->SetRangeUser(posMax_diff-5, posMax_diff+5);
		double peakMean_diff = h1D_diffWin->GetMean(1);
		if( peakMean_diff <= 0 )
			continue;

		//h1D_sameWin->GetXaxis()->SetRangeUser(-128, 128);
		//h1D_diffWin->GetXaxis()->SetRangeUser(-128, 128);

		//double truePulseTimeDiff = 58.823;
		//double windowPeriod = truePulseTimeDiff/peakMean*128; 
		std::cout << " vadjNVal " << vadjNVal;
		std::cout << "\tpeakMean_same " << peakMean_same;
		std::cout << "\tpeakMean_diff " << peakMean_diff;
		std::cout << "\tdifference " << peakMean_same-peakMean_diff;
		std::cout << std::endl;

		g2D_diffVsVadjN->SetPoint(g2D_diffVsVadjN->GetN(), vadjNVal, peakMean_same-peakMean_diff);
		g2D_diffVsVadjN->SetPointError(g2D_diffVsVadjN->GetN()-1, 0.05, 0.05);
		
		c0->Clear();
		h1D->Draw();
		h2D->Draw("COLZ");
		h1D_sameWin->SetLineColor(kBlue);
		h1D_sameWin->Draw();
		h1D_diffWin->SetLineColor(kRed);
		h1D_diffWin->Draw("same");
		c0->Update();
		std::cin >> ct;
	}//end of test loop

	TF1 *f1 = new TF1("f1","pol1");
        g2D_diffVsVadjN->Fit("f1","");

	double b = f1->GetParameter(0);
	double m = f1->GetParameter(1);

	double vadjNZero = 0;
	if( m > 0 )
		vadjNZero = -b/m;
	std::cout << "vadjNZero " << vadjNZero << std::endl;
	
	char cf;
	c0->Clear();
	c0->Divide(2);
	c0->cd(1);
	g2D_diffVsVadjN->Draw("ALP");
	c0->cd(2);
	g2D_RcoCounterVsVadjN->Draw("AP");
	c0->Update();
	std::cin >> cf;

	TFile *f = new TFile( "output_irs3BControl_sampRateCal.root" , "RECREATE");
 	g2D_diffVsVadjN->Write("g2D_diffVsVadjN");
  	g2D_RcoCounterVsVadjN->Write("g2D_RcoCounterVsVadjN");
  	f->Close();
	delete f;

	return 1;
}
