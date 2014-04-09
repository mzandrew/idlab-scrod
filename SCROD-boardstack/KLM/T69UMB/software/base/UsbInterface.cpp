#include <stdexcept>
#include <stdio.h>
#include <cstring>

#include "base/UsbInterface.h"

using namespace std;

//
// USB device
//

UsbDevice::UsbDevice()
{
	_dev_buffer_pointer = 0;
	_dev_buffer_length = 0;
}

UsbDevice::UsbDevice(libusb_device_handle* handle, module_id id)
{
	_handle = handle;
	setDeviceID(id);
	
	// clear the handle
	int transferred, status, total, length;
	unsigned char buff[10];
	
	_dev_buffer_pointer = 0;
	_dev_buffer_length = 0;
	total = 0;
	transferred = 1;
	length = 10;
	while(transferred > 0)
	{
		status = libusb_bulk_transfer(_handle, USB_IN__ENDPOINT | LIBUSB_ENDPOINT_IN, buff, length, &transferred, 10);
		total += transferred;
	}
	//cout << "Cleared " << total << " bytes from the interface." << endl;
}

void UsbDevice::close()
{
	if(_handle)
		libusb_close(_handle);
	_handle = NULL;
}

UsbDevice::~UsbDevice()
{
	close();
}

void UsbDevice::send_data(unsigned char* data, int length, unsigned int timeout) const
{
	int transferred, status;
	
	while(true)
	{
		//cout << "Sending " << length << " bytes." << endl;
		//for(int i=0; i<length/4; i++)
		//	printf("0x%08x\n", *((uint32_t*)(data+i*4)));
		status = libusb_bulk_transfer(_handle, USB_OUT_ENDPOINT | LIBUSB_ENDPOINT_OUT, data, length, &transferred, timeout);
		if(status == 0)
		{
			// all ok
			length -= transferred;
			data += transferred;
			if(length == 0)
				return;
			else
				continue; // go on and finish
		}
		else if(status == LIBUSB_ERROR_TIMEOUT)
		{
			// time needed
			length -= transferred;
			data += transferred;
			if(length == 0)
				return;
			else
				continue; // go on and finish
		}
		else if(status == LIBUSB_ERROR_NO_DEVICE || status == LIBUSB_ERROR_PIPE || status == LIBUSB_ERROR_OVERFLOW)
		{
			// no device any more
			char text[100];
			sprintf(text, "Device with DeviceID=%u dissapiered from the USB.", getDeviceID());
			throw runtime_error(text);
		}
		else
		{
			// other errors
			char text[100];
			sprintf(text, "Device with DeviceID=%u had problem (%i) during bulk write.", getDeviceID(), status);
			throw runtime_error(text);
		}
	}    	
}

