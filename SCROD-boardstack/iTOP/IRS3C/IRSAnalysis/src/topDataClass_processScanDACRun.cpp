//compile with: g++ -o topDataClass_processScanDACRun src/topDataClass_processScanDACRun.cpp `root-config --cflags --glibs`
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

using namespace std;

//global TApplication object declared here for simplicity
TApplication *theApp;

//helper functions
int initializeGlobalHistograms();
int writeOutputFile();
int getDistributions(topDataClass *data);
int processDistributions();
double getWidth(TH1F *hist, double range);
double getMeanWidths(TH2F *hist, double range);

//hardcoded constants relevant to window
double windowTime = 1296.;
double windowLow = windowTime - 10.;
double windowHigh = windowTime + 10.;

//output file pointer
TFile* outputFile;

//histograms
TH1F *hPulseHeightAll;
TH1F *hPulseTimeAll;
TH1F *hPulseWidthAll;
TH1F *hPulseWidthSameWinAll;
TH1F *hPulseWidthDiffWinAll;
TH1F *hNHitAll;
TH2F *hNumPulsePMTArray;

TH1F *hPulseHeightAsic[NMODS][NROWS][NCOLS];
TH1F *hPulseTimeAsic[NMODS][NROWS][NCOLS];
TH1F *hPulseWidthSameWinAsic[NMODS][NROWS][NCOLS];
TH1F *hPulseWidthDiffWinAsic[NMODS][NROWS][NCOLS];
TH2F *hPulseHeightVsSmp256Asic[NMODS][NROWS][NCOLS];
TH2F *hPulseWidthSameVsSmp256Asic[NMODS][NROWS][NCOLS];
TH2F *hPulseWidthDiffVsSmp256Asic[NMODS][NROWS][NCOLS];
TH2F *hPulseWidthVsHeightAsic[NMODS][NROWS][NCOLS];

int hNumPulseGood[NMODS][NROWS][NCOLS][NCHS];
int hNumPulseBad[NMODS][NROWS][NCOLS][NCHS];
TH1F *hPulseBaseCh[NMODS][NROWS][NCOLS][NCHS];
TH1F *hPulseHeightCh[NMODS][NROWS][NCOLS][NCHS];
TH1F *hPulseTimeCh[NMODS][NROWS][NCOLS][NCHS];
TH1F *hPulseWidthSameWinCh[NMODS][NROWS][NCOLS][NCHS];
TH1F *hPulseWidthDiffWinCh[NMODS][NROWS][NCOLS][NCHS];
TH2F *hPulseTimeVsSmpCh[NMODS][NROWS][NCOLS][NCHS];

TGraphErrors *gTest;

//global variables
TTree* MetaDataTree;
Int_t treeReg;
Int_t treeDAC;
Int_t treeMod;
Int_t treeRow;
Int_t treeCol;
Int_t treeCh;
Float_t treeTimeRes;
Float_t treeTimeResSmpMean;
Float_t treeHeightMean;
Float_t treeHeightRMS;
Float_t treeFailRate;
Float_t treeTimeOffset;

int main(int argc, char* argv[]){
	if (argc != 4){
    		std::cout << "topDataClass_processScanDACRun - wrong number of arguments: usage ./topDataClass_processScanDACRun <file name> <register> <DAC>" << std::endl;
    		return 0;
  	}

	//define application object
	theApp = new TApplication("App", &argc, argv);
	TString inputFileName = theApp->Argv()[1];
	std::cout << "Input file name "  << inputFileName << std::endl;

	//specify scanned DAC
	int inReg = atoi(theApp->Argv()[2]);
	int inDAC = atoi(theApp->Argv()[3]);

	if( inReg < 0 || inReg > 600 || inDAC < 0 || inDAC > 100000 ){
    		std::cout << "topDataClass_processScanDACRun - register/DAC arguments out of range" << std::endl;
    		return 0;
  	}
	treeReg = inReg;
	treeDAC = inDAC;

	//create target6 interface object
	topDataClass *data = new topDataClass();

	//open summary tree file
	data->openSummaryTree(inputFileName);

	//create output file
  	TObjArray* strings = inputFileName.Tokenize("/");
  	TObjString* objstring = (TObjString*) strings->At(strings->GetLast());
  	TString inputFileNameBase(objstring->GetString());
	TString outputFileName = "output_processScanDACRun_";
	outputFileName += inReg;
  	outputFileName += "_";
  	outputFileName += inDAC;
  	outputFileName += "_";
  	outputFileName += inputFileNameBase;
  	//outputFileName += ".root";
  	std::cout << " outputFileName " << outputFileName << std::endl;
  	outputFile = new TFile( outputFileName , "RECREATE");

	//initialize histograms
	initializeGlobalHistograms();

	//initialize tree branches
	data->setTreeBranches();

	//get overall distributions
	getDistributions(data);

	//process distribution
	processDistributions();

	//write output file
	writeOutputFile();

	//delete target6 data object
	delete data;

	return 1;
}

