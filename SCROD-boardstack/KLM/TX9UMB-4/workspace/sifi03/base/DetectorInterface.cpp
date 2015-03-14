#include <stdexcept>
#include <iostream>

#include "base/DetectorInterface.h"

using namespace std;

DetectorInterface::DetectorInterface()
{
}

DetectorInterface::~DetectorInterface()
{
}

bool DetectorInterface::receivePacket(ScrodPacket* packet)
{
	unsigned int size_to_follow;
	int response;
	
	// tries to receive the packet
	packet->prepare_size(2);
	
	//cout << "Start with the header ... " << endl;
	// read the first two 
	response = this->receive_data(packet->get_raw_data(), 2*sizeof(scrod_word), USB_TIMEOUT_MS);
	if(response < 2*sizeof(scrod_word))
	{
		// time out
		return false;
	}
	
	// on basis of length field prepare the rest of the vector
	size_to_follow = packet->get_payload_length();
	//cout << "Waiting for the next " << size_to_follow << " words." << endl;
	packet->prepare_size(size_to_follow+2, true);
	
	// read the rest of the packet
	response = this->receive_data(packet->get_raw_data() + 2*sizeof(scrod_word), size_to_follow*sizeof(scrod_word), USB_TIMEOUT_MS);
	if(response < size_to_follow*sizeof(scrod_word))
	{
		// time out
		return false;
	}
	
	// packet is ready
	return true;
}
