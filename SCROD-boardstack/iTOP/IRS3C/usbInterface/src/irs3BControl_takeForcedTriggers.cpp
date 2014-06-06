#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <fstream>
#include <stdlib.h> 
#include "irs3BControlClass.h"
#include "TApplication.h"

using namespace std;

//global TApplication object declared here for simplicity
TApplication *theApp;

//global variables
int numEvents = 100;

int main(int argc, char* argv[]){
	int rowNum = -1;
	int colNum = -1;
	int chNum = -1;
	int calEnable = -1;

	if (argc != 6) {
		cout << "irs3BControl_takeData <rowNum> <colNum> <chNum> <calEnable> <numEvents>" << endl;
		return 1;
	}

	rowNum = atoi(argv[1]);
        if( rowNum < 0 || rowNum > 3 ){
                std::cout << "Invalid row number requested, exiting" << std::endl;
                return 0;
        }

	colNum = atoi(argv[2]);
        if( colNum < 0 || colNum > 3 ){
                std::cout << "Invalid col number requested, exiting" << std::endl;
                return 0;
        }

	chNum = atoi(argv[3]);
        if( chNum < 0 || chNum > 7 ){
                std::cout << "Invalid ch number requested, exiting" << std::endl;
                return 0;
        }

	calEnable  = atoi(argv[4]);
	if( calEnable != 0 && calEnable != 1 ){
                std::cout << "Invalid cal enable setting, exiting" << std::endl;
                return 0;
        }

	numEvents  = atoi(argv[5]);
	if( numEvents <= 0 ){
                std::cout << "Invalid number of events requested, exiting" << std::endl;
                return 0;
        }

	//define application object
	theApp = new TApplication("App", &argc, argv);

	//create irs3b interface object
	irs3BControlClass *control = new irs3BControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0x0;
	int regValReadback;

	//set minimum and maximum lookbacks
	control->registerWrite(board_id, 163, 59, regValReadback); //max lookback
	control->registerWrite(board_id, 164, 4, regValReadback); //minimum lookback

	//set first and last allowed windows
	control->registerWrite(board_id, 161, 0, regValReadback);
	control->registerWrite(board_id, 162, 63, regValReadback);

	//reset forced readout registers (171-178) ignore readout registers (179-186)
	for( int i = 171 ; i <= 186 ; i++ )
		control->registerWrite(board_id, i, 0, regValReadback);

	//set forced readout mode: registers 171 - 178
	control->setForcedReadoutRegister(board_id, rowNum, colNum, chNum );

	//reroute calibration signal to intended channel
	control->selectCalibrationDestination(board_id, rowNum, colNum, chNum, calEnable);

	//define output file 
	char name[100];
	memset(name,0,sizeof(char)*100 );
	sprintf(name,"output_takeForcedTriggers_%.1i_%.1i_%.1i.dat",rowNum,colNum,chNum);           
        ofstream dataFile;
        dataFile.open (name, ios::out | ios::binary );

	//take waveform data, applying pedestal correction
	for( int nevt = 0 ; nevt < numEvents ; nevt++){
		//send trigger
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
