#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <fstream>
#include "idl_usb.h"
#include "irs3BControlClass.h"
#include "irs3b_registers.h"
#include "packet_interface.h"

using namespace std;
bool debugglobal = 0;

int irs3BControlClass::sendSoftwareTrigger(unsigned int board_id){

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
        command_stack.AddWriteToPacket(SWTRIG_PED_FLAGS, 0x0000);
        command_stack.AddWriteToPacket(SWTRIG_PED_FLAGS, 0x4000);

	outbuf = command_stack.AssemblePacket(size);

        //send command packet to SCROD through USB interface
        usb_XferData((OUT_ADDR | LIBUSB_ENDPOINT_OUT), (unsigned char *) outbuf, size*4, TM_OUT);

	return 1;
}

int irs3BControlClass::getWaveformData(unsigned int wavedatabuf[], int &wavedataSize){
	//read back the data packet
	unsigned int databuf[65536];
	int dataSize = 0;
	readPacketFromUSBFifo( databuf, 65536, dataSize );

	//parse the data packet and extract waveform packets only
	parseResponsePacketForWaveforms(databuf,dataSize,wavedatabuf,wavedataSize);

	return 1;
}

//parse the SCROD read/write register command response packet
int irs3BControlClass::parseResponsePacketForWaveforms(unsigned int databuf[], int dataSize, unsigned int wavedatabuf[], int &wavedataSize){
	wavedataSize = 0;
	for(int j=0;j<dataSize; j++){
		//detect packet header word
		if( databuf[j] != 0x00BE11E2 )
			continue;
		//check that there are at least 2 more lines in buffer
		if( j >= dataSize - 2 )
			continue;
		int packetStartPos = j;
		unsigned int packetSize = databuf[packetStartPos+1]+2;
		//check that the packet is entirely contained within buffer
		if( j > dataSize - packetSize )
			continue;
		//check that packet is waveform type
		unsigned int packetType = databuf[packetStartPos+2];
		if( packetType != 0x77617665 )
			continue;
		//add waveform data packet to the data packet buffer
		for(int pos = packetStartPos; pos < packetStartPos + int(packetSize) ; pos++){
			wavedatabuf[wavedataSize] = databuf[pos];
			wavedataSize++;
		}
		//increment buffer position past waveform packet
		//j = j + wavedataSize-4;
	}
	return 1;
}

