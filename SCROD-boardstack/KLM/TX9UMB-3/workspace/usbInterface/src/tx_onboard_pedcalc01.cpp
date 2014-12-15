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
    		std::cout << "wrong number of arguments: usage ./tx_onboard_pedcalc01 <Navg> <Win start>  <Win end> <ASIC no>\n where 2**Navg will be the number of averages applied\n Win start is the start window 0 to 508 \n Win E is the end window 4 to 511 \n ASIC no is 0 to 9\n" << std::endl;
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

	int WinE = atoi(argv[3]);
	if( WinE < 4 || WinE >= 512 ){
		std::cout << "Invalid Window End-- should be between 4 and 511, exiting" << std::endl;
		return 0;
	}

	int ASICno = atoi(argv[4]);
	if( ASICno < 0 || ASICno > 10 ){
		std::cout << "Invalid ASIC no-- should be between 0 and 9, exiting" << std::endl;
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
	control->sendSamplingReset(board_id);
	int digOffset = 0;
	int asic[10]={0x001,0x002,0x004,0x008,0x010,0x020,0x040,0x080,0x100,0x200};

	control->registerWriteReadback(board_id, 20, 0, regValReadback); //Digitization OFF
	control->registerWriteReadback(board_id, 30, 0, regValReadback); //Serial readout OFF
	control->registerWriteReadback(board_id, 50, 0, regValReadback); //readout control start is 0
	control->registerWrite(board_id, 44, 0, regValReadback); //Stop event builder
	control->registerWrite(board_id, 45, 1, regValReadback); //Reset Event builder
	control->registerWrite(board_id, 45, 0, regValReadback); //Reset Event builder
//	control->registerWriteReadback(board_id, 51, 0x200, regValReadback); //enable ASICs for readout: 7/12/14: IM: changed such that only DC10 is measured
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

	ofstream dataFile;
	  	dataFile.open ("output_legacypeds.dat", ios::out | ios::binary );

for (int nWin=WinS;nWin<WinE;nWin+=4)
{
	cout<<"nWin= "<<nWin<<", ";
	control->registerWriteReadback(board_id, 51, asic[ASICno], regValReadback); //enable ASICs for readout: 7/12/14: IM: changed such that only DC10 is measured
	control->registerWriteReadback(board_id, 62, 0x8000 | nWin, regValReadback); //force start digitization start window to be the fixed value
	control->registerWrite(board_id,38,0b0100000000000000 | Navg,regValReadback);//setting for
	control->registerWrite(board_id,38,0b0100000000000000 | Navg,regValReadback);//setting for
	control->registerWrite(board_id,38,0b1100000000000000 | Navg,regValReadback);//setting for
	control->registerWrite(board_id,38,0b0100000000000000 | Navg,regValReadback);//setting for
	control->registerWrite(board_id,39,0b0000000000000000,regValReadback);//setting for using only the trig decision logic


	//define output file		

	unsigned int eventdatabuf[65536];
	int eventdataSize = 0;
	int numIter = 0;

	for( int numEv = 0 ; numEv < numEvents ; numEv++ )
	{
		//if( numEv % 10 == 0 )
		std::cout << "\nEvent # " << numEv << std::endl;
		//do software trigger

		control->sendTrigger(board_id,0);
		control->registerWriteReadback(board_id, 50, 0, regValReadback);

		usleep(5000);
		int cnt1,cnt2,niter;
		control->registerRead(board_id,256+5,cnt1);
		control->registerRead(board_id,256+30,cnt2);
		cout<<endl<<"SMP_Latch: "<<cnt1<<", Dig win start: "<<cnt2;
		control->registerRead(board_id,256+33,niter);
		cout<<endl<<"Iteration: "<< std::hex << niter << std::dec<<endl;

		int first = 1;
		int numSmall = 0;
		numIter = 0;
		while( (eventdataSize > 100 || numSmall < 3 ) && numIter < 25 ){
		//while( numIter < 4){
			//delay, just in case readout is still in progress
			
			//toggle continue bit
			control->continueReadout(board_id);
			//parse the data packet, look for event packets
			control->readPacketFromUSBFifo( eventdatabuf, 65536, eventdataSize );
			//increment iterate count
			numIter++;
			//save data to file
			if( eventdataSize > 100 ){
				first = 0;
				numSmall = 0;
				control->writeEventToFile(eventdatabuf, eventdataSize, dataFile );
			}
			else
				numSmall++;
		}
	}

	//reset readout
	control->registerWriteReadback(board_id, 50, 0, regValReadback); //readout control start is 0
	control->registerWriteReadback(board_id, 52, 0, regValReadback); //veto hardware triggers
	control->registerWrite(board_id, 55, 1, regValReadback); //make sure readout is reset
	control->registerWrite(board_id, 55, 0, regValReadback); //make sure readout is reset

}

	//close output file
  	dataFile.close();

	//close USB interface
        control->closeUSBInterface();

	//delete target6 interface object
	delete control;

	return 1;
}	
