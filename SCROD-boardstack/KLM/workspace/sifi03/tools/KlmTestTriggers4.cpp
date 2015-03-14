#include <iostream>
#include <cstdlib>
#include <unistd.h>
#include <stdio.h>

#include "base/KlmSystem.h"


using namespace std;

int main(int argc, char** argv)
{

	//const int Ncards=10;
	const int Nch=16;

	if(argc != 2)
	{
		cout << "USAGE: KlmTestTriggers <board_id>" << endl;
		return 1;
	}

	KlmModule* module;

	// init the system
	KlmSystem::KLM().initialize(std::cout);

	// get the module
	module = KlmSystem::KLM()[atoi(argv[1])];
	if(!module)
	{
		cout << "ERROR: Module " << atoi(argv[1]) << " not found!" << endl;
		// clear the system
		KlmSystem::Cleanup();
		return 0;
	}

	//initialize the DAC loading and latch period registers to something reasonable
	module->write_register(5, 128, true);
	module->write_register(6, 320, true);

	//reset and enable trigger scalers
	module->write_register(70, 0, true); //disable
	module->write_register(71, 0, true); //reset counters low
	module->write_register(71, 1, true); //reset counters high
	module->write_register(71, 0, true); //reset counters low
	module->write_register(70, 1, true); //enable

	//start a text file for output
	FILE*fout=fopen("outdir/output.txt","wt");
	fprintf(fout,"threshold,cardno,chno,hval,count\n");

	//iterate over channels, vary thresholds each iteration. Automatically test all DC on MB each iteration
	const int NCards=10;int Cards[NCards]={0,1,2,3,4,5,6,7,8,9};
//	const int NCards=1;int Cards[NCards]={9};

//	const int Nhval=7;int hval[Nhval]={25,50,60,70,80,90,100};
//	const int Nhval=1;int hval[Nhval]={25};
//	const int Nhval=6;int hval[Nhval]={1,50,100,50,1,250};
	const int Nhval=3;int hval[Nhval]={10,100,10};
//	const int Nhval=7;int hval[Nhval]={1,10,50,100,150,200,250};
//	const int Nhval=6;int hval[Nhval]={10,20,40,60,80,100};
//	const int Nhval=31;int hval[Nhval]; for (int i=0;i<Nhval-1;i++) hval[i]=i*5; hval[Nhval-1]=250;//use this as the Vb=off value

	int th_start=3300,th_end=3600,th_step=5;
	//init all trigger thresholds to 0
	for(int chno = 0 ; chno< 16 ; chno++)
	{
		for(int CardNo = 0 ; CardNo < 10 ; CardNo++)
		{
			module->write_ASIC_register(CardNo, chno*2, 0);
		}
	}
	//reset scalers
	module->write_register(71, 0, true); //reset counters low
	module->write_register(71, 1, true); //reset counters high
	module->write_register(71, 0, true); //reset counters low
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
					scrod_register HVval,HVvalout;
					HVval=(Cards[cardidx]<<12) | (chno <<8) | (hval[ihval]&255);
					HVvalout=HVval;//(HVval&0x00FF)<<8 | (HVval&0xFF00)>>8;
					module->write_register(60,HVvalout,true);
					usleep(5500);
					//write thresholds - set non-zero threshold for one channel on each daughter card
					module->write_ASIC_register(Cards[cardidx], chno*2, (threshold)&4095);
				}
				//reset scalers
				module->write_register(71, 0, true); //reset counters low
				module->write_register(71, 1, true); //reset counters high
				module->write_register(71, 0, true); //reset counters low

				usleep(120000);//wait for counters to become valid
				//read scalers - read trigger scaler for each daughter card

				for(int cardidx = 0 ; cardidx < NCards ; cardidx++)
				{
					//int count = chno*100+threshold;
					int countLo = module->read_register(256 + 10+Cards[cardidx]);
					int countHi = module->read_register(256 + 40+Cards[cardidx]);
					int count=countHi*65536+countLo;
					std::cout << "th: "<< threshold << "\tCard: # " << Cards[cardidx] << ",Channel # " << chno << ",Hval= "<<hval[ihval] << ",Counter=" << count << std::endl;
					fprintf(fout,"%d, %d, %d, %d, %d\n",threshold,Cards[cardidx],chno,hval[ihval],count);
				}
				for(int cardidx = 0 ; cardidx < NCards ; cardidx++)
				{
					//reset thresholds to 0
					module->write_ASIC_register(Cards[cardidx], chno*2, 0);
				}
				module->write_register(71, 0, true); //reset counters low
				module->write_register(71, 1, true); //reset counters high
				module->write_register(71, 0, true); //reset counters low

				usleep(120000);

			}

		}
	}

	fclose(fout);
	// clear the system
	KlmSystem::Cleanup();
}