//set ASIC DACs appropriate for IRS3Cs on carriers Rev C/D
int irs3BControlClass::initializeAsicDACs_irs3B_carrierRevC(unsigned int board_id){
	std::cout << "INITIALIZING ASIC DACS" << std::endl;

	int numASICs = 16;

	//define register readback variable
	int regValReadback;

	//Set readout control signals ---------------------------------------------------

	//clear hardware/software trigger masks
	if( !registerWriteReadback(board_id, SWTRIG_PED_FLAGS, 0x0, regValReadback) )
		std::cout << "Failed to set SWTRIG_PED_FLAGS " << std::endl;

	//set minimum and maximum lookbacks
	if( !registerWriteReadback(board_id, MAX_NUM_WINDOWS, 15, regValReadback) )
		std::cout << "Failed to set MAX_NUM_WINDOWS " << std::endl;
	if( !registerWriteReadback(board_id, MIN_NUM_WINDOWS, 0, regValReadback) )
		std::cout << "Failed to set MIN_NUM_WINDOWS " << std::endl;
	
	//set number of window pairs to sample after trigger
	if( !registerWriteReadback(board_id, NUM_WINPAIRS_SAMP, 0, regValReadback) )
		std::cout << "Failed to set NUM_WINPAIRS_SAMP " << std::endl;

	//set first and last allowed windows
	if( !registerWriteReadback(board_id, FIRST_ALLOWED_WINDOW, 0, regValReadback) )
		std::cout << "Failed to set FIRST_ALLOWED_WINDOW " << std::endl;
	if( !registerWriteReadback(board_id, LAST_ALLOWED_WINDOW, 15, regValReadback) )
		std::cout << "Failed to set LAST_ALLOWED_WINDOW " << std::endl;

	//use external VadjN DAC
	if( !registerWriteReadback(board_id, USE_EXTERNAL_DACS_FOR_SAMPLING_RATE_CONTROL, 0x1, regValReadback) )
		std::cout << "Failed to set USE_EXTERNAL_DACS_FOR_SAMPLING_RATE_CONTROL " << std::endl;
	
	//Disable feedbacks before setting DACs ---------------------------------------------------

	//disable VadjP/N feedbacks
	if( !registerWriteReadback(board_id, SAMP_RATE_FEEDBK_ENA, 0x0000, regValReadback) )
		std::cout << "Failed to set SAMP_RATE_FEEDBK_ENA " << std::endl;

	//disable Wilkinson feedbacks
	if( !registerWriteReadback(board_id, WILK_RATE_FEEDBK_ENA, 0x0000, regValReadback) )
		std::cout << "Failed to set WILK_RATE_FEEDBK_ENA " << std::endl;

	//disable trigger width feedbacks
	if( !registerWriteReadback(board_id, TRIG_WIDTH_FEEDBACK_ENA, 0x0000, regValReadback) )
		std::cout << "Failed to set TRIG_WIDTH_FEEDBACK_ENA " << std::endl;

	//Set general ASIC DACs ---------------------------------------------------

	//Set DAC buffer biases 
	if( !registerWriteReadback(board_id, DAC_BUF_BIASES, 0x340, regValReadback) )
		std::cout << "Failed to set DAC_BUF_BIASES " << std::endl;

	//Set VadjP DAC buffer biases
	if( !registerWriteReadback(board_id, DAC_BUF_BIAS_VADJP, 0x0, regValReadback) )
		std::cout << "Failed to set DAC_BUF_BIAS_VADJP " << std::endl;

	//Set VadjN DAC buffer biases
	if( !registerWriteReadback(board_id, DAC_BUF_BIAS_VADJN, 0x0, regValReadback) )
		std::cout << "Failed to set DAC_BUF_BIAS_VADJN " << std::endl;

	//Set ISEL DAC buffer bias - DAC_BUF_BIAS_ISEL and ISEL - set by resistor
	if( !registerWriteReadback(board_id, DAC_BUF_BIAS_ISEL, 0x0, regValReadback) )
		std::cout << "Failed to set DAC_BUF_BIAS_VADJN " << std::endl;
	
	//Set SBBIAS
	if( !registerWriteReadback(board_id, SBBIAS, 0x380, regValReadback) )
		std::cout << "Failed to set SBBIAS " << std::endl;

	//Set PUBIAS
	if( !registerWriteReadback(board_id, PUBIAS, 3056, regValReadback) )
		std::cout << "Failed to set PUBIAS " << std::endl;

	//Set CMPBias
	if( !registerWriteReadback(board_id, CMPBIAS, 1075, regValReadback) )
		std::cout << "Failed to set CMPBIAS " << std::endl;

	//Set CMPBias2
	if( !registerWriteReadback(board_id, CMPBIAS2, 1000, regValReadback) )
		std::cout << "Failed to set CMPBIAS2 " << std::endl;

	//Set TRGBias	
	if( !registerWriteReadback(board_id, TRGBIAS, 0x3e8, regValReadback) )
		std::cout << "Failed to set TRGBIAS " << std::endl;

	//Set ASIC-specific DACs ---------------------------------------------------
	for(int i = 0 ; i < numASICs ; i++ ){
		//Set WBIAS
		if( !registerWriteReadback(board_id, WBIAS_base + i, 1310, regValReadback) )
			std::cout << "Failed to set WBIAS, register " << WBIAS_base + i << std::endl;
		//Set VBias
		if( !registerWriteReadback(board_id, VBIAS_base + i, 0x300, regValReadback) )
			std::cout << "Failed to set VBIAS, register " << VBIAS_base + i << std::endl;
		//Set VBias2
		if( !registerWriteReadback(board_id, VBIAS2_base + i, 0x300, regValReadback) )
			std::cout << "Failed to set VBIAS2, register " << VBIAS2_base + i << std::endl;
		//Set Wilkinson DACs
		if( !registerWriteReadback(board_id, VDLY_base + i, 2000, regValReadback) )
			std::cout << "Failed to set VDLY_base, register " << VDLY_base + i << std::endl;
		//Set VadjP DAC values
		if( !registerWriteReadback(board_id, VADJP_base + i, 0xAC00, regValReadback) )
			std::cout << "Failed to set VADJP_base, register " << VADJP_base + i << std::endl;
		//Set VadjN DAC values
		if( !registerWriteReadback(board_id, VADJN_base + i, 25000, regValReadback) )
			std::cout << "Failed to set VADJN_base, register " << VADJN_base + i << std::endl;
	}

	//set timing generator control DACs - ASIC specific
	for(int i = 0 ; i < numASICs ; i++ ){
		//TIMING_WR_STRB_base
		if( !registerWriteReadback(board_id, TIMING_WR_STRB_base + i, 0x7040, regValReadback) )
			std::cout << "Failed to set TIMING_WR_STRB_base, register " << TIMING_WR_STRB_base + i << std::endl;
		//TIMING_PHASE_base
		if( !registerWriteReadback(board_id, TIMING_PHASE_base + i, 0x3018, regValReadback) )
			std::cout << "Failed to set TIMING_PHASE_base, register " << TIMING_PHASE_base + i << std::endl;
		//TIMING_SSP_base
		if( !registerWriteReadback(board_id, TIMING_SSP_base + i, 0x1060, regValReadback) )
		//if( !registerWriteReadback(board_id, TIMING_SSP_base + i, 0x1064, regValReadback) )
			std::cout << "Failed to set TIMING_SSP_base, register " << TIMING_SSP_base + i << std::endl;
		//TIMING_S1_base
		if( !registerWriteReadback(board_id, TIMING_S1_base + i, 0x5828, regValReadback) )
			std::cout << "Failed to set TIMING_S1_base, register " << TIMING_S1_base + i << std::endl;
		//TIMING_S2_base
		if( !registerWriteReadback(board_id, TIMING_S2_base + i, 0x1868, regValReadback) )
			std::cout << "Failed to set TIMING_S2_base, register " << TIMING_S2_base + i << std::endl;
	}

	//set feedback targets ---------------------------------------------------
	for(int i = 0 ; i < numASICs ; i++ ){
		if( !registerWriteReadback(board_id, WILKINSON_TARGET_base + i, 14000, regValReadback) )
			std::cout << "Failed to set WILKINSON_TARGET_base, register " << WILKINSON_TARGET_base + i << std::endl;
		if( !registerWriteReadback(board_id, RCO_TARGET_base + i, 10950, regValReadback) )
		//if( !registerWriteReadback(board_id, RCO_TARGET_base + i, 10790, regValReadback) )
			std::cout << "Failed to set RCO_TARGET_base, register " << RCO_TARGET_base + i << std::endl;
	}

	//Enable feedbacks after setting DACs ---------------------------------------------------

	//enable VadjP/N feedbacks
	//if( !registerWriteReadback(board_id, SAMP_RATE_FEEDBK_ENA, 0xFFFF, regValReadback) )
	//	std::cout << "Failed to set SAMP_RATE_FEEDBK_ENA " << std::endl;

	//enable Wilkinson feedbacks
	if( !registerWriteReadback(board_id, WILK_RATE_FEEDBK_ENA, 0xFFFF, regValReadback) )
		std::cout << "Failed to set WILK_RATE_FEEDBK_ENA " << std::endl;

	//NOT USED enable trigger width feedbacks
	//if( !registerWriteReadback(board_id, TRIG_WIDTH_FEEDBACK_ENA, 0xFFFF, regValReadback) )
	//	std::cout << "Failed to set TRIG_WIDTH_FEEDBACK_ENA " << std::endl;
	
	//Set SCROD_ASIC synchronization specific signals

	//Select phase of WR_ADDR relative to PHAB - bits 11-9 - using phase 001
	unsigned int writePhase = 0x0000;
	if( !registerWriteReadback(board_id, TIMING_REG, writePhase | 0x0015, regValReadback) )
		std::cout << "Failed to set TIMING_REG " << std::endl;

	//Ensure PHAB is being output, turn off monitor header
	if( !registerWriteReadback(board_id, TIMING_SELECT, 0x0, regValReadback) )
		std::cout << "Failed to set TIMING_SELECT " << std::endl;

	//synchronize write address phase - must come last, PHAB must be coming out of ASICs
	registerWriteReadback(board_id, TIMING_REG, writePhase | 0x0095, regValReadback); //clear phase
	registerWriteReadback(board_id, TIMING_REG, writePhase | 0x0015, regValReadback);
	registerWriteReadback(board_id, TIMING_REG, writePhase | 0x0115, regValReadback); //sync the sampling block
	registerWriteReadback(board_id, TIMING_REG, writePhase | 0x0015, regValReadback);

	return 1;
}

