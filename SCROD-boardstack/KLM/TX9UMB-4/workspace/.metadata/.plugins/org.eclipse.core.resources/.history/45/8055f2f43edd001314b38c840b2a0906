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
	FILE*fout=fopen("output.txt","wt");

	//iterate over channels, vary thresholds each iteration. Automatically test all DC on MB each iteration

	for(int chno = 4 ; chno< Nch ; chno++){
		int count[Ncards];
		//loop over channel trigger threshold values
		for(int i = 0 ; i < 60 ; i++){
			int threshold = 1000+10*i;

			//reset scalers
			module->write_register(71, 1, true); //reset counters high
			module->write_register(71, 0, true); //reset counters low
		
			//write thresholds - set non-zero threshold for one channel on each daughter card
			for(int cardno = 0 ; cardno < Ncards ; cardno++)
				module->write_ASIC_register(cardno, chno, threshold);

			//wait some time
			sleep(1);

			//read scalers - read trigger scaler for each daughter card
			for(int cardno = 0 ; cardno < Ncards ; cardno++)
				count[cardno] = module->read_register(266 + cardno);

			//do something with scalars
			std::cout << "Threshold\t" << threshold << std::endl;
			for(int cardno = 0 ; cardno < Ncards ; cardno++){
				std::cout << "\tCard: # " << cardno << "\tChannel # " << chno << "\tCounter\t" << count[cardno] << std::endl;
				fprintf(fout,"%d, %d, %d, %d\n",threshold,cardno,chno,count[cardno]);
			}

		}
		//reset thresholds to 0
		for(int cardno = 0 ; cardno < Ncards ; cardno++)
			module->write_ASIC_register(cardno, chno, 0);
	}
	
	fclose(fout);
	// clear the system
	KlmSystem::Cleanup();
}
