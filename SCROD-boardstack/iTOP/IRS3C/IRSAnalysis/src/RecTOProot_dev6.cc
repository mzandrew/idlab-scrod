#include <stdio.h>
#include <iostream>
#include "TFile.h"
#include "TTree.h"

#include "CRTChannelConversion.hh"
#include "IRS3Bana.hxx"
#include "IRS3Bana.cxx"
#include "TMath.h"

using namespace std;

#define MaxROI 400

//sample value histograms
double meanMaxADC = 500;

struct _rawdata {
  Int_t runNum;
  Int_t eventNum;
  Short_t ftsw;

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

};

struct _top {
  Int_t runNum;
  Int_t eventNum;
  Short_t ftsw;
  Short_t eventflag;
  Short_t nhit;
  Short_t refWindow[MaxROI];
  Short_t firstWindow[MaxROI];
  Short_t pmtid_mcp[MaxROI];
  Short_t ch_mcp[MaxROI];
  Float_t adc0_mcp[MaxROI];
  Float_t tdc0_mcp[MaxROI];
  Float_t base_mcp[MaxROI];
  Short_t pmtflag_mcp[MaxROI];
  Float_t smp_mcp[MaxROI];
  Float_t tdc0_smpPrevY_mcp[MaxROI];
  Float_t tdc0_smpNextY_mcp[MaxROI];
  Float_t smpFall_mcp[MaxROI];
  Float_t tdc0Fall_smpPrevY_mcp[MaxROI];
  Float_t tdc0Fall_smpNextY_mcp[MaxROI];
  Float_t smpFix100_mcp[MaxROI];
  Float_t tdcFix100_smpPrevY_mcp[MaxROI];
  Float_t tdcFix100_smpNextY_mcp[MaxROI];
  Float_t smpFix100Fall_mcp[MaxROI];
  Float_t tdcFix100Fall_smpPrevY_mcp[MaxROI];
  Float_t tdcFix100Fall_smpNextY_mcp[MaxROI];
};

void initRootTree(TTree*, struct _rawdata&, TTree*, struct _top&);
void initAna(struct _rawdata&, struct _top&);
void waveformAna(struct _rawdata&, struct _top&, IRS3Bana&);
void measureADC(struct _rawdata&, IRS3Bana&);
void trackerAna(struct _rawdata&, struct _top&);
void applyCalibration(struct _rawdata&, struct _top&);

int main(int argc, char *argv[]){
  if(argc!=3){
    cout<<"Usage: RecTOProot_dev6 [inputFilename] [outputFilename]"<<endl;
    exit(1);
  }

  char inputFilename[1000];
  char outputFilename[1000];
  sprintf(inputFilename,"%s",argv[1]);
  sprintf(outputFilename,"%s",argv[2]);

  std::cout << "Input File Name " << inputFilename << std::endl;
  std::cout << "Output File Name " << outputFilename << std::endl;

  TFile* fin = new TFile(inputFilename);
  TTree* tr_rawdata = (TTree*) fin->Get("rawData");

  TFile* fout = new TFile(outputFilename,"recreate");
  TTree* tr_top = new TTree("top", "top data tree");

  struct _rawdata rawdata;
  struct _top top;

  initRootTree(tr_rawdata, rawdata, tr_top, top);

  IRS3Bana _ana;

  fout->cd();
  //event loop - fill tree
  for(int i=0;i<tr_rawdata->GetEntries();i++){
    tr_rawdata->GetEntry(i);
    if((i%100)==0) cout<<i<<" events processed"<<endl;

    initAna(rawdata,top);
    waveformAna(rawdata,top,_ana);

    tr_top->Fill();
  }

  //write tree
  tr_top->Write();
  fout->Close();
  return 0;
}

