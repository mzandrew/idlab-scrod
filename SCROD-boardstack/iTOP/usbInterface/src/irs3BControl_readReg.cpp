#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h>
#include "irs3BControlClass.h"

using namespace std;

int main(int argc, char* argv[]){
	if (argc != 2){
    		std::cout << "wrong number of arguments: usage ./isr3BControl_readReg <reg num>" << std::endl;
    		return 0;
  	}

	//make sure register value is OK
  	int regNum = atoi(argv[1]);
	if( regNum < 0 || regNum > 1024 ){
		std::cout << "Invalid register number, exiting" << std::endl;
		return 0;
	}

	//create irs3b interface object
	irs3BControlClass *control = new irs3BControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0x00A20021;

	//read the register
	int regValReadback;
	if( !control->registerRead(board_id, regNum, regValReadback) )
		std::cout << "Register read failed, exiting" << std::endl;
	
	std::cout << "Register " << regNum << "\t=\t" << regValReadback << "\thex " << std::hex << regValReadback << std::dec << std::endl;
	std::cout << std::endl;

	//close USB interface
        control->closeUSBInterface();

	//delete irs3b interface object
	delete control;

	return 1;
}
