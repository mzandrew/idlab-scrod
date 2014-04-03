#ifndef INCLUDE_KLM_MODULE
#define INCLUDE_KLM_MODULE

#include <queue>

#include "base/DetectorInterface.h"
#include "base/defines.h"
#include "base/ScrodPacket.h"
#include "base/ObjectSync.h"


class KlmModule
	/// Class for high lavel KLM module manipulation.
{
public:
	
	typedef enum { hw_trigger, sw_trigger } TrgType_t;

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
		
	int send_trigger(KlmModule::TrgType_t trigger);
		/// Sends the trigger.
		
	ScrodPacket* read_packet() const;
		/// Reads the next packet and return it.
		
	bool start(ObjectSync<ScrodPacket>*	data_drain);
		/// Runs this module.
		
	void stop();
		/// Stops this module.
		
	void wait_end(std::ostream& output);
		/// Waits for the end of execution.

	static void* pt_starter(void* module);
		/// Starts the module.
	
protected:

	void run();
		/// Runs this module.		

	bool should_continue() const;
		/// Should the thread continue.
		
private:

	KlmModule();
		/// Constructor.
	
private:

	DetectorInterface*	_interface;
	scrod_word			_packet_id;
	
	//std::queue<ScrodPacket*>	_packet_queue;
	bool				_run;
	
	pthread_t		_thread;
	pthread_attr_t	_thread_att;
	ObjectSync<ScrodPacket>*	_data_drain;
};

inline bool KlmModule::should_continue() const
{
	return _run;
}
#endif