//define histograms
int initializeGlobalHistograms(){
	hPulseHeightAll = new TH1F("hPulseHeightAll","Pulse Height Distribution - All",1000,-50,1950.);
  	hPulseTimeAll = new TH1F("hPulseTimeAll","Pulse Time Distribution",10000,-64*64*1./2.7515,64*64*1./2.7515);
	hPulseWidthAll = new TH1F("hPulseWidthAll","Pulse Width Distribution",3000,-150,150.);
	hPulseWidthSameWinAll = new TH1F("hPulseWidthSameWinAll","Pulse Width Same Window Distribution",3000,-150,150.);
	hPulseWidthDiffWinAll = new TH1F("hPulseWidthDiffWinAll","Pulse Width Different Window Distribution",3000,-150,150.);
	hNHitAll = new TH1F("hNHitAll","Number of Hits (all) per Event",512,0.,512.);

	hNumPulsePMTArray = new TH2F("hNumPulsePMTArray","Number of Pulses - Looking Towards PMTs from Quartz",64,0,64,8,0,8);
	hNumPulsePMTArray->GetXaxis()->SetTitle("PMT Channel Column #");
	hNumPulsePMTArray->GetYaxis()->SetTitle("PMT Channel Row #");

	char name[100];
  	char title[200];
	for(int m = 0 ; m < NMODS ; m++ )
	for(int r = 0 ; r < NROWS ; r++ )
    	for(int c = 0 ; c < NCOLS ; c++ ){
		memset(name,0,sizeof(char)*100 );
		memset(title,0,sizeof(char)*200 );
		sprintf(name,"hPulseHeightAsic_%.2i_%.2i_%.2i",m,r,c);
		sprintf(title,"Pulse Heights");
		hPulseHeightAsic[m][r][c] = new TH1F(name,title,200,-50,1950.);

		memset(name,0,sizeof(char)*100 );
		memset(title,0,sizeof(char)*200 );
		sprintf(name,"hPulseTimeAsic_%.2i_%.2i_%.2i",m,r,c);
		sprintf(title,"Pulse Times %.2i %.2i %.2i",m,r,c);
		hPulseTimeAsic[m][r][c] = new TH1F(name,title,200,windowLow,windowHigh);

		memset(name,0,sizeof(char)*100 );
		memset(title,0,sizeof(char)*200 );
		sprintf(name,"hPulseWidthSameWinAsic_%.2i_%.2i_%.2i",m,r,c);
		sprintf(title,"Pulse Widths");
		hPulseWidthSameWinAsic[m][r][c] = new TH1F(name,title,300,-150,150.);

		memset(name,0,sizeof(char)*100 );
		memset(title,0,sizeof(char)*200 );
		sprintf(name,"hPulseWidthDiffWinAsic_%.2i_%.2i_%.2i",m,r,c);
		sprintf(title,"Pulse Widths");
		hPulseWidthDiffWinAsic[m][r][c] = new TH1F(name,title,300,-150,150.);

		memset(name,0,sizeof(char)*100 );
		memset(title,0,sizeof(char)*200 );
		sprintf(name,"hPulseHeightVsSmp256Asic_%.2i_%.2i_%.2i",m,r,c);
		sprintf(title,"Pulse Heights Vs Sample Bin #");
		hPulseHeightVsSmp256Asic[m][r][c] = new TH2F(name,title,256,0,256,200,-50,1950.);

		memset(name,0,sizeof(char)*100 );
		memset(title,0,sizeof(char)*200 );
		sprintf(name,"hPulseWidthVsHeightAsic_%.2i_%.2i_%.2i",m,r,c);
		sprintf(title,"Pulse Width Vs Height");
		hPulseWidthVsHeightAsic[m][r][c] = new TH2F(name,title,200,-50,1950.,300,0,30.);

		memset(name,0,sizeof(char)*100 );
		memset(title,0,sizeof(char)*200 );
		sprintf(name,"hPulseWidthSameVsSmp256Asic_%.2i_%.2i_%.2i",m,r,c);
		sprintf(title,"Pulse Width Vs Sample Bin #");
		hPulseWidthSameVsSmp256Asic[m][r][c] = new TH2F(name,title,256,0,256,300,0,30.);
	
		memset(name,0,sizeof(char)*100 );
		memset(title,0,sizeof(char)*200 );
		sprintf(name,"hPulseWidthDiffVsSmp256Asic_%.2i_%.2i_%.2i",m,r,c);
		sprintf(title,"Pulse Width Vs Sample Bin #");
		hPulseWidthDiffVsSmp256Asic[m][r][c] = new TH2F(name,title,256,0,256,300,0,30.);
	}

	for(int m = 0 ; m < NMODS ; m++ )
  	for(int r = 0 ; r < NROWS ; r++ )
  	for(int c = 0 ; c < NCOLS ; c++ )
  	for(int ch = 0 ; ch < NCHS ; ch++ ){
		memset(name,0,sizeof(char)*100 );
		memset(title,0,sizeof(char)*200 );
		sprintf(name,"hPulseHeightCh_%.2i_%.2i_%.2i_%.2i",m,r,c,ch);
		sprintf(title,"Pulse Heights");
		hPulseHeightCh[m][r][c][ch] = new TH1F(name,title,200,-50,1950.);

		memset(name,0,sizeof(char)*100 );
		memset(title,0,sizeof(char)*200 );
		sprintf(name,"hPulseTimeCh_%.2i_%.2i_%.2i_%.2i",m,r,c,ch);
		sprintf(title,"Pulse Times");
		hPulseTimeCh[m][r][c][ch] = new TH1F(name,title,200,windowLow,windowHigh);

		memset(name,0,sizeof(char)*100 );
		memset(title,0,sizeof(char)*200 );
		sprintf(name,"hPulseBaseCh_%.2i_%.2i_%.2i_%.2i",m,r,c,ch);
		sprintf(title,"Baselines");
		hPulseBaseCh[m][r][c][ch] = new TH1F(name,title,200,-100.,100.);

		memset(name,0,sizeof(char)*100 );
		memset(title,0,sizeof(char)*200 );
		sprintf(name,"hPulseWidthSameWinCh_%.2i_%.2i_%.2i_%.2i",m,r,c,ch);
		sprintf(title,"Pulse Widths");
		hPulseWidthSameWinCh[m][r][c][ch] = new TH1F(name,title,300,-150,150.);

		memset(name,0,sizeof(char)*100 );
		memset(title,0,sizeof(char)*200 );
		sprintf(name,"hPulseWidthDiffWinCh_%.2i_%.2i_%.2i_%.2i",m,r,c,ch);
		sprintf(title,"Pulse Widths");
		hPulseWidthDiffWinCh[m][r][c][ch] = new TH1F(name,title,300,-150,150.);

		memset(name,0,sizeof(char)*100 );
		memset(title,0,sizeof(char)*200 );
		sprintf(name,"hPulseTimeVsSmpCh_%.2i_%.2i_%.2i_%.2i",m,r,c,ch);
		sprintf(title,"Pulse Times Vs Sample Bin #");
		hPulseTimeVsSmpCh[m][r][c][ch] = new TH2F(name,title,128,0,128,200,windowLow,windowHigh);

		hNumPulseGood[m][r][c][ch] = 0;
		hNumPulseBad[m][r][c][ch] = 0;
	}

	MetaDataTree = new TTree("MetaData", "metadata");  
        MetaDataTree->Branch("reg", &treeReg, "treeReg/I");
        MetaDataTree->Branch("DAC", &treeDAC, "treeDAC/I");
        MetaDataTree->Branch("mod", &treeMod, "treeMod/I");   
        MetaDataTree->Branch("row", &treeRow, "treeRow/I");
        MetaDataTree->Branch("col", &treeCol, "treeCol/I");
        MetaDataTree->Branch("ch", &treeCh, "treeCh/I");
        MetaDataTree->Branch("timeRes", &treeTimeRes, "treeTimeRes/F");
	MetaDataTree->Branch("timeResSmpMean", &treeTimeResSmpMean, "treeTimeResSmpMean/F");
	MetaDataTree->Branch("heightMean", &treeHeightMean, "treeHeightMean/F");
	MetaDataTree->Branch("heightRMS", &treeHeightRMS, "treeHeightRMS/F");
	MetaDataTree->Branch("failRate", &treeFailRate, "treeFailRate/F");
	MetaDataTree->Branch("timeOffset", &treeTimeOffset, "treeTimeOffset/F");    
}

