#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h> 
#include "target6DataClass.h"

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
#define POINTS_PER_WAVEFORM2    32//redefined


//global TApplication object declared here for simplicity
TApplication *theApp;

using namespace std;

int target6DataClass::plotWaveformTreeFile2(TCanvas *c0){
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

			for(int s = 0 ; s < POINTS_PER_WAVEFORM2 ; s++ ){
				int sampVal = samples[n][s];
				//std::cout << "pedVal " << pedestal_mean;
				//std::cout << "\tsampVal " << sampVal;
				//std::cout << std::endl;
				//gPlot->SetPoint( gPlot->GetN(), s, samples[n][s] );
				double pedVal = 0;
				gPlot->SetPoint( gPlot->GetN(), s, sampVal );
/*				if( isPedestalTree == 1 ){
					Long64_t entryToGet(s + POINTS_PER_WAVEFORM2*windowNum[n] + POINTS_PER_WAVEFORM2*MEMORY_DEPTH*asicCh[n]
						+ POINTS_PER_WAVEFORM2*MEMORY_DEPTH*NCHS*asicNum[n] );
					pedestalTree->GetEntry(entryToGet);
					pedVal = pedestal_mean;
				}
				gPlot->SetPoint( gPlot->GetN(), s, sampVal - pedVal ); */
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




int main(int argc, char* argv[]){
	if (argc != 2){
    		std::cout << "wrong number of arguments: usage ./tx_plotdata1 <file name>" << std::endl;
    		return 0;
  	}

	//define application object
	theApp = new TApplication("App", &argc, argv);

	std::cout << "Input file name "  << theApp->Argv()[1] << std::endl;

	//initialize canvas
  	TCanvas *c0 = new TCanvas("c0", "c0",800,600);

	//create target6 interface object
	target6DataClass *data = new target6DataClass();

	if( !data->getWaveformTreeFile(theApp->Argv()[1]) ){
		std::cout << "Failed to load waveform tree, exiting" << std::endl;
		delete data;
		return 0;
	}

	//data->getPedestalFile("output_target6DataClass_pedestalFile.root");
	
	data->plotWaveformTreeFile2(c0);

	//delete target6 data object
	delete data;

	return 1;
}	
