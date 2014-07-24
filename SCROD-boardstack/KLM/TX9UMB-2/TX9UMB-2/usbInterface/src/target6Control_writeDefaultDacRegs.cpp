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
	if (argc != 2){
    		std::cout << "wrong number of arguments: usage ./target6Control_writeDefaultDacRegs <DC#>" << std::endl;
    		return 0;
  	}

	//get DC #
	int dcNum = atoi(argv[1]);
	if( dcNum < 0 || dcNum > 9 ){
		std::cout << "Invalid daughter card number, exiting" << std::endl;
		return 0;
	}

	int regValReadback;

	//create target6 interface object
	target6ControlClass *control = new target6ControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0;

	//initialize the DAC loading and latch period registers to something reasonable
	control->registerWriteReadback(board_id, 5, 128 , regValReadback);
	control->registerWriteReadback(board_id, 6, 320 , regValReadback);

	//control->writeDACReg(board_id, dcNum, regNum, regVal);

	//Trigger thresholds (PCLK 1-15)
	control->writeDACReg(board_id, dcNum, 0, 1700);
	control->writeDACReg(board_id, dcNum, 1, 1700);
	control->writeDACReg(board_id, dcNum, 2, 1700);
	control->writeDACReg(board_id, dcNum, 3, 1700);
	control->writeDACReg(board_id, dcNum, 4, 1700);
	control->writeDACReg(board_id, dcNum, 5, 1700);
	control->writeDACReg(board_id, dcNum, 6, 1700);
	control->writeDACReg(board_id, dcNum, 7, 1700);
	control->writeDACReg(board_id, dcNum, 8, 1700);
	control->writeDACReg(board_id, dcNum, 9, 1700);
	control->writeDACReg(board_id, dcNum, 10, 1700);
	control->writeDACReg(board_id, dcNum, 11, 1700);
	control->writeDACReg(board_id, dcNum, 12, 1700);
	control->writeDACReg(board_id, dcNum, 13, 1700);
	control->writeDACReg(board_id, dcNum, 14, 1700);
	control->writeDACReg(board_id, dcNum, 15, 1700);
	//ITBias (PCLK_17)
	control->writeDACReg(board_id, dcNum, 16, 1300);
	//SPAREbias (PCLK_18)
	control->writeDACReg(board_id, dcNum, 17, 1300);
	//Vbias (PCLK_19)
	control->writeDACReg(board_id, dcNum, 18, 900);
	//GGbias (PCLK_20)
	control->writeDACReg(board_id, dcNum, 19, 1600);
	//TRGbias (PCLK_21)
	control->writeDACReg(board_id, dcNum, 20, 1800);
	//Wbias (PCLK_22)
	control->writeDACReg(board_id, dcNum, 21, 700);
	//SBbuff = 2047  (PCLK_38)
	control->writeDACReg(board_id, dcNum, 37, 1400);
	//SBbias  (PCLK_39)
	control->writeDACReg(board_id, dcNum, 38, 1400);
	//MonTRGThresh (PCLK_40)
	control->writeDACReg(board_id, dcNum, 39, 0);
	//WCBuff (PCLK_41)
	control->writeDACReg(board_id, dcNum, 40, 1400);
	//CMPbias (PCLK_42)
	control->writeDACReg(board_id, dcNum, 41, 1300);
	//PUbias  (PCLK_43)
	control->writeDACReg(board_id, dcNum, 42, 2400);
	//Misc Digital Reg  (PCLK_44)
	control->writeDACReg(board_id, dcNum, 43, 0);
	//VAbuff  (PCLK_45)
	control->writeDACReg(board_id, dcNum, 44, 985);
	//VAdjN (PCLK_46)
	control->writeDACReg(board_id, dcNum, 45, 2000);
	//VAdjP (PCLK_47)
	control->writeDACReg(board_id, dcNum, 46, 2050);
	//DBbias (DAC buffer bias) (PCLK_48)
	control->writeDACReg(board_id, dcNum, 47, 1500);
	//ISEL (PCLK_49)
	control->writeDACReg(board_id, dcNum, 48, 2300);
	//Vdischarge (PCLK_50)
	control->writeDACReg(board_id, dcNum, 49, 800);
	//PROBIAS (Vdly DAC bias) (PCLK_51)
	control->writeDACReg(board_id, dcNum, 50, 1400);
	//VDLY (PCLK_52)
	control->writeDACReg(board_id, dcNum, 51, 3400);

	//close USB interface
        control->closeUSBInterface();

	//delete target6 interface object
	delete control;

	return 1;
}
