//compile with: g++ -o topDataClass_checkHitRate src/topDataClass_checkHitRate.cpp `root-config --cflags --glibs`
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
int getDistributions(topDataClass *data);
int printInfo();

//hardcoded constants relevant to laser data
double windowTime = 1240;
double windowLow = windowTime-10.;
double windowHigh = windowTime+10.;

//output file pointer
TFile* outputFile;

//histograms
TH1F *hPulseHeightAll;
TH1F *hPulseTimeAll;
TH1F *hPulseWidthAll;
TH1F *hPulseWidthSameWinAll;
TH1F *hPulseWidthDiffWinAll;
TH2F *hNumPulsesMod[4];
TH2F *hNumLaserPulsesMod[4];
TH1F *hPulseHeightCh[NMODS][NROWS][NCOLS][NCHS];
TH1F *hPulseWidthSameWinCh[NMODS][NROWS][NCOLS][NCHS];
TH1F *hPulseWidthDiffWinCh[NMODS][NROWS][NCOLS][NCHS];

TGraphErrors *gTest;

int main(int argc, char* argv[]){
	if (argc != 2){
    		std::cout << "wrong number of arguments: usage ./topDataClass_simpleDistributions <file name>" << std::endl;
    		return 0;
  	}

	//define application object
	theApp = new TApplication("App", &argc, argv);
	TString inputFileName = theApp->Argv()[1];
	std::cout << "Input file name "  << inputFileName << std::endl;

	//create target6 interface object
	topDataClass *data = new topDataClass();

	//open summary tree file
	data->openSummaryTree(inputFileName);

	//create output file
  	TObjArray* strings = inputFileName.Tokenize("/");
  	TObjString* objstring = (TObjString*) strings->At(strings->GetLast());
  	TString inputFileNameBase(objstring->GetString());
	TString outputFileName = "output_topDataClass_simpleDistributions_";
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

	//print distribution info
	printInfo();

	//write output file
	writeOutputFile();

	//delete target6 data object
	delete data;

	return 1;
}

//define histograms
int initializeGlobalHistograms(){
	hPulseHeightAll = new TH1F("hPulseHeightAll","Pulse Height Distribution",1000,-50,1950.);
  	hPulseTimeAll = new TH1F("hPulseTimeAll","Pulse Time Distribution",10000,-64*64*1./2.7515,64*64*1./2.7515);
	hPulseWidthAll = new TH1F("hPulseWidthAll","Pulse Width Distribution",3000,-150,150.);
	hPulseWidthSameWinAll = new TH1F("hPulseWidthSameWinAll","Pulse Width Same Window Distribution",3000,-150,150.);
	hPulseWidthDiffWinAll = new TH1F("hPulseWidthDiffWinAll","Pulse Width Different Window Distribution",3000,-150,150.);

	char name[100];
  	char title[200];
  	for(int m = 0 ; m < 4 ; m++ ){
  		memset(name,0,sizeof(char)*100 );
		memset(title,0,sizeof(char)*200 );
		sprintf(name,"hNumPulsesMod_%.2i",m);
		sprintf(title,"Number of Pulses Module %.2i ASIC ROW # vs 10 x COL # + CH #",m);
	  	hNumPulsesMod[m] = new TH2F(name,title,4*10,0,4*10,4,0,4);

		memset(name,0,sizeof(char)*100 );
		memset(title,0,sizeof(char)*200 );
		sprintf(name,"hNumLaserPulsesMod_%.2i",m);
		sprintf(title,"Number of Laser Pulses Module %.2i ASIC ROW # vs 10 x COL # + CH #",m);
  		hNumLaserPulsesMod[m] = new TH2F(name,title,4*10,0,4*10,4,0,4);
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
		sprintf(name,"hPulseWidthSameWinCh_%.2i_%.2i_%.2i_%.2i",m,r,c,ch);
		sprintf(title,"Pulse Widths");
		hPulseWidthSameWinCh[m][r][c][ch] = new TH1F(name,title,300,-150,150.);

		memset(name,0,sizeof(char)*100 );
		memset(title,0,sizeof(char)*200 );
		sprintf(name,"hPulseWidthDiffWinCh_%.2i_%.2i_%.2i_%.2i",m,r,c,ch);
		sprintf(title,"Pulse Widths");
		hPulseWidthDiffWinCh[m][r][c][ch] = new TH1F(name,title,300,-150,150.);
	}
}

