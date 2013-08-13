#ifndef STURM2DATA_H
#define STURM2DATA_H

//ROOT includes
#include <TROOT.h>
#include <TTree.h>
#include <TFile.h>
#include <TH1.h>
#include <TH2.h>
#include <TF1.h>
#include <TCanvas.h>
#include <TVirtualPad.h>
#include <TStyle.h>
#include <TSpline.h>
#include <math.h>
#include "Riostream.h"
#include <RQ_OBJECT.h>
//user includes
#include <iostream>
#include <fstream>
#include "Defs.h"
#include <sys/stat.h>

class STURM2Data{
  RQ_OBJECT("STURM2Data")
 private:
  int nEntries;
  TFile *f;  
  TTree *T;
  TH2D* GenVCAL_PLOT_2D;
  TH2D* GenVCAL_PLOT_2D_extracted;
  TCanvas* c0;
  double fVLUT[NUM_CHANNELS][NUM_SMPL][NUM_DAC];
  double fPED[NUM_CHANNELS][NUM_SMPL];
  int fRaw[NUM_CHANNELS][NUM_SMPL];
  int Raw[NUM_CHANNELS][NUM_SMPL];
  double fWaveform[NUM_CHANNELS][NUM_SMPL];
  double Waveform[NUM_CHANNELS][NUM_SMPL];
  int fPRCO_INT;
  int fPROVDD;
  int fRCO_INT;
  int fROVDD;
  int fPED_SCAN;
  int fDEBUG;
  int PRCO_INT;
  int PROVDD;
  int RCO_INT;
  int ROVDD;
  int PED_SCAN;
  int DEBUG;
  void GenVCAL_spline(int CH,int SMPL,int* xDAT,double* spline_data);
  void GenVCAL_PLOT(int CH,int SMPL,int* xDAT,double* spline_data);  
 
 public:
  STURM2Data();
  ~STURM2Data();  
  void unpackData(int fReadoutBuffer[BUFFERSIZE]);
  void LoadPED();
  void GenPED();
  void LoadVCAL();
  void GenVCAL();
  void open_TFile(TString filename);
  void close_TFile();
  //extracted values 
  int Get_Raw(int ch, int smpl){return fRaw[ch][smpl];};
  double Get_fWaveform(int ch, int smpl){return fWaveform[ch][smpl];};
  int Get_PRCO_INT(){return fPRCO_INT;};
  int Get_PROVDD(){return fPROVDD;};
  int Get_RCO_INT(){return fRCO_INT;};
  int Get_ROVDD(){return fROVDD;};
  int Get_PED_SCAN(){return fPED_SCAN;};
  int Get_DEBUG(){return fDEBUG;};
};

#endif // STURM2Data_H