void initRootTree(TTree* tr_rawdata, struct _rawdata& rawdata, 
		  TTree* tr_top, struct _top& top){

  tr_rawdata->SetBranchAddress("runNum", &(rawdata.runNum));
  tr_rawdata->SetBranchAddress("eventNum", &(rawdata.eventNum));
  tr_rawdata->SetBranchAddress("ftsw",&(rawdata.ftsw));
  tr_rawdata->SetBranchAddress("nROI", &(rawdata.nROI));
  tr_rawdata->SetBranchAddress("scrodId", &(rawdata.scrodId));
  tr_rawdata->SetBranchAddress("refWindow", &(rawdata.refWindow));
  tr_rawdata->SetBranchAddress("eModule", &(rawdata.eModule));
  tr_rawdata->SetBranchAddress("asicRow", &(rawdata.asicRow));
  tr_rawdata->SetBranchAddress("asicCol", &(rawdata.asicCol));
  tr_rawdata->SetBranchAddress("asicCh", &(rawdata.asicCh));
  tr_rawdata->SetBranchAddress("ROI", &(rawdata.ROI));
  tr_rawdata->SetBranchAddress("firstWindow", &(rawdata.firstWindow));
  tr_rawdata->SetBranchAddress("samples", &(rawdata.samples));
  tr_rawdata->SetBranchAddress("PSsamples", &(rawdata.PSsamples));

  tr_top->Branch("runNum", &(top.runNum), "runNum/I");  
  tr_top->Branch("eventNum", &(top.eventNum), "eventNum/I");
  tr_top->Branch("ftsw", &(top.ftsw), "ftsw/S");
  tr_top->Branch("eventflag", &(top.eventflag), "eventflag/S");
  tr_top->Branch("nhit", &(top.nhit), "nhit/S");
  tr_top->Branch("refWindow", &(top.refWindow), "refWindow[nhit]/S");
  tr_top->Branch("firstWindow", &(top.firstWindow), "firstWindow[nhit]/S");
  tr_top->Branch("pmt", &(top.pmtid_mcp), "pmt[nhit]/S");
  tr_top->Branch("ch", &(top.ch_mcp), "ch[nhit]/S"); 
  tr_top->Branch("adc0", &(top.adc0_mcp), "adc0[nhit]/F");    //IRS3B unit?
  tr_top->Branch("tdc0", &(top.tdc0_mcp), "tdc0[nhit]/F");
  tr_top->Branch("base", &(top.base_mcp), "base[nhit]/F");    //IRS3B unit?
  tr_top->Branch("pmtflag", &(top.pmtflag_mcp), "pmtflag[nhit]/S"); 
  tr_top->Branch("smp", &(top.smp_mcp), "smp[nhit]/F");    //sample number
  tr_top->Branch("tdc0_smpPrevY", &(top.tdc0_smpPrevY_mcp), "tdc0_smpPrevY[nhit]/F");    //ps
  tr_top->Branch("tdc0_smpNextY", &(top.tdc0_smpNextY_mcp), "tdc0_smpNextY[nhit]/F");    //ps
  tr_top->Branch("smpFall", &(top.smpFall_mcp), "smpFall[nhit]/F");    //sample number
  tr_top->Branch("tdc0Fall_smpPrevY", &(top.tdc0Fall_smpPrevY_mcp), "tdc0Fall_smpPrevY[nhit]/F");    //ps
  tr_top->Branch("tdc0Fall_smpNextY", &(top.tdc0Fall_smpNextY_mcp), "tdc0Fall_smpNextY[nhit]/F");    //ps
  tr_top->Branch("smpFix100", &(top.smpFix100_mcp), "smpFix100[nhit]/F");    //ps
  tr_top->Branch("tdcFix100_smpPrevY_mcp", &(top.tdcFix100_smpPrevY_mcp), "tdcFix100_smpPrevY_mcp[nhit]/F");    //ps
  tr_top->Branch("tdcFix100_smpNextY_mcp", &(top.tdcFix100_smpNextY_mcp), "tdcFix100_smpNextY_mcp[nhit]/F");    //ps
  tr_top->Branch("smpFix100Fall", &(top.smpFix100Fall_mcp), "smpFix100Fall[nhit]/F");    //ps
  tr_top->Branch("tdcFix100Fall_smpPrevY_mcp", &(top.tdcFix100Fall_smpPrevY_mcp), "tdcFix100Fall_smpPrevY_mcp[nhit]/F");    //ps
  tr_top->Branch("tdcFix100Fall_smpNextY_mcp", &(top.tdcFix100Fall_smpNextY_mcp), "tdcFix100Fall_smpNextY_mcp[nhit]/F");    //ps
}

void initAna(struct _rawdata& rawdata, struct _top& top){
  //init top
  top.eventflag = 0;
  top.nhit = 0;
  top.ftsw = 0;

  // copy of contents
  top.runNum = rawdata.runNum;
  top.eventNum = rawdata.eventNum;
}

