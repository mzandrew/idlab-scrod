//compile with: g++ -o topDataClass_doAnalysis src/topDataClass_doAnalysis.cpp `root-config --cflags --glibs`

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
#include "topDataClass.h"
#include "topDataClass.cpp"

//global TApplication object declared here for simplicity
TApplication *theApp;

using namespace std;

//helper functions
int initializeGlobalHistograms();
int writeOutputFile();

//hardcoded constants relevant to laser data
//double windowTime = 1253;
double windowTime = 1240;
double windowLow = windowTime-10.;
double windowHigh = windowTime+10.;

//output file pointer
TFile* outputFile;

//histograms
TH1F *hPulseHeightAll;
TH1F *hPulseTimeAll;

TH1F *hPulseHeightCut;
TH1F *hPulseTimeCut;
TH1F *hPulseSampleCut;
TH1F *hPulseSmp128Cut;
TH2F *hPulseTimeVsSmp128Cut;
TH2F *hPulseTimeVsSmp128PosCut;
TH2F *hPulseTimeVsFTSWCut;
TH2F *hPulseTimeVsHeightCut;
TH2F *hFTSWVsSmp128Cut;

TH1F *hSampleTimes;
TH1F *hSampleWidths;
TH2F *hResidualPulseTimeVsSmpPos;
TH2F *hResidualMarkerTimeVsSmpPos;
TH2F *hResidualPulseTimeVsHeight;

TH1F *hPulseHeightFinal;
TH1F *hPulseTimeFinal;
TH1F *hPulseSampleFinal;
TH1F *hPulseSmp128Final;
TH2F *hPulseTimeVsSmp128Final;
TH2F *hPulseTimeVsSmp128PosFinal;
TH2F *hPulseTimeVsFTSWFinal;
TH2F *hPulseTimeVsHeightFinal;
TH2F *hFTSWVsSmp128Final;
TH2F *hResidualPulseTimeVsSmpPosFinal;
TH2F *hPulseTimeVsFirstWindowFinal;

TH1F *hPulseTimeMarkTimeDiffFinal;
TH2F *hPulseTimeMarkTimeDiffVsMarkSmpBinNumFinal;
TH2F *hPulseTimeMarkTimeDiffVsMarkSmpBinNumVsSmpBinNumFinal;

