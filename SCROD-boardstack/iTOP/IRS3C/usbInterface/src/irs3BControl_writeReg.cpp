#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h> 
#include "irs3BControlClass.h"

using namespace std;

int main(int argc, char* argv[]){
	if (argc != 3){
    		std::cout << "wrong number of arguments: usage ./isr3BControl_writeReg <reg num> <reg val>" << std::endl;
    		return 0;
  	}

  	int regNum = atoi(argv[1]);
	int regVal = atoi(argv[2]);

	if( regNum < 0 || regNum > 1024 ){
		std::cout << "Invalid register number, exiting" << std::endl;
		return 0;
	}
	if( regVal < 0 || regVal > 0xFFFF ){
		std::cout << "Invalid register value, exiting" << std::endl;
		return 0;
	}

	//create irs3b interface object
	irs3BControlClass *control = new irs3BControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0x0;

	//write the register
	int regValReadback;
	if( !control->registerWriteReadback(board_id, regNum, regVal, regValReadback) )
		std::cout << "Register write failed" << std::endl;
	
	std::cout << "Register " << regNum << "\t=\t" << regValReadback << "\thex " << std::hex << regValReadback << std::dec << std::endl;
	std::cout << std::endl;

	//close USB interface
        control->closeUSBInterface();

	//delete irs3b interface object
	delete control;

	return 1;
}
