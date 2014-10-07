#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h> 
#include "target6ControlClass.h"

#include <TGraph.h>
#include <TH1.h>
#include "TApplication.h"
#include "TCanvas.h"
#include "TAxis.h"
#include "TF1.h"
#include "TMath.h"
#include "TFile.h"
#include "TGraphErrors.h"

//global TApplication object declared here for simplicity
TApplication *theApp;

using namespace std;

int main(int argc, char* argv[]){
	if (argc != 1){
    		std::cout << "wrong number of arguments: usage ./target6Control_test" << std::endl;
    		return 0;
  	}

	//define application object
	theApp = new TApplication("App", &argc, argv);

	int regValReadback;

	//create target6 interface object
	target6ControlClass *control = new target6ControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0;

	//initialize the DAC loading and latch period registers to something reasonable
	control->registerWriteReadback(board_id, 5, 128 , regValReadback);
	control->registerWriteReadback(board_id, 6, 320 , regValReadback);

	//reset and enable trigger scalers
	control->registerWriteReadback(board_id, 70, 0 , regValReadback); //disable
	control->registerWriteReadback(board_id, 71, 0 , regValReadback); //reset low
	control->registerWriteReadback(board_id, 71, 1 , regValReadback); //reset high
	control->registerWriteReadback(board_id, 71, 0 , regValReadback); //reset low
	control->registerWriteReadback(board_id, 70, 1 , regValReadback); //enable

	TCanvas *c0 = new TCanvas("c0","c0",1300,800);
	TGraph *gPlot[10][16];
	int numPoint[10][16];
	for(int a = 0 ; a < 10 ; a++){
	for(int c = 0 ; c < 16 ; c++){
		numPoint[a][c] = 0;
		gPlot[a][c] = new TGraph();
  		gPlot[a][c]->SetMarkerColor(2);
  		gPlot[a][c]->SetMarkerStyle(21);
  		gPlot[a][c]->SetMarkerSize(1.5);
	}		
	}
	
	//iterate over channels, vary thresholds each iteration. Automatically test all DC on MB each iteration
	for(int c = 0 ; c < 16 ; c++){
		int count[10];
		//loop over channel trigger threshold values
		for(int i = 0 ; i < 50 ; i++){
			int threshold = 1800+5*i;

			//reset scalers
			control->registerWriteReadback(board_id, 71, 1 , regValReadback); //reset high
			control->registerWriteReadback(board_id, 71, 0 , regValReadback); //reset low
			//control->resetTriggers(board_id);
		
			//write thresholds
			for(int a = 0 ; a < 10 ; a++)
				control->writeDACReg(board_id, a, c, threshold);

			//wait some time
			sleep(2);

			//read scalers
			for(int a = 0 ; a < 10 ; a++)
				control->registerRead(board_id, 266 + a, count[a]);

			//do something with scalars
			std::cout << "Threshold\t" << threshold << std::endl;
			for(int a = 0 ; a < 10 ; a++){
				std::cout << "\tMB # " << a << "\tChannel # " << c << "\tCounter\t" << count[a] << std::endl;
				gPlot[a][c]->SetPoint(numPoint[a][c],threshold,count[a]);
				numPoint[a][c]++;
			}
		}
		//reset thresholds
		for(int a = 0 ; a < 10 ; a++)
			control->writeDACReg(board_id, a, c, 0);
	}

	/*
	c0->Clear();
	//gPlot[2]->GetYaxis()->SetRangeUser(0,4100);
  	//gPlot[2]->Draw("AP");
	c0->Divide(3,4);
	for(int a = 0 ; a < 10 ; a++){
		if( numPoint[a] < 1 )
			continue;
		c0->cd(a+1);
		std::cout << std::dec << numPoint[a] << std::endl;
		gPlot[a]->GetYaxis()->SetRangeUser(0,70000);
  		gPlot[a]->Draw("AP");
	}
  	c0->Update();
	char ct;
	std::cin >> ct;
	*/

	//close USB interface
        control->closeUSBInterface();

	//delete target6 interface object
	delete control;

	char name[100];
	TFile *f = new TFile( "output_target6Control_testTrigger.root" , "RECREATE");
	for(int a = 0 ; a < 10 ; a++){
	for(int c = 0 ; c < 16 ; c++){
		memset(name,0,sizeof(char)*100 );
		sprintf(name,"gPlot_DC%.2i_Chan%.2i",a,c);
		if( numPoint[a][c] > 0 )
			gPlot[a][c]->Write(name);
	}
	}
  	f->Close();
	delete f;

	return 1;
}	
