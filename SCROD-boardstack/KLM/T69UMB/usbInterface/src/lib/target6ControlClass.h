#ifndef IRS3BCONTROLCLASS__H
#define IRS3BCONTROLCLASS__H

#define IN_ADDR (0x86)          //Endpoint 6 (FPGA2USB Endpoint)
#define OUT_ADDR (0x02)         //Endpoint 2 (USB2FPGA Endpoint)
#define usbbuf_size (512)

class target6ControlClass {
private:

public:
  //target6ControlClass();
  //~target6ControlClass();

  int initializeUSBInterface();
  int closeUSBInterface();
  int clearDataBuffer();
  int registerRead(unsigned int board_id, unsigned int reg, int &regValReadback);
  int registerWrite(unsigned int board_id, unsigned int reg, unsigned int regVal, int &regValReadback);
  int registerWriteReadback(unsigned int board_id, unsigned int reg, unsigned int regVal, int &regValReadback);
  int readPacketFromUSBFifo( unsigned int databuf[], int bufSize, int &dataSize );
  int parseResponsePacketFromUSBforReadWrite( int reg, int command_id, unsigned int databuf[], int dataSize, int &regVal );
};

#endif