void waveformAna(struct _rawdata& rawdata, struct _top& top, IRS3Bana& ana){
  //waveform analysis event variables set here
  top.ftsw = rawdata.ftsw;
	
  //loop over event ROIs
  for (int r=0; r<rawdata.nROI; r++) {

    ana.MakeWaveform(rawdata.PSsamples[r]);
    //ana.MakeWaveformSmooth();
    ana.AlignWaveform(rawdata.firstWindow[r],rawdata.refWindow[r],rawdata.ftsw,rawdata.eModule[r],
			    rawdata.asicRow[r], rawdata.asicCol[r]);

    int BIIpmt = ASIC_2_BIIpmt(rawdata.eModule[r],rawdata.asicRow[r],
			       rawdata.asicCol[r]);
    int BIIch = ASICch_2_BIIch(rawdata.asicRow[r],rawdata.asicCh[r]);

    //detect overflow
    bool overflowFlag = 0;
    int overflowCount = 0;
    for( int i = 0 ; i < 256 ; i++ ){
	if( rawdata.samples[r][i] < 100 )
		overflowCount++;
    }
    if( overflowCount > 2 ){
	overflowFlag = 1;
	//continue;
    }
 
    double pulseSample = -1;
    double pulseFallSample = -1;
    double pulseSmpFix100 = -1; 
    double pulseSmpFix100Fall = -1;
    double pulseHeight = -1;
    double pulseTime = -1;
    double pulseBaseline = -1;
    bool pulseTimeFlag = 0;
    int maxSampleNum;
    double maxSampleValue;
    Double_t temp, tempT, tempY;

    //find peak sample
    ana.SearchPeakSampleNumber(maxSampleNum, maxSampleValue);
    pulseHeight = ana.GetTruncatedMean(maxSampleNum); 
 
    //get baseline estimate
    ana.g->GetPoint( TMath::FloorNint( maxSampleNum )-20, tempT , tempY );
    pulseBaseline = tempY;

    //CFD section
    if( !ana.FindThresholdSampleAndTime(maxSampleNum,pulseHeight*0.2, pulseSample, pulseTime) ){
	  //when valid pulse time not found, set pulse time to first sample of waveform
    	  pulseTimeFlag = 1;
	  pulseSample = 0.5;
    }

    top.refWindow[top.nhit] = rawdata.refWindow[r];
    top.firstWindow[top.nhit] = rawdata.firstWindow[r];
    top.pmtid_mcp[top.nhit] = BIIpmt;
    top.ch_mcp[top.nhit] = BIIch;  
    top.tdc0_mcp[top.nhit] = pulseTime;
    top.adc0_mcp[top.nhit] = pulseHeight;
    top.base_mcp[top.nhit] = pulseBaseline;
    top.pmtflag_mcp[top.nhit] = 0;
    if( overflowFlag || pulseTimeFlag )
    	top.pmtflag_mcp[top.nhit] = 1;
 
    top.smp_mcp[top.nhit] = pulseSample;
    ana.g->GetPoint( TMath::FloorNint( pulseSample ), tempT , tempY );
    top.tdc0_smpPrevY_mcp[top.nhit] = tempY;
    ana.g->GetPoint( TMath::FloorNint( pulseSample )+1, tempT , tempY );
    top.tdc0_smpNextY_mcp[top.nhit] = tempY;

    ana.FindThresholdSampleAndTimeFalling(maxSampleNum,pulseHeight*0.2, pulseFallSample, tempY);
    top.smpFall_mcp[top.nhit] = pulseFallSample;
    ana.g->GetPoint( TMath::FloorNint( pulseFallSample ), tempT , tempY );
    top.tdc0Fall_smpPrevY_mcp[top.nhit] = tempY;
    ana.g->GetPoint( TMath::FloorNint( pulseFallSample )+1, tempT , tempY );
    top.tdc0Fall_smpNextY_mcp[top.nhit] = tempY;

    ana.FindThresholdSampleAndTime(maxSampleNum,100., pulseSmpFix100, tempY);
    top.smpFix100_mcp[top.nhit] = pulseSmpFix100;
    ana.g->GetPoint( TMath::FloorNint( pulseSmpFix100 ), tempT , tempY );
    top.tdcFix100_smpPrevY_mcp[top.nhit] = tempY;
    ana.g->GetPoint( TMath::FloorNint( pulseSmpFix100 )+1, tempT , tempY );
    top.tdcFix100_smpNextY_mcp[top.nhit] = tempY;

    ana.FindThresholdSampleAndTimeFalling(maxSampleNum,100., pulseSmpFix100Fall, tempY);
    top.smpFix100Fall_mcp[top.nhit] = pulseSmpFix100Fall;
    ana.g->GetPoint( TMath::FloorNint( pulseSmpFix100Fall ), tempT , tempY );
    top.tdcFix100Fall_smpPrevY_mcp[top.nhit] = tempY;
    ana.g->GetPoint( TMath::FloorNint( pulseSmpFix100Fall )+1, tempT , tempY );
    top.tdcFix100Fall_smpNextY_mcp[top.nhit] = tempY;

    top.nhit++;
  }//end roi
}
