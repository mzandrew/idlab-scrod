/////////////////////////////////////////////////
//  Set of functions to convert electronics 
//  channel numbers to Belle-II channel numbers
/////////////////////////////////////////////////

#ifndef CRTCHANNELCONVERSION_HH
#define CRTCHANNELCONVERSION_HH


#include <utility>
#include "TObject.h"


//  BelleII numbering scheme: 32PMTs
//
//   +-------------~~~~~~~---------+
//   |17 18 19 20          30 31 32|
//   |1  2  3  4           5  6  7 |
//   +-------------~~~~~~~---------+
//  each with 16 Pads:
//   +-----------+
//   |13 14 15 16|
//   |9  10 11 12|
//   |5  6  7  8 |
//   |1  2  3  4 |
//   +-----------+
//
//  CRT channel numbering scheme available here:
//  https://belle2.cc.kek.jp/~twiki/bin/view/Detector/TOP/ElectronicsChannelMapping
//
//  Note: Both of these numbering schemes are looking from the mirror towards the PMTs 
//  (i.e. from +z to -z)
//
//  Note: Both of these numbering schemes are rotated by 180 degrees to their physical
//  positions in the CRT, this does not affect the mapping between the two.
//
//  Note: integer division is used implicitly in these functions, 
//  they would need to be modified to work with floating point parameters/division.


//The pararmeters used in the following functions are:
// EPMTcol        Electronics PMT column number
// EPMTrow        Electronics PMT row number
// EPMTch         Electronics PMT channel number
// Emod           Electronics module (column) number
// ASICcol        ASIC column number
// ASICrow        ASIC row number
// ASICch         ASIC channel number
// BIIpmt         Belle-II PMT number
// BIIch          Belle-II PMT channel number




// Functions to obtain numbers of the electronics numbering scheme from the BelleII numbering scheme:
// These all take the same two arguements (BIIpmt and BIIch) though often only one is used.

inline UInt_t BII_2_EPMTrow(UInt_t BIIpmt, UInt_t BIIch) {
  return (BIIpmt-1)/16;
}

inline UInt_t BII_2_ASICrow(UInt_t BIIpmt, UInt_t BIIch) {
  return 2*((BIIpmt-1)/16) + (BIIch-1)/8;
}

inline UInt_t BII_2_EPMTcol(UInt_t BIIpmt, UInt_t BIIch) {
  return 15-(BIIpmt-1)%16;
}

inline UInt_t BII_2_ASICcol(UInt_t BIIpmt, UInt_t BIIch) {
  return 3-(BIIpmt-1)%4;
}

inline UInt_t BII_2_EPMTch(UInt_t BIIpmt, UInt_t BIIch) {
  return 4*((BIIch-1)%4) + 3 - (BIIch-1)/4;
}

inline UInt_t BII_2_ASICch(UInt_t BIIpmt, UInt_t BIIch) {
  return 2*((BIIch-1)%4) + ((BIIch-1)%8)/4;
}

inline UInt_t BII_2_Emod(UInt_t BIIpmt, UInt_t BIIch) {
  return 3 - (BIIpmt-1)%16 / 4;
}


//functions to obtain values according to the Belle II numbering scheme from the electronics numbering scheme:

inline UInt_t EPMT_2_BIIpmt(UInt_t EPMTrow, UInt_t EPMTcol) {
  return 16*EPMTrow - EPMTcol + 16;
}

inline UInt_t EPMTch_2_BIIch(UInt_t EPMTch) {
  return 13 - (EPMTch%4)*4 + EPMTch/4;
} 



inline std::pair<UInt_t, UInt_t> EPMT_2_BII(UInt_t EPMTrow, UInt_t EPMTcol, UInt_t EPMTch) {
  return std::pair<UInt_t, UInt_t>(EPMT_2_BIIpmt(EPMTrow, EPMTcol), EPMTch_2_BIIch(EPMTch));
}


inline UInt_t ASIC_2_BIIpmt(UInt_t Emod, UInt_t ASICrow, UInt_t ASICcol) {
  return 16 - 4*Emod - ASICcol + 16*(ASICrow/2);
}

inline UInt_t ASICch_2_BIIch(UInt_t ASICrow, UInt_t ASICch) {
  return 8*(ASICrow%2) + 4*(ASICch%2) + (ASICch/2) + 1;
}

inline std::pair<UInt_t, UInt_t> ASIC_2_BII(UInt_t Emod, UInt_t ASICrow, UInt_t ASICcol, UInt_t ASICch) {
  return std::pair<UInt_t, UInt_t>(ASIC_2_BIIpmt(Emod, ASICrow, ASICcol), ASICch_2_BIIch(ASICrow, ASICch));
} 




// Test validity of parameters (UInt_t >=0 is included incase type is changed to signed):

inline bool EPMTcol_isValid(UInt_t EPMTcol) {
  if (EPMTcol >= 0 && EPMTcol <= 15) {return true;}
  return false;
}

inline bool EPMTrow_isValid(UInt_t EPMTrow) {
  if (EPMTrow >= 0 && EPMTrow <= 1) {return true;}
  return false;
}

inline bool EPMTch_isValid(UInt_t EPMTch) {
  if (EPMTch >= 0 && EPMTch <= 15) {return true;}
  return false;
}

inline bool Emod_isValid(UInt_t Emod) {
  if (Emod >= 0 && Emod <= 3) {return true;}
  return false;
}

inline bool ASICcol_isValid(UInt_t ASICcol) {
  if (ASICcol >= 0 && ASICcol <= 3) {return true;}
  return false;
}

inline bool ASICrow_isValid(UInt_t ASICrow) {
  if (ASICrow >= 0 && ASICrow <= 3) {return true;}
  return false;
}

inline bool ASICch_isValid(UInt_t ASICch) {
  if (ASICch >= 0 && ASICch <= 7) {return true;}
  return false;
}

inline bool BIIpmt_isValid(UInt_t BIIpmt) {
  if (BIIpmt >= 1 && BIIpmt <= 32) {return true;}
  return false;
}

inline bool BIIch_isValid(UInt_t BIIch) {
  if (BIIch >= 1 && BIIch <= 16) {return true;}
  return false;
}


#endif
