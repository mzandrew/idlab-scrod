#ifndef IRS3BCONTROLCLASS__H
#define IRS3BCONTROLCLASS__H

#define IN_ADDR (0x86)          //Endpoint 6 (FPGA2USB Endpoint)
#define OUT_ADDR (0x02)         //Endpoint 2 (USB2FPGA Endpoint)
#define usbbuf_size (512)

class irs3BControlClass {
private:

public:
  //irs3BControlClass();
  //~irs3BControlClass();

  int initializeUSBInterface();
  int closeUSBInterface();
  int clearDataBuffer();
  int registerRead(unsigned int board_id, unsigned int reg, int &regValReadback);
  int registerWrite(unsigned int board_id, unsigned int reg, unsigned int regVal, int &regValReadback);
  int registerWriteReadback(unsigned int board_id, unsigned int reg, unsigned int regVal, int &regValReadback);
  int readPacketFromUSBFifo( unsigned int databuf[], int bufSize, int &dataSize );
  int parseResponsePacketFromUSBforReadWrite( int reg, int command_id, unsigned int databuf[], int dataSize, int &regVal );
  int parseResponsePacketForWaveforms(unsigned int databuf[], int dataSize,unsigned int wavedatabuf[], int &wavedataSize);
  int i2c_read(unsigned int board_id, unsigned int regw, unsigned int regr, unsigned int addr, int &regValOut);
  int i2c_write(unsigned int board_id, unsigned int regw, unsigned int regr, unsigned int addr, unsigned int cmd, int data);
  int readTemperatures(unsigned int board_id);
  int readTemperature(unsigned int board_id, int row, int col, int &temperature);
  int selectCalibrationDestination(unsigned int board_id, unsigned int row_in, unsigned int column_in, unsigned int channel_in, bool enable);
  int setupGPIOs_irs3B_carrierRevC(unsigned int board_id);
  int initializeAsicDACs_irs3B_carrierRevC(unsigned int board_id);
  int sendSoftwareTrigger(unsigned int board_id);
  int sendHardwareTrigger(unsigned int board_id);
  int getWaveformData(unsigned int wavedatabuf[], int &wavedataSize);
  int writeEventToFile(unsigned int eventdatabuf[], int eventdataSize, std::ofstream& dataFile);
  int setForcedReadoutRegister(int board_id, int rowNum, int colNum, int chNum );

};

#endif
