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
	int HVCoarseCal[NhvCoraseCal]={11,2,4,1,12,11,3,8,8,8,3,5,13,3,1,1,1,12,6,11,11,3,1,5,7,1,9,2,1,2,10,1,13,13,13,14,13,12,9,13,9,12,10,10,9,10,11,1,11,10,12,10,10,9,8,11,10,10,9,12,11,9,10,1,11,11,10,13,10,10,8,9,9,12,9,9,10,11,10,1,10,9,11,9,6,10,9,9,8,1,1,1,1,1,1,1,1,1,1,1,8,5,10,8,8,8,10,9,10,12,10,1,10,9,9,11,9,8,10,7,8,7,11,9,11,12,13,1,13,9,10,12,11,11,10,8,13,1,1,1,1,1,1,1,1,1,7,1,1,8,4,1,2,10,1,1,8,1,1,1};
	int TrigThresholds[NhvCoraseCal]={134,224,0,0,455,0,0,0,0,0,0,145,97,242,0,0,0,521,0,0,361,494,0,0,0,0,0,0,0,470,43,0,1029,974,1062,1352,961,808,407,987,433,762,479,450,328,514,601,0,762,484,837,467,408,331,255,596,462,565,421,742,600,337,483,0,633,544,486,943,444,420,246,335,348,602,344,348,411,468,403,0,564,328,679,369,62,496,276,362,173,0,0,0,0,0,0,0,0,0,0,0,319,29,635,249,184,204,421,341,494,788,428,0,460,348,384,560,360,283,414,201,261,156,573,405,555,668,831,0,1032,386,660,805,813,654,564,267,922,0,0,0,0,0,0,0,0,0,103,0,0,0,207,0,25,0,0,0,157,0,0,0};
	
 
	for (int i=0;i<NhvCoraseCal;i++)
	{
		int cardno=i>>4;
		int chno=i&15;
		scrod_register HVval;
		HVval=(cardno<<12) | (chno <<8) | (HVCoarseCal[i])&255;
		module->write_register(60,HVval,true);
		printf("Cardno= %d, CHno= %d, HVDAC= %d, REG=%x\n",cardno,chno,HVCoarseCal[i],HVval);
		usleep(1000);
		module->write_ASIC_register(cardno, chno*2, (TrigThresholds[i])&4095);
		usleep(1000);

	}


	// clear the system
	KlmSystem::Cleanup();
}