//initialize the USB interface
int irs3BControlClass::initializeUSBInterface(){
	//setup USB starts here
        setup_usb();
	clearDataBuffer();
	return 1;
}

//initialize the USB interface
int irs3BControlClass::closeUSBInterface(){
	//close USB starts here
        close_usb();

	return 1;
}

//Clear the input buffer
int irs3BControlClass::clearDataBuffer(){
	int size = 0;
        unsigned int inbuf[usbbuf_size];
	unsigned char *p_inbuf = (unsigned char*) &inbuf[0];
        usb_ClearEndpnt((IN_ADDR | LIBUSB_ENDPOINT_IN), p_inbuf, usbbuf_size, TM_OUT);
	usb_ClearEndpnt((IN_ADDR | LIBUSB_ENDPOINT_IN), p_inbuf, usbbuf_size, TM_OUT);

	return 1;
}

//do simple register read
int irs3BControlClass::registerRead(unsigned int board_id, unsigned int reg, int &regValReadback) {
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
int irs3BControlClass::registerWrite(unsigned int board_id, unsigned int reg, unsigned int regVal, int &regValReadback) {
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
int irs3BControlClass::registerWriteReadback(unsigned int board_id, unsigned int reg, unsigned int regVal, int &regValReadback) {
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
int irs3BControlClass::readPacketFromUSBFifo( unsigned int databuf[], int bufSize, int &dataSize ){
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

		//optionally pause to ensure all data is acquired 		
		//usleep(500);
	}
	if( count >= bufSize ){
		std::cout << "USB packet read larger than data buffer, data is missing " << std::endl;
		return 0;
	}
	dataSize = count;

	//Debugging - print out each response packet in it's entirety
	//if(debugglobal){
	if(0){
		std::cout << "RESPONSE PACKET " << std::endl;
		for(int j=0;j<dataSize; j++)
			std::cout << "\t" << std::hex << databuf[j] << std::endl;
		std::cout << "END RESPONSE PACKET " << std::endl;
		std::cout << std::endl;
	}

	return 1;
}

//parse the SCROD read/write register command response packet
int irs3BControlClass::parseResponsePacketFromUSBforReadWrite( int reg, int command_id, unsigned int databuf[], int dataSize, int &regVal ){
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

int irs3BControlClass::writeEventToFile(unsigned int eventdatabuf[], int eventdataSize, std::ofstream& dataFile){
        if( !dataFile.is_open() ){
                std::cout << "File is not open for writing event" << std::endl;
                return 0;
        }

        dataFile.write(reinterpret_cast<char*>(&eventdatabuf), eventdataSize*sizeof(unsigned int));

        return 1;
}

//simple function to send a word over I2C bus
int irs3BControlClass::i2c_write(unsigned int board_id, unsigned int regw, unsigned int regr, unsigned int addr, unsigned int cmd, int data){
	//define I2C commands to be sent over bus
	unsigned int SEND_I2C[8] = 
		   {0x0100,           // start
	            0x0000 | addr,    // setup send
	            0x0200 | addr,    // send addr + write
	            0x0000 | cmd,     // setup send
	            0x0200 | cmd,     // send command
	            0x0000 | data,    // setup send
	            0x0200 | data,    // send data
	            0x1000};          // stop
	//send write command over I2C bus as set of register writes
	int regValReadback = 0;
	for( int i = 0 ; i < 8 ; i++ ){
		//try writing register, return if write fails
		if(!registerWriteReadback(board_id, regw, SEND_I2C[i], regValReadback))
			return 0;
		usleep(50000); //5ms pause as I2C bus is slow
		//check for ack
		if(!registerRead(board_id, regr, regValReadback))
			return 0;
		//if( ( regValReadback & 0x8000 ) >> 15 ) 
		//	std::cout << "ACKNOWLEDGED " << std::endl;
	}

	return 1;
}

//simple function to read a word over I2C bus
int irs3BControlClass::i2c_read(unsigned int board_id, unsigned int regw, unsigned int regr, unsigned int addr, int &regValOut){
	regValOut = 0;
	 unsigned int cmd = 0x00;
	//define I2C commands to be sent over bus
	unsigned int SEND_I2C[11] = 
		   {0x0100,           // start
	            0x0000 | addr,    // setup send
	            0x0200 | addr,    // send addr + write
	            0x0000 | cmd,     // setup send
	            0x0200 | cmd,     // send register addr
	            0x0100,           // repeat start
	            0x0000 | addr|1,  // setup send
	            0x0200 | addr|1,  // send addr + read
	            0x0000,           // read w/o ack
	            0x0400,           // read w/o ack
	            0x1000};          // stop
	//send read command over I2C bus as set of register writes
	int regValReadback = 0;
	for( int i = 0 ; i < 11 ; i++ ){
		//try writing register, return if write fails
		if(!registerWriteReadback(board_id, regw, SEND_I2C[i], regValReadback))
			return 0;
		usleep(50000); //5ms pause as I2C bus is slow
		//check for ack
		if(!registerRead(board_id, regr, regValReadback))
			return 0;
		//if( ( regValReadback & 0x8000 ) >> 15 ) 
		//	std::cout << "ACKNOWLEDGED " << std::endl;
	}

	//return read out value - only lower 8 bits have info
	regValOut = (regValReadback & 0xFF);
	return 1;
}

//read temperatures from board stack using I2C interface
int irs3BControlClass::readTemperatures(unsigned int board_id){

	int regValOut = 0;
	std::cout << "Reading temperatures on board stack " << std::hex << board_id << std::dec << std::endl;

	//Read SCROD temp
	if( !i2c_read(board_id, I2C_BUS_0_WR, I2C_BUS_0_RD, 0x94, regValOut) ){
		std::cout << "I2C read failed " << std::endl;
		return 0;
	}
	std::cout << "SCROD TEMP " <<  regValOut << std::endl;

	unsigned int carrier_i2c_addresses[8] = {0x90, 0x92, 0x70, 0x72, 0x94, 0x96, 0x74, 0x76};

	//do carrier 0-1
	for(int i = 0 ; i < 8 ; i++ ){
		if( !i2c_read(board_id, I2C_BUS_3_WR, I2C_BUS_3_RD, carrier_i2c_addresses[i], regValOut) ){
			std::cout << "I2C read failed " << std::endl;
			return 0;
		}
		std::cout << "ASIC row " << i/4 << "\t col " << i%4;
		std::cout << "\tTemp " << regValOut << std::endl;
	}

	//do carrier 2-3
	for(int i = 0 ; i < 8 ; i++ ){
		if( !i2c_read(board_id, I2C_BUS_4_WR, I2C_BUS_4_RD, carrier_i2c_addresses[i], regValOut) ){
			std::cout << "I2C read failed " << std::endl;
			return 0;
		}
		std::cout << "ASIC row " << 2+i/4 << "\t col " << i%4;
		std::cout << "\tTemp " << regValOut << std::endl;
	}
		
	return 1;
}

//read temperatures from board stack using I2C interface
int irs3BControlClass::readTemperature(unsigned int board_id, int row, int col, int &temperature){

	temperature = -1;
	if( row < 0 || row > 3 || col < 0 || col > 3 ){
		std::cout << "Incorrect row or col requested" << std::endl;
		return 0;
	}

	int regValOut = 0;
	std::cout << "Reading temperature on board stack " << std::hex << board_id << std::dec << "\trow " << row << "\tcol " << col << std::endl;

	unsigned int carrier_i2c_addresses[8] = {0x90, 0x92, 0x70, 0x72, 0x94, 0x96, 0x74, 0x76};

	//do carrier 0-1
	if( row < 2 ){
		int index = row*4 + col;
		if( index < 0 || index > 7 )
			return 0;
		if( !i2c_read(board_id, I2C_BUS_3_WR, I2C_BUS_3_RD, carrier_i2c_addresses[index], regValOut) ){
			std::cout << "I2C read failed " << std::endl;
			return 0;
		}
		temperature = regValOut;
	}
	//do carrier 2-3
	else{
		int index = (row-2)*4 + col;
		if( index < 0 || index > 7 )
			return 0;
		if( !i2c_read(board_id, I2C_BUS_4_WR, I2C_BUS_4_RD, carrier_i2c_addresses[index], regValOut) ){
			std::cout << "I2C read failed " << std::endl;
			return 0;
		}
		temperature = regValOut;
	}

	return 1;
}

//set GPIOs appropriate for IRS3Bs on carriers Rev C
int irs3BControlClass::setupGPIOs_irs3B_carrierRevC(unsigned int board_id){
	//setup GPIOs
	//Carrier 02/13 rev C:
	//GPIO0 : readback sample, channel and window shift registers
	//GPIO1 : readback generic shift register, also control ASIC shutdown
	//GPIO2 : control calibration signal, amp_disable

	//i2c_write(Board ID, write register, read register, address, command, data)
	//command 01 = set port binary value, command 03 = set port direction

	std::cout << "Setting all carrier GPIO0 as inputs" << std::endl;
	if( !i2c_write(board_id, I2C_BUS_5_WR, I2C_BUS_5_RD, ROW02_GPIO0_ADDR, 0x03, 0xFF) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_5_WR, I2C_BUS_5_RD, ROW13_GPIO0_ADDR, 0x03, 0xFF) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_6_WR, I2C_BUS_6_RD, ROW02_GPIO0_ADDR, 0x03, 0xFF) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_6_WR, I2C_BUS_6_RD, ROW13_GPIO0_ADDR, 0x03, 0xFF) ) return 0;

	std::cout << "Setting carrier GPIO1 ports 0-3 as inputs, 4-7 as outputs" << std::endl;
	if( !i2c_write(board_id, I2C_BUS_5_WR, I2C_BUS_5_RD, ROW02_GPIO1_ADDR, 0x03, 0x0F) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_5_WR, I2C_BUS_5_RD, ROW13_GPIO1_ADDR, 0x03, 0x0F) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_6_WR, I2C_BUS_6_RD, ROW02_GPIO1_ADDR, 0x03, 0x0F) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_6_WR, I2C_BUS_6_RD, ROW13_GPIO1_ADDR, 0x03, 0x0F) ) return 0;

	std::cout << "Setting SHUTDOWN_ASIC_BAR signals high (turns ASICS on)" << std::endl;
	if( !i2c_write(board_id, I2C_BUS_5_WR, I2C_BUS_5_RD, ROW02_GPIO1_ADDR, 0x01, 0xF0) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_5_WR, I2C_BUS_5_RD, ROW13_GPIO1_ADDR, 0x01, 0xF0) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_6_WR, I2C_BUS_6_RD, ROW02_GPIO1_ADDR, 0x01, 0xF0) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_6_WR, I2C_BUS_6_RD, ROW13_GPIO1_ADDR, 0x01, 0xF0) ) return 0;

	std::cout << "Setting all carrier GPIO2 as outputs" << std::endl;
	if( !i2c_write(board_id, I2C_BUS_3_WR, I2C_BUS_3_RD, ROW02_GPIO2_ADDR, 0x03, 0x00) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_3_WR, I2C_BUS_3_RD, ROW13_GPIO2_ADDR, 0x03, 0x00) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_4_WR, I2C_BUS_4_RD, ROW02_GPIO2_ADDR, 0x03, 0x00) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_4_WR, I2C_BUS_4_RD, ROW13_GPIO2_ADDR, 0x03, 0x00) ) return 0;

	std::cout << "Setting SAMPSEL_ANY high on GPIO2 (everything else low)" << std::endl;
	if( !i2c_write(board_id, I2C_BUS_3_WR, I2C_BUS_3_RD, ROW02_GPIO2_ADDR, 0x01, 0x40) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_3_WR, I2C_BUS_3_RD, ROW13_GPIO2_ADDR, 0x01, 0x40) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_4_WR, I2C_BUS_4_RD, ROW02_GPIO2_ADDR, 0x01, 0x40) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_4_WR, I2C_BUS_4_RD, ROW13_GPIO2_ADDR, 0x01, 0x40) ) return 0;

	std::cout << "Setting interconnect GPIO0 as outputs" << std::endl;
	if( !i2c_write(board_id, I2C_BUS_7_WR, I2C_BUS_7_RD, interconnect_revC_GPIO0_ADDR, 0x01, 0x00) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_7_WR, I2C_BUS_7_RD, interconnect_revC_GPIO0_ADDR, 0x03, 0x00) ) return 0;

	std::cout << "Setting interconnect GPIO1 as outputs" << std::endl;
	if( !i2c_write(board_id, I2C_BUS_7_WR, I2C_BUS_7_RD, interconnect_revC_GPIO1_ADDR, 0x01, 0x3c) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_7_WR, I2C_BUS_7_RD, interconnect_revC_GPIO1_ADDR, 0x03, 0x00) ) return 0;
	//i2c_write(board_id, I2C_BUS_7_WR, I2C_BUS_7_RD, interconnect_revC_GPIO1_ADDR, 0x03, 0x04);

	return 1;
}

