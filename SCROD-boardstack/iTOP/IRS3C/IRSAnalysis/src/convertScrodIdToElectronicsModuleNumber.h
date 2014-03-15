//This script will convert from ScrodId To Electronics Module Number
//Ideally this should be done via a configuration file, and conversion routines
//that do not include hard coded numbers.  This hard coded file is intended as
//a temporary measure.

#ifndef CONVERTSCRODIDTOELECTRONICSMODULENUMBER_H
#define CONVERTSCRODIDTOELECTRONICSMODULENUMBER_H

#include "TObject.h"

inline Int_t convertScrodIdToElectronicsModuleNumber(Int_t scrodId) {
  //std::cout << std::hex << scrodId << std::dec << std::endl;
  //if (32 == scrodId%256) {return 1;}
  return 0;
  //return -1;
}

inline Int_t convertElectronicsModuleNumberToScrodId(Int_t electronicsModuleNumber) {
  //if (0==electronicsModuleNumber) {return 37;}
  return 0;
  //return -1;
}

#endif



