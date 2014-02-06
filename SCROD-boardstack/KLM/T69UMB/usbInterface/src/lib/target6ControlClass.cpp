#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include "idl_usb.h"
#include "target6ControlClass.h"
#include "packet_interface.h"

using namespace std;
bool debugglobal = 0;

//initialize the USB interface
int target6ControlClass::initializeUSBInterface(){
	//setup USB starts here
        setup_usb();
	clearDataBuffer();
	return 1;
}

//initialize the USB interface
int target6ControlClass::closeUSBInterface(){
	//close USB starts here
        close_usb();

	return 1;
}

//Clear the input buffer
int target6ControlClass::clearDataBuffer(){
	int size = 0;
        unsigned int inbuf[usbbuf_size];
	unsigned char *p_inbuf = (unsigned char*) &inbuf[0];
        usb_ClearEndpnt((IN_ADDR | LIBUSB_ENDPOINT_IN), p_inbuf, usbbuf_size, TM_OUT);
	usb_ClearEndpnt((IN_ADDR | LIBUSB_ENDPOINT_IN), p_inbuf, usbbuf_size, TM_OUT);

	return 1;
}

//do simple register read
int target6ControlClass::registerRead(unsigned int board_id, unsigned int reg, int &regValReadback) {
	//clear data point
 	clearDataBuffer();
	
	///set up data buffers that are used in USB interface
	int size = 0;
	unsigned int *outbuf;

	//create command packet
	int command_id = 13;
	packet command_stack;
	command_stack.ClearPacket();
	command_stack.CreateCommandPacket(command_id,board_id);
	command_stack.AddReadToPacket(reg);
	outbuf = command_stack.AssemblePacket(size);

	//send command packet to SCROD through USB interface
        usb_XferData((OUT_ADDR | LIBUSB_ENDPOINT_OUT), (unsigned char *) outbuf, size*4, TM_OUT);

	//read back the command response packet
	unsigned int databuf[usbbuf_size];
	int dataSize = 0;
	readPacketFromUSBFifo( databuf, usbbuf_size, dataSize );

	//parse the response packet, get the register value
	regValReadback = -1;
	if( !parseResponsePacketFromUSBforReadWrite( reg, command_id, databuf, dataSize, regValReadback ) ){
		std::cout << "REGISTER READ FAILED " << std::endl;
		return 0;
	}

	//Debugging - print out information
	if(debugglobal){
		std::cout << "Read register # " << std::dec << reg;
		std::cout << "\tregister value hex " << std::hex << regValReadback;
		std::cout << "\tdec " << std::dec << regValReadback << std::endl;
		std::cout << std::endl;
	}

	return 1;
}

//do simple register write without readback
int target6ControlClass::registerWrite(unsigned int board_id, unsigned int reg, unsigned int regVal, int &regValReadback) {
	//clear data point
 	clearDataBuffer();
	
	///set up data buffers that are used in USB interface
	int size = 0;
	unsigned int *outbuf;

	//create command packet
	int command_id = 13;
	packet command_stack;
	command_stack.ClearPacket();
	command_stack.CreateCommandPacket(command_id,board_id);
	command_stack.AddWriteToPacket(reg, regVal);
	outbuf = command_stack.AssemblePacket(size);

	//send command packet to SCROD through USB interface
        usb_XferData((OUT_ADDR | LIBUSB_ENDPOINT_OUT), (unsigned char *) outbuf, size*4, TM_OUT);

	return 1;
}

//do simple register write with readback
int target6ControlClass::registerWriteReadback(unsigned int board_id, unsigned int reg, unsigned int regVal, int &regValReadback) {
	//clear data point
 	clearDataBuffer();
	
	///set up data buffers that are used in USB interface
	int size = 0;
	unsigned int *outbuf;

	//create command packet
	int command_id = 13;
	packet command_stack;
	command_stack.ClearPacket();
	command_stack.CreateCommandPacket(command_id,board_id);
	command_stack.AddWriteToPacket(reg, regVal);
	outbuf = command_stack.AssemblePacket(size);

	//send command packet to SCROD through USB interface
        usb_XferData((OUT_ADDR | LIBUSB_ENDPOINT_OUT), (unsigned char *) outbuf, size*4, TM_OUT);

	//read back the command response packet
	unsigned int databuf[usbbuf_size];
	int dataSize = 0;
	readPacketFromUSBFifo( databuf, usbbuf_size, dataSize );

	//parse the response packet, get the register value
	regValReadback = -1;
	if( !parseResponsePacketFromUSBforReadWrite( reg, command_id, databuf, dataSize, regValReadback ) ){
		std::cout << "REGISTER WRITE FAILED " << std::endl;
		return 0;
	}
	//test readback register value to make sure register write succeeded
	if( regValReadback != regVal ){
		std::cout << "REGISTER WRITE FAILED, INCORRECT REGISTER VALUE SET! " << std::endl;
		return 0;
	}

	//Debugging - print out information
	if(debugglobal){
		std::cout << "Write register # " << std::dec << reg;
		std::cout << "\tregister value hex " << std::hex << regValReadback;
		std::cout << "\tdec " << std::dec << regValReadback << std::endl;
		std::cout << std::endl;
	}

	return 1;
}