TGraphErrors *gPulseTimeVsFTSW;
TGraphErrors *gPulseTimeVsHeight;
TGraphErrors *gPulseTimeVsSmp128Index;
TGraphErrors *gPulseTimeVsSmp128Pos;
TGraphErrors *gResidualPulseTimeVsSmpPos;
TGraphErrors *gResidualMarkerTimeVsSmpPos;
TGraphErrors *gPulseTimeVsEventNum;
TGraphErrors *gPulseTimeResVsSmp128Index;
TGraphErrors *gPulseTimeResVsHeight;
TGraphErrors *gTest;

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
	data->setTimingMarkerChannel( 0, 2, 0, 2 );

	//specify time window
	data->windowTime = windowTime;

	//open summary tree file
	data->openSummaryTree(inputFileName);

	//create output file
  	TObjArray* strings = inputFileName.Tokenize("/");
  	TObjString* objstring = (TObjString*) strings->At(strings->GetLast());
  	TString inputFileNameBase(objstring->GetString());
	TString outputFileName = "output_topDataClass_doAnalysis_";
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

	//make basic overall distributions
	data->getOverallDistributions(hPulseHeightAll, hPulseTimeAll);

	//load pulse info into arrays
	data->selectPulsesForArray();

	//loop over selected events, histogram selected pulse time distributions
  	for(int entry = 0; entry < data->numUsed; entry++) {
		//skip events not in arrays
  		if( entry >= maxNumEvt )
			continue;

		double pulseTime = data->measurePulseTimeArrayEntry(entry,1);
		double pulseHeight = data->adc_0_A[entry];
		int smpBinNumIn128Array = data->getSmpBinNumIn128Array(entry);
		double smpPos =	data->getSmpPos(entry);
	
		//for calibration purposes, cut on pulse height
		if( 0 && pulseHeight < 100 ) continue;
	
		//histogram selected pulse distributions
		hPulseHeightCut->Fill( data->adc_0_A[entry] );
		hPulseTimeCut->Fill( pulseTime );
		hPulseSampleCut->Fill(data->smp_0_A[entry]);
       		hPulseSmp128Cut->Fill(smpBinNumIn128Array);
		hPulseTimeVsSmp128Cut->Fill(smpBinNumIn128Array, pulseTime );
		hPulseTimeVsSmp128PosCut->Fill(smpBinNumIn128Array + smpPos, pulseTime );
		hPulseTimeVsHeightCut->Fill(pulseHeight, pulseTime );
		hPulseTimeVsFTSWCut->Fill(data->ftsw_A[entry], pulseTime );
   		hFTSWVsSmp128Cut->Fill(smpBinNumIn128Array, data->ftsw_A[entry]);
  	}

	//parameterize pulse time as a function of different variables
	gPulseTimeVsFTSW = new TGraphErrors();
	data->makeCorrectionGraph(hPulseTimeVsFTSWCut, gPulseTimeVsFTSW, 0, 25, 2, 0.5);
	gPulseTimeVsSmp128Index = new TGraphErrors();
	data->makeCorrectionGraph(hPulseTimeVsSmp128Cut, gPulseTimeVsSmp128Index, 0, 25, 2, 0.5);
	gPulseTimeVsSmp128Pos = new TGraphErrors();
	data->makeCorrectionGraph(hPulseTimeVsSmp128PosCut, gPulseTimeVsSmp128Pos, 0, 25, 2, 0.2);

	//use pulse time vs sample index to measure sample-DTs
  	double time0 = gPulseTimeVsSmp128Index->Eval(0+0.5,0,"");
  	for(int i = 0 ; i < gPulseTimeVsSmp128Index->GetN() ; i++ ){
		double smpTime = gPulseTimeVsSmp128Index->Eval(i+0.5,0,"");
		data->smp128StartTimes[i] = data->smp128StartTimes[i] - ( smpTime - time0 );
		hSampleTimes->SetBinContent(i, data->smp128StartTimes[i] );
		if( i > 0)
			hSampleWidths->SetBinContent(i, data->smp128StartTimes[i] - data->smp128StartTimes[i-1] );
  	}

	//loop over selected events, histogram residual distributions
  	for(int entry = 0; entry < data->numUsed; entry++) {
		//skip events not in arrays
  		if( entry >= maxNumEvt )
			continue;

		double pulseTime = data->measurePulseTimeArrayEntry(entry,1);
		double pulseHeight = data->adc_0_A[entry];
		int smpBinNumIn128Array = data->getSmpBinNumIn128Array(entry);
		double smpPos =	data->getSmpPos(entry);
	
		//for calibration purposes, cut on pulse height
		if( 0 && pulseHeight < 100 ) continue;

		//apply cuts to make sample position dependence clearer
		//Cut on ends of FTSW range
		if( data->ftsw_A[entry] < 650 || data->ftsw_A[entry] > 1650 )
			continue;
		//cut on sample #
		if( smpBinNumIn128Array >= 126 )
			continue;
	
		//histogram selected pulse distributions
		hResidualPulseTimeVsSmpPos->Fill( (smpBinNumIn128Array % 2) + smpPos , pulseTime );

		double markerTime = data->measureMarkerTimeArrayEntry(entry,1);
		double markerSmpPos = data->getMarkerSmpPos(entry);
		int markerSmpBinNum = data->getMarkerSmpBinNumIn128Array(entry);
		hResidualMarkerTimeVsSmpPos->Fill( (markerSmpBinNum % 2) + markerSmpPos , markerTime );
		hResidualPulseTimeVsHeight->Fill(pulseHeight, pulseTime );
  	}

	//parameterize pulse time as a function of sample position
	gResidualPulseTimeVsSmpPos = new TGraphErrors();
	data->makeCorrectionGraph(hResidualPulseTimeVsSmpPos, gResidualPulseTimeVsSmpPos, 0, 25, 2, 0.2);
	gResidualMarkerTimeVsSmpPos = new TGraphErrors();
	data->makeCorrectionGraph(hResidualMarkerTimeVsSmpPos, gResidualMarkerTimeVsSmpPos, 0, 25, 2, 0.2);

	gPulseTimeVsHeight = new TGraphErrors();
	data->makeCorrectionGraph(hResidualPulseTimeVsHeight, gPulseTimeVsHeight, 0, 25, 2, 0.2);
	
	//loop over selected events, apply corrections histogram pulse time distributions
	//monitor pulse time vs event #
  	gPulseTimeVsEventNum = new TGraphErrors();
	gTest = new TGraphErrors();
  	for(int entry = 0; entry < data->numUsed; entry++) {
		//skip events not in arrays
  		if( entry >= maxNumEvt )
			continue;

		double pulseTime = data->measurePulseTimeArrayEntry(entry,1);
		double pulseHeight = data->adc_0_A[entry];
		int smpBinNumIn128Array = data->getSmpBinNumIn128Array(entry);
		double smpPos =	data->getSmpPos(entry);

		//apply sample position correction
       		//double smpPosCorr = gPulseTimeVsSmp128Pos->Eval( smpPosIn128Array + smpPos ,0,"");
    		//pulseTime = pulseTime - smpPosCorr + windowLow + (windowHigh - windowLow)/2.;
		double smpPosCorr = gResidualPulseTimeVsSmpPos->Eval( (smpBinNumIn128Array % 2) + smpPos ,0,"");
    		//pulseTime = pulseTime - smpPosCorr + windowLow + (windowHigh - windowLow)/2.;
		//FTSW correction
		//double ftswPosCorr = gPulseTimeVsFTSW->Eval( data->ftsw_A[entry] ,0,"");
		//pulseTime = pulseTime - ftswPosCorr + windowLow + (windowHigh - windowLow)/2.;
		//timewalk correction
		double timewalkCorr = gPulseTimeVsHeight->Eval( pulseHeight ,0,"");
		pulseTime = pulseTime - timewalkCorr + windowLow + (windowHigh - windowLow)/2.;

		//apply analysis cuts
		//Cut on ends of FTSW range
		if( data->ftsw_A[entry] < 650 || data->ftsw_A[entry] > 1650 )
			continue;
		//cut on sample #
		if( smpBinNumIn128Array >= 127 )
			continue;
		//measure pulse time vs event #
		gPulseTimeVsEventNum->SetPoint( gPulseTimeVsEventNum->GetN() , data->eventNum_A[entry],  pulseTime );
		//cut on event #
		if( data->eventNum_A[entry] < 0 )
			continue;

		//histogram selected pulse distributions
		hPulseHeightFinal->Fill( data->adc_0_A[entry] );
		hPulseTimeFinal->Fill( pulseTime );
		hPulseSampleFinal->Fill(data->smp_0_A[entry]);
       		hPulseSmp128Final->Fill(smpBinNumIn128Array);
		hPulseTimeVsSmp128Final->Fill(smpBinNumIn128Array, pulseTime );
		hPulseTimeVsSmp128PosFinal->Fill(smpBinNumIn128Array + smpPos, pulseTime );
		hPulseTimeVsHeightFinal->Fill(pulseHeight, pulseTime );
		hPulseTimeVsFTSWFinal->Fill(data->ftsw_A[entry], pulseTime );
   		hFTSWVsSmp128Final->Fill(smpBinNumIn128Array, data->ftsw_A[entry]);
		hResidualPulseTimeVsSmpPosFinal->Fill( (smpBinNumIn128Array % 2) + smpPos , pulseTime );
		hPulseTimeVsFirstWindowFinal->Fill( data->first_0_A[entry] , pulseTime );

		if( smpBinNumIn128Array == 10 )
			gTest->SetPoint( gTest->GetN() , data->ftsw_A[entry] , pulseTime );

		//get timing marker
		double pulseTimeNoFTSWTDCCorr = data->measurePulseTimeArrayEntry(entry,0);
		double markerTime = data->measureMarkerTimeArrayEntry(entry,0);
		double markerSmpPos = data->getMarkerSmpPos(entry);
		int markerSmpBinNum = data->getMarkerSmpBinNumIn128Array(entry);
		double markerPosCorr = gResidualMarkerTimeVsSmpPos->Eval( (markerSmpBinNum % 2) + markerSmpPos ,0,"");
		//if(smpBinNumIn128Array == 41){
		if(1){
			//hPulseTimeMarkTimeDiffFinal->Fill( (pulseTimeNoFTSWTDCCorr - smpPosCorr) - (markerTime - markerPosCorr) );
			hPulseTimeMarkTimeDiffFinal->Fill( (pulseTimeNoFTSWTDCCorr - timewalkCorr ) - (markerTime) );
			//gTest->SetPoint( gTest->GetN() , markerTime - markerPosCorr , pulseTimeNoFTSWTDCCorr - smpPosCorr );
		}

		hPulseTimeMarkTimeDiffVsMarkSmpBinNumFinal->Fill( markerSmpBinNum , (pulseTimeNoFTSWTDCCorr - timewalkCorr ) - (markerTime ) );
		//hPulseTimeMarkTimeDiffVsMarkSmpBinNumFinal->Fill( smpBinNumIn128Array , (pulseTimeNoFTSWTDCCorr - smpPosCorr) - (markerTime - markerPosCorr) );
		hPulseTimeMarkTimeDiffVsMarkSmpBinNumVsSmpBinNumFinal->Fill( smpBinNumIn128Array , markerSmpBinNum
			 , (pulseTimeNoFTSWTDCCorr - timewalkCorr) - (markerTime) );
	}

	//parameterize pulse time resolution as function of sample #
	gPulseTimeResVsSmp128Index = new TGraphErrors();
	data->makeCorrectionGraph(hPulseTimeVsSmp128Final, gPulseTimeResVsSmp128Index, 1, 25, 2, 0.2);

	gPulseTimeResVsHeight = new TGraphErrors();
	data->makeCorrectionGraph(hPulseTimeVsHeightFinal, gPulseTimeResVsHeight, 1, 25, 2, 0.2);

	//write output file
	writeOutputFile();

	//delete target6 data object
	delete data;

	return 1;
}

