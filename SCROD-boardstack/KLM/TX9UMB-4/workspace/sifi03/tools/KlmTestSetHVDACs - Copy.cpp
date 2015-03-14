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

	const int NhvCoraseCal=160;
	int HVCoarseCal[NhvCoraseCal]={25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,90,90,90,90,90,90,90,80,90,80,90,80,80,80,80,25,};

	for (int i=0;i<NhvCoraseCal;i++)
	{
		int cardno=i>>4;
		int chno=i&15;
		scrod_register HVval;
		HVval=(cardno<<12) | (chno <<8) | (HVCoarseCal[i])&255;
		module->write_register(60,HVval,true);
		printf("Cardno= %d, CHno= %d, HVDAC= %d, REG=%x\n",cardno,chno,HVCoarseCal[i],HVval);
		usleep(1000);
	}


	// clear the system
	KlmSystem::Cleanup();
}
