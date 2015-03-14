#include <stdexcept>
#include <stdio.h>

#include "base/ScrodPacket.h"

using namespace std;

ScrodPacket::ScrodPacket()
{
	_data.reserve(START_PACKET_SIZE);
}
	
ScrodPacket::~ScrodPacket()
{
}

void ScrodPacket::create_command(const scrod_word command, scrod_word cmd_id, bool silent)
{
	reset_content();
	_data.push_back(PACKET_HEADER);// header
	_data.push_back(0);// packet size
	_data.push_back(PACKET_TYPE_COMMAND);// command
	_data.push_back(DESTINATION_BROADCAST);// destination
	if(silent)
		_data.push_back(FLAG_RESPONSE_NO | (cmd_id & 0x00FFFFFF));// destination
	else
		_data.push_back((cmd_id & 0x00FFFFFF));// destination
	_data.push_back(command);// command	
	_checksum = _data[0] + _data[2] + _data[3] + _data[4];
}

void ScrodPacket::create_command_ping(scrod_word cmd_id, bool silent)
{
	create_command(COMMAND_TYPE_PING, cmd_id, silent);
	// add command checksum
	_data.push_back(_data[4]+_data[5]);
	// calculate final checksum
	_checksum += 2*_data.back();
	// finalize packet
	finalize_packet();
}

void ScrodPacket::create_command_read(scrod_address reg_addr, scrod_word cmd_id, bool silent)
{
	create_command(COMMAND_TYPE_READ, cmd_id, silent);
	// add register address
	_data.push_back((scrod_word)reg_addr);
	// add command checksum
	_data.push_back(_data[4]+_data[5]+_data[6]);
	// calculate final checksum
	_checksum += 2*_data.back();
	// finalize packet
	finalize_packet();
}

void ScrodPacket::create_command_write(scrod_address reg_addr, scrod_register value, scrod_word cmd_id, bool silent)
{
	create_command(COMMAND_TYPE_WRITE, cmd_id, silent);
	// add register address
	_data.push_back(((scrod_word)reg_addr) | ((scrod_word)value) << 16);
	// add command checksum
	_data.push_back(_data[4]+_data[5]+_data[6]);
	// calculate final checksum
	_checksum += 2*_data.back();
	// finalize packet
	finalize_packet();
}
