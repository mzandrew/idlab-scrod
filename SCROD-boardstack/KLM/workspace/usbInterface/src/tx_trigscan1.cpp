#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h>
#include "idl_usb.h"

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

extern libusb_device_handle *dev_handle;

using namespace std;
enum OpMode {raw=0b00,pedsub=0b01,ped=0b10,wave=0b11};

int main(int argc, char* argv[]){
	if (argc != 1){
    		std::cout << "wrong number of arguments: usage \n./tx_trigscan1 " << std::endl;
    		return 0;
  	}


	//define application object
	//theApp = new TApplication("App", &argc, argv);

	int regValReadback;

	//create target6 interface object
	target6ControlClass *control = new target6ControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();
	libusb_reset_device(dev_handle);

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0;
	int asic[10]={0x001,0x002,0x004,0x008,0x010,0x020,0x040,0x080,0x100,0x200};

	//clear data buffer
	control->clearDataBuffer();

	control->registerWriteReadback(board_id, 5, 128, regValReadback); //timing for ASIC slow ctrl
	control->registerWriteReadback(board_id, 6, 320, regValReadback); //timing for ASIC slow ctrl
	//reset and enable trigger scalers
	control->registerWriteReadback(board_id, 70,0, regValReadback);
	control->registerWriteReadback(board_id, 71,0, regValReadback);
	control->registerWriteReadback(board_id, 71,1, regValReadback);
	control->registerWriteReadback(board_id, 71,0, regValReadback);
	control->registerWriteReadback(board_id, 70,1, regValReadback);


	//start a text file for output
	FILE*fout=fopen("outdir/trigscan.txt","wt");
	fprintf(fout,"threshold,cardno,chno,hval,count\n");

	const int NCards=10;int Cards[NCards]={0,1,2,3,4,5,6,7,8,9};
	const int Nch=16;


	//	const int Nhval=7;int hval[Nhval]={25,50,60,70,80,90,100};
	//	const int Nhval=1;int hval[Nhval]={25};
	//	const int Nhval=6;int hval[Nhval]={1,50,100,50,1,250};
		const int Nhval=3;int hval[Nhval]={10,100,10};
	//	const int Nhval=7;int hval[Nhval]={1,10,50,100,150,200,250};
	//	const int Nhval=6;int hval[Nhval]={10,20,40,60,80,100};
	//	const int Nhval=31;int hval[Nhval]; for (int i=0;i<Nhval-1;i++) hval[i]=i*5; hval[Nhval-1]=250;//use this as the Vb=off value

		//Initialize

		int th_start=3300,th_end=3600,th_step=5;
		//init all trigger thresholds to 0
		for(int chno = 0 ; chno< 16 ; chno++)
		{
			for(int CardNo = 0 ; CardNo < 10 ; CardNo++)
			{
				control->writeDACReg(board_id, CardNo, chno*2, 0);
			}
		}
		//reset scalers

		control->registerWriteReadback(board_id, 71,0, regValReadback);
		control->registerWriteReadback(board_id, 71,1, regValReadback);
		control->registerWriteReadback(board_id, 71,0, regValReadback);
		usleep(150000);//wait for counters to become valid
		cout<<"\nInit... Done!\n";


		for (int ihval=0;ihval<Nhval;ihval++)
		{
				//loop over channel trigger threshold values
			for(int chno = 0 ; chno< Nch ; chno++)
			{
				for(int i = th_start ; i < th_end ; i+=th_step)
				{
					int threshold = i;
					for(int cardidx = 0 ; cardidx < NCards ; cardidx++)
					{
						unsigned int HVval,HVvalout;
						HVval=(Cards[cardidx]<<12) | (chno <<8) | (hval[ihval]&255);
						HVvalout=HVval;//(HVval&0x00FF)<<8 | (HVval&0xFF00)>>8;
						control->registerWriteReadback(board_id, 60,HVvalout,regValReadback);
						usleep(5500);
						//write thresholds - set non-zero threshold for one channel on each daughter card
						control->writeDACReg(board_id, Cards[cardidx], chno*2, (threshold)&4095);
					}
					//reset scalers
					control->registerWriteReadback(board_id, 71,0, regValReadback);
					control->registerWriteReadback(board_id, 71,1, regValReadback);
					control->registerWriteReadback(board_id, 71,0, regValReadback);

					usleep(120000);//wait for counters to become valid
					//read scalers - read trigger scaler for each daughter card

					for(int cardidx = 0 ; cardidx < NCards ; cardidx++)
					{
						//int count = chno*100+threshold;
						int countLo, countHi;
						control->registerRead(board_id, 256 + 10+Cards[cardidx], countLo);
						control->registerRead(board_id, 256 + 40+Cards[cardidx], countHi);
						int count=countHi*65536+countLo;
						std::cout << "th: "<< threshold << "\tCard: # " << Cards[cardidx] << ",Channel # " << chno << ",Hval= "<<hval[ihval] << ",Counter=" << count << std::endl;
						fprintf(fout,"%d, %d, %d, %d, %d\n",threshold,Cards[cardidx],chno,hval[ihval],count);
					}
					for(int cardidx = 0 ; cardidx < NCards ; cardidx++)
					{
						//reset thresholds to 0
						control->writeDACReg(board_id, Cards[cardidx], chno*2, 0);
					}
						control->registerWriteReadback(board_id, 71,0, regValReadback);
						control->registerWriteReadback(board_id, 71,1, regValReadback);
						control->registerWriteReadback(board_id, 71,0, regValReadback);

					usleep(120000);

				}

			}
		}

		fclose(fout);



		//close output file

	//close USB interface
        control->closeUSBInterface();

	//delete target6 interface object
	delete control;


	//f->Close();
	//delete f;

	return 1;
}





