#include <stdexcept>
#include <stdio.h>
#include <algorithm>

#include "base/KlmConsumer.h"

using namespace std;


KlmConsumer::KlmConsumer()
{
}

KlmConsumer::~KlmConsumer()
{
}

bool KlmConsumer::start()
{
	_run = true;
	
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
}

void* KlmConsumer::pt_starter(void* consumer)
{
	((KlmConsumer*)consumer)->run();
	pthread_exit(NULL);
}

void KlmConsumer::run()
{
	// doing the actual thing
	
	while(should_continue())
	{
		// ?!?!
	}	
}
