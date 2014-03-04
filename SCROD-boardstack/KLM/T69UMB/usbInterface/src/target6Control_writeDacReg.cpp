#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h> 
#include "target6ControlClass.h"

using namespace std;

int main(int argc, char* argv[]){
	if (argc != 4){
    		std::cout << "wrong number of arguments: usage ./target6Control_writeDacReg <DC#> <ASIC REG#> <DAC VAL>" << std::endl;
    		return 0;
  	}

	int dcNum = atoi(argv[1]);
	int regNum = atoi(argv[2]);
	int regVal = atoi(argv[3]);
	int regValReadback;

	if( dcNum < 0 || dcNum > 9 ){
		std::cout << "Invalid daughter card number, exiting" << std::endl;
		return 0;
	}
	if( regNum < 0 || regNum > 1024 ){
		std::cout << "Invalid register number, exiting" << std::endl;
		return 0;
	}
	if( regVal < 0 || regVal > 0xFFFF ){
		std::cout << "Invalid register value, exiting" << std::endl;
		return 0;
	}

	//create target6 interface object
	target6ControlClass *control = new target6ControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0;

	//begin ASIC DAC programming through software, uses regNum and regVal
	std::cout << "Start DAC Program Process - Writing DC # " << dcNum << "\tRegister " << regNum << "\tValue " << regVal << std::endl;
	
	control->writeDACReg(board_id, dcNum, regNum, regVal);

	/*
	//clear update i/o register (register #0)
	control->registerWriteReadback(board_id, 1, 0, regValReadback);

	//set the correct bit in the DAC loading DC# mask
	control->registerWriteReadback(board_id, 4, (1 << dcNum) , regValReadback);

	//initialize the DAC loading and latch period registers to something reasonable
	control->registerWriteReadback(board_id, 5, 256 , regValReadback);
	control->registerWriteReadback(board_id, 6, 640 , regValReadback);

	//write desired ASIC register # and DAC to corresponding firmware i/o registers
	control->registerWriteReadback(board_id, 2, regNum, regValReadback);
	control->registerWriteReadback(board_id, 3, regVal, regValReadback);

	//set bit of update i/o register (register #0)
	control->registerWriteReadback(board_id, 1, 1, regValReadback);

	//wait some time
	usleep(100);

	//clear update i/o register (register #0)
	control->registerWriteReadback(board_id, 1, 0, regValReadback);

	*/
	
	//close USB interface
        control->closeUSBInterface();

	//delete target6 interface object
	delete control;

	return 1;
}
