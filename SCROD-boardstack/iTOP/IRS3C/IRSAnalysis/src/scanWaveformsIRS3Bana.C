#include "TFile.h"
#include "TTree.h"
#include "TH1.h"
#include "TH2.h"
#include "TString.h"
#include "TCanvas.h"
#include <iostream>
#include <TGraphErrors.h>
#include "IRS3Bana.hxx"
#include "IRS3Bana.cxx"
#include "convertScrodIdToElectronicsModuleNumber.h"

using namespace std;

#define MaxROI 1000
TCanvas* c0;

//ROI tr_rawdata variables
TTree* tr_rawdata;
Int_t runNum;
Int_t eventNum;
Int_t nROI;
Short_t refWindow[MaxROI];
UInt_t scrodId[MaxROI];
Short_t eModule[MaxROI];
Short_t asicRow[MaxROI];
Short_t asicCol[MaxROI];
Short_t asicCh[MaxROI];
Int_t ROI[MaxROI];
Short_t firstWindow[MaxROI];
Int_t nWindows[MaxROI];
Int_t nSamples[MaxROI];
Int_t samples[MaxROI][256];
Float_t PSsamples[MaxROI][256];
Float_t sampleErrors[MaxROI][256];
Bool_t truncatedWaveform[MaxROI];
Short_t ftsw;

void waveformAna(IRS3Bana&);

void scanWaveformsIRS3Bana(TString inputFileName) {

  //get file containing ROI-based event tr_rawdata
  TFile* file = new TFile(inputFileName);
  if (file->IsZombie()) {
	std::cout << "Error opening input file" << std::endl;
	return;
  }

  if( !file )
	return;

  //initialize tr_rawdata branches
  tr_rawdata = (TTree*) file->Get("rawData");
  //tr_rawdata = (TTree*) file->Get("newTree");
  if( !tr_rawdata )
	return;

  //initialize canvas
  c0 = new TCanvas("c0", "c0",1300,800);

  tr_rawdata->SetBranchAddress("eventNum", &eventNum);
  tr_rawdata->SetBranchAddress("nROI", &nROI);
  tr_rawdata->SetBranchAddress("scrodId", &scrodId);
  tr_rawdata->SetBranchAddress("refWindow", &refWindow);
  tr_rawdata->SetBranchAddress("eModule", &eModule);
  tr_rawdata->SetBranchAddress("asicRow", &asicRow);
  tr_rawdata->SetBranchAddress("asicCol", &asicCol);
  tr_rawdata->SetBranchAddress("asicCh", &asicCh);
  tr_rawdata->SetBranchAddress("ROI", &ROI);
  tr_rawdata->SetBranchAddress("firstWindow", &firstWindow);
  tr_rawdata->SetBranchAddress("samples", &samples);
  tr_rawdata->SetBranchAddress("PSsamples", &PSsamples);
  tr_rawdata->SetBranchAddress("sampleErrors", &sampleErrors);
  tr_rawdata->SetBranchAddress("truncatedWaveform", &truncatedWaveform);
  tr_rawdata->SetBranchAddress("ftsw",&ftsw);
  //tr_rawdata->SetBranchAddress("camacTDC",&ftsw);

  //create analysis object
  IRS3Bana *_ana = new IRS3Bana();
  //_ana->GetCalibrationConstants("pulser_output/"); //######!!!!!!!######
  //_ana->GetCalibrationConstants("output_measureSampleTimeOffsetsTopSummaryTree_output_topcrt-pulser-allRun536ro539.noSampleDT.summaryTree.root");
  //_ana->GetCalibrationConstants("output_calibration_constants.root");

  //loop over tr_rawdata entries
  Long64_t nEntries(tr_rawdata->GetEntries());
  for(Long64_t entry(0); entry<nEntries; ++entry) {
    tr_rawdata->GetEntry(entry);
    waveformAna(*_ana);
    //char ct;
    //std::cin >> ct;
    //if( ct == 'Q')
    //	break;
  }//entries      

  return;
}

void waveformAna(IRS3Bana& ana){
  //loop over event ROIs
  for (int r=0; r<nROI; r++) {
    
    //if( !( eModule[r] == 2 && asicRow[r] == 1 && asicCol[r] == 0 ) ) continue;
    //if( !( eModule[r] == 0 && asicRow[r] == 0 && asicCol[r] == 1 && asicCh[r] == 2) ) continue;
    //if( ftsw < 920 || ftsw > 950 ) continue;
    //if( eventNum != 5638 ) continue;
    
    //Float_t temp[256];
    //for(int i = 0 ; i < 256 ; i++)
    //	temp[i] = samples[r][i];
    //ana.MakeWaveform(temp);
    //make analysis object
    ana.MakeWaveform(PSsamples[r]);
    //apply CAMAC correction and convert sample timebase to ns
    ana.AlignWaveform(firstWindow[r],refWindow[r],ftsw,eModule[r], asicRow[r], asicCol[r]);
    //ana.DoTimingCalibration(firstWindow[r],eModule[r],asicRow[r], asicCol[r],asicCh[r]);

    //find maximum sample position, apply CFD time estimation method to get pulse time (pulser data only)
    int maxSampleNum;
    double maxSampleValue, pulseTime, pulseHeight, pulseTimeSample;
    ana.SearchPeakSampleNumber(maxSampleNum, maxSampleValue);
    pulseHeight = ana.GetTruncatedMean(maxSampleNum);
    if( !ana.FindThresholdSampleAndTime(maxSampleNum,0.4*pulseHeight, pulseTimeSample, pulseTime) ){
    	  cerr << "Warning: Pulse time not found " << std::endl;
	  //pulseTimeFlag = 1;
    }

    //Variables to use
    //event # : eventNum
    //raw samples (int) : samples[r][256] 
    //pedestal substracted samples (float) : PSsamples[r][256]
    //reference window : refWindow[r]
    //first window # : firstWindow[r]
    //module  # : eModule[r]
    //ASIC row # : asicRow[r]
    //ASIC col # : asicCol[r]
    //ASIC ch # : asicCh[MaxROI]
    //pulse time estimate (ns) : pulseTime
    //pulse time estmate (sample #) : pulseTimeSample
    //pulse height estimate (adc) : pulseHeight

     std::cout << "event number " << eventNum;
     std::cout << "\tRow " << asicRow[r];
     std::cout << "\tCol " << asicCol[r];
     std::cout << "\tChannel " << asicCh[r];
     std::cout << "\tPulse time " << pulseTime << std::endl;

    //plot ROI
    ana.plotRoi(c0, eModule[r], asicRow[r], asicCol[r], asicCh[r] );
    char ct;
    std::cin >> ct;

  }//end roi
}

int main(int argc, char *argv[]){
  if(argc!=2){
    cout<<"Usage: checkHitRate [inputFilename]"<<endl;
    return 0;
  }

  char inputFileName[1000];
  sprintf(inputFileName,"%s",argv[1]);

  scanWaveformsIRS3Bana(inputFileName); 

  return 1;
}
