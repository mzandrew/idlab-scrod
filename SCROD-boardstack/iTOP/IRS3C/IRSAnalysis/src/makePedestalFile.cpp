///////////////////////////////////////////////////////////////////////
// This code takes the output from parseIRS3BCopperTriggerData.cxx
// and calculates the means and RMS values for every channel x window
// combination.
// compile g++ -o makePedestalFile src/makePedestalFile.cpp `root-config --cflags --glibs`
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

#define MAX_SEGMENTS_PER_EVENT 512
#define POINTS_PER_WAVEFORM    64
#define MEMORY_DEPTH           64
#define NCOLS                  4
#define NROWS                  4
#define NCHS                   8
#define NWORDS_EVENT_HEADER    11
#define NWORDS_WAVE_PACKET     42
#define NELECTRONICSMODULES    4

double sampleAvg[NELECTRONICSMODULES][NROWS][NCOLS][NCHS][MEMORY_DEPTH][POINTS_PER_WAVEFORM];
int numEntries[NELECTRONICSMODULES][NROWS][NCOLS][NCHS][MEMORY_DEPTH][POINTS_PER_WAVEFORM];

int main(int argc, char *argv[]) {

  int numberOfElectronicsModules(NELECTRONICSMODULES); //update when running with more than 1 electronics module.
  int numberOfAsicRows(NROWS);  
  int numberOfAsicColumns(NCOLS);
  int numberOfAsicChannels(NCHS);
  int numberOfWindows(MEMORY_DEPTH);
  int numberOfSamples(POINTS_PER_WAVEFORM);

  if (argc != 2 ) {
    std::cerr << "Usage: makePedestalFile <filename>" << std::endl << " <filename> should be a root file produced by parseIRS3BCopperTriggerData.cxx" << std::endl;
    return EXIT_FAILURE;
  } 

  TString inputFileName(argv[1]);
  if( inputFileName.Sizeof() == 0 ){
	std::cout << "makePedestalFile: Invalid input file name, exiting" << std::endl;
	return 0;
  }
  //set up output file
  TString outputFileName(inputFileName);
  if( outputFileName.Sizeof() == 0 ){
       std::cout << "makePedestalFile: Invalid output file name produced, exiting" << std::endl;
       return 0;
  }

  outputFileName.ReplaceAll(".root", "_Pedestal.root");

  if (outputFileName == inputFileName) {
    std::cerr << "Error:  The input file name does not end in \".root\", is it a root file?" << std::endl;
    std::cerr << "        Please change the file name extension to .root to ensure smooth operation of this script" << std::endl;
    return EXIT_FAILURE;
  }

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
        inputMetaData->SetBranchAddress("nWindows", &numberOfWindows);
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

      for (int n(0); n<nEntries; ++n) {
        tree->GetEntry(n);
        if (window > numberOfWindows-1) {continue;}
        for (int s(0); s<numberOfSamples; ++s) {
	  		if (asicRow == row && eModule == module) { 
	    		sampleAvg[module][asicRow][asicCol][asicCh][window][s] += samples[s];
	    		numEntries[module][asicRow][asicCol][asicCh][window][s]++;
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
		output_mean = 0;
		if( numEntries[output_eModule][output_asicRow][output_asicCol][output_asicCh][output_window][output_sample] > 0 ){
        	output_mean = sampleAvg[output_eModule][output_asicRow][output_asicCol][output_asicCh][output_window][output_sample]/
			double( numEntries[output_eModule][output_asicRow][output_asicCol][output_asicCh][output_window][output_sample] );
		}
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
