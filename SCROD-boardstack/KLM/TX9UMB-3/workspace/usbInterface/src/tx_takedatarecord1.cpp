#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h> 
#include "target6ControlClass.h"

#include <fstream>

#include <TGraph.h>
#include <TMultiGraph.h>
#include <TH1.h>
#include "TApplication.h"
#include "TCanvas.h"
#include "TAxis.h"
#include "TF1.h"
#include "TMath.h"
#include "TFile.h"
#include "TGraphErrors.h"


using namespace std;
enum OpMode {raw=0b00,pedsub=0b01,ped=0b10,wave=0b11};

int main(int argc, char* argv[]){
	if (argc != 7){
    		std::cout << "wrong number of arguments: usage \n./tx_takedatarecord1 <num events> <trig type: 0= SW, 1= HW> <Win start> <Win offset> <ASIC no> <op mode>" << std::endl;
    		return 0;
  	}

	int numEvents = atoi(argv[1]);
	if( numEvents <= 0 ){
		std::cout << "Invalid number of events, exiting" << std::endl;
		return 0;
	}

	//get trigger type
	//int trigType = 0;

	int trigType = atoi(argv[2]);
	if( trigType != 0 && trigType != 1 ){
		std::cout << "Invalid trigger type, exiting" << std::endl;
		return 0;
	}

	int WinS = atoi(argv[3]);
		if( WinS < 0 || WinS >= 509 ){
			std::cout << "Invalid Window Start-- should be between 0 and 508, exiting" << std::endl;
			return 0;
		}

		int WinOffset = atoi(argv[4]);
		if( WinOffset < 0 || WinOffset >= 512 ){
			std::cout << "Invalid Window offset-- should be between 0 and 511, exiting" << std::endl;
			return 0;
		}

		int ASICno = atoi(argv[5]);
		if( ASICno < 0 || ASICno > 10 ){
			std::cout << "Invalid ASIC no-- should be between 0 and 9, exiting" << std::endl;
			return 0;
		}

		int opmode = atoi(argv[6]);
			if( opmode < 0 || opmode > 3 ){
				std::cout << "Invalid operation mode-- \n0: Raw legacy waveform output\n1:Pedestal subtracted waveform\n2:Pedestals only\n3:Wavform only" << std::endl;
				return 0;
			}


	//define application object
	//theApp = new TApplication("App", &argc, argv);

	int regValReadback;

	//create target6 interface object
	target6ControlClass *control = new target6ControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0;
	int asic[10]={0x001,0x002,0x004,0x008,0x010,0x020,0x040,0x080,0x100,0x200};

	//clear data buffer
	control->clearDataBuffer();

	//make simple sample histogram

	//Initialize
	control->sendSamplingReset(board_id);

	int digOffset = WinOffset;

		//	control->registerWriteReadback(board_id, 11, 1, regValReadback); //Start sampling
			control->registerWriteReadback(board_id, 20, 0, regValReadback); //Digitization OFF
			control->registerWriteReadback(board_id, 30, 0, regValReadback); //Serial readout OFF
			control->registerWriteReadback(board_id, 31, 0, regValReadback); //keep test pattern gen off
			control->registerWriteReadback(board_id, 50, 0, regValReadback); //readout control start is 0
			control->registerWrite(board_id, 44, 0, regValReadback); //Stop event builder
			control->registerWrite(board_id, 45, 1, regValReadback); //Reset Event builder
			control->registerWrite(board_id, 45, 0, regValReadback); //Reset Event builder
//			control->registerWriteReadback(board_id, 51, 0x200, regValReadback); //enable ASICs for readout
			control->registerWriteReadback(board_id, 51, asic[ASICno], regValReadback); //enable ASICs for readout
			control->registerWriteReadback(board_id, 52, 0, regValReadback); //veto hardware triggers
			control->registerWriteReadback(board_id, 53, 0, regValReadback); //set trigger delay
			control->registerWriteReadback(board_id, 54, digOffset, regValReadback); //set digitization window offset
			control->registerWriteReadback(board_id, 55, 1, regValReadback); //reset readout
			control->registerWriteReadback(board_id, 55, 0, regValReadback); //reset readout
			control->registerWriteReadback(board_id, 56, 0, regValReadback); //select readout control module signals
			control->registerWriteReadback(board_id, 57, 4, regValReadback); //set # of windows to read
			control->registerWrite(board_id, 58, 0, regValReadback); //reset packet request
			control->registerWrite(board_id, 72, 0x3FF, regValReadback); //enable trigger bits
		//	control->registerWrite(board_id, 72, 0x000, regValReadback); //enable trigger bits
			control->registerWrite(board_id, 61, 0xF00, regValReadback); //ramp length- working on 40us ish
			control->registerWrite(board_id,38,0,regValReadback);//setting for using only the trig decision logic
			control->registerWrite(board_id,38,1<<11,regValReadback);//reset buffers
			control->registerWrite(board_id,38,0,regValReadback);//setting for using only the trig decision logic
			//int opmode=pedsub;
			control->registerWrite(board_id,38,opmode<<12 | 0x1<<7,regValReadback);//setting for using only the trig decision logic
			control->registerWrite(board_id,39,0b0000000000000000,regValReadback);//setting for using only the trig decision logic

			if (trigType == 0){// SW trigger, so we should use a fixed start window:
			control->registerWriteReadback(board_id, 62, 0x8000 | WinS, regValReadback); //force start digitization start window to be the fixed value
			}
			if (trigType == 1){// HW trigger, so start window is mandated by the FPGA:
			control->registerWriteReadback(board_id, 62, 0x0000 , regValReadback); //force start digitization start window to be the fixed value
			}


	//define output file		
	ofstream dataFile;
  	dataFile.open ("out_txrec1.dat", ios::out | ios::binary );

	unsigned int eventdatabuf[65536];
	int eventdataSize = 0;
	int numIter = 0;
	int samples[10][512][32];
	int PeakC=0,PeakT=0;


	unsigned int bitNum = 0;
	unsigned int addrNum = 0;
	unsigned int asicNum = 0;
	unsigned int sampNum = 0;
	unsigned int chanNum = 0;
	unsigned int winNum =0;
	unsigned int wraddrNum =0;


	int nEvt = 0;
	while(nEvt<numEvents){
		usleep(10000);

		//do software trigger
			if(trigType == 0){
				control->sendTrigger(board_id,0);
				usleep(500);
				control->registerWriteReadback(board_id, 50, 0, regValReadback);
			/*	int cnt1,cnt2;
				control->registerRead(board_id,256+5,cnt1);
				control->registerRead(board_id,256+30,cnt2);
				cout<<endl<<"SMP_Latch: "<<cnt1<<", Dig win start: "<<cnt2;*/
			}

			if(trigType == 1){
				control->registerWrite(board_id,39,1<<15 | asic[ASICno],regValReadback);//setting for using only the trig decision logic. also mask the not needed ASICs so they wont trigger.
				//cout<<"\nWaiting for SiPM Trigger...";
				usleep(10000);
				//control->registerWrite(board_id,39,0,regValReadback);//setting for using only the trig decision logic
			}


			//give the trigger some time
		usleep(50000);



		int first = 1;
		int numSmall = 0;
		numIter = 0;
		int nData=0;
		int EVTvalid=false;

		while( (eventdataSize > 100 || numSmall < 3 ) && numIter < 25 ){
		//while( numIter < 4){
			//delay, just in case readout is still in progress

			control->continueReadout(board_id);

			//usleep(1000);
	
			//parse the data packet, look for event packets
			control->readPacketFromUSBFifo( eventdatabuf, 65536, eventdataSize );
		//	std::cout << "EVENT SIZE " << eventdataSize << std::endl;
		
			//increment iterate count
			numIter++;

			//save data to file
			//myfile.write(reinterpret_cast<char*>(&eventdatabuf), eventdataSize*sizeof(unsigned int));
			if( eventdataSize > 100 ){
				first = 0;
				numSmall = 0;
				control->writeEventToFile(eventdatabuf, eventdataSize, dataFile );
				std::cout << "EVENT SIZE " << eventdataSize << ", Event Num="<<nEvt<<std::endl;
				EVTvalid=true;
				nEvt++;
			}
			else
				numSmall++;
			
			//print out packet

if (EVTvalid=true){

}
  		control->registerWrite(board_id, 55, 1, regValReadback); //make sure readout is reset
  		control->registerWrite(board_id, 55, 0, regValReadback); //make sure readout is reset
		}
		//check main_cnt variable
		control->registerRead(board_id, 261, regValReadback);
//		std::cout << std::dec << "LATCH MAIN_CNT " << regValReadback << std::endl;
		control->registerRead(board_id, 260, regValReadback);
//		std::cout << std::dec << "DIG MAIN_CNT " << regValReadback << std::endl;
//		std::cout << std::dec << "DIG OFFSET " << digOffset << std::endl;
//		std::cout << std::dec << "# Readout iterations " << nEvt << std::endl;

//		std::cout << "Please enter character, Q to quit" << std::endl;
		//std::cin >> ct;
		usleep(1000);
		
	}

	//reset readout
	control->registerWriteReadback(board_id, 50, 0, regValReadback); //readout control start is 0
	control->registerWriteReadback(board_id, 52, 0, regValReadback); //veto hardware triggers
	control->registerWrite(board_id, 55, 1, regValReadback); //make sure readout is reset
	control->registerWrite(board_id, 55, 0, regValReadback); //make sure readout is reset

	//close output file
  	dataFile.close();

	//close USB interface
        control->closeUSBInterface();

	//delete target6 interface object
	delete control;


	//f->Close();
	//delete f;

	return 1;
}





