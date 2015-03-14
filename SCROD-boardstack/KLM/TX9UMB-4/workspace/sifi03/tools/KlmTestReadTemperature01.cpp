/*
 * KlmTestReadTemperature01.cpp
 *
 *  Created on: Jul 1, 2014
 *      Author: isar
 */

#include <iostream>
#include <cstdlib>
#include <unistd.h>
#include <stdio.h>

#include "base/KlmSystem.h"


using namespace std;

int main(int argc, char** argv)
{


	if(argc != 2)
	{
		cout << "USAGE: KlmTestHVDACSingleChannelTriggers <board_id>" << endl;
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



	int nch, ndc;
	int i=0x9F;
	const int Nbuf=20;
	int adc_val,adc_rdy,c=0;
	float tbuf[Nbuf];

	while(true)
	{
		ndc=(i>>4)&15;
		nch=i&15;
		module->write_register(62,i,true);//set the MUX
		usleep(10000);
		module->write_register(62,i,true);//set the MUX
		usleep(10000);
		module->write_register(63,0,true);//run_adc=0,reset=0
		module->write_register(63,1,true);//run_adc=0,reset=1:pulse reset
		module->write_register(63,2,true);//run_adc=1,reset=0: enable ADC
		usleep(4000);
		adc_rdy=module->read_register(256+22);
		adc_val=module->read_register(256+21);

		tbuf[c%Nbuf]=float(adc_val)/4096.0f*3.3f*2.0f*100.0f;

		usleep(1000);
		module->write_register(63,0,true);//run_adc=0,reset=0: disable ADC
		usleep(2500);
		if (c%Nbuf==0)
		{
			float tmp=0.0f;
			for (int j=0;j<Nbuf;j++) tmp+=(tbuf[j]/(float)Nbuf);

			printf("Card=%d, Ch=%d, Temp= %.4f\n",ndc,nch,tmp);

		}
		c++;

	}

	// clear the system
	KlmSystem::Cleanup();

}

