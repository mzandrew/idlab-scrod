#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <fstream>
#include <stdlib.h> 
#include "irs3BControlClass.h"
#include "irs3BDataClass.h"
#include "TApplication.h"
#include "TCanvas.h"
#include "TFile.h"

using namespace std;

//global TApplication object declared here for simplicity
TApplication *theApp;

//global variables
int numEvents = 100;

int main(int argc, char* argv[]){
	if (argc != 2) {
		cout << "irs3BControl_takeHardwareTriggers #event" << endl;
		return 1;
	}

	//get event #, row, col, ch, cal enable
        numEvents = atoi(argv[1]);
        if( numEvents <= 0 ){
                std::cout << "Invalid number of events, exiting" << std::endl;
                return 0;
        }

	//define application object
	theApp = new TApplication("App", &argc, argv);

	//define output file            
        ofstream dataFile;
        dataFile.open ("output_irs3BControl_takeHardwareTriggers.dat", ios::out | ios::binary );

	//create irs3b interface object
	irs3BControlClass *control = new irs3BControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0x0;
	int regValReadback;

	//reset forced readout registers (171-178) ignore readout registers (179-186)
	for( int i = 171 ; i <= 186 ; i++ )
		control->registerWrite(board_id, i, 0, regValReadback);

	//take waveform data, applying pedestal correction
	int nHit = 0;
	for( int nevt = 0 ; nevt < numEvents ; nevt++){
		//send hardware trigger
		//control->sendHardwareTrigger(board_id);
		control->sendSoftwareTrigger(board_id);

		//get USB data - write to files
		unsigned int eventdatabuf[65536];
		int eventdataSize = 0;
		control->readPacketFromUSBFifo( eventdatabuf, 65536, eventdataSize );

		if( eventdataSize > 10 )
			control->writeEventToFile(eventdatabuf, eventdataSize, dataFile );
		if(  eventdataSize > 20 ){
			nHit++;
			std::cout << "nHit " << nHit << std::endl;
		}
		if( nevt % 100 == 0 )
			std::cout << nevt << std::endl;
	}

	//close output file
        dataFile.close();

	//close USB interface
        control->closeUSBInterface();

	//delete irs3b interface object
	delete control;

	return 1;
}
