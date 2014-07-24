#include <stdexcept>
#include <stdio.h>
#include <algorithm>
#include <iostream>

#include "base/KlmConsumer.h"

using namespace std;


KlmConsumer::KlmConsumer()
{
	_packet_counter = 0;
	pthread_mutex_init(&_data_mutex, NULL);
}

KlmConsumer::~KlmConsumer()
{
	pthread_mutex_destroy(&_data_mutex);
}

bool KlmConsumer::start()
{
	_run = true;
	_packet_counter = 0;
	
	this->initialize();
	
	// start the thread
	pthread_attr_init(&_thread_att);
	pthread_attr_setdetachstate(&_thread_att, PTHREAD_CREATE_JOINABLE);
	int rc = pthread_create(&_thread, &_thread_att, KlmConsumer::pt_starter, (void*)this);
	if (rc)
	{
		_run = false;
		return false;
	}
	
	return true;
}

void KlmConsumer::stop()
{
	_run = false;
	_data_source.insert(NULL);
}

void* KlmConsumer::pt_starter(void* consumer)
{
	((KlmConsumer*)consumer)->run();
	pthread_exit(NULL);
}

void KlmConsumer::run()
{
	try
	{
		// doing the actual thing
		ScrodPacket* packet;
		while(should_continue())
		{
			// get packet
			packet = _data_source.getObject();
			if(packet)
			{
				// process it
				this->process_packet(packet);
				// remove the packet
				delete packet;
			}
			else
				break;
		}
		this->deinitialize();
	}
	catch(std::exception& e)
	{
		std::cout << "Consumer died !! exception caught: " << e.what() << endl;
	}
	catch(...)
	{
		std::cout << "Consumer died !! unknown exxception" << endl;
	}	
}

void KlmConsumer::process_packet(ScrodPacket* packet)
{
	pthread_mutex_lock(&_data_mutex);
	_packet_counter++;
	pthread_mutex_unlock(&_data_mutex);
	//cout << "Packet received!" << endl;
}

int KlmConsumer::get_packet_count() const
{
	int x;
	pthread_mutex_lock(&_data_mutex);
	x = _packet_counter;
	pthread_mutex_unlock(&_data_mutex);
	return x;
}

void KlmConsumer::process_next_packet()
{
	ScrodPacket* packet;
	// get packet
	packet = _data_source.getObject();
	// process it
	this->process_packet(packet);
	// remove the packet
	delete packet;
}

void KlmConsumer::initialize()
{
}

void KlmConsumer::deinitialize()
{
}