int writeOutputFile(){
	outputFile->cd();

	hPulseHeightAll->Write();
	hPulseTimeAll->Write();
	hPulseWidthAll->Write();
	hPulseWidthSameWinAll->Write();
	hPulseWidthDiffWinAll->Write();

	for(int m = 0 ; m < 4 ; m++ )
  		hNumPulsesMod[m]->Write();
  	for(int m = 0 ; m < 4 ; m++ )
  		hNumLaserPulsesMod[m]->Write();

	outputFile->mkdir("hPulseHeightCh");
	outputFile->cd("hPulseHeightCh");
	for(int m = 0 ; m < NMODS ; m++ )
  	for(int r = 0 ; r < NROWS ; r++ )
  	for(int c = 0 ; c < NCOLS ; c++ )
  	for(int ch = 0 ; ch < NCHS ; ch++ ){
		if(  hPulseHeightCh[m][r][c][ch]->GetEntries() > 0 )
		hPulseHeightCh[m][r][c][ch]->Write();
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

			//get pulse times
			double pulseTime = data->measurePulseTimeTreeEntry(i,1);
			double pulseHeight = data->adc0_mcp[i];
			double smpPos = data->getSmp128IndexTreeEntry(i) + data->getSmpPosTreeEntry(i);
			double smpFallPos = data->getSmpFall128IndexTreeEntry(i) + data->getSmpFallPosTreeEntry(i);
			double pulseWidth = smpFallPos - smpPos;
			if( smpFallPos < smpPos )
				pulseWidth = smpFallPos + 128 - smpPos;

			hPulseHeightAll->Fill(pulseHeight);
			hPulseTimeAll->Fill(pulseTime);
			hPulseWidthAll->Fill(smpFallPos - smpPos );

			hPulseHeightCh[asicMod][asicRow][asicCol][asicCh]->Fill(pulseHeight);
			if( smpFallPos > smpPos ){
				hPulseWidthSameWinAll->Fill(pulseWidth);
				hPulseWidthSameWinCh[asicMod][asicRow][asicCol][asicCh]->Fill(pulseWidth);
			}
			else{
				hPulseWidthDiffWinAll->Fill(pulseWidth);
				hPulseWidthDiffWinCh[asicMod][asicRow][asicCol][asicCh]->Fill(pulseWidth);
			}

			hNumPulsesMod[asicMod]->Fill(10*asicCol + asicCh, asicRow );
			//if( tdc0_mcp[i]/1000. > laserTime - 47.17 && tdc0_mcp[i]/1000. < laserTime + 47.17 )
				hNumLaserPulsesMod[asicMod]->Fill(10*asicCol + asicCh, asicRow );
		}
	}

	return 1;
}

int printInfo(){
	std::cout << "Pulse Heights" << std::endl;
  	for(int m = 0 ; m < 4 ; m++ ){
  	for(int r = 0 ; r < 4 ; r++ ){
  	for(int c = 0 ; c < 4 ; c++ ){
  	for(int ch = 0 ; ch < 8 ; ch++ ){
		if(  hPulseHeightCh[m][r][c][ch]->GetEntries() > 0 ){
			double mean = hPulseHeightCh[m][r][c][ch]->GetMean(1);
			double rms = hPulseHeightCh[m][r][c][ch]->GetRMS(1);
			std::cout << " Mod " << m << "\tRow " << r << "\tCol " << c << "\tCh " << ch;
			std::cout << "\tAvg " << mean << "\tRms " << rms;
			std::cout << std::endl;
		}
  	}}}}//end print out

	std::cout << "Pulse Widths" << std::endl;
  	for(int m = 0 ; m < 4 ; m++ ){
  	for(int r = 0 ; r < 4 ; r++ ){
  	for(int c = 0 ; c < 4 ; c++ ){
  	for(int ch = 0 ; ch < 8 ; ch++ ){
		if(  hPulseHeightCh[m][r][c][ch]->GetEntries() > 0 ){
			double meanSame = hPulseWidthSameWinCh[m][r][c][ch]->GetMean(1);
			double rmsSame = hPulseWidthSameWinCh[m][r][c][ch]->GetRMS(1);
			double meanDiff = hPulseWidthDiffWinCh[m][r][c][ch]->GetMean(1);
			double rmsDiff = hPulseWidthDiffWinCh[m][r][c][ch]->GetRMS(1);
			std::cout << " Mod " << m << "\tRow " << r << "\tCol " << c << "\tCh " << ch;
			std::cout << "\tAvg Same " << meanSame << "\tRms Same " << rmsSame;
			std::cout << "\tAvg Diff " << meanDiff << "\tRms Diff " << rmsDiff;
			std::cout << std::endl;
		}
  	}}}}//end print out

	return 0;
}