//read out SCROD response packet from USB FIFO
int target6ControlClass::readPacketFromUSBFifo( unsigned int databuf[], int bufSize, int &dataSize ){
	int size = 0;
	unsigned int inbuf[usbbuf_size];
	unsigned char *p_inbuf = (unsigned char*) &inbuf[0];
	int count = 0;	

	//continually read out USB FIFO and copy into data buffer
	int retval = usb_XferData((IN_ADDR | LIBUSB_ENDPOINT_IN), p_inbuf, usbbuf_size*sizeof(unsigned int), TM_OUT);
	while (retval > 0 && count < 10000){ //count based time out condition
		for(int j=0;j<retval/4;j++){
			if( count < bufSize )
				databuf[count] = inbuf[j];
			count++;
		}
   		retval = usb_XferData((IN_ADDR | LIBUSB_ENDPOINT_IN), p_inbuf, usbbuf_size*sizeof(unsigned int), TM_OUT);
	}
	if( count >= bufSize ){
		std::cout << "USB packet read larger than data buffer, data is missing " << std::endl;
		return 0;
	}
	dataSize = count;

	//Debugging - print out each response packet in it's entirety
	if(debugglobal){
		std::cout << "RESPONSE PACKET " << std::endl;
		for(int j=0;j<dataSize; j++)
			std::cout << "\t" << std::hex << databuf[j] << std::endl;
		std::cout << "END RESPONSE PACKET " << std::endl;
		std::cout << std::endl;
	}

	return 1;
}

//parse the SCROD read/write register command response packet
int target6ControlClass::parseResponsePacketFromUSBforReadWrite( int reg, int command_id, unsigned int databuf[], int dataSize, int &regVal ){
	//initialize return register value to obviously wrong state
	regVal = -1;

	//check if data packet has at least two lines
	if( dataSize != 8 ){
		std::cout << "Truncated/malformed read/write response packet, assume command failed" << std::endl;
		return 0;
	}
	
	//check for SCROD packet header
	if( databuf[0] != 0x00BE11E2 ){
		std::cout << "Invalid response packet header, assume command failed" << std::endl;
		return 0;
	}
	
	//check for packet length
	if( databuf[1] > usbbuf_size ){
		std::cout << "Response packet too long, assume command failed" << std::endl;
		return 0;
	}

	//check for mismatch between packet size and number of words field
	if( databuf[1] !=  dataSize - 2){
		std::cout << "Mismatch between packet size and number of words field, assume command failed" << std::endl;
		return 0;
	}

	//check that response packet is "okay" type
	if( databuf[2] != 0x6f6b6179){
		std::cout << "Wrong packet type in response packet, assume command failed" << std::endl;
		return 0;
	}

	//check that command ID matches the one used
	if( databuf[4] != command_id ){
		std::cout << "Response command ID does not match input, assume command failed" << std::endl;
		return 0;
	}

	//check that command type agrees with command packet type (basic implementation here)
	if( databuf[5] != 0x72656164 && databuf[5] != 0x72697465 ){
		std::cout << "Response packet command type does not match input, assume command failed" << std::endl;
		return 0;
	}

	//should test something with checksum here...

	//read register values
	int regResponse = databuf[6] & 0xFFFF;
	int regValResponse  = ((databuf[6] & 0xFFFF0000) >> 16);

	//check that register matches input register
	if( reg != regResponse ){
		std::cout << "Mismatch between command and response packet register address, assume command failed" << std::endl;
		return 0;
	}
	
	//assign register value in response packet to return value
	regVal = regValResponse;

	return 1;
}
