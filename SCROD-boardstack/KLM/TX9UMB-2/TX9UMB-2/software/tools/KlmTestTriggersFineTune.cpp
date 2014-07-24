#include <iostream>
#include <cstdlib>
#include <unistd.h>
#include <stdio.h>

#include "base/KlmSystem.h"


using namespace std;

int main(int argc, char** argv)
{

	const int Ncards=10;
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
	FILE*fout=fopen("outdir/output_finetune.txt","wt");

	//iterate over channels, vary thresholds each iteration. Automatically test all DC on MB each iteration

	//const int Nhval=6;int hval[Nhval]={0,50,100,150,200,255};
	//const int Nhval=7;int hval[Nhval]={0,10,20,30,40,50,60};
	const int Nhval=30;int hval[Nhval];
	for (int i=0;i<Nhval;i++)
		hval[i]=i*2;

	int HVCoarseCal[]={8,6,4,16,6,4,6,4,4,4,0,2,22,0,22,0,6,4,8,2,8,6,8,0,6,4,6,0,4,6,10,0,22,12,2,12,4,10,6,10,0,6,2,6,2,6,4,0,2,16,20,16,16,16,18,12,14,16,14,18,12,20,14,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,4,2,6,6,10,4,12,2,6,0,6,0,0,0,0,6,2,2,6,2,10,2,0,0,0,0,0,0,0,0,0,6,8,4,12,2,10,4,10,0,14,0,12,2,10,2,0,2,12,2,18,2,10,4,6,0,6,6,4,4,6,8,0,20,2,20,2,20,4,20,0,22,0,14,2,20,0,12,0};


//	for (int ihval=0;ihval<Nhval;ihval++)
	{

		for(int chno = 0 ; chno< Nch ; chno++){
			int count[Ncards];
			//loop over channel trigger threshold values
			for(int i = 0 ; i < 300 ; i++){
				int threshold = 1350+i;

				//reset scalers
				module->write_register(71, 1, true); //reset counters high
				module->write_register(71, 0, true); //reset counters low

				//write thresholds - set non-zero threshold for one channel on each daughter card
				for(int cardno = 0 ; cardno < Ncards ; cardno++)
				{
					module->write_ASIC_register(cardno, chno, threshold);
					scrod_register HVval,HVvalout;
//					HVval=(cardno<<12) | (chno <<8) | (hval[ihval]&255);
					HVval=(cardno<<12) | (chno <<8) | (HVCoarseCal[cardno*16+chno]);

					HVvalout=HVval;//(HVval&0x00FF)<<8 | (HVval&0xFF00)>>8;
					module->write_register(60,HVvalout,true);


					//printf("HVval=%x\n",HVvalout);
					usleep(100);

				}

			//wait some time
				usleep(100);

				//read scalers - read trigger scaler for each daughter card
				for(int cardno = 0 ; cardno < Ncards ; cardno++)
					count[cardno] = module->read_register(266 + cardno);

			//do something with scalars
				//std::cout << "Threshold\t" << threshold << std::endl;
				for(int cardno = 0 ; cardno < Ncards ; cardno++){
					std::cout << "th: "<< threshold << "\tCard: # " << cardno << ",Channel # " << chno << ",Hval= "<< HVCoarseCal[cardno*16+chno] << ",Counter=" << count[cardno] << std::endl;
					fprintf(fout,"%d, %d, %d, %d, %d\n",threshold,cardno,chno,HVCoarseCal[cardno*16+chno],count[cardno]);
				}

			}
		//reset thresholds to 0
			for(int cardno = 0 ; cardno < Ncards ; cardno++)
				module->write_ASIC_register(cardno, chno, 0);
		}
	}

	fclose(fout);
	// clear the system
	KlmSystem::Cleanup();
}
