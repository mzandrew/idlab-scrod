#ifndef TARGET6DATACLASS__H
#define TARGET6DATACLASS__H

#include "TROOT.h"
#include <TFile.h>
#include "TTree.h"

//define global constants
#define POINTS_PER_WAVEFORM    32
#define MEMORY_DEPTH           512
#define NASICS                 10
#define NCHS                   16
const Int_t MaxROI(400);

class target6DataClass {
private:
public:

	//waveform tree variables
	bool isWaveformTree;
	TFile* file;
	TTree *tree;
	Int_t eventNum;
	Int_t nROI;
	UInt_t scrodId[MaxROI];
	Int_t asicNum[MaxROI];
	Int_t asicCh[MaxROI];
	Int_t windowNum[MaxROI];
	Int_t samples[MaxROI][POINTS_PER_WAVEFORM];

	//pedestal tree variables
	bool isPedestalTree;
	TFile* pedestalFile;
	TTree *pedestalTree;
	Float_t pedestal_mean;
  	Float_t pedestal_RMS;

	target6DataClass();
  	~target6DataClass();
	int getWaveformTreeFile(TString inputFileName);
	int getPedestalFile(TString inputFileName);
	int plotWaveformTreeFile(TCanvas *c0);
	int measurePedestals(TCanvas *c0);
};

#endif
