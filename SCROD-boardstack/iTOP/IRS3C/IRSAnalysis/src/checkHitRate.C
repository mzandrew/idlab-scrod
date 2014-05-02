//compile with: g++ -o checkHitRate src/checkHitRate.C `root-config --cflags --glibs`
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h> 
#include <fstream>
#include "TROOT.h"
#include "TFile.h"
#include "TTree.h"
#include "TH1.h"
#include "TH2.h"
#include "TString.h"
#include "TCanvas.h"
#include <iostream>
#include <fstream>
#include "CRTChannelConversion.hh"
#include "TApplication.h"

using namespace std;

#define MaxROI 1000
TCanvas* c0;

double laserTime = 1126.;

//tree
TTree* tr_top;
Int_t eventNum;
Int_t runNum;
Short_t nhit;
Short_t pmtid_mcp[MaxROI];
Short_t ch_mcp[MaxROI];
//Short_t pmtflag_mcp[MaxROI];
//Short_t pmtflag_ch[MaxROI];
Float_t smp_mcp[MaxROI];
Float_t smp128_mcp[MaxROI];
Float_t tdc0_mcp[MaxROI];
Float_t adc0_mcp[MaxROI];
Int_t timing_tdc;
Int_t timing_adc;
Int_t veto_adc[2];
Short_t ftsw;

void pulseAna();
void initializeGlobalHistograms();

//global TApplication object declared here for simplicity
TApplication *theApp;

//histograms and graphs
TH1F *hPulseTimeAll;
TH1F *hPulseHeightAll;
TH2F *hNumPulsesMod[4];
TH2F *hNumLaserPulsesMod[4];

int numEvents = 0;
int numWins = 0;