int UsbDevice::receive_data(unsigned char* data, int length, unsigned int timeout) const
{
	int transferred, status, todo, total;
	
	total = 0;
	
	// transfer from before
	if(_dev_buffer_length > 0)
	{
		//cout << "Before(" << _dev_buffer_pointer << "," << _dev_buffer_length << "," << length << ")";
		if(_dev_buffer_length >= length)
		{
			memcpy(data, _dev_buffer+_dev_buffer_pointer, length);
			_dev_buffer_pointer += length;
			_dev_buffer_length -= length;
			//cout << "All before" << endl;
			return length;
		}
		else
		{
			memcpy(data, _dev_buffer+_dev_buffer_pointer, _dev_buffer_length);
			data += _dev_buffer_length;
			total += _dev_buffer_length;
			length -= _dev_buffer_length;
			_dev_buffer_pointer = 0;
			_dev_buffer_length = 0;
		}
	}	
	
	// how many whole packets?
	int packets = length/USB_ENDPOINT_PACKET_SIZE;
	if(packets > 0)
	{
		todo = packets*USB_ENDPOINT_PACKET_SIZE;
		// read the whole packets
		while(true)
		{
			status = libusb_bulk_transfer(_handle, USB_IN__ENDPOINT | LIBUSB_ENDPOINT_IN, data, todo, &transferred, timeout);
			//cout << "Packet(" << packets << "," << todo << "," << total << ")";
			if(status == 0)
			{
				// all ok
				todo -= transferred;
				data += transferred;
				total += transferred;
				if(todo == 0)
					break; // all read
				else
					continue; // go on and finish
			}
			else if(status == LIBUSB_ERROR_TIMEOUT)
			{
				// timeout
				//cout << endl;
				return total;
			}
			else if(status == LIBUSB_ERROR_OVERFLOW)
			{
				// overflow
				char text[100];
				sprintf(text, "Device with DeviceID=%u has overflow problem.", getDeviceID());
				throw runtime_error(text);
			}
			else if(status == LIBUSB_ERROR_NO_DEVICE || status == LIBUSB_ERROR_PIPE)
			{
				// no device any more
				char text[100];
				sprintf(text, "Device with DeviceID=%u dissapiered from the USB.", getDeviceID());
				throw runtime_error(text);
			}
			else
			{
				// other errors
				char text[100];
				sprintf(text, "Device with DeviceID=%u had problem (%i) during bulk read.", getDeviceID(), status);
				throw runtime_error(text);
			}
		}
		
		// here all the packets were read
		length -= packets*USB_ENDPOINT_PACKET_SIZE;
	 }
	 
	 // is there a partial read left?
	 if(length > 0)
	 {
		_dev_buffer_pointer = 0;
		_dev_buffer_length = 0;		
		todo = USB_ENDPOINT_PACKET_SIZE;	
		while(true)
		{
			status = libusb_bulk_transfer(_handle, USB_IN__ENDPOINT | LIBUSB_ENDPOINT_IN, _dev_buffer+_dev_buffer_length, todo, &transferred, timeout);
			//cout << "End(" << length << "," << todo << "," << total << "," << _dev_buffer_length << ")";
			if(status == 0)
			{
				// all ok
				todo -= transferred;
				total += transferred;
				_dev_buffer_length += transferred;
				if(_dev_buffer_length >= length)
				{
					memcpy(data, _dev_buffer, length);
					_dev_buffer_pointer = length;
					_dev_buffer_length -= length;
					//cout << "Done(" << _dev_buffer_pointer << "," << _dev_buffer_length << ")";
					break; // all read
				}
				else
					continue; // go on and finish
			}
			else if(status == LIBUSB_ERROR_TIMEOUT)
			{
				// timeout
				//cout << endl;
				return total;
			}
			else if(status == LIBUSB_ERROR_OVERFLOW)
			{
				// overflow
				char text[100];
				sprintf(text, "Device with DeviceID=%u has overflow problem.", getDeviceID());
				throw runtime_error(text);
			}
			else if(status == LIBUSB_ERROR_NO_DEVICE || status == LIBUSB_ERROR_PIPE)
			{
				// no device any more
				char text[100];
				sprintf(text, "Device with DeviceID=%u dissapiered from the USB.", getDeviceID());
				throw runtime_error(text);
			}
			else
			{
				// other errors
				char text[100];
				sprintf(text, "Device with DeviceID=%u had problem (%i) during bulk read.", getDeviceID(), status);
				throw runtime_error(text);
			}
		}
	}
	
	//cout << endl;
	return total;
}

//
// USB interface
//

UsbInterface* UsbInterface::_singleton = NULL;

UsbInterface& UsbInterface::USB()
{
	if(_singleton == NULL)
		_singleton = new UsbInterface();
	return *_singleton;
}

void UsbInterface::Cleanup()
{
	if(_singleton)
		delete _singleton;
	_singleton = NULL;
}

UsbInterface::UsbInterface()
{
	// create context
	_usblib_context = NULL;
	
	int status = libusb_init(&_usblib_context); // create a libusb session
	if(status < 0) // create a libusb session
	{
		_usblib_context = NULL;
		throw runtime_error("Can not create libusb session.");
	}
	libusb_set_debug(_usblib_context, 3); // set verbosity to lvl 3

	//cout << "Opening USB session!" << endl;
}

UsbInterface::~UsbInterface()
{
	// destroy context
	if(_usblib_context)
		libusb_exit(_usblib_context); // close libusb session
		
	//cout << "Closing USB session!" << endl;
}