//function handles routing of calibration signal on boardstack - copied directly from python code with c++ modifications
int irs3BControlClass::selectCalibrationDestination(unsigned int board_id, unsigned int row_in, unsigned int column_in, unsigned int channel_in, bool enable){

	//setup row/column/channel variables
	unsigned int row     = int(row_in)     & 0x3 ;//# mask off any shenanigans
	unsigned int column  = int(column_in)  & 0x3 ;//# mask off any shenanigans
	unsigned int channel = int(channel_in) & 0x7 ;// # mask off any shenanigans

	column = column ^ 0x3; //# COL bits need to be inverted (see carrier02/13 schematic)

	//# Bit 7 = Amp disable, 6 = SAMPSEL_ANY, 5-4 = CAL_COL, 3 = CAL_EN, 2-0 = CAL_CH
	unsigned int base_value = 0;
	base_value |= 0 << 7; //# AMP disable = 0 (ignored with OPA846 anyway...)
	base_value |= 1 << 6; //# SAMPSEL_ANY = 1

	unsigned int value = base_value;
	value |= 1 << 3; //# CAL_EN = 1 # this enables the '138 outputs that drive the MUX selects
	value |= column << 4;
	value |= channel << 0;
	unsigned int value_for_carrier0 = base_value;
	unsigned int value_for_carrier1 = base_value;
	unsigned int value_for_carrier2 = base_value;
	unsigned int value_for_carrier3 = base_value;
	if(enable){
		std::cout << "steering cal signal " << std::endl;
		if(row == 0){
			value_for_carrier0 = value;
		}
		else if (row == 1){
			value_for_carrier1 = value;
		}
		else if (row == 2){
			value_for_carrier2 = value;
		}
		else if (row == 3){
			value_for_carrier3 = value;
		}
	}
	else
		std::cout << "disabling cal signal" << std::endl;

	//# tell the interconnect to turn off both sources here
	//std::cout << "GPIO value for output register on GPIO2 on carrier3: " << value_for_carrier3 << std::endl;
	//std::cout << "GPIO value for output register on GPIO2 on carrier2: " << value_for_carrier2 << std::endl;
	//std::cout << "GPIO value for output register on GPIO2 on carrier1: " << value_for_carrier1 << std::endl;
	//std::cout << "GPIO value for output register on GPIO2 on carrier0: " << value_for_carrier0 << std::endl;
	if( !i2c_write(board_id, I2C_BUS_3_WR, I2C_BUS_3_RD, ROW02_GPIO2_ADDR, 0x01, value_for_carrier0) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_3_WR, I2C_BUS_3_RD, ROW13_GPIO2_ADDR, 0x01, value_for_carrier1) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_4_WR, I2C_BUS_4_RD, ROW02_GPIO2_ADDR, 0x01, value_for_carrier2) ) return 0;
	if( !i2c_write(board_id, I2C_BUS_4_WR, I2C_BUS_4_RD, ROW13_GPIO2_ADDR, 0x01, value_for_carrier3) ) return 0;

	return 1;
}

