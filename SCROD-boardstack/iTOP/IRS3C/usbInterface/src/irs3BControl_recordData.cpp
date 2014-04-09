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

//global variables for quick testing
//setting variables for readouts on row 0 col 2 ch 2
//set forced readout mode: registers 171 - 178, row 0 col 2 = register 175, lower 8 bits, set channel 2 for readout
int ForcedReadoutReg = 175; //Forced readout for row 0 col 2 ch 2
int ForcedReadoutVal = 0x0004; //Forced readout for row 0 col 2 ch 2
int numEvents = 100;
int rowNum = 0;
int colNum = 2;
int chNum = 2;
bool calEnable = 1;

int main(int argc, char* argv[]){
	if (argc != 6) {
		cout << "irs3BControl_recordData #event row col ch calEnable" << endl;
		return 1;
	}

	//get event #, row, col, ch, cal enable
        numEvents = atoi(argv[1]);
        if( numEvents <= 0 ){
                std::cout << "Invalid number of events, exiting" << std::endl;
                return 0;
        }

	rowNum = atoi(argv[2]);
        if( rowNum < 0 || rowNum > 3 ){
                std::cout << "Invalid row number requested, exiting" << std::endl;
                return 0;
        }

	colNum = atoi(argv[3]);
        if( colNum < 0 || colNum > 3 ){
                std::cout << "Invalid col number requested, exiting" << std::endl;
                return 0;
        }

	chNum = atoi(argv[4]);
        if( chNum < 0 || chNum > 7 ){
                std::cout << "Invalid ch number requested, exiting" << std::endl;
                return 0;
        }

	calEnable  = atoi(argv[5]);
	if( calEnable != 0 && calEnable != 1 ){
                std::cout << "Invalid cal enable setting, exiting" << std::endl;
                return 0;
        }

	//define application object
	theApp = new TApplication("App", &argc, argv);

	//define output file            
        ofstream dataFile;
        dataFile.open ("output_irs3BControl_recordData.dat", ios::out | ios::binary );

	//create irs3b interface object
	irs3BControlClass *control = new irs3BControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0x0;
	int regValReadback;
	char ct;

	//reset forced readout registers (171-178) ignore readout registers (179-186)
	for( int i = 171 ; i <= 186 ; i++ )
		control->registerWrite(board_id, i, 0, regValReadback);

	//set forced readout mode: registers 171 - 178
	//row 0 col 2 = register 175, lower 8 bits, set channel 2 for readout
	control->registerWrite(board_id, ForcedReadoutReg, ForcedReadoutVal, regValReadback);

	//set minimum and maximum lookbacks
	control->registerWrite(board_id, 163, 7, regValReadback); //max lookback
	control->registerWrite(board_id, 164, 0, regValReadback); //minimum lookback

	//set first and last allowed windows
	control->registerWrite(board_id, 161, 0, regValReadback);
	control->registerWrite(board_id, 162, 59, regValReadback);

	//set trigger delay
	control->registerWrite(board_id, 188, 0, regValReadback);

	//reroute calibration signal to intended channel
	control->selectCalibrationDestination(board_id, rowNum, colNum, chNum, calEnable);

	//take waveform data, applying pedestal correction
	for( int nevt = 0 ; nevt < numEvents ; nevt++){
		//send software trigger
		control->sendSoftwareTrigger(board_id);

		//get USB data - write to files
		unsigned int eventdatabuf[65536];
		int eventdataSize = 0;
		control->readPacketFromUSBFifo( eventdatabuf, 65536, eventdataSize );
		if( eventdataSize > 10 )
			control->writeEventToFile(eventdatabuf, eventdataSize, dataFile );
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
