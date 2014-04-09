#include <iostream>
#include <cstdlib>
#include <time.h>
#include <unistd.h>

#include "base/KlmSystem.h"
#include "base/KlmConsumer.h"

using namespace std;

int main(int argc, char** argv)
{
	int N_events;

	if(argc != 4)
	{
		cout << "USAGE: KlmToFile <configuration> <output_file> <events>" << endl;
		return 1;
	}
	
	// events
	N_events = atoi(argv[3]);

	// bring up the KLM
	KlmSystem::KLM().initialize(std::cout, argv[1]);
	
	// create the consumer and run it
	KlmConsumer data_destination;
	//KlmFile data_destination(argv[2]);
	
	//if(!data_destination.start())
	//{
		//// failed to start the data consumer
		//// clear the system
		//KlmSystem::Cleanup();
		//return 1;
	//}
	
	// start the KLM readout
	KlmSystem::KLM().start(std::cout, data_destination.get_data_drain());
	
	// issue triggers
	
	cout << "Start" << endl;
	//int event = data_destination.get_packet_count();
	int event = 0;
	while(event < N_events)
	{
		KlmSystem::KLM().send_trigger(KlmModule::sw_trigger);
		data_destination.process_next_packet();
		//
		if(event % 100 == 0)
			cout << event << endl;
		event++;
	}
	
	cout << "Done" << endl;
	KlmSystem::KLM().stop(std::cout);
	cout << "Stopping" << endl;
	
	// stop the destination
	//data_destination.stop();
	cout << "Finished" << endl;	
	
	// clear the system
	KlmSystem::Cleanup();
	
	return 0;
}
