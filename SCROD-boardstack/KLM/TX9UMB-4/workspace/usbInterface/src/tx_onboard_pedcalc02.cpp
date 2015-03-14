#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h> 
#include "target6ControlClass.h"

#include <fstream>

#include <TGraph.h>
#include <TH1.h>
#include "TApplication.h"
#include "TCanvas.h"
#include "TAxis.h"
#include "TF1.h"
#include "TMath.h"
#include "TFile.h"
#include "TGraphErrors.h"

//global TApplication object declared here for simplicity
TApplication *theApp;

using namespace std;

int main(int argc, char* argv[]){
	if (argc != 5){
    		std::cout << "wrong number of arguments: usage ./tx_onboard_pedcalc02 <Navg> <Win start>  <Win Len> <ASIC mask>\n where 2**Navg will be the number of averages applied\n Win start is the start window 0 to 508 \n Win Len is the end window multiple of 4 1..127 \n ASIC mask is 0 to 1023\n" << std::endl;
    		return 0;
  	}

	//get event #
	int Navg = atoi(argv[1]);
	if( Navg < 0 || Navg >= 8 ){
		std::cout << "Invalid number of Navg-- should be between 0 and 7, exiting" << std::endl;
		return 0;
	}
	int numEvents=1<<Navg;

	int WinS = atoi(argv[2]);
	if( WinS < 0 || WinS >= 509 ){
		std::cout << "Invalid Window Start-- should be between 0 and 508, exiting" << std::endl;
		return 0;
	}

	int WinL = atoi(argv[3]);
	if( WinL < 1 || WinL > 127 ){
		std::cout << "Invalid Window Len-- should be between 1 and 127, exiting" << std::endl;
		return 0;
	}

	int ASICmask = atoi(argv[4]);
	if( ASICmask < 0 || ASICmask > 1023 ){
		std::cout << "Invalid ASIC mask-- should be between 0 and 1023, exiting" << std::endl;
		return 0;
	}


	//get trigger type

	//define application object
	theApp = new TApplication("App", &argc, argv);

	int regValReadback;

	//create target6 interface object
	target6ControlClass *control = new target6ControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0;

	//clear data buffer
	control->clearDataBuffer();

	//make simple sample histogram
	TCanvas *c0 = new TCanvas("c0","c0",1300,800);
	TH1F *hSampDist = new TH1F("hSampDist","",110,3000,4100);

	//Initialize

	int digOffset = 0;

	control->registerWriteReadback(board_id, 20, 0, regValReadback); //Digitization OFF
	control->registerWriteReadback(board_id, 30, 0, regValReadback); //Serial readout OFF
	control->registerWriteReadback(board_id, 50, 0, regValReadback); //readout control start is 0
	control->registerWrite(board_id, 44, 0, regValReadback); //Stop event builder
	control->registerWrite(board_id, 45, 1, regValReadback); //Reset Event builder
	control->registerWrite(board_id, 45, 0, regValReadback); //Reset Event builder
//	control->registerWriteReadback(board_id, 51, 0x200, regValReadback); //enable ASICs for readout: 7/12/14: IM: changed such that only DC10 is measured
	control->registerWriteReadback(board_id, 51, ASICmask, regValReadback); //enable ASICs for readout
	control->registerWriteReadback(board_id, 52, 0, regValReadback); //veto hardware triggers
	control->registerWriteReadback(board_id, 53, 0, regValReadback); //set trigger delay
	control->registerWriteReadback(board_id, 54, digOffset, regValReadback); //set digitization window offset: internal_CMDREG_READCTRL_dig_offset
	control->registerWriteReadback(board_id, 55, 1, regValReadback); //reset readout
	control->registerWriteReadback(board_id, 55, 0, regValReadback); //reset readout
	control->registerWriteReadback(board_id, 56, 0, regValReadback); //select readout control module signals
	control->registerWriteReadback(board_id, 57, 4, regValReadback); //set # of windows to read: internal_READCTRL_win_num_to_read
	control->registerWrite(board_id, 58, 0, regValReadback); //reset packet request
	control->registerWrite(board_id, 72, 0x3FF, regValReadback); //enable trigger bits
	control->registerWrite(board_id, 61, 0xF00, regValReadback); //ramp length- working on 40us ish
	control->registerWrite(board_id,38,0,regValReadback);//setting for using only the trig decision logic
	control->registerWrite(board_id,38,1<<11,regValReadback);//reset buffers
	control->registerWrite(board_id,38,0,regValReadback);//setting for using only the trig decision logic

	ofstream dataFile;
	  	dataFile.open ("outdir/output_legacypeds.dat", ios::out | ios::binary );

		control->registerWrite(board_id,11,32<<10 | 0b01,regValReadback);//setting for wr_addr_clr_start phase
		control->sendSamplingReset(board_id);

		control->registerWrite(board_id,38,0b0000000000000000 | Navg,regValReadback);//setting for
		control->registerWrite(board_id,38,0b0100000000000000 | Navg,regValReadback);//setting for
		control->registerWrite(board_id,38,0b1100000000000000 | Navg,regValReadback);//setting for
		control->registerWrite(board_id,38,0b0100000000000000 | Navg,regValReadback);//setting for
		control->registerWrite(board_id,39,0b0000000000000000,regValReadback);//setting for using only the trig decision logic

		control->registerWriteReadback(board_id, 42, WinL<<9 | WinS, regValReadback); //win start and length
		control->registerWriteReadback(board_id, 41, ASICmask, regValReadback); //enable ASICs for readout- ped calc
		control->registerWriteReadback(board_id, 41,1<<15 |  ASICmask, regValReadback); //enable ASICs for readout- ped calc
		control->registerWriteReadback(board_id, 41, ASICmask, regValReadback); //enable ASICs for readout- ped calc

		usleep(50000);

//	control->registerWrite(board_id,38,0b0000000000000000 | Navg,regValReadback);//setting for


	//close output file
  	dataFile.close();

	//close USB interface
        control->closeUSBInterface();

	//delete target6 interface object
	delete control;

	return 1;
}	
