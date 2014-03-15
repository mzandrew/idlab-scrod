#ifndef __LIB_IRS3BANA__
#define __LIB_IRS3BANA__

#include <iostream>
#include <vector>
#include <fstream>
#include <stdlib.h>
#include <math.h>

#include "TGraph.h"
#include "TFile.h"
#include "TTree.h"
#include "TCanvas.h"
#include "TApplication.h"
#include "TROOT.h"
#include "TH1.h"
#include "TH2.h"
#include "TF1.h"
#include "TProfile.h"

#define LED_DEFAULT_THRESHOLD 150
#define FIT_REGION_LEFT 10
#define FIT_REGION_RIGHT 5
#define CFD_RATIO 0.5
#define SMOOTHING_FACTOR 5
#define SCALE_FACTOR_IRS3B_VS_CAMACTDC 0.122981

#define MAX_SEGMENTS_PER_EVENT 512
#define POINTS_PER_WAVEFORM    64
#define MEMORY_DEPTH           64
#define NCOLS                  4
#define NROWS                  4
#define NCHS                   8
#define NWORDS_EVENT_HEADER    11
#define NWORDS_WAVE_PACKET     42
#define NELECTRONICSMODULES    4
#define ADConversionFactor 1
#define THRESHOLD_FOR_COINCIDENCE 4000 //ps

const int NWindowsPerROI = 4;
const int NSamples = POINTS_PER_WAVEFORM * NWindowsPerROI;
const int Scrod[NELECTRONICSMODULES] = {37,32,35,36};
const int NTotalCh = NELECTRONICSMODULES * NROWS * NCOLS * NCHS;

class IRS3Bana {
private:
  TF1 *f1;

public:

  TGraph *g;
  IRS3Bana();
  ~IRS3Bana();

  bool MakeWaveform(float PSsamples[]); //set first
  bool AlignWaveform(short int firstWindow,short int refWindow,short int camacTDC, int iModule,int iRow,int iCol);

  void plotGraph(TGraph *grIn,TCanvas *c0);
  void plotRoi(TCanvas *c0, int mod, int row, int col, int ch);
  void SearchPeakSampleNumber(int &MaxSampleNum, double &MaxSampleValue);
  int FindThresholdSampleAndTime(int start_sample, double target_value, double &threshold_sample, double &threshold_time);
  int FindThresholdSampleAndTimeFalling(int start_sample, double target_value, double &threshold_sample, double &threshold_time);
  double GetTruncatedMean(int sample);
};

#endif
