///////////////////////////////////////////////////////////////////////
// This code takes the output from parseIRS3BCopperTriggerData.cxx
// and calculates the means and RMS values for every channel x window
// combination.
/////////////////////////////////////////////////////////////////////// 

#include <iostream>
#include <fstream>
#include <sstream>
#include <cstdlib>
#include <utility>
#include <TFile.h>
#include "TTree.h"
#include "TSystem.h"
#include "TROOT.h"
#include "TApplication.h"
#include <math.h>
#include <TH1.h> 
#include <TH2.h> 
#include <TF1.h>
#include <TMath.h> 
#include "TCanvas.h"
#include <TMultiGraph.h>
#include <TGraphErrors.h>
#include <TGraphAsymmErrors.h>
#include "TFitResult.h"
#include "TFitResultPtr.h"


#define POINTS_PER_WAVEFORM    64

Int_t GetFlag(TH1S* histo);
void GetChi2(TH1S* histo, Float_t &chi2, Float_t &ndof);


int main(int argc, char *argv[]) {

  int numberOfElectronicsModules(1); //update when running with more than 1 electronics module.
  int numberOfAsicRows(4);  
  int numberOfAsicColumns(4);
  int numberOfAsicChannels(8);
  int numberOfWindows(64);
  int numberOfSamples(POINTS_PER_WAVEFORM);

  //include the chi2 and ndof values for fitting a Gaussian to the pedestal distribution
  //Warning the fitting takes a long time to run!
  bool performChi2Fit(false);  


  if (argc != 2 && argc != 3) {
    std::cerr << "Usage: GetMeanAndRMSFromIRS3BCopperTriggerData <filename> [numberOfWindows]" << std::endl << "       <filename> should be a root file produced by parseIRS3BCopperTriggerData.cxx" << std::endl;
    return EXIT_FAILURE;
  } 

  TString inputFileName(argv[1]);
  if (3==argc) {numberOfWindows = atoi(argv[2]);}
      


  //set up output file
  TString outputFileName(inputFileName);
  outputFileName.ReplaceAll(".root", "_Pedestal.root");

  if (outputFileName == inputFileName) {
    std::cerr << "Error:  The input file name does not end in \".root\", is it a root file?" << std::endl;
    std::cerr << "        Please change the file name extension to .root to ensure smooth operation of this script" << std::endl;
    return EXIT_FAILURE;
  }

  TCanvas *c0 = new TCanvas("c0", "c0",1300,800);

  TFile* outputFile;
  outputFile = new TFile(outputFileName, "recreate");

  TTree* outputTree = new TTree("PedestalTree", "Pedestal mean and RMS values");

  //UInt_t output_scrodId;
  //UInt_t output_winId;
  Int_t output_eModule;
  Int_t output_asicCol;
  Int_t output_asicRow;
  Int_t output_asicCh;
  Int_t output_window;
  Int_t output_sample;
  Float_t output_mean;
  Float_t output_RMS;
  Int_t output_flag;
  Float_t output_chi2;
  Float_t output_ndof;

  outputTree->Branch("eModule", &output_eModule, "eModule/I"); 
  outputTree->Branch("asicRow", &output_asicRow, "asicRow/I");  
  outputTree->Branch("asicCol", &output_asicCol, "asicCol/I");   
  outputTree->Branch("asicCh", &output_asicCh, "asicCh/I");
  outputTree->Branch("window", &output_window, "window/I");  
  outputTree->Branch("sample", &output_sample, "sample/I");   
  outputTree->Branch("mean", &output_mean, "mean/F");  
  outputTree->Branch("RMS", &output_RMS, "RMS/F");
  outputTree->Branch("flag", &output_flag, "flag/I");
  if (performChi2Fit) {
    outputTree->Branch("chi2", &output_chi2, "chi2/F");
    outputTree->Branch("ndof", &output_ndof, "ndof/F");
  }

  std::cout << "Reading input file : " << inputFileName << std::endl;


  for (int module(0); module<numberOfElectronicsModules; ++module) {
    for (int row(0); row<numberOfAsicRows; ++row) { 



      TFile* inputFile = new TFile(inputFileName);
      if (!inputFile || inputFile->IsZombie()) {
        std::cerr << "Unable to open file " << inputFileName << std::endl << "Exiting ... " << std::endl;
        return EXIT_FAILURE;
      }
  
      TTree* inputMetaData = (TTree*) inputFile->Get("MetaData");
      if (!inputMetaData || inputMetaData->IsZombie()) {
        //std::cout << "Cannot read metadata tree.  Ignoring..." << std::endl; 
      } else {
        //read number of rows, cols etc from input root file:
        inputMetaData->SetBranchAddress("nEModules", &numberOfElectronicsModules);
        inputMetaData->SetBranchAddress("nAsicRows", &numberOfAsicRows);
        inputMetaData->SetBranchAddress("nAsicColumns", &numberOfAsicColumns);
        inputMetaData->SetBranchAddress("nAsicChannels", &numberOfAsicChannels);
        if (3 != argc) {inputMetaData->SetBranchAddress("nWindows", &numberOfWindows);}
        inputMetaData->SetBranchAddress("nSamples", &numberOfSamples);
        inputMetaData->GetEntry(0);
      }


      TTree* tree = (TTree*) inputFile->Get("T");  
      if (!tree || tree->IsZombie()) {
        std::cerr << "Error: could not read input root tree T ..." << std::endl; 
      }


 
      //process separately for asic rows and electronics modules to save on memory.
      int numberOfHistograms(numberOfAsicColumns*numberOfAsicChannels*numberOfWindows*numberOfSamples); 
  
      static const int samplesArraySize(numberOfSamples);
   
      UInt_t scrodId;
      UInt_t winId;
      int eModule;
      int asicCol;
      int asicRow;
      int asicCh;
      int window;  
      int samples[samplesArraySize];
  
      tree->SetBranchAddress("scrodId", &scrodId);
      tree->SetBranchAddress("winId", &winId);
      tree->SetBranchAddress("eModule", &eModule);
      tree->SetBranchAddress("asicCol", &asicCol);
      tree->SetBranchAddress("asicRow", &asicRow);
      tree->SetBranchAddress("asicCh", &asicCh);
      tree->SetBranchAddress("window", &window);
      tree->SetBranchAddress("samples", &samples);  
      int nEntries(tree->GetEntries());  
 

      //TH1C only works as long as there are less than 100 (actually 127) triggers/events. TH1S should work for up to 32767 events.
      std::vector<TH1S*> histos;
  
      histos.reserve(numberOfHistograms);


      for (int i(0); i<numberOfHistograms; ++i) {
        TString name("namae");
        name += i;

        TH1S* dummy = new TH1S(name, "title", 4096, 0, 4096);    
        histos.push_back(dummy);
      }

      for (int n(0); n<nEntries; ++n) {
        tree->GetEntry(n);
        if (window > numberOfWindows-1) {continue;}
	//std::cout << " eModule " << eModule;
	//std::cout << "module " << module;
	//std::cout << std::endl;
        for (int s(0); s<numberOfSamples; ++s) {
	  if (asicRow == row && eModule == module) { 
	    int entry(s + numberOfSamples*window + numberOfSamples*numberOfWindows*asicCh +  numberOfSamples*numberOfWindows*numberOfAsicChannels*asicCol);
	    if (entry > numberOfHistograms-1) {std::cerr << "Error: requested histogram number is too high, please check number of asic rows, asic cols, etc" << std::endl;}
	    histos.at(entry)->Fill(samples[s]); 
          }
        }    
      } 
 
      outputFile->cd();

      for (int i(0); i<numberOfHistograms; ++i) {
        output_eModule = module;
	output_asicRow = row;
	output_asicCol = (i/(numberOfAsicChannels*numberOfWindows*numberOfSamples))%numberOfAsicColumns;
        output_asicCh = (i/(numberOfWindows*numberOfSamples))%numberOfAsicChannels;
        output_window = (i/numberOfSamples)%numberOfWindows;
        output_sample = i%numberOfSamples;
        //output_mean = histos.at(i)->GetMean();
	double posMax = histos.at(i)->GetBinCenter( histos.at(i)->GetMaximumBin() );
	histos.at(i)->GetXaxis()->SetRangeUser(posMax-5, posMax+5);
	output_mean = histos.at(i)->GetMean(1);
        output_RMS = histos.at(i)->GetRMS();
        output_flag = GetFlag(histos.at(i));
        if (performChi2Fit) {GetChi2(histos.at(i), output_chi2, output_ndof);} 
        outputTree->Fill();
      }

      inputFile->Close();

    }//loop over asic rows
  }//loop over electronics modules


  std::cout << "Writing output file: " << outputFileName << std::endl;

  outputTree->Write();

  //Save any additional information to a separate tree 
  TTree* PedestalMetaDataTree = new TTree("PedestalMetaData", "Pedestal meta data");  
  PedestalMetaDataTree->Branch("nEModules", &numberOfElectronicsModules, "nEModules/I");   
  PedestalMetaDataTree->Branch("nAsicRows", &numberOfAsicRows, "nAsicRows/I");
  PedestalMetaDataTree->Branch("nAsicColumns", &numberOfAsicColumns, "nAsicColumns/I");
  PedestalMetaDataTree->Branch("nAsicChannels", &numberOfAsicChannels, "nAsicChannels/I");
  PedestalMetaDataTree->Branch("nWindows", &numberOfWindows, "nWindows/I");
  PedestalMetaDataTree->Branch("nSamples", &numberOfSamples, "nSamples/I");
  PedestalMetaDataTree->Fill();
  PedestalMetaDataTree->Write();  
  

  outputFile->Close();

  return EXIT_SUCCESS;


}

