#ifndef INCLUDE_KLMCONSUMER
#define INCLUDE_KLMCONSUMER

#include "base/ObjectSync.h"
#include "base/ScrodPacket.h"

class KlmConsumer
	/// Base class for all users of the KLM data
{
public:

	KlmConsumer();
		/// Constructor.
		
	virtual ~KlmConsumer();
		/// Destructor.
		
	bool start();
		/// Run the consumer in its own thread. Returns
		/// TRUE if thread started ok.
		
	void stop();
		/// Stops the thread.
		
	ObjectSync<ScrodPacket>* get_data_drain();
		/// Returns the data input object.
		
	virtual void process_packet(ScrodPacket* packet);
		/// Process the packets.
		
	virtual void initialize();
		/// Prepare for running.
		
	virtual void deinitialize();
		/// Finish after running.

	static void* pt_starter(void* consumer);
		/// Starts the module.

	int get_packet_count() const;
		/// Returns the number of processed packets.
		
	void process_next_packet();
		/// Processes only the next packet.

protected:

	bool should_continue() const;
		/// Should the thread continue.

private:

	void run();
		/// Runs this module.		
	
private:

	mutable pthread_mutex_t _data_mutex;

	int				_packet_counter;

	bool			_run;

	pthread_t		_thread;
	pthread_attr_t	_thread_att;
	ObjectSync<ScrodPacket>	_data_source;
};

inline ObjectSync<ScrodPacket>* KlmConsumer::get_data_drain()
{
	return &_data_source;
}

inline bool KlmConsumer::should_continue() const
{
	return _run;
}

#endif
