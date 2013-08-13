#ifndef STURM2_H
#define STURM2_H

//ROOT includes
#include <TTree.h>
#include <TFile.h>
#include <TString.h>
#include <TRootHelpDialog.h>
#include <TRandom.h>
#include <TMath.h>
#include <TGTextView.h>
#include <TGTextEntry.h>
#include <TGFrame.h>
#include <TGStatusBar.h>
#include "Riostream.h"
#include <RQ_OBJECT.h>
//user includes
#include <iostream>
#include <fstream>
#include "Defs.h"
#include "IDL_USB.h"
#include "STURM2Data.h"

class STURM2_EVAL{
  RQ_OBJECT("STURM2_EVAL")
 private:
  IDL_USB *xIDL_USB;
  TString BoolToTString(bool value);
  bool retVal;
  void ShowErrorMessage(const char* ErrorText);
  bool fVerbose;
  bool fOffLineMode;
  TGTextEntry *fCMDline;
  TGMainFrame *fMain;
  TGStatusBar *fStatusBar;
  TFile *hfile;  
  TTree *tree;
  void GEN_DUMMY_Waveform();
  void Start_TFile(TString filename);
  void End_TFile();
  int fRaw[NUM_CHANNELS][NUM_SMPL]; 
  int fReadoutBuffer[BUFFERSIZE];
  double fWaveform[NUM_CHANNELS][NUM_SMPL]; 
  int fPRCO_INT;
  int fPROVDD;
  int fRCO_INT;
  int fROVDD;
  int fPED_SCAN;
  int fDEBUG;
  STURM2Data *xSTURM2Data;
 public:  
  STURM2_EVAL(bool Verbose, bool OffLineMode,TGTextEntry *CMDline,TGStatusBar *StatusBar);
  virtual ~STURM2_EVAL();
  //////////////////////////////////////
  void SendCMDline(); 
  void SendSyncUSB(bool ENABLE);
  void SendSoftTrig();
  void SendPEDSCAN(unsigned int DAC);
  void SendEN_PED(bool ENABLE);
  void SendVCAL(bool ENABLE);
  void SendDEBUG(unsigned int value);
  int  ReadUSB(bool dumpHex, bool display_data);
  double Get_Waveform(int ch, int smpl){return fWaveform[ch][smpl];};
 //////////////////////////////////////  
  void GenPED();
  void LoadPED();
  void LoadVCAL();
  void GenVCAL();
  void LOG_DATA();
  //////////////////////////////////////    
};
#endif //STURM2_EVAL_H