int writeOutputFile(){
	outputFile->cd();

	MetaDataTree->Write();

	hPulseHeightAll->Write();
	hPulseTimeAll->Write();
	hNHitAll->Write();
	hPulseWidthAll->Write();
	hPulseWidthSameWinAll->Write();
	hPulseWidthDiffWinAll->Write();
	hNumPulsePMTArray->Write();
	hNumPulsePMTArray->SetStats(kFALSE);

	/*
	TCanvas *cTimeAsic = new TCanvas("cTimeAsic","");
	cTimeAsic->Clear();
	cTimeAsic->Divide(8,8);
	for(int m = 0 ; m < NMODS ; m++ )
    	for(int r = 0 ; r < NROWS ; r++ )
    	for(int c = 0 ; c < NCOLS ; c++ )
	{
		cTimeAsic->cd(c+4*r+16*m+1);
		hPulseTimeAsic[m][r][c]->Draw();
	}
	cTimeAsic->Update();
	cTimeAsic->Write();
	*/

	outputFile->mkdir("hPulseHeightAsic");
	outputFile->cd("hPulseHeightAsic");
	for(int m = 0 ; m < NMODS ; m++ )
	for(int r = 0 ; r < NROWS ; r++ )	
	for(int c = 0 ; c < NCOLS ; c++ ){
		if(  hPulseHeightAsic[m][r][c]->GetEntries() > 0 )
	    		hPulseHeightAsic[m][r][c]->Write();
    	}

	outputFile->mkdir("hPulseTimeAsic");
	outputFile->cd("hPulseTimeAsic");
	for(int m = 0 ; m < NMODS ; m++ )
	for(int r = 0 ; r < NROWS ; r++ )	
	for(int c = 0 ; c < NCOLS ; c++ ){
		if(  hPulseTimeAsic[m][r][c]->GetEntries() > 0 )
	    		hPulseTimeAsic[m][r][c]->Write();
    	}

    	outputFile->mkdir("hPulseWidthAsic");
    	outputFile->cd("hPulseWidthAsic");
    	for(int m = 0 ; m < NMODS ; m++ )
    	for(int r = 0 ; r < NROWS ; r++ )
    	for(int c = 0 ; c < NCOLS ; c++ )
	{
	    if(  hPulseWidthSameWinAsic[m][r][c]->GetEntries() > 0 )
	        hPulseWidthSameWinAsic[m][r][c]->Write();
	    if(  hPulseWidthDiffWinAsic[m][r][c]->GetEntries() > 0 )
		hPulseWidthDiffWinAsic[m][r][c]->Write();
	}

    	outputFile->mkdir("hPulseHeightVsSmp256Asic");
    	outputFile->cd("hPulseHeightVsSmp256Asic");
    	for(int m = 0 ; m < NMODS ; m++ )
    	for(int r = 0 ; r < NROWS ; r++ )
    	for(int c = 0 ; c < NCOLS ; c++ )
		if(  hPulseHeightVsSmp256Asic[m][r][c]->GetEntries() > 0 )
	    		hPulseHeightVsSmp256Asic[m][r][c]->Write();

	outputFile->mkdir("hPulseWidthVsSmp256Asic");
    	outputFile->cd("hPulseWidthVsSmp256Asic");
    	for(int m = 0 ; m < NMODS ; m++ )
    	for(int r = 0 ; r < NROWS ; r++ )
    	for(int c = 0 ; c < NCOLS ; c++ ){
		if(  hPulseWidthSameVsSmp256Asic[m][r][c]->GetEntries() > 0 )
	    		hPulseWidthSameVsSmp256Asic[m][r][c]->Write();
		if(  hPulseWidthDiffVsSmp256Asic[m][r][c]->GetEntries() > 0 )
	    		hPulseWidthDiffVsSmp256Asic[m][r][c]->Write();
	}

	outputFile->mkdir("hPulseWidthVsHeightAsic");
    	outputFile->cd("hPulseWidthVsHeightAsic");
    	for(int m = 0 ; m < NMODS ; m++ )
    	for(int r = 0 ; r < NROWS ; r++ )
    	for(int c = 0 ; c < NCOLS ; c++ )
		if(  hPulseWidthVsHeightAsic[m][r][c]->GetEntries() > 0 )
	    		hPulseWidthVsHeightAsic[m][r][c]->Write();

	outputFile->mkdir("hPulseHeightCh");
	outputFile->cd("hPulseHeightCh");
	for(int m = 0 ; m < NMODS ; m++ )
  	for(int r = 0 ; r < NROWS ; r++ )
  	for(int c = 0 ; c < NCOLS ; c++ )
  	for(int ch = 0 ; ch < NCHS ; ch++ ){
		if(  hPulseHeightCh[m][r][c][ch]->GetEntries() > 0 )
			hPulseHeightCh[m][r][c][ch]->Write();
	}

	outputFile->mkdir("hPulseTimeCh");
	outputFile->cd("hPulseTimeCh");
	for(int m = 0 ; m < NMODS ; m++ )
  	for(int r = 0 ; r < NROWS ; r++ )
  	for(int c = 0 ; c < NCOLS ; c++ )
  	for(int ch = 0 ; ch < NCHS ; ch++ ){
		if(  hPulseTimeCh[m][r][c][ch]->GetEntries() > 0 )
		hPulseTimeCh[m][r][c][ch]->Write();
	}

	outputFile->mkdir("hPulseBaseCh");
	outputFile->cd("hPulseBaseCh");
	for(int m = 0 ; m < NMODS ; m++ )
  	for(int r = 0 ; r < NROWS ; r++ )
  	for(int c = 0 ; c < NCOLS ; c++ )
  	for(int ch = 0 ; ch < NCHS ; ch++ ){
		if(  hPulseBaseCh[m][r][c][ch]->GetEntries() > 0 )
		hPulseBaseCh[m][r][c][ch]->Write();
	}

	outputFile->mkdir("hPulseWidthCh");
	outputFile->cd("hPulseWidthCh");
	for(int m = 0 ; m < NMODS ; m++ )
  	for(int r = 0 ; r < NROWS ; r++ )
  	for(int c = 0 ; c < NCOLS ; c++ )
  	for(int ch = 0 ; ch < NCHS ; ch++ ){
		if(  hPulseWidthSameWinCh[m][r][c][ch]->GetEntries() > 0 )
			hPulseWidthSameWinCh[m][r][c][ch]->Write();
		if(  hPulseWidthDiffWinCh[m][r][c][ch]->GetEntries() > 0 )
			hPulseWidthDiffWinCh[m][r][c][ch]->Write();
	}

	outputFile->mkdir("hPulseTimeVsSmpCh");
	outputFile->cd("hPulseTimeVsSmpCh");
	for(int m = 0 ; m < NMODS ; m++ )
  	for(int r = 0 ; r < NROWS ; r++ )
  	for(int c = 0 ; c < NCOLS ; c++ )
  	for(int ch = 0 ; ch < NCHS ; ch++ )
		if( hPulseTimeVsSmpCh[m][r][c][ch]->GetEntries() > 0 )
			hPulseTimeVsSmpCh[m][r][c][ch]->Write();
	
	outputFile->Close();
	return 1;
}

