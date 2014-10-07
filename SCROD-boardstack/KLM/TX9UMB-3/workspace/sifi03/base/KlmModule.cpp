#include <stdexcept>
#include <stdio.h>
#include <unistd.h>
#include <iostream>

#include "base/KlmModule.h"


using namespace std;

KlmModule::KlmModule()
{
}

KlmModule::KlmModule(DetectorInterface* interface)
: _interface(interface), _packet_id(0), _run(true)
{
}

KlmModule::~KlmModule()
{
}

void KlmModule::write_register(scrod_address address, scrod_register value, bool verify)
{
	scrod_word id = _packet_id;
	
	// create a command packet
	ScrodPacket packet;
	packet.create_command_write(address, value, _packet_id++, !verify);
	_interface->sendPacket(&packet);
	
	if(verify)
	{
		// wait for the response
		_interface->receivePacket(&packet);
		if(packet.is_okay() && (packet.get_command_id() == id) && (packet.get_command_type() == COMMAND_TYPE_WRITE))
		{
			// this is the right response
			if(packet.get_register_value() == value)
				return;
			else
				throw runtime_error("Bad value read back after write.");
		}
		else
		{
			throw runtime_error("Bad response from write command.");
		}
	}
}

scrod_word KlmModule::read_register(scrod_address address)
{
	scrod_word id = _packet_id;
	
	// create a command packet
	ScrodPacket packet;
	packet.create_command_read(address, _packet_id++, false);
	_interface->sendPacket(&packet);
	
	// wait for the response
	_interface->receivePacket(&packet);
	if(packet.is_okay() && (packet.get_command_id() == id) && (packet.get_command_type() == COMMAND_TYPE_READ))
	{
		// this is the right response
		return packet.get_register_value();
	}
	else
	{
		throw runtime_error("Bad response from read command.");
	}
}

ScrodPacket* KlmModule::read_packet() const
{
	ScrodPacket* packet = new ScrodPacket;
	if(_interface->receivePacket(packet))
	{
		return packet;
	}
	else
	{
		delete packet;
		return NULL;
	}
}

void KlmModule::write_ASIC_register(uint8_t card, uint8_t address, uint16_t value)
{
	ScrodPacket packet;
	scrod_word id;
	scrod_register reg_value;
	
	write_register(SCROD_REGISTER_T6_STROBE, (scrod_register)0, true);
	// create a command packet
	write_register(SCROD_REGISTER_T6_SLOT, (scrod_register)(1 << card), true);
	write_register(SCROD_REGISTER_T6_ADDRESS, (scrod_register)address, true);
	write_register(SCROD_REGISTER_T6_DATA, (scrod_register)value, true);
	write_register(SCROD_REGISTER_T6_STROBE, (scrod_register)1, true);
	//wait some time
	usleep(50);
	write_register(SCROD_REGISTER_T6_STROBE, (scrod_register)0, true);
}

int KlmModule::send_trigger(KlmModule::TrgType_t trigger)
{
	//std::cout << "Trigger send for " << _interface->getDeviceID() << endl;

	///set up data buffers that are used in USB interface
	int size = 0;
	unsigned int *outbuf;

	write_register(50, (scrod_register)0, false);
	write_register(52, (scrod_register)0, false);
	write_register(55, (scrod_register)1, false);
	write_register(55, (scrod_register)0, false);
	
	if(trigger == KlmModule::hw_trigger)
	{
		write_register(52, (scrod_register)1, false);
	}
	else
	{
		write_register(50, (scrod_register)1, false);
	}
}

bool KlmModule::start(ObjectSync<ScrodPacket>*	data_drain)
{
	_data_drain = data_drain;
	_run = true;
	
	// start the thread
	pthread_attr_init(&_thread_att);
	pthread_attr_setdetachstate(&_thread_att, PTHREAD_CREATE_JOINABLE);
	int rc = pthread_create(&_thread, &_thread_att, KlmModule::pt_starter, (void*)this);
	if (rc)
	{
		_run = false;
		return false;
	}
	
	return true;
}

void KlmModule::stop()
{
	_run = false;
}

void KlmModule::wait_end(std::ostream& output)
{
	void* status;
	pthread_join(_thread, &status);
}

void* KlmModule::pt_starter(void* module)
{
	((KlmModule*)module)->run();
	pthread_exit(NULL);
}

void KlmModule::run()
{
	// doing the actual thing

	try
	{
		ScrodPacket* pack;
		
		while(should_continue())
		{
			pack = this->read_packet();
			if(pack)
			{
				//std::cout << "Packet processed for " << _interface->getDeviceID() << endl;
				_data_drain->insert(pack);
			}
		}	
	}
	catch(std::exception& e)
	{
		std::cout << "Process for module " << _interface->getDeviceID() << " died !! exception caught: " << e.what() << endl;
	}
	catch(...)
	{
		std::cout << "Process for module " << _interface->getDeviceID() << " died !! unknown exxception" << endl;
	}
}
