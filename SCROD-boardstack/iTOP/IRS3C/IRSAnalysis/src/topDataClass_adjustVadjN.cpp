//compile with: g++ -o topDataClass_adjustVadjN src/topDataClass_adjustVadjN.cpp `root-config --cflags --glibs`
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
int writeVadjNValues();

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
TH1F *hPulseHeightAsic[NMODS][NROWS][NCOLS];
TH1F *hPulseWidthSameWinAsic[NMODS][NROWS][NCOLS];
TH1F *hPulseWidthDiffWinAsic[NMODS][NROWS][NCOLS];
TH2F *hPulseHeightVsSmp256Asic[NMODS][NROWS][NCOLS];
TH2F *hPulseHeightVsWinAsic[NMODS][NROWS][NCOLS];

TGraphErrors *gTest;

//global variables
int numEvents = 0;
int numWins = 59;

int main(int argc, char* argv[]){
	if (argc != 2){
    		std::cout << "wrong number of arguments: usage ./topDataClass_adjustVadjN <file name>" << std::endl;
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
	TString outputFileName = "output_topDataClass_adjustVadjN_";
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

	//output VadjN values in some format
	writeVadjNValues();

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
        sprintf(name,"hPulseHeightVsWin_%.2i_%.2i_%.2i",m,r,c);
        sprintf(title,"Pulse Heights Vs Window #");
        hPulseHeightVsWinAsic[m][r][c] = new TH2F(name,title,64,0,64,200,-50,1950.);
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

	outputFile->mkdir("hPulseHeightAsic");
	outputFile->cd("hPulseHeightAsic");
	for(int m = 0 ; m < NMODS ; m++ )
	for(int r = 0 ; r < NROWS ; r++ )	
	for(int c = 0 ; c < NCOLS ; c++ ){
		if(  hPulseHeightAsic[m][r][c]->GetEntries() > 0 )
	    	hPulseHeightAsic[m][r][c]->Write();
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

	outputFile->mkdir("hPulseHeightVsWin");
    outputFile->cd("hPulseHeightVsWin");
    for(int m = 0 ; m < NMODS ; m++ )
    for(int r = 0 ; r < NROWS ; r++ )
    for(int c = 0 ; c < NCOLS ; c++ )
         if(  hPulseHeightVsWinAsic[m][r][c]->GetEntries() > 0 )
             hPulseHeightVsWinAsic[m][r][c]->Write();

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

		numEvents++;

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
			//int getSmp128Bin(int firstWindow, int smpNum);
			//double getSmpPos(double smpNextY, double smpPrevY, double adc0);
			double smpPos = data->getSmp128Bin( data->firstWindow[i], data->smp0_mcp[i] ) 
				+ data->getSmpPos( data->tdc0_smpNextY_mcp[i] , data->tdc0_smpPrevY_mcp[i] , data->adc0_mcp[i] );
			double smpFallPos = data->getSmp128Bin( data->firstWindow[i], data->smp0Fall_mcp[i] ) 
				+ data->getSmpFallPos( data->tdc0Fall_smpNextY_mcp[i] , data->tdc0Fall_smpPrevY_mcp[i] , data->adc0_mcp[i] );
			double pulseWidth = smpFallPos - smpPos;
			if( smpFallPos < smpPos )
				pulseWidth = smpFallPos + 128 - smpPos;

			hPulseHeightAll->Fill(pulseHeight);
			hPulseTimeAll->Fill(pulseTime);
			hPulseWidthAll->Fill(smpFallPos - smpPos );

			hPulseHeightCh[asicMod][asicRow][asicCol][asicCh]->Fill(pulseHeight);
			hPulseHeightAsic[asicMod][asicRow][asicCol]->Fill(pulseHeight);
			if( smpFallPos > smpPos && smpPos <100){
				hPulseWidthSameWinAll->Fill(pulseWidth);
				hPulseWidthSameWinCh[asicMod][asicRow][asicCol][asicCh]->Fill(pulseWidth);
				hPulseWidthSameWinAsic[asicMod][asicRow][asicCol]->Fill(pulseWidth);
			}
			if( smpFallPos < smpPos && smpPos < 127){
				hPulseWidthDiffWinAll->Fill(pulseWidth);
				hPulseWidthDiffWinCh[asicMod][asicRow][asicCol][asicCh]->Fill(pulseWidth);
				hPulseWidthDiffWinAsic[asicMod][asicRow][asicCol]->Fill(pulseWidth);
			}

			hNumPulsesMod[asicMod]->Fill(10*asicCol + asicCh, asicRow );
			//if( tdc0_mcp[i]/1000. > laserTime - 47.17 && tdc0_mcp[i]/1000. < laserTime + 47.17 )
			hNumLaserPulsesMod[asicMod]->Fill(10*asicCol + asicCh, asicRow );

			hPulseHeightVsSmp256Asic[asicMod][asicRow][asicCol]->Fill( data->getSmp256Bin( data->firstWindow[i], data->smp0_mcp[i] ) , pulseHeight);

			hPulseHeightVsWinAsic[asicMod][asicRow][asicCol]->Fill( data->firstWindow[i] + data->smp0_mcp[i]/64  , pulseHeight);
		}
	}

	return 1;
}

