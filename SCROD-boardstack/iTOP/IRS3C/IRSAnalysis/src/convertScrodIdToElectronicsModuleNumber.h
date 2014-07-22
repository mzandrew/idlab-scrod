//This script will convert from ScrodId To Electronics Module Number
//Ideally this should be done via a configuration file, and conversion routines
//that do not include hard coded numbers.  This hard coded file is intended as
//a temporary measure.

#ifndef CONVERTSCRODIDTOELECTRONICSMODULENUMBER_H
#define CONVERTSCRODIDTOELECTRONICSMODULENUMBER_H

#include "TObject.h"

inline Int_t convertScrodIdToElectronicsModuleNumber(Int_t scrodId) {
  //std::cout << std::hex << scrodId << std::dec << std::endl;
  if (59 == scrodId%256) {return 0;}
  if (66 == scrodId%256) {return 1;}
  if (65 == scrodId%256) {return 2;}
  //if (68 == scrodId%256) {return 3;}
  if (67 == scrodId%256) {return 3;}
  std::cout << "Warning: convertScrodIdToElectronicsModuleNumber could not find SCROD ID " << scrodId%256 << " returning default value of 255" << std::endl;
  return 65;
  //return -1;
}

inline Int_t convertElectronicsModuleNumberToScrodId(Int_t electronicsModuleNumber) {
  if (0==electronicsModuleNumber) {return 59;}
  if (1==electronicsModuleNumber) {return 66;}
  if (2==electronicsModuleNumber) {return 65;}
  //if (3==electronicsModuleNumber) {return 68;}
  if (3==electronicsModuleNumber) {return 67;}
  std::cout << "Warning: convertScrodIdToElectronicsModuleNumber could not find electronicsModuleNumber, returning default value of 0" << std::endl;
  return 0;
  //return -1;
}

#endif



