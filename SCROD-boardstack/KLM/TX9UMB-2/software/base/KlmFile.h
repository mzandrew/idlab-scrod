#ifndef INCLUDE_KLMFILE
#define INCLUDE_KLMFILE

#include <fstream>

#include "base/KlmConsumer.h"

class KlmFile : public KlmConsumer
	/// Consumer class for dumping packets to the file.
{
public:

	KlmFile(std::string fileName);
		/// Constructor.
		
	virtual ~KlmFile();
		/// Destructor.
		
	virtual void process_packet(ScrodPacket* packet);
		/// Process the packets.
		
	virtual void initialize();
		/// Prepare for running.
		
	virtual void deinitialize();
		/// Finish after running.

protected:

	KlmFile();
		/// Constructor.

private:

private:

	std::string   _name;
	std::ofstream* _file;
};

#endif