void UsbInterface::list_all_devices(std::ostream& output) const
{
	int dev_cnt, status;
	libusb_device **devices;
	libusb_device_descriptor descriptor;
	
	dev_cnt = libusb_get_device_list(_usblib_context, &devices); // get list of USB devices

	if(dev_cnt < 0 )
	{
		output << "No USB devices found." << endl;
	}
	else
	{
		ssize_t i;
		output << "VID    | PID    | # consfig | class  | bus | addr |" << endl;
		for(int i = 0; i < dev_cnt; i++)
		{
			status = libusb_get_device_descriptor(devices[i], &descriptor);
			if(status < 0)
			{
				throw runtime_error("Failed to get device descriptor.");
			}
			else
			{
				print_device(output, devices[i]);
			}
		}
	}
}

void UsbInterface::print_device(std::ostream& output, libusb_device *device) const
{
	int status;
	char text[100];
	libusb_device_descriptor descriptor;
	
	status = libusb_get_device_descriptor(device, &descriptor);
	if (status < 0)
	{
		throw runtime_error("Failed to get device descriptor.");
	}

	sprintf(text, "0x%04x | 0x%04x | %6u    | %6i | %3u |  %3u |" , descriptor.idVendor, descriptor.idProduct, (unsigned)descriptor.bNumConfigurations, (int)descriptor.bDeviceClass, libusb_get_bus_number(device), libusb_get_device_address(device));
    output << text << endl;
}

void UsbInterface::open_all_devices(std::ostream& output, uint16_t vid, uint16_t pid)
{
	int dev_cnt, status;
	unsigned char text[100];
	libusb_device **devices;
	libusb_device_descriptor descriptor;
	libusb_device_handle *handle;
	
	dev_cnt = libusb_get_device_list(_usblib_context, &devices); // get list of USB devices

	if(dev_cnt < 0 )
	{
		output << "No USB devices found." << endl;
	}
	else
	{
		ssize_t i;
		for(int i = 0; i < dev_cnt; i++)
		{
			status = libusb_get_device_descriptor(devices[i], &descriptor);
			if(status < 0)
			{
				throw runtime_error("Failed to get device descriptor.");
			}
			else if(descriptor.idVendor == vid && descriptor.idProduct == pid)
			{
				// the desired vendor & product
				
				// open and get serial number
				status = libusb_open(devices[i], &handle);
				
				if(status)
				{
					// error occured
					output << "Error opening device (bus=" << (int)libusb_get_bus_number(devices[i]) << " addr=" << (int)libusb_get_device_address(devices[i]) <<"): " << status /*libusb_error_name(status)*/ << endl;
					continue;
				}
				
				// keep it open 
				
				// assign ID to a device 
				// NOTE: this is a dummy algo, must use something smarter
				module_id id = _devices.size(); 

				// create a device
				UsbDevice* tmp_device = new UsbDevice(handle, id);
				
				// inser into device list
				std::pair<device_map::iterator,bool> ret;
				ret = _devices.insert( std::pair<module_id, UsbDevice*>(tmp_device->getDeviceID(), tmp_device) );
				if(ret.second==false)
				{
					// this device id already in use
					output << "ERROR: Device (bus=" << (int)libusb_get_bus_number(devices[i]) << " addr=" << (int)libusb_get_device_address(devices[i]) <<"): assigned already used DeviceID=" << (int)id << ". It will not be used." << endl;
					delete tmp_device;
					continue;
				}

				// done
				output << "Device (bus=" << (int)libusb_get_bus_number(devices[i]) << " addr=" << (int)libusb_get_device_address(devices[i]) <<"): loaded under DeviceID=" << (int)tmp_device->getDeviceID() << "." << endl;
			}
		}
	}
}

void UsbInterface::close_all_devices()
{
	for(device_map::iterator dev = _devices.begin(); dev != _devices.end(); dev++)
	{
		dev->second->close();
		delete dev->second;
	}
	_devices.clear();
}

UsbDevice* UsbInterface::getDevice(module_id id) const
{
	device_map::const_iterator it = _devices.find(id);
	if(it == _devices.end())
		return NULL;
	else
		return it->second;
}

std::vector<module_id> UsbInterface::getListOfModules() const
{
	std::vector<module_id> list;
	
	for(device_map::const_iterator dev = _devices.begin(); dev != _devices.end(); dev++)
		list.push_back(dev->first);
		
	return list;
}
