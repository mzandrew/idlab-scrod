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

//global TApplication object declared here for simplicity
TApplication *theApp;

using namespace std;

int main(int argc, char* argv[]){
	if (argc != 3){
    		std::cout << "wrong number of arguments: usage ./target6Data_viewWaveformTree <file name> <pedestal file name>" << std::endl;
    		return 0;
  	}

	//define application object
	theApp = new TApplication("App", &argc, argv);

	std::cout << "Input file name "  << theApp->Argv()[1] << std::endl;
	std::cout << "Pedestal file name "  << theApp->Argv()[2] << std::endl;

	//create target6 interface object
	target6DataClass *data = new target6DataClass();

	if( !data->getWaveformTreeFile(theApp->Argv()[1]) ){
		std::cout << "Failed to load waveform tree, exiting" << std::endl;
		delete data;
		return 0;
	}

	data->getPedestalFile(theApp->Argv()[2]);
	
	data->makeHitTree();

	//delete target6 data object
	delete data;

	return 1;
}	
