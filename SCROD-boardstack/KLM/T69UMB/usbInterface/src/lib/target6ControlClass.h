#ifndef TARGET6CONTROLCLASS__H
#define TARGET6CONTROLCLASS__H

#define IN_ADDR (0x86)          //Endpoint 6 (FPGA2USB Endpoint)
#define OUT_ADDR (0x02)         //Endpoint 2 (USB2FPGA Endpoint)
#define usbbuf_size (10240)     //roginally 512

class target6ControlClass {
private:

public:
  //target6ControlClass();
  //~target6ControlClass();

  int initializeUSBInterface();
  int closeUSBInterface();
  int clearDataBuffer();
  int usbTest();
  int registerRead(unsigned int board_id, unsigned int reg, int &regValReadback);
  int registerWrite(unsigned int board_id, unsigned int reg, unsigned int regVal, int &regValReadback);
  int registerWriteReadback(unsigned int board_id, unsigned int reg, unsigned int regVal, int &regValReadback);
  int readPacketFromUSBFifo( unsigned int databuf[], int bufSize, int &dataSize );
  int printPacketFromUSBFifo();
  int parseResponsePacketFromUSBforReadWrite( int reg, int command_id, unsigned int databuf[], int dataSize, int &regVal );
  int parseResponsePacketForEvents(unsigned int databuf[], int dataSize, unsigned int wavedatabuf[], int &wavedataSize);
  int getEventData(unsigned int eventdatabuf[], int &eventdataSize);
  int writeEventToFile(unsigned int eventdatabuf[], int eventdataSize, std::ofstream& dataFile);
  int writeDACReg(unsigned int board_id, int dcNum, int regNum, int regVal);
  int resetTriggers(unsigned int board_id);
  int sendTrigger(unsigned int board_id, bool softwareOrHardware);
  int continueReadout(unsigned int board_id);
};

#endif
