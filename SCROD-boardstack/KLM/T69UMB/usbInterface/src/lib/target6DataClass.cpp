#include <iostream>
#include <fstream>
#include <sstream>
#include <cstdlib>
#include <vector>
#include <TFile.h>
#include "TTree.h"
#include "TSystem.h"
#include "TROOT.h"
#include "TApplication.h"
#include <math.h>
#include <TH1F.h> 
#include <TH2S.h> 
#include <TH2F.h> 
#include <TF1.h>
#include <TMath.h> 
#include <TGraph.h>
#include "TCanvas.h"
#include "target6DataClass.h"
using namespace std;

target6DataClass::target6DataClass(){
	isWaveformTree = 0;
	file = NULL;
	tree = NULL;
}

target6DataClass::~target6DataClass(){
	//delete grCh;
}


//open waveform tree, initialize class variables
int target6DataClass::getWaveformTreeFile(TString inputFileName){
	//open file
	file = new TFile(inputFileName);
  	if (file->IsZombie()) {
		std::cerr << "getWaveformTreeFile : Error opening waveform tree input file, exiting" << std::endl;
		return 0;
  	}

  	if( !file ){
		std::cerr << "getWaveformTreeFile : Error opening waveform tree input file, exiting" << std::endl;
		return 0;
  	}

	//initialize tree branches
  	tree = (TTree*) file->Get("T");
  	if( !tree ){
		std::cerr << "getWaveformTreeFile : Error getting tree object, exiting" << std::endl;
		return 0;
	}

	//assign tree branches
  	tree->SetBranchAddress("eventNum", &eventNum);
  	tree->SetBranchAddress("nROI", &nROI);
  	tree->SetBranchAddress("scrodId", &scrodId);
  	tree->SetBranchAddress("asicNum", &asicNum);
  	tree->SetBranchAddress("asicCh", &asicCh);
  	tree->SetBranchAddress("windowNum", &windowNum);
  	tree->SetBranchAddress("samples", &samples);

	isWaveformTree = 1;

	return 1;
}

int target6DataClass::getPedestalFile(TString inputFileName){
	//open file
	pedestalFile = new TFile(inputFileName);
  	if (pedestalFile->IsZombie()) {
		std::cerr << "getPedestalFile : Error opening waveform tree input file, exiting" << std::endl;
		return 0;
  	}

  	if( !pedestalFile ){
		std::cerr << "getPedestalFile : Error opening waveform tree input file, exiting" << std::endl;
		return 0;
  	}

	//initialize tree branches
  	pedestalTree = (TTree*) pedestalFile->Get("PedestalTree");
  	if( !pedestalTree ){
		std::cerr << "getPedestalFile : Error getting tree object, exiting" << std::endl;
		return 0;
	}

	//assign tree branches
  	pedestalTree->SetBranchAddress("mean", &pedestal_mean);
  	pedestalTree->SetBranchAddress("RMS", &pedestal_RMS);
	isPedestalTree = 1;

	return 1;
}

int target6DataClass::plotWaveformTreeFile(TCanvas *c0){
	if( isWaveformTree == 0){
		std::cout << "plotWaveformTreeFile : Waveform tree file not loaded, exiting" << std::endl;
		return 0;
	}
	
	//define graph object
	TGraph *gPlot = new TGraph();
	gPlot->SetMarkerColor(2);
  	gPlot->SetMarkerStyle(21);
  	gPlot->SetMarkerSize(1.5);

	//loop over waveform tree
  	Long64_t nEntries(tree->GetEntries());
  	for(Long64_t entry(0); entry<nEntries; ++entry) {
    		tree->GetEntry(entry);
    		
		std::cout << "eventNum " << eventNum;
		std::cout << "\tnROI " << nROI;
		std::cout << std::endl;
		
		for( int n = 0 ; n < nROI ; n++){
			std::cout << "\t\tasicNum[n] " << asicNum[n];
			std::cout << "\tasicCh[n] " << asicCh[n];
			std::cout << "\twindowNum[n] " << windowNum[n];
			std::cout << std::endl;
			
			gPlot->Set(0);
	
			for(int s = 0 ; s < POINTS_PER_WAVEFORM ; s++ ){
				int sampVal = samples[n][s];
				//std::cout << "pedVal " << pedestal_mean;
				//std::cout << "\tsampVal " << sampVal;
				//std::cout << std::endl;
				//gPlot->SetPoint( gPlot->GetN(), s, samples[n][s] );
				double pedVal = 0;
				if( isPedestalTree == 1 ){
					Long64_t entryToGet(s + POINTS_PER_WAVEFORM*windowNum[n] + POINTS_PER_WAVEFORM*MEMORY_DEPTH*asicCh[n] 
						+ POINTS_PER_WAVEFORM*MEMORY_DEPTH*NCHS*asicNum[n] );
					pedestalTree->GetEntry(entryToGet);
					pedVal = pedestal_mean;
				}
				gPlot->SetPoint( gPlot->GetN(), s, sampVal - pedVal );
			}
			

			c0->Clear();
			gPlot->GetYaxis()->SetRangeUser(0,4095);
			if( isPedestalTree == 1 )
				gPlot->GetYaxis()->SetRangeUser(-2050,2050);
  			gPlot->Draw("AP");
			c0->Update();
			char ct;
			std::cin >> ct;
		}
  	}//entries 

	delete gPlot;

	return 1;
}

