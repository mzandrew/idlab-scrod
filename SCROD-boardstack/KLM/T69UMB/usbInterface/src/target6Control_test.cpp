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

	//make simple sample histogram
	TCanvas *c0 = new TCanvas("c0","c0",1300,800);
	TH1F *hSampDist = new TH1F("hSampDist","",110,3000,4100);

	//initialize
	int srSel = 0;
	int srClk = 0;
	int srClr = 0;
	int sampleSel = 0;
	int sampleSelAny = 0;
	int srSelReg = 11;
	int srClkReg = 12;
	int srClrReg = 13;
	int sampleSelReg = 14;
	int sampleSelAnyReg = 15;
	
	
	control->registerWriteReadback(board_id, 9, 0, regValReadback);
	control->registerWriteReadback(board_id, 10, 0, regValReadback);

	srSel = 0; srClk = 0; srClr = 0; sampleSel = 0; sampleSelAny = 0;
	control->registerWriteReadback(board_id, srSelReg, srSel, regValReadback);
	control->registerWriteReadback(board_id, srClkReg, srClk, regValReadback);
	control->registerWriteReadback(board_id, srClrReg, srClr, regValReadback);
	control->registerWriteReadback(board_id, sampleSelReg, sampleSel, regValReadback);
	control->registerWriteReadback(board_id, sampleSelAnyReg, sampleSelAny, regValReadback);
	usleep(1);

	for(int numLoop = 0 ; numLoop < 50 ; numLoop++){

	//start sampling process
	std::cout << "Start a sampling process " << std::endl;
	control->registerWriteReadback(board_id, 9, 0, regValReadback);
	usleep(10);
	control->registerWriteReadback(board_id, 9, 1, regValReadback);
	usleep(10);

	//see if trigger occurred
	//control->registerRead(board_id, 67, regValReadback) );
	//if( regValReadback == 0 ){
	//	std::cout << "No trigger, continuing " << std::endl;
	//	continue;
	//}
	
	std::cout << "Start a digitization process " << std::endl;
	control->registerWriteReadback(board_id, 10, 1, regValReadback);
	usleep(50);
	//control->registerWriteReadback(board_id, 10, 0, regValReadback);
	//usleep(1);

	//readout digital data through shift register interface
	for(int i = 0 ; i < 1 ; i++ ){
		//set samplesel to desired value
		srSel = 0; srClk = 0; srClr = 0; sampleSel = i; sampleSelAny = 0;
		control->registerWriteReadback(board_id, sampleSelReg, sampleSel, regValReadback);
		usleep(1);

		//set samplesel_any = 1
		srSel = 0; srClk = 0; srClr = 0; sampleSel = i; sampleSelAny = 1;
		control->registerWriteReadback(board_id, sampleSelAnyReg, sampleSelAny, regValReadback);
		usleep(1);

		//set srSel = 1
		srSel = 1; srClk = 0; srClr = 0; sampleSel = i; sampleSelAny = 1;
		control->registerWriteReadback(board_id, srSelReg, srSel, regValReadback);
		usleep(1);

		//set srClk = 1
		srSel = 1; srClk = 1; srClr = 0; sampleSel = i; sampleSelAny = 1;
		control->registerWriteReadback(board_id, srClkReg, srClk, regValReadback);
		usleep(1);

		//set srSel = 0
		srSel = 0; srClk = 1; srClr = 0; sampleSel = i; sampleSelAny = 1;
		control->registerWriteReadback(board_id, srSelReg, srSel, regValReadback);
		usleep(1);

		int samples[16] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
		std::cout << "Sample sel = " << i << std::endl;
		for(int j = 0 ; j < 12 ; j++ ){
			//set srClk = 1
			srSel = 0; srClk = 1; srClr = 0; sampleSel = i; sampleSelAny = 1;
			control->registerWriteReadback(board_id, srClkReg, srClk, regValReadback);
			usleep(1);
	
			//set srClk = 0
			srSel = 0; srClk = 0; srClr = 0; sampleSel = i; sampleSelAny = 1;
			control->registerWriteReadback(board_id, srClkReg, srClk, regValReadback);

			control->registerRead(board_id, 64+1, regValReadback);
			//std::cout << "\tD0 " << std::hex << regValReadback << std::dec << std::endl;

			for(int k = 0 ; k < 16 ; k++){
				int temp = regValReadback;
				samples[k] = ( (samples[k] << 1) | ( (temp >> k ) & 0x1 ));
				//samples[k] = ( samples[k] | ( (temp >> k ) & 0x1 ) << j );
			}

			usleep(1);

		}
		
		//cycle SR clock once more
		//set srClk = 1
		srSel = 0; srClk = 1; srClr = 0; sampleSel = i; sampleSelAny = 1;
		control->registerWriteReadback(board_id, srClkReg, srClk, regValReadback);
		usleep(1);
	
		//set srClk = 0
		srSel = 0; srClk = 0; srClr = 0; sampleSel = i; sampleSelAny = 1;
		control->registerWriteReadback(board_id, srClkReg, srClk, regValReadback);
		usleep(1);

		for(int k = 0 ; k < 2 ; k++)
			std::cout << "Sample ch # " << k << "\t" << std::hex << samples[k] << "\t" << std::dec << samples[k] << std::endl;
		if(samples[0] < 20 )
			hSampDist->Fill(4096);
		else
			hSampDist->Fill(samples[0]);
		
	}

	//reset
	control->registerWriteReadback(board_id, 9, 0, regValReadback);
	control->registerWriteReadback(board_id, 10, 0, regValReadback);
	srSel = 0; srClk = 0; srClr = 0; sampleSel = 0; sampleSelAny = 0;
	control->registerWriteReadback(board_id, srSelReg, srSel, regValReadback);
	control->registerWriteReadback(board_id, srClkReg, srClk, regValReadback);
	control->registerWriteReadback(board_id, srClrReg, srClr, regValReadback);
	control->registerWriteReadback(board_id, sampleSelReg, sampleSel, regValReadback);
	control->registerWriteReadback(board_id, sampleSelAnyReg, sampleSelAny, regValReadback);
	usleep(10);

	}

	//close USB interface
        control->closeUSBInterface();

	//delete target6 interface object
	delete control;

	c0->Clear();
	hSampDist->Draw();
	c0->Update();

	TFile *f = new TFile( "output_target6Control_test.root" , "RECREATE");
	hSampDist->Write();
  	f->Close();
	delete f;

	return 1;
}
