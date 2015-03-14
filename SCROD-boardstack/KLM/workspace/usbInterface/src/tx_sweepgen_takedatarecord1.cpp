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
	if (argc != 9){
    		std::cout << "wrong number of arguments: usage \n./tx_takedatarecord1 <Win start> <Win end> <ncycles> <delay start> <delay end> <delay step> <ASIC no> <op mode>" << std::endl;
    		return 0;
  	}

	//get trigger type
	int trigType = 0;

	int WinS = atoi(argv[1]);
	if( WinS < 0 || WinS >= 509 ){
		std::cout << "Invalid Window Start-- should be between 0 and 508, exiting" << std::endl;
		return 0;
	}

	int WinE = atoi(argv[2]);
	if( WinE < 0 || WinE >= 509 ){
		std::cout << "Invalid Window End-- should be between 0 and 508, exiting" << std::endl;
		return 0;
	}

	int WinOffset = 0;

	int ncycles = atoi(argv[3]);
	if( ncycles < 0 || ncycles >= 1000 ){
		std::cout << "Invalid ncycles-- should be between 0 and 1000, exiting" << std::endl;
		return 0;
	}

	int DelayS = atoi(argv[4]);
	if( DelayS < 0 || DelayS >= 16383 ){
		std::cout << "Invalid DelayStart-- should be between 0 and 16383 us, exiting" << std::endl;
		return 0;
	}

	int DelayE = atoi(argv[5]);
	if( DelayE < 0 || DelayE >= 16383 ){
		std::cout << "Invalid DelayEnd-- should be between 0 and 16383 us, exiting" << std::endl;
		return 0;
	}

	int DelayStep = atoi(argv[6]);
	if( DelayStep < 0 || DelayStep >= 16383 ){
		std::cout << "Invalid DelayStep-- should be between 0 and 16383 us, exiting" << std::endl;
		return 0;
	}

	int ASICno = atoi(argv[7]);
	if( ASICno < 0 || ASICno > 10 ){
		std::cout << "Invalid ASIC no-- should be between 0 and 9, exiting" << std::endl;
		return 0;
	}

		int opmode = atoi(argv[8]);
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
			control->registerWrite(board_id,11,32<<10 | 0b01,regValReadback);//setting for wr_addr_clr_start phase


			control->registerWriteReadback(board_id, 62, 0x8000 | WinS, regValReadback); //force start digitization start window to be the fixed value



	//define output file		
	ofstream dataFile;

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

	char cmd[100],fn[100];

	for (int DelayCur=DelayS;DelayCur<DelayE;DelayCur+=DelayStep)
	{
//		execl("/usr/bin/python ../sigen/use_func.py 2 0 10 1412",(char*) 0 );
		sprintf(cmd,"/usr/bin/python /home/isar/workspace/usbInterface/sigen/use_func.py 2 1 %d %f",ncycles,DelayCur/1000.0);
		cout<<cmd<<"\n";
		system( cmd );

		sprintf(fn,"outdir/sweeps/out_txrec_delay%.6d_ncyc%.4d.dat",DelayCur,ncycles);


	  	dataFile.open (fn, ios::out | ios::binary );


	for (int WinCur=WinS;WinCur<WinE;WinCur+=4)
	{


		control->registerWriteReadback(board_id, 62, 0x8000 | WinCur, regValReadback); //force start digitization start window to be the fixed value

		usleep(10000);

		//do software trigger
				control->sendTrigger(board_id,0);
				usleep(500);
				control->registerWriteReadback(board_id, 50, 0, regValReadback);
				int cnt1,cnt2;
				control->registerRead(board_id,256+5,cnt1);
				control->registerRead(board_id,256+30,cnt2);
				cout<<endl<<"SMP_Latch: "<<cnt1<<", Dig win start: "<<cnt2;



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
//				std::cout << "EVENT SIZE " << eventdataSize << ", Event Num="<<nEvt<<std::endl;
				EVTvalid=true;
//				nEvt++;
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

	dataFile.close();


	}
	//reset readout
	control->registerWriteReadback(board_id, 50, 0, regValReadback); //readout control start is 0
	control->registerWriteReadback(board_id, 52, 0, regValReadback); //veto hardware triggers
	control->registerWrite(board_id, 55, 1, regValReadback); //make sure readout is reset
	control->registerWrite(board_id, 55, 0, regValReadback); //make sure readout is reset

	//close output file

	//close USB interface
        control->closeUSBInterface();

	//delete target6 interface object
	delete control;


	//f->Close();
	//delete f;

	return 1;
}





