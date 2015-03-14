#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include "idl_usb.h"
#include "target6ControlClass.h"
#include "packet_interface.h"
#include <fstream>

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

int target6ControlClass::usbTest(){
	//printdev(&dev);
	//list_endpoints(libusb_device *desc);
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

//read out SCROD response packet from USB FIFO
int target6ControlClass::printPacketFromUSBFifo(){
	int bufSize = usbbuf_size;
	unsigned int databuf[usbbuf_size];
	int dataSize = 0;
	int size = 0;
	unsigned int inbuf[usbbuf_size];
	unsigned char *p_inbuf = (unsigned char*) &inbuf[0];
	int count = 0;	

	//continually read out USB FIFO and copy into data buffer
	int retval = usb_XferData((IN_ADDR | LIBUSB_ENDPOINT_IN), p_inbuf, usbbuf_size*sizeof(unsigned int), TM_OUT);
	while (retval > 0 && count < 10000){ //count based time out condition
		for(int j=0;j<retval/4+4;j++){
			if( count < bufSize )
				databuf[count] = inbuf[j];
			count++;
		}
   		retval = usb_XferData((IN_ADDR | LIBUSB_ENDPOINT_IN), p_inbuf, usbbuf_size*sizeof(unsigned int), TM_OUT);
	}
	if( count >= bufSize ){
		std::cout << "USB packet read larger than data buffer, data is missing " << std::endl;

		std::cout << "RESPONSE PACKET " << std::endl;
		for(int j=0;j<bufSize; j++)
			std::cout << "\t" << std::hex << databuf[j] << std::endl;
		std::cout << "END RESPONSE PACKET " << std::endl;
		std::cout << std::endl;

		std::cout << "USB packet read larger than data buffer, data is missing " << std::endl;
		return 0;
	}
	dataSize = count;

	//Debugging - print out each response packet in it's entirety
	if(1){
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

//parse the SCROD event packet
int target6ControlClass::parseResponsePacketForEvents(unsigned int databuf[], int dataSize, unsigned int wavedatabuf[], int &wavedataSize){
	wavedataSize = 0;
	for(int j=0;j<dataSize; j++){
		unsigned int bitNum = ((0x0F000000 &  databuf[j]) >> 24 );
		unsigned int sampNum = ((0x001F0000 & databuf[j]) >> 16 );
		unsigned int winNum = ((0x00E00000 & databuf[j]) >> 21 );
		std::cout << std::hex << databuf[j];			
		std::cout << "\t" << bitNum;
		std::cout << "\t" << sampNum;
		std::cout << "\t" << winNum;
		std::cout << std::endl;


		continue;
		//detect packet header word
		if( databuf[j] != 0x00BE11E2 )
			continue;
		//check that there are at least 2 more lines in buffer
		if( j >= dataSize - 2 )
			continue;
		int packetStartPos = j;
		unsigned int packetSize = databuf[packetStartPos+1]+2;
		//check that the packet is entirely contained within buffer
		//if( j > dataSize - packetSize ) //currently diable
		//	continue;
		//check that packet is event type
		unsigned int packetType = databuf[packetStartPos+2];
		if( packetType != 0x65766e74 )
			continue;
		//HACK - just check if temp sample data words are there
		//unsigned int firstSample = databuf[packetStartPos+5];
		//if( (firstSample & 0xF0000000 ) != 0xD0000000 )
		//	continue;
		//add waveform data packet to the data packet buffer
		//for now just assume entire remaining buffer is data, bad assumptionm
		for(int pos = packetStartPos; pos < dataSize ; pos++){
			wavedatabuf[wavedataSize] = databuf[pos];
			wavedataSize++;
		}
		//increment buffer position past waveform packet
		//j = j + wavedataSize-4;
	}
	return 1;
}

int target6ControlClass::getEventData(unsigned int eventdatabuf[], int &eventdataSize){
	//read back the data packet
	unsigned int databuf[65536];
	int dataSize = 0;
	readPacketFromUSBFifo( databuf, 65536, dataSize );

	//parse the data packet and extract waveform packets only
	parseResponsePacketForEvents(databuf,dataSize,eventdatabuf,eventdataSize);

	return 1;
}

int target6ControlClass::writeEventToFile(unsigned int eventdatabuf[], int eventdataSize, std::ofstream& dataFile){
	if( !dataFile.is_open() ){
		std::cout << "File is not open for writing event" << std::endl;
		return 0;
	}

	dataFile.write(reinterpret_cast<char*>(eventdatabuf), eventdataSize*sizeof(unsigned int));
//	dataFile.write( (unsigned char)*(&eventdatabuf), eventdataSize*sizeof(unsigned int) );

	return 1;
}

int target6ControlClass::writeDACReg(unsigned int board_id, int dcNum, int regNum, int regVal){

	if( dcNum < 0 || dcNum > 9 ){
		std::cout << "writeDACReg - invalid dcNum input: " << dcNum << std::endl;
		return 0;
	}

	if( regNum < 0 || regNum > 255 ){
		std::cout << "writeDACReg - invalid regNum input: " << regNum << std::endl;
		return 0;
	}

	if( regVal < 0 || regVal > 4095 ){
		std::cout << "writeDACReg - invalid regVal input: " << regVal << std::endl;
		return 0;
	}

	//clear data point
 	clearDataBuffer();

	int regValReadback;

	//begin ASIC DAC programming through software, uses regNum and regVal
	std::cout << "Start DAC Program Process - Writing DC # " << dcNum << "\tRegister " << regNum << "\tValue " << regVal << std::endl;

	///set up data buffers that are used in USB interface
	int size = 0;
	unsigned int *outbuf;

	//create command packet
	int command_id = 13;
	packet command_stack;
	command_stack.ClearPacket();
	command_stack.CreateCommandPacket(command_id,board_id);
	//clear update i/o register (register #0)
	command_stack.AddWriteToPacket(1, 0);
	//set the correct bit in the DAC loading DC# mask
	command_stack.AddWriteToPacket(4, (1 << dcNum));
	//write desired ASIC register # and DAC to corresponding firmware i/o registers
	command_stack.AddWriteToPacket(2, regNum);
	command_stack.AddWriteToPacket(3, regVal);
	//toggle bit of update i/o register (register #0)
	command_stack.AddWriteToPacket(1, 1);
	command_stack.AddWriteToPacket(1, 0);
	outbuf = command_stack.AssemblePacket(size);

	//send command packet to SCROD through USB interface
        usb_XferData((OUT_ADDR | LIBUSB_ENDPOINT_OUT), (unsigned char *) outbuf, size*4, TM_OUT);
	
	/*
	//clear update i/o register (register #0)
	registerWriteReadback(board_id, 1, 0, regValReadback);

	//set the correct bit in the DAC loading DC# mask
	registerWriteReadback(board_id, 4, (1 << dcNum) , regValReadback);

	//initialize the DAC loading and latch period registers to something reasonable
	//registerWriteReadback(board_id, 5, 256 , regValReadback);
	//registerWriteReadback(board_id, 6, 640 , regValReadback);

	//write desired ASIC register # and DAC to corresponding firmware i/o registers
	registerWriteReadback(board_id, 2, regNum, regValReadback);
	registerWriteReadback(board_id, 3, regVal, regValReadback);

	//set bit of update i/o register (register #0)
	registerWriteReadback(board_id, 1, 1, regValReadback);

	//wait some time
	//usleep(100);

	//clear update i/o register (register #0)
	//registerWriteReadback(board_id, 1, 0, regValReadback);
	*/	

	return 1;
}

int target6ControlClass::resetTriggers(unsigned int board_id){

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
	command_stack.AddWriteToPacket(71, 0);
	command_stack.AddWriteToPacket(71, 1);
	command_stack.AddWriteToPacket(71, 0);
	outbuf = command_stack.AssemblePacket(size);

	//send command packet to SCROD through USB interface
        usb_XferData((OUT_ADDR | LIBUSB_ENDPOINT_OUT), (unsigned char *) outbuf, size*4, TM_OUT);

	return 1;
}

int target6ControlClass::sendTrigger(unsigned int board_id, bool softwareOrHardware){

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
	command_stack.AddWriteToPacket(50, 0);
	command_stack.AddWriteToPacket(52, 0);
	command_stack.AddWriteToPacket(55, 1);
	command_stack.AddWriteToPacket(55, 0);
	//Software trigger
	if(softwareOrHardware == 0)
		command_stack.AddWriteToPacket(50, 1);
	//Hardware trigger
	else
		command_stack.AddWriteToPacket(52, 1);
	outbuf = command_stack.AssemblePacket(size);

	//send command packet to SCROD through USB interface
        usb_XferData((OUT_ADDR | LIBUSB_ENDPOINT_OUT), (unsigned char *) outbuf, size*4, TM_OUT);

	return 1;
}

int target6ControlClass::continueReadout(unsigned int board_id){

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
	command_stack.AddWriteToPacket(58, 0);
	command_stack.AddWriteToPacket(58, 1);
	outbuf = command_stack.AssemblePacket(size);

	//send command packet to SCROD through USB interface
        usb_XferData((OUT_ADDR | LIBUSB_ENDPOINT_OUT), (unsigned char *) outbuf, size*4, TM_OUT);

	return 1;
}


int target6ControlClass::sendSamplingReset(unsigned int board_id){

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
	command_stack.AddWriteToPacket(10, 0);
//	command_stack.AddWriteToPacket(10, 0);
//	command_stack.AddWriteToPacket(10, 1);
//	command_stack.AddWriteToPacket(10, 1);
	command_stack.AddWriteToPacket(10, 1);
//	command_stack.AddWriteToPacket(10, 0);
//	command_stack.AddWriteToPacket(10, 0);
	command_stack.AddWriteToPacket(10, 0);
	//Software trigger
	outbuf = command_stack.AssemblePacket(size);

	//send command packet to SCROD through USB interface
        usb_XferData((OUT_ADDR | LIBUSB_ENDPOINT_OUT), (unsigned char *) outbuf, size*4, TM_OUT);

	return 1;
}
