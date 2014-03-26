#ifndef TOPDATACLASS__H
#define TOPDATACLASS__H

#include "TROOT.h"
#include <TFile.h>
#include "TTree.h"
#include "TH2.h"

//define global constants
#define POINTS_PER_WAVEFORM    64
#define MEMORY_DEPTH           512
#define NASICS                 1
#define NCHS                   8
const Int_t MaxROI(400);
double FTSW_SCALE = 0.045056; //ns per FTSW DAC
double avg128Period = 128./2.715; //ns
double defaultSmpWidth = 1./2.715;
double sampleWidthScaleFactor = 1.0;
double cfdFraction = 0.2;
const int maxNumEvt = 1000000;

class topDataClass {
private:
public:
	//input file object
	bool isInputFile;
	TFile* inputFile;

	//Input Tree object
	bool isTOPTree;
	TTree* tr_top;

	//Input Tree Branches
	//event specific
	Int_t eventNum;
	Short_t ftsw;
	Short_t nhit;
	//ROI specific
	Short_t refWindow[MaxROI];
	Short_t firstWindow[MaxROI];
	Short_t pmtid_mcp[MaxROI];
	Short_t ch_mcp[MaxROI];
	Short_t pmtflag_mcp[MaxROI];
	Float_t adc0_mcp[MaxROI];
	Float_t base_mcp[MaxROI];
	//CFD - rising edge
	Float_t smp0_mcp[MaxROI];
	Float_t tdc0_smpPrevY_mcp[MaxROI];
	Float_t tdc0_smpNextY_mcp[MaxROI];
	//CFD - falling edge
	Float_t smp0Fall_mcp[MaxROI];
	Float_t tdc0Fall_smpPrevY_mcp[MaxROI];
	Float_t tdc0Fall_smpNextY_mcp[MaxROI];
	//Fixed threshold - rising edge
	Float_t smpFix100_mcp[MaxROI];
	Float_t tdcFix100_smpPrevY_mcp[MaxROI];
	Float_t tdcFix100_smpNextY_mcp[MaxROI];
	//Fixed threshold - falling edge
	Float_t smpFix100Fall_mcp[MaxROI];
	Float_t tdcFix100Fall_smpPrevY_mcp[MaxROI];
	Float_t tdcFix100Fall_smpNextY_mcp[MaxROI];

	//channel of interest variables
	int tr_mod;
	int tr_row;
	int tr_col;
	int tr_ch;
	int tr_pmt;
  	int tr_pmtch;

	//timing marker channel variables
	int marker_mod;
	int marker_row;
	int marker_col;
	int marker_ch;
	bool isTimingMarker;

	//channel of interest pulse info storage arrays
	int numUsed;
	int entryNum_A[maxNumEvt];
	int eventNum_A[maxNumEvt];
	int ftsw_A[maxNumEvt];
	double adc_0_A[maxNumEvt];
	int first_0_A[maxNumEvt];
	int ref_0_A[maxNumEvt];
	int smp_0_A[maxNumEvt];
	double smpPrevY_0_A[maxNumEvt];
	double smpNextY_0_A[maxNumEvt];
	int smpFall_0_A[maxNumEvt];
	double smpFallPrevY_0_A[maxNumEvt];
	double smpFallNextY_0_A[maxNumEvt];
	int smp_Fix100_A[maxNumEvt];
	double smpPrevY_Fix100_A[maxNumEvt];
	double smpNextY_Fix100_A[maxNumEvt];
	int smpFall_Fix100_A[maxNumEvt];
	double smpFallPrevY_Fix100_A[maxNumEvt];
	double smpFallNextY_Fix100_A[maxNumEvt];
	double mark_adc_0_A[maxNumEvt];
	int mark_first_0_A[maxNumEvt];
	int mark_ref_0_A[maxNumEvt];
	int mark_smp_0_A[maxNumEvt];
	double mark_smpPrevY_0_A[maxNumEvt];
	double mark_smpNextY_0_A[maxNumEvt];

	//Sample-DT variables
	//basic constants
	double smp128StartTimes[128];

	//analysis constansts
	double windowTime;

	//functions
	topDataClass();
  	~topDataClass();

	int setAnalysisChannel(int mod, int row, int col, int ch);
	int setTimingMarkerChannel(int mod, int row, int col, int ch);
	
	int openSummaryTree(TString inputFileName);
	int setTreeBranches();

	int getOverallDistributions(TH1F *hPulseHeight, TH1F *hPulseTime);

	int selectPulsesForArray();

	double measurePulseTimeArrayEntry(int entry, bool useFTSWTDCCorr);
	double measurePulseTimeStandalone(int infirst, int inref, int insmp, int inftsw, double inFTSW_SCALE, double inavg128Period, double insmp128StartTimes[], double insmpPrevY, double insmpNextY, double intarget);
	int getSmpBinNumIn128Array(int entry);
	double getSmpPos(int entry);

	int getTimingMarkerNHitNum(int entry, int &markerHitNum);
	double measureMarkerTimeArrayEntry(int entry, bool useFTSWTDCCorr);
	int getMarkerSmpBinNumIn128Array(int entry);
	double getMarkerSmpPos(int entry);

	int makeCorrectionGraph(TH2F *h2dIn, TGraphErrors *gOut, bool meanOrRms, double minEntries, double range, double maxErr);

	int measurePulseMarkerTimeDifferenceDistribution(TH1F *hPulseTimeMarkTimeDiff, TH2F *hPulseTimeMarkTimeDiffVsMarkSmpBinNum);
};

#endif