int target6DataClass::measurePedestals(TCanvas *c0){
	if( isWaveformTree == 0){
		std::cout << "measurePedestals : Waveform tree file not loaded, exiting" << std::endl;
		return 0;
	}

	//create histograms to store pedestals
     	int numberOfHistograms(NASICS*NCHS*MEMORY_DEPTH*POINTS_PER_WAVEFORM);

	//TH1C only works as long as there are less than 100 (actually 127) triggers/events. TH1S should work for up to 32767 events.
	std::cout << "INITIALIZING SAMPLE HISTOGRAMS" << std::endl;
      	std::vector<TH1C*> histos;
  	histos.reserve(numberOfHistograms);
	std::cout << "# of histograms " << numberOfHistograms << std::endl;
	for (int i(0); i<numberOfHistograms; ++i) {
		if( i % 100000 == 0 )
			std::cout << "Initializing histogram # " << i << "\tout of " << numberOfHistograms  << std::endl;
	        TString name("name");
		name += i;
		TH1C* dummy = new TH1C(name, "title", 410, 0, 4100);    
        	histos.push_back(dummy);
	}
	
	//loop over waveform tree
	TH2F *hTemp = new TH2F("hTemp","",512,0,512,10,0,10);
	std::cout << "LOOPING OVER EVENTS" << std::endl;
  	Long64_t nEntries(tree->GetEntries());
	for(Long64_t entry(0); entry<nEntries; ++entry) {
		tree->GetEntry(entry);
		if( entry % 10 == 0 )
			std::cout << "Processing event # " << entry << "\tout of " << nEntries  << std::endl;
		for(int n = 0 ; n < nROI ; n++){
			for(int s = 0 ; s < POINTS_PER_WAVEFORM ; s++ ){
				int sampIndex(s + POINTS_PER_WAVEFORM*windowNum[n] + POINTS_PER_WAVEFORM*MEMORY_DEPTH*asicCh[n] 
					+ POINTS_PER_WAVEFORM*MEMORY_DEPTH*NCHS*asicNum[n]);
	    			if(sampIndex > numberOfHistograms-1) 
					std::cerr << "Error: requested histogram number is too high, please check number of ASICs, etc" << std::endl;
	   			else
					histos.at(sampIndex)->Fill(samples[n][s]);
			}//end of samples loops
			hTemp->Fill( windowNum[n] , asicNum[n] );
		}//end of nROI loop
  	}//entries 

	//define output pedestal file name
	TString outputFileName("output_target6DataClass_pedestalFile.root");
	std::cout << " outputFileName " << outputFileName << std::endl;
	TFile g(outputFileName , "RECREATE");

	//creat output tree
	TTree* outputTree = new TTree("PedestalTree", "Pedestal mean and RMS values");
  	UInt_t output_scrodId;
  	Int_t output_asicNum;
  	Int_t output_asicCh;
  	Int_t output_windowNum;
  	Int_t output_sample;
 	Float_t output_mean;
  	Float_t output_RMS;
  	outputTree->Branch("scrodId", &output_scrodId, "scrodId/I");
  	outputTree->Branch("asicNum", &output_asicNum, "asicNum/I");   
  	outputTree->Branch("asicCh", &output_asicCh, "asicCh/I");
  	outputTree->Branch("windowNum", &output_windowNum, "windowNum/I");  
  	outputTree->Branch("sample", &output_sample, "sample/I");   
  	outputTree->Branch("mean", &output_mean, "mean/F");  
  	outputTree->Branch("RMS", &output_RMS, "RMS/F");

	//measure means
	std::cout << "MEASURING PEDESTALS" << std::endl;
	for (int i(0); i<numberOfHistograms; ++i) {
		if( i % 100000 == 0 ){
			std::cout << "Processing histogram # " << i << "\tout of " << numberOfHistograms  << std::endl;
		}
		double posMax = histos.at(i)->GetBinCenter( histos.at(i)->GetMaximumBin() );
		histos.at(i)->GetXaxis()->SetRangeUser(posMax-5, posMax+5);
		output_scrodId = 0;
		output_asicNum =  (i/(NCHS*MEMORY_DEPTH*POINTS_PER_WAVEFORM))%NASICS;
		output_asicCh = (i/(MEMORY_DEPTH*POINTS_PER_WAVEFORM))%NCHS;
		output_windowNum =  (i/POINTS_PER_WAVEFORM)%MEMORY_DEPTH;
		output_sample = i%POINTS_PER_WAVEFORM;
		output_mean = histos.at(i)->GetMean(1);
        	output_RMS = histos.at(i)->GetRMS();
        	outputTree->Fill();
      	}
	outputTree->Write();
	hTemp->Write();
	g.Close();
	std::cout << "DONE MEASURING PEDESTALS" << std::endl;

	//delete outputTree;

	//delete histograms
	//for (int i(0); i<numberOfHistograms; ++i)
	//	delete histos.at(i);

	return 1;
}
