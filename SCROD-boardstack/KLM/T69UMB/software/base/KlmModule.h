#ifndef INCLUDE_KLM_MODULE
#define INCLUDE_KLM_MODULE

#include <queue>

#include "base/DetectorInterface.h"
#include "base/defines.h"


class KlmModule
	/// Class for high lavel KLM module manipulation.
{
public:
	KlmModule(DetectorInterface* interface);
		/// Constructor.
	
	virtual ~KlmModule();
		/// Destructor.

	// primitive functions
	
	void write_register(scrod_address address, scrod_register value, bool verify = true);
		/// Writes a value to the desired register.
		
	scrod_word read_register(scrod_address address);
		/// Reads the value of the desired register.
		
	void write_ASIC_register(uint8_t card, uint8_t address, uint16_t value);
		/// Writes a value to the ASIC register.

protected:

private:

	KlmModule();
		/// Constructor.
	
private:

	DetectorInterface*	_interface;
	scrod_word			_packet_id;
	
	//std::queue<ScrodPacket*>	_packet_queue;
};

#endif