Int_t GetFlag(TH1S* histo) {

  Int_t nEntries(histo->GetEntries());
  Int_t lowValue(15);
  
  if (histo->GetBinContent(1) >= nEntries/2) {return 10;}
  if (histo->GetBinContent(4096) >= nEntries/2) {return 11;}
  if (histo->Integral(2, lowValue+1) >= nEntries/2) {return 12;} //will include bins between 2 and lowValue+1, i.e. values from 1 to lowValue
  bool hasZeros(false);
  bool hasFFFs(false);
  bool hasLowValues(false);

  if (histo->GetBinContent(1) > 0) {hasZeros = true;}
  if (histo->GetBinContent(4096) > 0) {hasFFFs = true;}
  if (histo->Integral(2, lowValue+1) > 0) {hasLowValues = true;}

  if (hasZeros && hasFFFs && hasLowValues) {return 19;}
  if (hasZeros && hasFFFs) {return 16;}
  if (hasZeros && hasLowValues) {return 17;}
  if (hasFFFs && hasLowValues) {return 18;}
  if (hasZeros) {return 13;}
  if (hasFFFs) {return 14;}
  if (hasLowValues) {return 15;}


  return 0;
  
}


void GetChi2(TH1S* histo, Float_t &chi2, Float_t &ndof) {
  TFitResultPtr result = histo->Fit("gaus","SQN", "goff");
  chi2 = result->Chi2();
  ndof = result->Ndf();
}


