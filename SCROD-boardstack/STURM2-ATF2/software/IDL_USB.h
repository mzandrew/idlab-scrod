#ifndef IDL_USB_H
#define IDL_USB_H

//ROOT includes
#include <TString.h>
#include "Riostream.h"
#include <TRootHelpDialog.h>
#include <RQ_OBJECT.h>

//user includes
#include <iostream>
#include <fstream>
#include "Defs.h"

class IDL_USB{
  RQ_OBJECT("IDL_USB")
 private:
  unsigned short fReadoutBuffer[BUFFERSIZE+2];
  bool fOffLineMode;
  bool fVerbose;
  void ShowErrorMessage(TString ErrorText);
  TString BoolToTString(bool value);
 public:  
  IDL_USB (bool OffLineMode,bool Verbose);
  virtual ~IDL_USB();
  //////////////////////////////////////
  void SetOffLineMode(bool flag) {fOffLineMode=flag;};
  bool GetOffLineMode() {return fOffLineMode;};
  //////////////////////////////////////
  void SetVerbose(bool flag) {fVerbose=flag;};
  bool GetVerbose() {return fVerbose;};
  //////////////////////////////////////
  int  GetBuffer(int i) {return (int)fReadoutBuffer[i];}; 
  //////////////////////////////////////
  int  ReadUSBBuffer(bool DumpData);
  bool SendUSBCMD(unsigned int value);
  bool SendCMDline(TString CMDline); 
  //////////////////////////////////////    
};
#endif //IDL_USB_H