//define histograms
int initializeGlobalHistograms(){
	hPulseHeightAll = new TH1F("hPulseHeightAll","Pulse Height Distribution",1000,-50,1950.);
  	hPulseTimeAll = new TH1F("hPulseTimeAll","Pulse Time Distribution",50000,0,64*64*1./2.7515);

	hPulseHeightCut = new TH1F("hPulseHeightCut","Pulse Height Distribution",1000,-50,1950.);
  	hPulseTimeCut = new TH1F("hPulseTimeCut","Pulse Time Distribution",50000,0,64*64*1./2.7515);
  	hPulseSampleCut = new TH1F("hPulseSampleCut","Pulse Sample Distribution",256,0,256);
  	hPulseSmp128Cut = new TH1F("hPulseSmp128Cut","Pulse Sample Distribution",128,0,128);
  	hPulseTimeVsSmp128Cut = new TH2F("hPulseTimeVsSmp128Cut","",128,0,128,1000,windowLow,windowHigh);
	hPulseTimeVsSmp128PosCut = new TH2F("hPulseTimeVsSmp128PosCut","",640,0,128,1000,windowLow,windowHigh);
  	hPulseTimeVsFTSWCut = new TH2F("hPulseTimeVsFTSWCut","",2100,0,2100,2000,windowLow,windowHigh);
  	hPulseTimeVsHeightCut = new TH2F("hPulseTimeVsHeightCut","Pulse Time Vs Height",20,10,1610,400,windowLow,windowHigh);
  	hFTSWVsSmp128Cut  = new TH2F("hFTSWVsSmp128Cut","FTSW Vs Sample Bin Array #",128,0,128,2100,0,2100);
	
	hSampleTimes = new TH1F("hSampleTimes","",128,0,128);
	hSampleWidths = new TH1F("hSampleWidths","",128,0,128);

	hResidualPulseTimeVsSmpPos = new TH2F("hResidualPulseTimeVsSmpPos","Pulse Time Vs Residual Sample Position (Index Mod 2)",40,0,2,1000,windowLow,windowHigh);
	hResidualMarkerTimeVsSmpPos = new TH2F("hResidualMarkerTimeVsSmpPos","Marker Time Vs Residual Sample Position (Index Mod 2)",40,0,2,1000,windowLow,windowHigh);
	hResidualPulseTimeVsHeight = new TH2F("hResidualPulseTimeVsHeight","Pulse Time Vs Height",20,10,1610,400,windowLow,windowHigh);

	hPulseHeightFinal = new TH1F("hPulseHeightFinal","Pulse Height Distribution",1000,-50,1950.);
  	hPulseTimeFinal = new TH1F("hPulseTimeFinal","Pulse Time Distribution",50000,0,64*64*1./2.7515);
  	hPulseSampleFinal = new TH1F("hPulseSampleFinal","Pulse Sample Distribution",256,0,256);
  	hPulseSmp128Final = new TH1F("hPulseSmp128Final","Pulse Sample Distribution",128,0,128);
  	hPulseTimeVsSmp128Final = new TH2F("hPulseTimeVsSmp128Final","",128,0,128,1000,windowLow,windowHigh);
	hPulseTimeVsSmp128PosFinal = new TH2F("hPulseTimeVsSmp128PosFinal","",640,0,128,1000,windowLow,windowHigh);
  	hPulseTimeVsFTSWFinal = new TH2F("hPulseTimeVsFTSWFinal","",2100,0,2100,2000,windowLow,windowHigh);
  	hPulseTimeVsHeightFinal = new TH2F("hPulseTimeVsHeightFinal","Pulse Time Vs Height",400,10,1610,1000,windowLow,windowHigh);
  	hFTSWVsSmp128Final  = new TH2F("hFTSWVsSmp128Final","FTSW Vs Sample Bin Array #",128,0,128,2100,0,2100);
	hResidualPulseTimeVsSmpPosFinal = new TH2F("hResidualPulseTimeVsSmpPosFinal","Pulse Time Vs Residual Sample Position (Index Mod 2)",40,0,2,1000,windowLow,windowHigh);
	hPulseTimeVsFirstWindowFinal = new TH2F("hPulseTimeVsFirstWindowFinal","Pulse Time Vs First Window #",64,0,64,1000,windowLow,windowHigh);

	hPulseTimeMarkTimeDiffFinal = new TH1F("hPulseTimeMarkTimeDiffFinal","Pulse and Timing Marker Time Difference",1000000,-64*64*1./2.7515,64*64*1./2.7515);
	hPulseTimeMarkTimeDiffVsMarkSmpBinNumFinal = new TH2F("hPulseTimeMarkTimeDiffVsMarkSmpBinNumFinal","",128,0,128,10000,-1100,-1000.);
	hPulseTimeMarkTimeDiffVsMarkSmpBinNumVsSmpBinNumFinal = new TH2F("hPulseTimeMarkTimeDiffVsMarkSmpBinNumVsSmpBinNumFinal","",128,0,128,128,0,128);
}

