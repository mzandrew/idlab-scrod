#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h>
#include "irs3BControlClass.h"

using namespace std;

int main(int argc, char* argv[]){
	if (argc != 1) {
		cout << "irs3BControl_readTemps " << endl;
		return 1;
	}

	//create irs3b interface object
	irs3BControlClass *control = new irs3BControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0x0;

	//setup GPIOs
	//control->setupGPIOs_irs3B_carrierRevC(board_id);

	//check temperatures (sanity check)
	control->readTemperatures(board_id);

	//close USB interface
        control->closeUSBInterface();

	//delete irs3b interface object
	delete control;

	return 1;
}
