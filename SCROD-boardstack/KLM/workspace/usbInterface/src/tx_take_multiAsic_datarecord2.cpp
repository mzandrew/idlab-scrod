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
	if (argc != 5){
    		std::cout << "Multi Asic readout and recording. Wrong number of arguments: usage \n./tx_take_multiAsic_datarecord2 <num events> <Win offset> <ASIC bitmask> <op mode>" << std::endl;
    		return 0;
  	}

	int numEvents = atoi(argv[1]);
	if( numEvents <= 0 ){
		std::cout << "Invalid number of events, exiting" << std::endl;
		return 0;
	}

	int WinOffset = atoi(argv[2]);
	if( WinOffset < 0 || WinOffset >= 512 ){
		std::cout << "Invalid Window offset-- should be between 0 and 511, exiting" << std::endl;
		return 0;
	}

		int ASICmask = atoi(argv[3]);
		if( ASICmask < 0 || ASICmask > 1023 ){
			std::cout << "Invalid ASIC Mask-- should be between 2^0 and 2^9-1, exiting" << std::endl;
			return 0;
		}

		int opmode = atoi(argv[4]);
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
//	int asic[10]={0x001,0x002,0x004,0x008,0x010,0x020,0x040,0x080,0x100,0x200};

	//clear data buffer
	control->clearDataBuffer();

	//make simple sample histogram

	//Initialize
	//control->sendSamplingReset(board_id);

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
			control->registerWriteReadback(board_id, 51, ASICmask, regValReadback); //enable ASICs for readout
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

			control->registerWrite(board_id,11,32<<10 | 0b01,regValReadback);//setting for wr_addr_clr_start phase
			control->sendSamplingReset(board_id);


			control->registerWriteReadback(board_id, 62, 0x0000 , regValReadback); //force start digitization start window to be the fixed value


	//define output file		
	ofstream dataFile;
  	dataFile.open ("outdir/out_txrec1.dat", ios::out | ios::binary );

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

	control->registerWriteReadback(board_id, 70,0, regValReadback);
	control->registerWriteReadback(board_id, 71,0, regValReadback);
	control->registerWriteReadback(board_id, 71,1, regValReadback);
	control->registerWriteReadback(board_id, 71,0, regValReadback);
	control->registerWriteReadback(board_id, 70,1, regValReadback);


	int nEvt = 0;
	while(nEvt<numEvents){
		usleep(10000);



		control->registerWrite(board_id,39,1<<15 | 1<<14 | ASICmask,regValReadback);//setting for using only the trig decision logic. trig based on X and Y logic, and keep all ASICs on
			cout<<"Waiting for SiPM Trigger...\n";
			usleep(10000);
			//control->registerWrite(board_id,39,0,regValReadback);//setting for using only the trig decision logic



			//give the trigger some time
		usleep(50000);



		int first = 1;
		int numSmall = 0;
		numIter = 0;
		int nData=0;
		int trg_scaler_lo,trg_scaler_hi=0;
		int EVTvalid=false;


		while( (eventdataSize > 100 || numSmall < 2 ) && numIter < 10 ){
		//while( numIter < 4){
			//delay, just in case readout is still in progress

			control->continueReadout(board_id);

			//usleep(1000);
	
			//parse the data packet, look for event packets
			control->readPacketFromUSBFifo( eventdatabuf, 65536, eventdataSize );
			control->registerRead(board_id,256+24,trg_scaler_lo);
			control->registerRead(board_id,256+25,trg_scaler_hi);
			cout<<trg_scaler_lo+trg_scaler_hi*65536<<",";
			//std::cout << "EVENT SIZE, Iter " << eventdataSize <<", "<<numIter << std::endl;
		
			//increment iterate count
			numIter++;

			//save data to file
			//myfile.write(reinterpret_cast<char*>(&eventdatabuf), eventdataSize*sizeof(unsigned int));
			if( eventdataSize > 100 ){
				first = 0;
				numSmall = 0;
				control->writeEventToFile(eventdatabuf, eventdataSize, dataFile );
				std::cout << "EVENT SIZE " << eventdataSize << ", Event Num="<<nEvt;//<<std::endl;
				for (int i=0;i<eventdataSize;i++)
					if ((eventdatabuf[i] & 0xFE000000)==0xFE000000) printf(" %x,",eventdatabuf[i]);

				std::cout<<std::endl;

			EVTvalid=true;
				nEvt++;
			}
			else
				numSmall++;
			
			//print out packet

			if (EVTvalid=true){
			}

  			}

		control->registerWrite(board_id, 55, 1, regValReadback); //make sure readout is reset
	  	control->registerWrite(board_id, 55, 0, regValReadback); //make sure readout is reset


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





