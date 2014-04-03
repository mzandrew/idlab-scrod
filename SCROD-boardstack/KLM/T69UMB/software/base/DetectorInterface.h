#ifndef INCLUDE_DETECTOR_INTERFACE
#define INCLUDE_DETECTOR_INTERFACE

#include "base/ScrodPacket.h"

class DetectorInterface
	/// Abstraction class for differen interfaces to the detector.
{
public:
	virtual ~DetectorInterface();
		/// Destructor.
		
	void sendPacket(ScrodPacket* packet);
		/// Sends packet to detector.
		
	bool receivePacket(ScrodPacket* packet);
		/// Receives a packet. Returns false on the timeout.

protected:

	virtual void send_data(unsigned char* data, int length, unsigned int timeout) const = 0;
		/// Sends the data. If error occurs, std::runtime_error is thrown.
	
	virtual int receive_data(unsigned char* data, int length, unsigned int timeout) const = 0;
		/// Receives the data and returns the number ob bytes received.
		
protected:

	DetectorInterface();
		/// Constructor.
	
private:

};

inline void DetectorInterface::sendPacket(ScrodPacket* packet)
{
	// get packet buffer and send it
	this->send_data(packet->get_raw_data(), packet->get_raw_data_length(), 0);
}

#endif