int printInfo(){
    std::cout << std::fixed;
	std::cout.precision(5);
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
			std::cout << "\tDead Time " << meanSame - meanDiff;
			std::cout << std::endl;
		}
  	}}}}//end print out

	std::cout << "Number of Pulses" << std::endl;
  	for(int m = 0 ; m < 4 ; m++ ){
  	for(int r = 0 ; r < 4 ; r++ ){
  	for(int c = 0 ; c < 4 ; c++ ){
  	for(int ch = 0 ; ch < 8 ; ch++ ){
		double num = hNumPulsesMod[m]->GetBinContent( 1 + ch + 10*c , 1 + r );
		double numLaser = hNumLaserPulsesMod[m]->GetBinContent( 1 + ch + 10*c , 1 + r );
		if( num <= 0. ) continue;
		double rate = -1;
		if( numEvents > 0 )
			rate = num/(double(numEvents)*double(numWins)*23.586E-9)/1000.;
		std::cout << " Mod " << m << "\tRow " << r << "\tCol " << c << "\tCh " << ch;
		std::cout << "\t# Hits " << num << "\t# Laser Hits " << numLaser;
		std::cout << "\tRate [kHz] " << rate;
		std::cout << std::endl;
  	}}}}//end print out

	return 0;
}

int writeVadjNValues(){
	std::cout << std::fixed;
	std::cout.precision(5);
	std::cout << "Dead Times" << std::endl;

	double slope_dVadjNdDT = 71.;

    ofstream scriptfile;
	scriptfile.open ("copperCommands_adjustVadjNValues.sh");
    scriptfile << "#/bin/bash\n";
    //scriptfile << "cd /home/copper/crt_data/20140614_irs3CTests\n";
    scriptfile << "cd /home/copper/crt_data/20140624_coldstart\n";

	for(int m = 0 ; m < 4 ; m++ ){
	for(int r = 0 ; r < 4 ; r++ ){
	for(int c = 0 ; c < 4 ; c++ ){
		if( hPulseHeightAsic[m][r][c]->GetEntries() <= 0 )
			continue;
		if( hPulseHeightAsic[m][r][c]->GetMean(1) < 50 )
			continue;
		if( hPulseHeightAsic[m][r][c]->GetRMS(1) > 200 )
			continue;
		if( hPulseWidthSameWinAsic[m][r][c]->GetMean(1) < 10 )
			continue;
		
		double meanSame = hPulseWidthSameWinAsic[m][r][c]->GetMean(1);
		double meanDiff = hPulseWidthDiffWinAsic[m][r][c]->GetMean(1);
		double deadTime = meanSame - meanDiff;
		double targetDeadTime = 0.;
		
		//don't reprogram certain ASICs
		//if( m == 0 && r == 0 && c == 1) continue;
		//if( m == 0 && r == 2 && c == 2) continue;
		//if( m == 1 && r == 0 && c == 3) continue;
		//if( m == 1 && r == 1 && c == 3) continue;
		//if( m == 2 && r == 0 && c == 0) continue;
		//if( m == 2 && r == 0 && c == 3) continue;
		//if( m == 2 && r == 2 && c == 0) continue;
		//if( m == 3 && r == 1 && c == 2) continue;
		//if( m == 3 && r == 2 && c == 0) continue;
		//if( m == 3 && r == 2 && c == 1) continue;
		/*
		if( m == 0 && r == 0 && c == 1)
			targetDeadTime = -7;
		if( m == 2 && r == 1 && c == 3)
            targetDeadTime = -7;		
		if( m == 0 && r == 2 && c == 2)
            targetDeadTime = -7;
        if( m == 2 && r == 2 && c == 0)
            targetDeadTime = -7;
		if( m == 2 && r == 2 && c == 1)
             targetDeadTime = -7;
		if( m == 2 && r == 0 && c == 0)
              targetDeadTime = -7;
		*/
		double adjustVadjN = -1.*(deadTime-targetDeadTime)*slope_dVadjNdDT;

		std::cout << " Mod " << m << "\tRow " << r << "\tCol " << c;
		std::cout << "\tDead Time " << deadTime;
		std::cout << "\t" << "Adjust VadjN" << "\t" << adjustVadjN;
		std::cout << std::endl;

		int regNum = 267 + r + 4*c;
        TString fibreStr("");
        if( m == 0 )  //0x3b
            fibreStr = "a:0";
        if( m == 1 )  //0x42
            fibreStr = "b:0";
        if( m == 2 )  //0x41
         	fibreStr = "c:0";
        if( m == 3 )  //0x43
            fibreStr = "d:0";
        std::cout << "./scrod-reg-adjust.py " << regNum << " " << int(adjustVadjN) << " " << fibreStr << std::endl;
        scriptfile << "./scrod-reg-adjust.py " << regNum << " " << int(adjustVadjN) << " " << fibreStr << std::endl;
	}
	}
	}

	scriptfile.close();

	return 0;
}