int irs3BControlClass::setForcedReadoutRegister(int board_id, int rowNum, int colNum, int chNum ){

	int ForcedReadoutReg = -1;
	int ForcedReadoutVal = -1;
	int regValReadback = 0;
	
	//reset forced readout registers (171-178) ignore readout registers (179-186)
	for( int i = 171 ; i <= 186 ; i++ )
		registerWrite(board_id, i, 0, regValReadback);

	if( colNum == 0 && ( rowNum == 0 || rowNum == 1) )
		ForcedReadoutReg = 171;
	if( colNum == 0 && ( rowNum == 2 || rowNum == 3) )
		ForcedReadoutReg = 172;	
	if( colNum == 1 && ( rowNum == 0 || rowNum == 1) )
		ForcedReadoutReg = 173;
	if( colNum == 1 && ( rowNum == 2 || rowNum == 3) )
		ForcedReadoutReg = 174;	
	if( colNum == 2 && ( rowNum == 0 || rowNum == 1) )
		ForcedReadoutReg = 175;
	if( colNum == 2 && ( rowNum == 2 || rowNum == 3) )
		ForcedReadoutReg = 176;	
	if( colNum == 3 && ( rowNum == 0 || rowNum == 1) )
		ForcedReadoutReg = 177;
	if( colNum == 3 && ( rowNum == 2 || rowNum == 3) )
		ForcedReadoutReg = 178;	
	int shiftBits = chNum + (rowNum % 2)*8;
	ForcedReadoutVal = (0x1 << shiftBits);

	if( ForcedReadoutReg < 0 || ForcedReadoutVal < 0 )
		return 0;

	registerWrite(board_id, ForcedReadoutReg, ForcedReadoutVal, regValReadback);
	return 1;
}

