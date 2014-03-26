//compile with: g++ -o topDataClass_doAnalysis_doublePulseSampleDTFit src/topDataClass_doAnalysis_doublePulseSampleDTFit.cpp `root-config --cflags --glibs` -lMinuit
//Program assumes there is a channel of interest and a "timing marker" channel, specified by topDataClass functions.
//Maximum likelihood fit finds sample-DTs that result in smallest variance in distribution of means measured from pulse time - marker time for each sampling array bin
//alternative fit would simply constrain sample-DTs to values that result in time difference measurements closest to know pulse time difference 

#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h> 
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
#include <TMinuit.h>
#include "topDataClass.h"
#include "topDataClass.cpp"

//global TApplication object declared here for simplicity
TApplication *theApp;

using namespace std;

//helper functions
int initializeGlobalHistograms();
int writeOutputFile();

//hardcoded constants relevant to laser data
double windowTime = 1077.5;
double windowLow = windowTime-10.;
double windowHigh = windowTime+10.;

//output file pointer
TFile* outputFile;

//histograms
TH1F *hSampleTimes;

TH1F *hPulseHeightInitial;
TH1F *hPulseTimeInitial;
TH1F *hPulseSampleInitial;
TH1F *hPulseSmp128Initial;
TH2F *hPulseTimeVsSmp128Initial;
TH2F *hPulseTimeVsSmp128PosInitial;
TH2F *hPulseTimeVsFTSWInitial;
TH2F *hPulseTimeVsHeightInitial;
TH2F *hFTSWVsSmp128Initial;

TH1F *hPulseTimeMarkTimeDiffInitial;
TH2F *hPulseTimeMarkTimeDiffVsMarkSmpBinNumInitial;

TGraphErrors *gPulseTimeVsEventNum;
TGraphErrors *gTest;

//Stupid global Minuit fit variables
topDataClass *fitter_data;
TH1F *hFitter_PulseTimeDiff;
TH2F *hFitter_PulseTimeDiffVsSmp128;
TGraphErrors *gFitter;
TH1F *hBinTimeDiffs;
TH1F *hFitter_SampleWidths;
TH2F *hFitter_Cov;
int doDoublePulseFit(topDataClass *in_data);
static void fitFuncML(int& npar, double* gout, double& result, double par[], int flg);
int numSteps;
TCanvas *c0;

int main(int argc, char* argv[]){
	if (argc != 6){
    		std::cout << "wrong number of arguments: usage ./topDataClass_doAnalysis <file name> <mod #> <row #> <col #> <ch #>" << std::endl;
    		return 0;
  	}

	//define application object
	theApp = new TApplication("App", &argc, argv);
	TString inputFileName = theApp->Argv()[1];
	std::cout << "Input file name "  << inputFileName << std::endl;

	//create target6 interface object
	topDataClass *data = new topDataClass();

	//specify channel of interest
	int inMod = atoi(theApp->Argv()[2]);
	int inRow = atoi(theApp->Argv()[3]);
	int inCol = atoi(theApp->Argv()[4]);
	int inCh = atoi(theApp->Argv()[5]);
	data->setAnalysisChannel( inMod, inRow, inCol, inCh );

	//specify timing marker channel
	data->setTimingMarkerChannel( 0, 0, 1, 2 );

	//specify time window
	data->windowTime = windowTime;

	//open summary tree file
	data->openSummaryTree(inputFileName);

	//create output file
  	TObjArray* strings = inputFileName.Tokenize("/");
  	TObjString* objstring = (TObjString*) strings->At(strings->GetLast());
  	TString inputFileNameBase(objstring->GetString());
	TString outputFileName = "output_topDataClass_doAnalysis_doublePulseSampleDTFit_";
  	outputFileName += inMod;
  	outputFileName += "_";
  	outputFileName += inRow;
  	outputFileName += "_";
  	outputFileName += inCol;
  	outputFileName += "_";
  	outputFileName += inCh;
  	outputFileName += "_";
  	outputFileName += inputFileNameBase;
  	//outputFileName += ".root";
  	std::cout << " outputFileName " << outputFileName << std::endl;
  	outputFile = new TFile( outputFileName , "RECREATE");

	//initialize histograms
	initializeGlobalHistograms();

	//initialize tree branches
	data->setTreeBranches();

	//load pulse info into arrays
	data->selectPulsesForArray();

	//loop over selected events, apply corrections histogram pulse time distributions
	//monitor pulse time vs event #
  	gPulseTimeVsEventNum = new TGraphErrors();
  	for(int entry = 0; entry < data->numUsed; entry++) {
		//skip events not in arrays
  		if( entry >= maxNumEvt )
			continue;

		double pulseTime = data->measurePulseTimeArrayEntry(entry,1);
		double pulseHeight = data->adc_0_A[entry];
		int smpBinNumIn128Array = data->getSmpBinNumIn128Array(entry);
		double smpPos =	data->getSmpPos(entry);

		//apply analysis cuts
		//if( smpBinNumIn128Array >= 127 )
		//	continue;
		//measure pulse time vs event #
		gPulseTimeVsEventNum->SetPoint( gPulseTimeVsEventNum->GetN() , data->eventNum_A[entry],  pulseTime );
		//cut on event #
		if( data->eventNum_A[entry] < 0 )
			continue;

		//histogram selected pulse distributions
		hPulseHeightInitial->Fill( data->adc_0_A[entry] );
		hPulseTimeInitial->Fill( pulseTime );
		hPulseSampleInitial->Fill(data->smp_0_A[entry]);
       		hPulseSmp128Initial->Fill(smpBinNumIn128Array);
		hPulseTimeVsSmp128Initial->Fill(smpBinNumIn128Array, pulseTime );
		hPulseTimeVsSmp128PosInitial->Fill(smpBinNumIn128Array + smpPos, pulseTime );
		hPulseTimeVsHeightInitial->Fill(pulseHeight, pulseTime );
		hPulseTimeVsFTSWInitial->Fill(data->ftsw_A[entry], pulseTime );
   		hFTSWVsSmp128Initial->Fill(smpBinNumIn128Array, data->ftsw_A[entry]);
	}
	
	//loop over selected events, measure time difference between timing marker and selected channel pulses
	gTest = new TGraphErrors();
	data->measurePulseMarkerTimeDifferenceDistribution(hPulseTimeMarkTimeDiffInitial,hPulseTimeMarkTimeDiffVsMarkSmpBinNumInitial );

	//run fit analysis
	doDoublePulseFit(data);

	//write output file
	writeOutputFile();

	//delete target6 data object
	delete data;

	return 1;
}