int main(int argc, char *argv[]){
  if(argc!=4){
    cout<<"Usage: checkHitRate [inputFilename] [num events] [num windows]"<<endl;
    return 0;
  }

  //define application object
  theApp = new TApplication("App", &argc, argv);

  //char inputFileName[1000];
  //sprintf(inputFileName,"%s",argv[1]);
  TString inputFileName = theApp->Argv()[1];
  std::cout << "Input file name "  << inputFileName << std::endl;

  //get numbers
  numEvents = atoi(theApp->Argv()[2]);
  numWins = atoi(theApp->Argv()[3]);

  if(numEvents <= 0 || numWins <= 0 ) {
	std::cout << "Invalid number of events or windows, exiting" << std::endl;
	return 0;
  }
	

  //get file containing ROI-based event tr_rawdata
  TFile* file = new TFile(inputFileName);
  if (file->IsZombie()) {
	std::cout << "Error opening input file" << std::endl;
	return 0;
  }

  if( !file )
	return 0;
  
  // check if raw_data tree is in file
  tr_top = (TTree*) file->Get("top");
  if( !tr_top )
	return 0;

  //initialize canvas
  c0 = new TCanvas("c0", "c0",1300,800);

  //initialize histograms
  initializeGlobalHistograms();

  //set tree branches
  tr_top->SetBranchAddress("eventNum", &(eventNum));
  tr_top->SetBranchAddress("runNum", &(runNum));
  tr_top->SetBranchAddress("nhit", &(nhit));
  tr_top->SetBranchAddress("pmt",&(pmtid_mcp));
  tr_top->SetBranchAddress("ch",&(ch_mcp));
  //tr_top->SetBranchAddress("pmtflag_mcp",&(pmtflag_mcp));
  //tr_top->SetBranchAddress("pmtflag_ch",&(pmtflag_ch));
  tr_top->SetBranchAddress("smp",&(smp_mcp));             
  tr_top->SetBranchAddress("adc0",&(adc0_mcp));
  tr_top->SetBranchAddress("ftsw",&(ftsw));

  //loop over tr_rawdata entries
  Long64_t nEntries(tr_top->GetEntries());
  for(Long64_t entry(0); entry<nEntries; ++entry) {
    tr_top->GetEntry(entry);
    pulseAna();
  }//entries

  std::cout << "HIT RATE - assuming 10000 events in run " << std::endl;
  for(int m = 0 ; m < 4 ; m++ ){
  for(int r = 0 ; r < 4 ; r++ ){
  for(int c = 0 ; c < 4 ; c++ ){
  for(int ch = 0 ; ch < 8 ; ch++ ){
	double num = hNumPulsesMod[m]->GetBinContent( 1 + ch + 10*c , 1 + r );
	double numLaser = hNumLaserPulsesMod[m]->GetBinContent( 1 + ch + 10*c , 1 + r );
	if( num <= 0. ) continue;
	double rate = num/double(numEvents);
	double rateLaser = numLaser/double(numEvents);
	double darkNoiseRate = num/(double(numEvents)*double(numWins)*23.586E-9)/1000.;
	std::cout << " Module " << m << "\tRow " << r << "\tCol " << c << "\tCh " << ch << std::endl;
	std::cout << "\t# Hits " << num << "\trate " << rate << "\tdark noise rate [kHz] " << darkNoiseRate << "\tlaser rate " << rateLaser*100 << " %" << std::endl;
	//std::cout << "\t# Hits " << num << "\trate " << rate << "\tdark noise rate " << darkNoiseRate << std::endl;
	//std::cout << "\t# Laser Hits " << numLaser << "\tlaser rate " << rateLaser << std::endl;
	std::cout << std::endl;
  }
  }
  }	
  }

  c0->Clear();
  c0->Divide(2,2);
  c0->cd(1);
  hNumPulsesMod[0]->Draw("COLZ");
  c0->cd(2);
  hNumPulsesMod[1]->Draw("COLZ");
  c0->cd(3);
  hNumPulsesMod[2]->Draw("COLZ");
  c0->cd(4);
  hNumPulsesMod[3]->Draw("COLZ");
  c0->Update();

  //define output file
  TString outputFileName = "output_checkHitRate.root";
  std::cout << " outputFileName " << outputFileName << std::endl;
  TFile *f = new TFile( outputFileName , "RECREATE");
  hPulseHeightAll->Write();
  hPulseTimeAll->Write();
  for(int m = 0 ; m < 4 ; m++ )
  	hNumPulsesMod[m]->Write();
  for(int m = 0 ; m < 4 ; m++ )
  	hNumLaserPulsesMod[m]->Write();
  f->Close();

  return 0;
}


void initializeGlobalHistograms(){
  hPulseHeightAll = new TH1F("hPulseHeightAll","Pulse Height Distribution",500,-50,950.);
  hPulseTimeAll = new TH1F("hPulseTimeAll","Pulse Time Distribution",1000,1000,1400);
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
  return;
}

void pulseAna(){
    	for( int i = 0 ; i < nhit ; i++ ){
		//use local pmt and channel number variables that start from 0
		int pmt_i =  pmtid_mcp[i] - 1;
		int pmtch_i =  ch_mcp[i] - 1;
		int asicMod = BII_2_Emod(pmtid_mcp[i], ch_mcp[i]);
		int asicRow = BII_2_ASICrow(pmtid_mcp[i], ch_mcp[i]);
		int asicCol = BII_2_ASICcol(pmtid_mcp[i], ch_mcp[i]);
		int asicCh  = BII_2_ASICch(pmtid_mcp[i], ch_mcp[i]);
		hPulseHeightAll->Fill(adc0_mcp[i]);
		hNumPulsesMod[asicMod]->Fill(10*asicCol + asicCh, asicRow );
		hPulseTimeAll->Fill(tdc0_mcp[i]/1000.);
		if( tdc0_mcp[i]/1000. > laserTime - 47.17 && tdc0_mcp[i]/1000. < laserTime + 47.17 )
			hNumLaserPulsesMod[asicMod]->Fill(10*asicCol + asicCh, asicRow );
	}//end loop over nhit
	return;
}
