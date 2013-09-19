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
int scanDAC( int board_id, irs3BControlClass *control, irs3BDataClass *data );
int scanVadjNWinTimeOffsets( int board_id, irs3BControlClass *control, irs3BDataClass *data );
int measureTimeRes( int board_id, irs3BControlClass *control, irs3BDataClass *data, double &timeMean, double &timeMeanErr, double &timeSig, double &timeSigErr );
int plotAdjacentTimes( int board_id, irs3BControlClass *control, irs3BDataClass *data);

//global data objects
TCanvas *c0;
TH1F *h1D;
TH2F *h2D;
TGraphErrors *g2D;

//global variables for quick testing
//setting variables for readouts on row 0 col 2 ch 2
//set forced readout mode: registers 171 - 178, row 0 col 2 = register 175, lower 8 bits, set channel 2 for readout
int dacReg = 275; //VadjN for row 0 col 2
int VadjNReg = 275; //VadjN for row 0 col 2
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
	scanDAC( board_id, control, data );
	//plotAdjacentTimes(board_id, control, data);

	//close USB interface
        control->closeUSBInterface();

	//delete irs3b interface object
	delete control;
	delete data;

	return 1;
}

int plotAdjacentTimes( int board_id, irs3BControlClass *control, irs3BDataClass *data){
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

			g2D->SetPoint( g2D->GetN() , time , timeNext );
			g2D->SetPointError( g2D->GetN()-1 , 0.5 , 0.5 );			
		}
		if( nEvents % 50 == 0 )
			std::cout << nEvents << std::endl;
		nEvents++;

		if(0){
			std::cout << "\tfirstWindowNum " << data->firstWindowNum << std::endl;
			data->grCh->GetXaxis()->SetRangeUser(0,1024);
			data->grChRef->GetXaxis()->SetRangeUser(0,1024);
			char ct;
			c0->Clear();
			c0->Divide(2);
			c0->cd(1);
			data->grCh->Draw("ALP");
			c0->cd(2);
			data->grChRef->Draw("ALP");
			c0->Update();	
			std::cin >> ct;
		}
	}//end of event loop

	char cf;
	c0->Clear();
	g2D->Draw("ALP");
	c0->Update();
	std::cin >> cf;

}

int scanDAC( int board_id, irs3BControlClass *control, irs3BDataClass *data ){

	//setup objects needed for test
	TGraphErrors *g2D_timeMeanVsDAC = new TGraphErrors();
	TGraphErrors *g2D_timeSigVsDAC = new TGraphErrors();		
	TGraphErrors *g2D_timeSigVsRCO = new TGraphErrors();		
	TGraphErrors *g2D_rcoCounterVsDAC = new TGraphErrors();
	TH1F *hRcoCounters = new TH1F("hRcoCounters","",70000,0,70000);

	//setup DACs needed for tests
	int regValReadback;
	int dacValInit = 24275;
	int dacValStep = 25;
	control->registerWrite(board_id, ForcedReadoutReg, ForcedReadoutVal, regValReadback); 	//force readout for row 0 col 2 ch 2
	control->registerWrite(board_id, 142, 0x0000, regValReadback);  //turn off feedbacks
	control->registerWrite(board_id, dacReg, dacValInit, regValReadback);  //set VadjN

	//run tests
	int numTests = 5;
	for( int test = 0 ; test < numTests ; test++){
		//set DAC specific for each test
		double dacVal = dacValInit + dacValStep*test;
		control->registerWrite(board_id, dacReg, dacVal, regValReadback);  //set VadjN

		double timeMean = 0;
		double timeMeanErr = 0;
		double timeSig = 0;
		double timeSigErr = 0;
		measureTimeRes( board_id, control, data, timeMean, timeMeanErr, timeSig, timeSigErr );
		g2D_timeMeanVsDAC->SetPoint(g2D_timeMeanVsDAC->GetN(), dacVal, timeMean);
		g2D_timeMeanVsDAC->SetPointError(g2D_timeMeanVsDAC->GetN()-1, 0.5, timeMeanErr);

		g2D_timeSigVsDAC->SetPoint(g2D_timeSigVsDAC->GetN(), dacVal, timeSig);
		g2D_timeSigVsDAC->SetPointError(g2D_timeSigVsDAC->GetN()-1, 0.5, timeSigErr);
		
		//record RCO counter values
		hRcoCounters->Reset();
		for(int i = 0 ; i < 20 ; i++ ){
			control->registerRead(board_id, RCOCounterReg, regValReadback);
			g2D_rcoCounterVsDAC->SetPoint( g2D_rcoCounterVsDAC->GetN(), dacVal, regValReadback );
			g2D_rcoCounterVsDAC->SetPointError( g2D_rcoCounterVsDAC->GetN()-1, 0.5, 2 );
			hRcoCounters->Fill(regValReadback);
		}
		//RCO counter vs sampling rate study
		double trueTimeDiff = 31.0; //ns
		double rcoMean = hRcoCounters->GetMean(1);
		double rcoRMS = hRcoCounters->GetRMS(1);

		g2D_timeSigVsRCO->SetPoint( g2D_timeSigVsRCO->GetN(), rcoMean, timeSig);
		g2D_timeSigVsRCO->SetPointError( g2D_timeSigVsRCO->GetN()-1, rcoRMS, timeSigErr);
	}//end of test loop

	if(1){
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
	g2D_timeSigVsRCO->Write("g2D_timeSigVsRCO");
  	f->Close();
	delete f;

	return 1;
}

int measureTimeRes( int board_id, irs3BControlClass *control, irs3BDataClass *data, double &timeMean, double &timeMeanErr, double &timeSig, double &timeSigErr ){

	//setup objects needed for test
	TH1F *h1D_timeDiff = new TH1F("h1D_timeDiff","",500,0,200);

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

	//take waveform data, applying pedestal correction
	int nEvents = 0;
	for( int nevt = 0 ; nevt < 1000 ; nevt++){
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
		data->findPulseTimesFixedThreshold(0., 0, 768);

		//record pulse times in histograms
		for(int i = 0 ; i < data->pulseTimes.size() - 1 ; i++){
			double time = data->pulseTimes.at(i);
			double timeNext = data->pulseTimes.at(i+1);
			if( timeNext < 768 && time < 768 ) 
				h1D_timeDiff->Fill( timeNext - time );
		}
		if( nEvents % 50 == 0 )
			std::cout << nEvents << std::endl;
		nEvents++;
	}//end of event loop

	//measure time resolution
	double posMax = h1D_timeDiff->GetBinCenter( h1D_timeDiff->GetMaximumBin() );
	h1D_timeDiff->GetXaxis()->SetRangeUser(posMax-10, posMax+10);

	TF1 *f1 = new TF1("f1","gaus",posMax-10, posMax+10);
        h1D_timeDiff->Fit("f1","QR");
	timeMean = f1->GetParameter(1);
	timeMeanErr = f1->GetParError(1);
	timeSig = f1->GetParameter(2);
	timeSigErr = f1->GetParError(2);

	if(0){
		std::cout << "\tmean " << timeMean;
		std::cout << "\tsigma " << timeSig;
		std::cout << std::endl;
		char ct;
		c0->Clear();	
		h1D_timeDiff->Draw();
		c0->Update();
		std::cin >> ct;
	}

	delete h1D_timeDiff;
	delete f1;

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