int getDistributions(topDataClass *data){
	if( data->isTOPTree == 0 ){
		std::cout << "getDistributions: tree object not loaded, quitting" << std::endl;
		return 0;
	}

	gTest = new TGraphErrors();

	//loop over tr_rawdata entries
  	Long64_t nEntries(data->tr_top->GetEntries());
  	for(Long64_t entry(0); entry<nEntries; ++entry) {
    		data->tr_top->GetEntry(entry);

		//number of hits count
		int nWindowHits = 0;
		int nAllHits = 0;

		//loop over all the hits in the event, store accepted pulses
    		for( int i = 0 ; i < data->nhit ; i++ ){
			int pmt_i =  data->pmtid_mcp[i] - 1;
			int pmtch_i =  data->ch_mcp[i] - 1;
			int asicMod = BII_2_Emod(data->pmtid_mcp[i], data->ch_mcp[i]);
			int asicRow = BII_2_ASICrow(data->pmtid_mcp[i], data->ch_mcp[i]);
			int asicCol = BII_2_ASICcol(data->pmtid_mcp[i], data->ch_mcp[i]);
			int asicCh  = BII_2_ASICch(data->pmtid_mcp[i], data->ch_mcp[i]);

			//require legitimate channel
			if( asicMod < 0 || asicMod >= NMODS || asicRow < 0 || asicRow >= NROWS || asicCol < 0 || asicCol >= NCOLS || asicCh < 0 || asicCh >= NCHS )
				continue;

			//represent pulse position on 8 x 64 grid representing PMT array front surface
			int boardStackPos = asicMod;
			if( asicMod == 0 )
				boardStackPos = 3;
			if( asicMod == 1 )
				boardStackPos = 2;
			if( asicMod == 2 )
				boardStackPos = 1;
			if( asicMod == 3 )
				boardStackPos = 0;
			int xIndex = 16*boardStackPos + 4*asicCol + 3 - asicCh/2;
			int yIndex = 2*(3 - asicRow) + 1 - asicCh % 2;
			hNumPulsePMTArray->Fill( xIndex, yIndex);

			//get pulse times
			double pulseTime = data->measurePulseTimeTreeEntry(i,1);
			double pulseHeight = data->adc0_mcp[i];
			double smpPos = data->getSmp128Bin( data->firstWindow[i], data->smp0_mcp[i] ) 
				+ data->getSmpPos( data->tdc0_smpNextY_mcp[i] , data->tdc0_smpPrevY_mcp[i] , data->adc0_mcp[i] );
			double smpFallPos = data->getSmp128Bin( data->firstWindow[i], data->smp0Fall_mcp[i] ) 
				+ data->getSmpFallPos( data->tdc0Fall_smpNextY_mcp[i] , data->tdc0Fall_smpPrevY_mcp[i] , data->adc0_mcp[i] );
			double pulseWidth = smpFallPos - smpPos;
			if( smpFallPos < smpPos )
				pulseWidth = smpFallPos + 128 - smpPos;
			double baseline = data->base_mcp[i];
			int smp256Bin = data->getSmp256Bin( data->firstWindow[i], data->smp0_mcp[i] );
			
			//looking at all hits
			nAllHits++;
		
			//looking just in window time range
			if( pulseTime > windowLow && pulseTime < windowHigh  )
				nWindowHits++;

			//fill overall event summary distributions
			hNHitAll->Fill(nAllHits);
	
			//OVerall distributions
			hPulseHeightAll->Fill(pulseHeight);
			hPulseTimeAll->Fill(pulseTime);
			hPulseWidthAll->Fill(pulseWidth);

			//ASIC specific distributions
			hPulseHeightAsic[asicMod][asicRow][asicCol]->Fill(pulseHeight);
			hPulseTimeAsic[asicMod][asicRow][asicCol]->Fill(pulseTime);
			hPulseHeightVsSmp256Asic[asicMod][asicRow][asicCol]->Fill( smp256Bin , pulseHeight);

			//channel specific disitributions
			hPulseHeightCh[asicMod][asicRow][asicCol][asicCh]->Fill(pulseHeight);
			hPulseBaseCh[asicMod][asicRow][asicCol][asicCh]->Fill(baseline);
			hPulseTimeCh[asicMod][asicRow][asicCol][asicCh]->Fill(pulseTime);
			hPulseTimeVsSmpCh[asicMod][asicRow][asicCol][asicCh]->Fill(smpPos,pulseTime);

			//ASIC specific distributions
			if( smpFallPos > smpPos )
				hPulseWidthVsHeightAsic[asicMod][asicRow][asicCol]->Fill(pulseHeight,pulseWidth);

			//count number of failed pulses
			if(pulseHeight < 200. )
				hNumPulseBad[asicMod][asicRow][asicCol][asicCh]++;
			else
				hNumPulseGood[asicMod][asicRow][asicCol][asicCh]++;

			//restrict pulse width measurements to larger pulses
			if(pulseHeight < 250. || pulseHeight > 850.)
				continue;

			//Pulse width measurements
			if( smpFallPos > smpPos ){
				hPulseWidthSameWinAll->Fill(pulseWidth);
				hPulseWidthSameWinAsic[asicMod][asicRow][asicCol]->Fill(pulseWidth);
				hPulseWidthSameWinCh[asicMod][asicRow][asicCol][asicCh]->Fill(pulseWidth);
				hPulseWidthSameVsSmp256Asic[asicMod][asicRow][asicCol]->Fill(smp256Bin,pulseWidth);
			}
			else{
				hPulseWidthDiffWinAll->Fill(pulseWidth);
				hPulseWidthDiffWinAsic[asicMod][asicRow][asicCol]->Fill(pulseWidth);
				hPulseWidthDiffWinCh[asicMod][asicRow][asicCol][asicCh]->Fill(pulseWidth);
				hPulseWidthDiffVsSmp256Asic[asicMod][asicRow][asicCol]->Fill(smp256Bin,pulseWidth);
			}
		}//end loop over hits
	}

	return 1;
}

