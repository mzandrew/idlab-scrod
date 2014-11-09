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

#define RAMaddrlo 32
#define RAMaddrhi 33
#define RAMdataWR 34
#define RAMupdateRW 35 // bit 0 is update, bit 1 is R (0) or W (1) mode
#define RAMdataRDbusy (256+23)



//global TApplication object declared here for simplicity
TApplication *theApp;

using namespace std;

int main(int argc, char* argv[]){
	if (argc != 3){
    		std::cout << "wrong number of arguments: usage ./SCRODA4_RAMtest02 <address> <data>" << std::endl;
    		return 0;
  	}

	int addr=atoi(argv[1]);
	int Wdata=atoi(argv[2]);



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
	cout<<"\nTesting RAM...\n";
	//int addr=1234;
	//int Wdata=28413,

	int Rdata=0,Rdata1=0;

	control->registerWrite(board_id, RAMaddrlo, addr  & 0xFFFF, regValReadback); //Address Lo
	control->registerWrite(board_id, RAMaddrhi, (addr>>16)  & 0x003F, regValReadback); //Address Hi
	control->registerWrite(board_id, RAMdataWR, Wdata & 0x00FF, regValReadback); //Data for write

	control->registerWrite(board_id, RAMupdateRW, 0 | 0, regValReadback); //Read mode
	control->registerWrite(board_id, RAMupdateRW, 0 | 1, regValReadback); //toggle update pin so it will perform operation
	control->registerWrite(board_id, RAMupdateRW, 0 | 0, regValReadback); //toggle update pin so it will perform operation
	control->registerRead(board_id,RAMdataRDbusy,Rdata1);
	usleep(10);//Now data should have been written

	control->registerWrite(board_id, RAMupdateRW, 2 | 0, regValReadback); //write mode
	control->registerWrite(board_id, RAMupdateRW, 2 | 1, regValReadback); //toggle update pin so it will perform operation
	control->registerWrite(board_id, RAMupdateRW, 2 | 0, regValReadback); //toggle update pin so it will perform operation
	usleep(10);//Now data should have been written

	control->registerWrite(board_id, RAMupdateRW, 0 | 0, regValReadback); //Read mode
	control->registerWrite(board_id, RAMupdateRW, 0 | 1, regValReadback); //toggle update pin so it will perform operation
	control->registerWrite(board_id, RAMupdateRW, 0 | 0, regValReadback); //toggle update pin so it will perform operation
	control->registerRead(board_id,RAMdataRDbusy,Rdata);
	usleep(10);//Now data should have been written

	printf("Address= (%d,%x), W data= (%d,%x), R data before=(%d,%x), Rdata after=(%d,%x)\n",addr,addr,Wdata,Wdata,Rdata1,Rdata1,Rdata,Rdata);
	
	//close USB interface
        control->closeUSBInterface();

	//delete target6 interface object
	delete control;

	return 1;
}	
