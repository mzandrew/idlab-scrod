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

	int c=0;
	int cardno=4;
	char s[100];
	const int Nch=2;int chs[Nch]={0,12};
	const int Nhval=5;int hval[Nhval]={0,50,100,200,50};
	const int Nth=1; int thr[Nth]={1};

	//init all trigger thresholds to 0
	for(int chno = 0 ; chno< 16 ; chno++)
	{
		for(int CardNo = 0 ; CardNo < 10 ; CardNo++)
		{
			//module->write_ASIC_register(CardNo, chno, 0);
			module->write_register(60,CardNo<<12 | chno<<8 ,true);
		}
	}
	cout<<"\nStep "<<c++<<": All thresholds and HVDAC =0... done!";c++;
	cin>>s;
	//reset scalers
	module->write_register(71, 1, true); //reset counters high
	module->write_register(71, 0, true); //reset counters low
	usleep(150000);//wait for counters to become valid
	//read scalers - read trigger scaler for each daughter card
	int count = module->read_register(266 + cardno);
	cout<<"Count read= "<<count;	//cout<<"\nStep "<<c++<<": Measure T6DC5(card 4), CH 0: SiPM1- DC= ";cin>>s;cout<< "& PA1- activity= ";cin>>s;

	for (int ihval=0;ihval<Nhval;ihval++)
	{
		for(int ich = 0 ; ich< Nch ; ich++)
		{
			module->write_register(60,cardno<<12 | chs[ich]<<8 | hval[ihval] ,true);
			cout<<"\nStep "<<c++<<": Card4, CH "<<chs[ich]<<" HV DAC set to "<<hval[ihval]<<"\nMeasure T6DC5(card 4), CH "<<chs[ich]<<": SiPM"<<chs[ich]+1<<" - DC=  ";cin>>s;
			cout<<"& PA"<<chs[ich]+1<<" - activity= ";cin>>s;

			//module->write_ASIC_register(cardno, chs[ich], thr[0]);
			//reset scalers
			module->write_register(71, 1, true); //reset counters high
			module->write_register(71, 0, true); //reset counters low
			usleep(150000);//wait for counters to become valid
			//read scalers - read trigger scaler for each daughter card
			int count = module->read_register(266 + cardno);
			cout<<"Count read= "<<count;

			//module->write_ASIC_register(cardno, chs[ich], 0);
			module->write_register(71, 1, true); //reset counters high
			module->write_register(71, 0, true); //reset counters low
			sleep(1);


		}
	}
	// clear the system
	KlmSystem::Cleanup();
}