int processDistributions(){

	//process channel specific distributions
	for(int m = 0 ; m < NMODS ; m++ )
  	for(int r = 0 ; r < NROWS ; r++ )
  	for(int c = 0 ; c < NCOLS ; c++ )
  	for(int ch = 0 ; ch < NCHS ; ch++ ){
		//skip empty channels
		if(  hPulseTimeCh[m][r][c][ch]->GetEntries() <= 1280 )
			continue;

		treeMod = m;
		treeRow = r;
		treeCol = c;
		treeCh = ch;

		//Time resolution
		treeTimeRes = getWidth(hPulseTimeCh[m][r][c][ch], 25);
		
		//Time resolution vs sample #
  		treeTimeResSmpMean = getMeanWidths(hPulseTimeVsSmpCh[m][r][c][ch], 25);

		//Pulse mean and RMS
		treeHeightMean = hPulseHeightCh[m][r][c][ch]->GetMean(1);
		treeHeightRMS = hPulseHeightCh[m][r][c][ch]->GetRMS(1);
		
		//Failure rate
		int total = hNumPulseGood[m][r][c][ch] + hNumPulseBad[m][r][c][ch];
		treeFailRate = 1.;
		if( total > 0 )
			treeFailRate = double(hNumPulseBad[m][r][c][ch])/double(total);

		//Time Offsets
		double meanSame = hPulseWidthSameWinCh[m][r][c][ch]->GetMean(1);
		double meanDiff = hPulseWidthDiffWinCh[m][r][c][ch]->GetMean(1);
		treeTimeOffset = meanSame - meanDiff;

		MetaDataTree->Fill();
	}

	return 0;
}

double getWidth(TH1F *hist, double range){
	if( hist->GetEntries() <= 100 )
		return -1;
	double posMax = hist->GetBinCenter( hist->GetMaximumBin() );
	TF1 *gfit = new TF1("Gaussian","gaus",posMax - range, posMax + range);
	gfit->SetLineColor(kRed);
	hist->Fit("Gaussian","QR");
	double timeRes = gfit->GetParameter(2)*1000.; //ps
	delete gfit;
	return timeRes;
}

double getMeanWidths(TH2F *hist, double range){
	double timeRes = 0;
	int count = 0;
	int numBins = hist->GetNbinsX();
  	TH1F *hBins[numBins];
  	char name[100];
  	for( int b = 0 ; b < numBins ; b++ ){
		memset(name,0,sizeof(char)*100 );
		sprintf(name,"bin_%.2i",b);
		hBins[b] = (TH1F*)hist->ProjectionY(name,b+1,b+1);
		if( hBins[b]->GetEntries() <= 10 )
			continue;
		double mean = getWidth(hBins[b],range);
		if( mean < 0 )
			continue;
		timeRes += mean;
		count++;
	}
	if( count > 0 )
		timeRes = timeRes/double(count);

	return timeRes;
}
