#ifndef INCLUDE_COPPERINTERFACE
#define INCLUDE_COPPERINTERFACE

#include <iostream>
#include <map>
#include <vector>

#include "base/DetectorInterface.h"	
#include "base/defines.h"

class CopperDevice : public DetectorInterface
	/// Class representing a single COPPER link device.
{
public:
		
	CopperDevice();
		/// Creates a COPPER device. 

	virtual ~CopperDevice();
		/// Destructor.

	void close();
		/// Close the connection
		
	void send_data(unsigned char* data, int length, unsigned int timeout) const;
		/// Sends the data. If error occurs, std::runtime_error is thrown.
	
	int receive_data(unsigned char* data, int length, unsigned int timeout) const;
		/// Receives the data and returns the number ob bytes received.
		
protected:
private:

};

class CopperInterface
	/// Class encapsulating common COPPER system utilities.
{
public:

	CopperInterface();
		/// Constructor.

	~CopperInterface();
		/// Destructor.

	
protected:

private:

private:

};


#endif
