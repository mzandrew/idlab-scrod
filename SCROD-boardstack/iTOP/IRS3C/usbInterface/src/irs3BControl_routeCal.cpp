#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h>
#include "irs3BControlClass.h"

using namespace std;

int main(int argc, char* argv[]){
	if (argc != 5) {
		cout << "irs3BControl_routeCal <row> <col> <ch> <enable/disable>" << endl;
		return 1;
	}

	//get input parameters
	int row =  atoi(argv[1]);
	int col =  atoi(argv[2]);
	int ch =  atoi(argv[3]);
	int enable =  atoi(argv[4]);
	if( row < 0 || row > 3 || col < 0 || col > 3 || ch < 0 || ch > 7 || enable < 0 || enable > 1 ){
		std::cout << "Invalid register number, exiting" << std::endl;
		return 0;
	}

	//create irs3b interface object
	irs3BControlClass *control = new irs3BControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0x0;

	//try routing input calibration signal - board id, row, col ch, enable/disable
	control->selectCalibrationDestination(board_id, row, col, ch, enable);

	//close USB interface
        control->closeUSBInterface();

	//delete irs3b interface object
	delete control;

	return 1;
}
