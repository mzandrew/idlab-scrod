#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h> 
#include "target6ControlClass.h"

#include <TGraph.h>
#include <TH1.h>
#include "TApplication.h"
#include "TCanvas.h"
#include "TAxis.h"
#include "TF1.h"
#include "TMath.h"
#include "TFile.h"
#include "TGraphErrors.h"


using namespace std;

int main(int argc, char* argv[]){
	if (argc != 1){
    		std::cout << "wrong number of arguments: usage ./target6Control_test" << std::endl;
    		return 0;
  	}

	//int regNum = atoi(argv[1]);
	//int regVal = atoi(argv[2]);
	int regValReadback;

	//if( regNum < 0 || regNum > 1024 ){
	//	std::cout << "Invalid register number, exiting" << std::endl;
	//	return 0;
	//}
	//if( regVal < 0 || regVal > 0xFFFF ){
	//	std::cout << "Invalid register value, exiting" << std::endl;
	//	return 0;
	//}

	//create target6 interface object
	target6ControlClass *control = new target6ControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0;

	//write a register
	//if( !control->registerWriteReadback(board_id, 0, 1023, regValReadback) )
	//	std::cout << "Register write failed" << std::endl;
	//std::cout << "ASIC register: " << regNum;
	//std::cout << "ASIC register value: " << regVal;
	//std::cout << std::endl;

	//loop over channel 0 trigger threshold values
	for(int i = 0 ; i < 40 ; i++){
		int threshold = 1800+10*i;
		control->registerWriteReadback(board_id, 0, threshold, regValReadback);

		int count1, count2, count3;

		control->registerRead(board_id, 267, count1);
		sleep(10);
		control->registerRead(board_id, 267, count2);
		sleep(10);
		control->registerRead(board_id, 267, count3);
		sleep(10);

		std::cout << "Threshold\t" << threshold << "\tCounter\t" << count1 << "\t" << count2 << "\t" << count3 << std::endl;
		
	}

	//close USB interface
        control->closeUSBInterface();

	//delete target6 interface object
	delete control;

	return 1;
}
