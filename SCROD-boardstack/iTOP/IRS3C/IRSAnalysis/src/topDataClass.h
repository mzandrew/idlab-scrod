#ifndef TOPDATACLASS__H
#define TOPDATACLASS__H

#include "TROOT.h"
#include <TFile.h>
#include "TTree.h"
#include "TH2.h"

//define global constants
#define NMODS    4
#define NROWS    4
#define NCOLS    4
#define NCHS	 8
const Int_t MaxROI(400);
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
	int mark_smp_Fix100_A[maxNumEvt];
	double mark_smpPrevY_Fix100_A[maxNumEvt];
	double mark_smpNextY_Fix100_A[maxNumEvt];

	//Calibration variables
	//basic constants
	double smp128StartTimes[128];
	double FTSW_SCALE; //ns per FTSW DAC
	double avg128Period; //ns
	double defaultSmpWidth;
	double sampleWidthScaleFactor;
	double cfdFraction;

	//analysis constansts
	double windowTime;

	//Functions ------------------------------------------------
	topDataClass();
  	~topDataClass();

	int setAnalysisChannel(int mod, int row, int col, int ch);
	int setTimingMarkerChannel(int mod, int row, int col, int ch);	
	int openSummaryTree(TString inputFileName);
	int setTreeBranches();
	int selectPulsesForArray();

	double measurePulseTimeTreeEntry(int hitIndex , bool useFTSWTDCCorr);
	double measurePulseTimeArrayEntry(int entry, bool useFTSWTDCCorr);
	double measurePulseTimeStandalone(int infirst, int inref, int insmp, int inftsw, double inFTSW_SCALE, double inavg128Period, double insmp128StartTimes[], double insmpPrevY, double insmpNextY, double intarget);

	int getSmp128Bin(int firstWindow, int smpNum);
	int getSmp256Bin(int firstWindow, int smpNum);
	double getSmpPos(double smpNextY, double smpPrevY, double adc0);
	double getSmpFallPos(double smpNextY, double smpPrevY, double adc0);
	double getSmpFixThreshPos(double smpNextY, double smpPrevY, double thresh);

	int getTimingMarkerNHitNum(int entry, int &markerHitNum);
	double measureMarkerTimeArrayEntry(int entry, bool useFTSWTDCCorr);

	int makeCorrectionGraph(TH2F *h2dIn, TGraphErrors *gOut, bool meanOrRms, double minEntries, double range, double maxErr);
};

#endif