//define histograms
int initializeGlobalHistograms(){
	
	hSampleTimes = new TH1F("hSampleTimes","",128,0,128);

	hPulseHeightInitial = new TH1F("hPulseHeightInitial","Pulse Height Distribution",1000,-50,1950.);
  	hPulseTimeInitial = new TH1F("hPulseTimeInitial","Pulse Time Distribution",50000,0,64*64*1./2.7515);
  	hPulseSampleInitial = new TH1F("hPulseSampleInitial","Pulse Sample Distribution",256,0,256);
  	hPulseSmp128Initial = new TH1F("hPulseSmp128Initial","Pulse Sample Distribution",128,0,128);
  	hPulseTimeVsSmp128Initial = new TH2F("hPulseTimeVsSmp128Initial","",128,0,128,2000,windowLow,windowHigh);
	hPulseTimeVsSmp128PosInitial = new TH2F("hPulseTimeVsSmp128PosInitial","",640,0,128,2000,windowLow,windowHigh);
  	hPulseTimeVsFTSWInitial = new TH2F("hPulseTimeVsFTSWInitial","",2100,0,2100,2000,windowLow,windowHigh);
  	hPulseTimeVsHeightInitial = new TH2F("hPulseTimeVsHeightInitial","Pulse Time Vs Height",400,10,1610,1000,windowLow,windowHigh);
  	hFTSWVsSmp128Initial  = new TH2F("hFTSWVsSmp128Initial","FTSW Vs Sample Bin Array #",128,0,128,2100,0,2100);

	hPulseTimeMarkTimeDiffInitial = new TH1F("hPulseTimeMarkTimeDiffInitial","Pulse and Timing Marker Time Difference",1000000,-64*64*1./2.7515,64*64*1./2.7515);
	hPulseTimeMarkTimeDiffVsMarkSmpBinNumInitial = new TH2F("hPulseTimeMarkTimeDiffVsMarkSmpBinNumInitial","",128,0,128,100000,-10,10.);

	//fitter histograms
	hFitter_PulseTimeDiff = new TH1F("hFitter_PulseTimeDiff","Pulse and Timing Marker Time Difference",1000000,-64*64*1./2.7515,64*64*1./2.7515);
	hFitter_PulseTimeDiffVsSmp128 = new TH2F("hFitter_PulseTimeDiffVsSmp128","",64,0,128,100000,-8,-4);
	gFitter = new TGraphErrors();
	hBinTimeDiffs = new TH1F("hBinTimeDiffs","",1000,-8,-4);
	hFitter_SampleWidths = new TH1F("hFitter_SampleWidths","Sample Widths (ns)",127,0,127);
	hFitter_Cov = new TH2F("hFitter_Cov","",127,0,127,127,0,127);
}

int writeOutputFile(){
	outputFile->cd();

	hSampleTimes->Write();

	hPulseHeightInitial->Write();
  	hPulseTimeInitial->Write();
  	hPulseSampleInitial->Write();
  	hPulseSmp128Initial->Write();
  	hPulseTimeVsSmp128Initial->Write();
	hPulseTimeVsSmp128PosInitial->Write();
  	hPulseTimeVsFTSWInitial->Write();
  	hPulseTimeVsHeightInitial->Write();
  	hFTSWVsSmp128Initial->Write();

	hPulseTimeMarkTimeDiffInitial->Write();
	hPulseTimeMarkTimeDiffVsMarkSmpBinNumInitial->Write();

	hFitter_SampleWidths->Write();
	hFitter_Cov->Write();

	gPulseTimeVsEventNum->Write("gPulseTimeVsEventNum");
	gTest->Write("gTest");
	outputFile->Close();
	return 1;
}

