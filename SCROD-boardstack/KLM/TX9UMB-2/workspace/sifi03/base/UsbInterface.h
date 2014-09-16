#ifndef INCLUDE_USBINTERFACE
#define INCLUDE_USBINTERFACE

#include <libusb.h>
#include <iostream>
#include <map>
#include <vector>

#include "base/DetectorInterface.h"	
#include "base/defines.h"

class UsbDevice : public DetectorInterface
	/// Class representing a single USB device.
{
public:
		
	UsbDevice(libusb_device_handle* handle, module_id id);
		/// Creates a USB device. 

	virtual ~UsbDevice();
		/// Destructor.

	void close();
		/// Close the connection
		
	void send_data(unsigned char* data, int length, unsigned int timeout) const;
		/// Sends the data. If error occurs, std::runtime_error is thrown.
	
	int receive_data(unsigned char* data, int length, unsigned int timeout) const;
		/// Receives the data and returns the number ob bytes received.
		
protected:
private:

	UsbDevice();
		/// Unreachable constructor.

	libusb_device_handle* _handle;
	
	// device data buffer
	mutable unsigned char	_dev_buffer[USB_ENDPOINT_PACKET_SIZE];
	mutable unsigned int	_dev_buffer_pointer;
	mutable unsigned int	_dev_buffer_length;
};

class UsbInterface
	/// Class encapsulating common USB system utilities.
{
public:

	~UsbInterface();
		/// Destructor.

	void list_all_devices(std::ostream& output) const;
		/// List all devices that are available.
		
	void open_all_devices(std::ostream& output, uint16_t vid, uint16_t pid);
		/// Opens devices.

	void close_all_devices();
		/// Opens devices.
			
	UsbDevice* getDevice(module_id id) const;
		/// Returns the device, or NULL if it has not been found.	
		
	std::vector<module_id> getListOfModules() const;
		/// Returns a vector of modules.
	
	
	
	// static function
	static UsbInterface& USB();
		/// Return singelton handle.
	
	static void Cleanup();
		/// Cleans up.
	
protected:

	void print_device(std::ostream& output, libusb_device *device) const;
		/// prints information of certain USB device.
		
private:

	UsbInterface();
		/// Unreachable constructor.

private:

	typedef std::map<module_id, UsbDevice*> device_map;

	libusb_context* _usblib_context;
	device_map _devices;
	
	static UsbInterface* _singleton;
};


#endif
