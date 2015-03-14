/*
 * KlmTestReadMPPCcurrents01.cpp
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


	float Rt[16]={1e6,1e6,1e6,1e6,1e6,1e6,1e6,1e6,1e6,1e6,1e6,1e6,   100e3,49.9e3, 14e3,1e6};
	int nch, ndc;

	int adc_val,adc_rdy;


	for (int hvl=10;hvl<11;hvl+=1)
	{
		cout<<"\ni,ndc,nch,adc,R,Vadc,Vhvl,I(uA)\n";
		for (int i=0x00;i<0x9f;i++)
				{//set HV value for all DC and all channels

		ndc=(i>>4)&15;
	nch=i&15;
	scrod_register HVval;
	HVval=(ndc<<12) | (nch<<8) | (hvl&255);
	module->write_register(60,HVval,true);
	usleep(1000);
	module->write_register(60,HVval,true);
	usleep(1000);
				}

	module->write_register(63,0,true);//
		usleep(1000);
		module->write_register(63,1,true);//update
		usleep(1000);
		module->write_register(63,0,true);// now all registers are updated
		for (int i=0x00;i<0xA0;i++)
		{
			ndc=(i>>4)&15;
			nch=i&15;
		adc_val=module->read_register(256+i+40);

		printf("%x, %d, %d, %d, %.2e, %.6f, %.6f, %.3f\n",i,ndc,nch,adc_val,Rt[nch],
				float(adc_val)/4096.0f*3.3f*2.0f,float(hvl)/256.0f*5.0f,-(float(adc_val)/4096.0f*3.3f*2.0f-float(hvl)/256.0f*5.0f)/Rt[nch]*1e6 );
//		printf("%d\t%d",i,adc_val);


//		HVval=(ndc<<12) | (nch<<8) | (0&255);
		//module->write_register(60,HVval,true);
		usleep(2500);



	}
	}

	// clear the system
	KlmSystem::Cleanup();

}

