#include <stdexcept>
#include <stdio.h>
#include <algorithm>
#include <iostream>

#include "base/KlmFile.h"

using namespace std;

KlmFile::KlmFile(std::string fileName)
{
	_name = fileName;
}

KlmFile::KlmFile()
{
}

KlmFile::~KlmFile()
{
}

void KlmFile::process_packet(ScrodPacket* packet)
{
	// write content of the packet into the file	
	_file->write((const char*)packet->get_raw_data(), packet->get_raw_data_length());
	_file->flush();

	//cout << "Writing file " << packet->get_raw_data_length() << endl;

	// should be on the end
	KlmConsumer::process_packet(packet);
}

void KlmFile::initialize()
{
	// should be on beggining
	KlmConsumer::initialize();
	
	cout << "Opening file " << _name << endl;
	// open the file
	_file = new std::ofstream(_name.c_str(), std::ofstream::out | std::ofstream::binary);
	if(!_file->is_open())
	{
		delete _file;
		_file = NULL;
		
		// throw exception
		char text[100];
		sprintf(text, "File %s could not be opened!", _name.c_str());
		throw runtime_error(text);
	}
}

void KlmFile::deinitialize()
{
	// should be on beggining
	KlmConsumer::deinitialize();
	
	cout << "Closing file " << _name << endl;

	// close the file
	_file->close();
	delete _file;
	_file = NULL;
}