int writeOutputFile(){
	outputFile->cd();

	hPulseHeightAll->Write();
	hPulseTimeAll->Write();

	hPulseHeightCut->Write();
  	hPulseTimeCut->Write();
  	hPulseSampleCut->Write();
  	hPulseSmp128Cut->Write();
  	hPulseTimeVsSmp128Cut->Write();
	hPulseTimeVsSmp128PosCut->Write();
  	hPulseTimeVsFTSWCut->Write();
  	hPulseTimeVsHeightCut->Write();
  	hFTSWVsSmp128Cut->Write();

	hSampleTimes->Write();
	hSampleWidths->Write();

	hResidualPulseTimeVsSmpPos->Write();
	hResidualMarkerTimeVsSmpPos->Write();
	hResidualPulseTimeVsHeight->Write();

	hPulseHeightFinal->Write();
  	hPulseTimeFinal->Write();
  	hPulseSampleFinal->Write();
  	hPulseSmp128Final->Write();
  	hPulseTimeVsSmp128Final->Write();
	hPulseTimeVsSmp128PosFinal->Write();
  	hPulseTimeVsFTSWFinal->Write();
  	hPulseTimeVsHeightFinal->Write();
  	hFTSWVsSmp128Final->Write();
	hResidualPulseTimeVsSmpPosFinal->Write();
	hPulseTimeVsFirstWindowFinal->Write();

	hPulseTimeMarkTimeDiffFinal->Write();
	hPulseTimeMarkTimeDiffVsMarkSmpBinNumFinal->Write();
	hPulseTimeMarkTimeDiffVsMarkSmpBinNumVsSmpBinNumFinal->Write();

	gPulseTimeVsFTSW->Write("gPulseTimeVsFTSW");
	gPulseTimeVsSmp128Index->Write("gPulseTimeVsSmp128Index");
	gPulseTimeVsSmp128Pos->Write("gPulseTimeVsSmp128Pos");
	gPulseTimeVsHeight->Write("gPulseTimeVsHeight");
	gResidualPulseTimeVsSmpPos->Write("gResidualPulseTimeVsSmpPos");
	gResidualMarkerTimeVsSmpPos->Write("gResidualMarkerTimeVsSmpPos");
	gPulseTimeVsEventNum->Write("gPulseTimeVsEventNum");
	gPulseTimeResVsSmp128Index->Write("gPulseTimeResVsSmp128Index");
	gPulseTimeResVsHeight->Write("gPulseTimeResVsHeight");
	gTest->Write("gTest");
	outputFile->Close();
	return 1;
}

