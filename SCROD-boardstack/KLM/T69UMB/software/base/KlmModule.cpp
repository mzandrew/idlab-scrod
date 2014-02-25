#include <stdexcept>
#include <stdio.h>
#include <unistd.h>

#include "base/KlmModule.h"


using namespace std;

KlmModule::KlmModule()
{
}

KlmModule::KlmModule(DetectorInterface* interface)
: _interface(interface), _packet_id(0)
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
	_interface->receivePacket(packet);
	
	return packet;
}

void KlmModule::write_ASIC_register(uint8_t card, uint8_t address, uint16_t value)
{
	ScrodPacket packet;
	scrod_word id;
	scrod_register reg_value;
	
	// create a command packet
	write_register(SCROD_REGISTER_T6_ADDRESS, (scrod_register)address, true);
	write_register(SCROD_REGISTER_T6_DATA, (scrod_register)value, true);
	write_register(SCROD_REGISTER_T6_STROBE, (scrod_register)1, true);
	//wait some time
	usleep(50);
	write_register(SCROD_REGISTER_T6_STROBE, (scrod_register)0, true);
}

void KlmModule::start()
{
}

void KlmModule::stop()
{
}
