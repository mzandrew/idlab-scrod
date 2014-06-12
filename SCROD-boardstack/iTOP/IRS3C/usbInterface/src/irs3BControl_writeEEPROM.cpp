#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h>
#include "irs3BControlClass.h"

using namespace std;

int main(int argc, char* argv[]){
	if (argc != 3) {
		cout << "irs3BControl_writeEEPROM <revision #> <board ID>" << endl;
		return 1;
	}

	int revisionNum = atoi(argv[1]);
        if( revisionNum < 0 || revisionNum > 511 ){
                std::cout << "Invalid revisionNum requested, exiting" << std::endl;
                return 0;
        }

	int boardNum = atoi(argv[2]);
        if( boardNum < 0 || boardNum > 511 ){
                std::cout << "Invalid board number requested, exiting" << std::endl;
                return 0;
        }


	//create irs3b interface object
	irs3BControlClass *control = new irs3BControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0x0;

	control->setSCRODEEPROM(boardNum, revisionNum);

	//close USB interface
        control->closeUSBInterface();

	//delete irs3b interface object
	delete control;

	return 1;
}