int doDoublePulseFit(topDataClass *in_data){
	//fitter histograms
	fitter_data = in_data;
	
	//initialize canvas
  	c0 = new TCanvas("c0", "c0",1300,800);

	//vary sample DTs until pulse widths are constant throughout array
  	TMinuit minimizer(127);
  	minimizer.SetFCN(fitFuncML);

  	//Minuit fit parameters - parameters # 0 to 128- 1
  	for( int i = 0; i < 127 ; i++ ){
  		char name[100]; memset(&name[0],0,sizeof(name) ); sprintf(name,"BinWidth_%i",i);
  		minimizer.DefineParameter(i, name, defaultSmpWidth, 0.25*defaultSmpWidth,0,0);
  	}
	
	//Set Minuit flags
  	Double_t arglist[10];
  	Int_t ierflg = 0;
  	arglist[0] = 0.5;
  	minimizer.mnexcm("SET ERR", arglist ,1,ierflg);
	
  	//MIGRAD minimization
  	Double_t tmp[1];
  	Int_t err;
  	tmp[0] = 50000;
  	minimizer.mnexcm("MIG", tmp ,1,err);
  	//minimizer.SetMaxIterations(10000);
  	//minimizer.Migrad();

	int status = minimizer.GetStatus();
  	Double_t parVal = 0;
  	Double_t parValErr = 0;
  	for(int i = 0 ; i < 127 ; i++ ){
		minimizer.GetParameter(i, parVal, parValErr);
		hFitter_SampleWidths->SetBinContent(i+1,parVal);
		hFitter_SampleWidths->SetBinError(i+1,parValErr);
  	}

  	Double_t covMatrix[127][127];
  	minimizer.mnemat(&covMatrix[0][0], 127);

  	hFitter_Cov = new TH2F("hFitter_Cov","",127,0,127,127,0,127);
  	for(int i = 0 ; i < 127 ; i++ ){
  	for(int j = 0 ; j < 127 ; j++ ){
		hFitter_Cov->SetBinContent( i+1,j+1,covMatrix[i][j] );
  	}
  	}
	
	return 1;
}

//Fit function - used by Minuit
static void fitFuncML(int& npar, double* gout, double& result, double par[], int flg){

	//load parameters into sample time arrays
	fitter_data->smp128StartTimes[0] = 0.;
	double widthTerm = 0;
  	for(int i = 1 ; i < 128 ; i++ ){
		fitter_data->smp128StartTimes[i] = fitter_data->smp128StartTimes[i-1] + par[i-1]; //ns
		hFitter_SampleWidths->SetBinContent(i, par[i-1]);
	
		widthTerm = widthTerm + ( par[i-1] - defaultSmpWidth )*( par[i-1] - defaultSmpWidth );
	}
	
	//measure pulse widths vs smp 128 for this set of sample widths, calculate ML of pulse widths
	fitter_data->measurePulseMarkerTimeDifferenceDistribution(hFitter_PulseTimeDiff, hFitter_PulseTimeDiffVsSmp128);

	//get slices from 2D histogram
  	int numBins = hFitter_PulseTimeDiffVsSmp128->GetNbinsX();
  	TH1D *hBins[numBins];
  	char name[100];
  	for( int b = 0 ; b < numBins ; b++ ){
		memset(name,0,sizeof(char)*100 );
		sprintf(name,"bin_%.2i",b);
		hBins[b] = hFitter_PulseTimeDiffVsSmp128->ProjectionY(name,b+1,b+1);
	}

	hBinTimeDiffs->Reset();
	int errCount = 0;
  	for( int b = 0 ; b < numBins ; b++ ){
		if( hBins[b]->GetEntries() < 100. ){
			if( errCount < 10 )
				std::cout << "Bin does not have enough entries, continue. Only flag first 10 instances of error." << std::endl;
			errCount++;
			continue;
		}
		double binVal = hFitter_PulseTimeDiffVsSmp128->GetBinCenter(b+1);
		double posMax = hBins[b]->GetBinCenter( hBins[b]->GetMaximumBin() );

		hBins[b]->GetXaxis()->SetRangeUser( posMax - 2.5, posMax + 2.5);
		hBinTimeDiffs->Fill( hBins[b]->GetMean(1) );
	}

	if(numSteps % 50 == 0){
		std::cout << "\tRMS term " << hBinTimeDiffs->GetRMS(1)*hBinTimeDiffs->GetRMS(1);
		std::cout << "\tWidth term " << widthTerm;
		std::cout << "\tOverall RMS " << hFitter_PulseTimeDiff->GetRMS();
		std::cout << std::endl;
		c0->Clear();
		c0->Divide(1,2);
		c0->cd(1);
		hFitter_PulseTimeDiffVsSmp128->Draw("COLZ");
		c0->cd(2);
		hFitter_SampleWidths->Draw();
		c0->Update();
	}
	numSteps++;

  	result = 0.5*hBinTimeDiffs->GetRMS(1)*hBinTimeDiffs->GetRMS(1)/(0.01)/(0.01) + 0.5*widthTerm/(0.05)/(0.05);
}
