#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h> 
#include "target6ControlClass.h"

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

	//request a data packet
	control->registerWrite(board_id, 58, 0, regValReadback);
	control->registerWrite(board_id, 58, 1, regValReadback);

	//parse the data packet, look for event packets
	unsigned int eventdatabuf[65536];
	int eventdataSize = 20;
	control->readPacketFromUSBFifo( eventdatabuf, 65536, eventdataSize );

	for(int j=0;j<eventdataSize; j++)
		std::cout << "RAW DATA\t" << std::hex << eventdatabuf[j] << std::dec << std::endl;

	std::cout << "PACKET SIZE " << eventdataSize << std::endl;
	//close USB interface
        control->closeUSBInterface();

	//delete target6 interface object
	delete control;

	return 1;
}	
