#include "packet_interface.h"
#include <iostream>
#include <fstream>
#include <sstream>
#include <cstdlib>
#include <TFile.h>
#include "TTree.h"
#include "TSystem.h"
#include "TROOT.h"
#include "TApplication.h"
#include <math.h>
#include <TH1F.h> 
#include <TH2F.h> 
#include <TF1.h>
#include <TMath.h> 
#include "TCanvas.h"
#include <TMultiGraph.h>
#include <TGraphErrors.h>
#include <TGraphAsymmErrors.h>
using namespace std;

//define global constants
#define MAX_SEGMENTS_PER_EVENT 512
#define POINTS_PER_WAVEFORM    64
#define MEMORY_DEPTH           64
#define NCOLS                  4
#define NROWS                  4
#define NCHS                   8
#define NWORDS_EVENT_HEADER    11
#define NWORDS_WAVE_PACKET     42
#define NELECTRONICSMODULES    1
//This will need to be modified when we move to running with more than one electronics module.

void initializeHistograms();
void initializeGraphs();
void processTree();
void plotSamples();
void makeGraph();
void plotGraphs();
void resetGraphs();
Float_t GetPedestalValue(Int_t eModule, Int_t asicRow, Int_t asicCol, Int_t asicCh, Int_t window, Int_t sample);
Float_t GetPedestalRMS(Int_t eModule, Int_t asicRow, Int_t asicCol, Int_t asicCh, Int_t window, Int_t sample);
//canvas
TCanvas *c1;
//global graph
TGraphErrors *grWinGlobal[MEMORY_DEPTH];

//Set tree variables as global for quick implementation
TTree *tree;
UInt_t scrodId;
UInt_t winId;
UInt_t eventNum;
int eModule;
int asicCol;
int asicRow;
int asicCh;
int window;
int samples[POINTS_PER_WAVEFORM];

TTree* pedestalTree;
Int_t pedestalEModule;
Int_t pedestalAsicRow;
Int_t pedestalAsicCol;
Int_t pedestalAsicCh;
Int_t pedestalWindow;
Int_t pedestalSample;
Float_t pedestalMean;
Float_t pedestalRMS;

bool subtractPedestals;

int firstWindow;

//histograms
//histograms go here

void analyzeIRS3BCopperTriggerData() {
  std::cerr << "Usage: analyzeIRS3BCopperTriggerData(inputFileName, pedestalFileName[optional])" << std::endl;
} 

void analyzeIRS3BCopperTriggerData(std::string inputFileName, std::string pedestalFileName){
	//define input file
	TFile *g;
	g = new TFile(TString(inputFileName), "READ"); //test mode
	if (g->IsZombie()) {
		std::cout << "Error opening input file" << std::endl;
		exit(-1);
	}


        subtractPedestals = true;
	if ("none" == pedestalFileName) {
	     subtractPedestals = false;
	     std::cout << "Not subracting pedestals." << std::endl;
	}
	
	

        if (subtractPedestals) {
	  TFile* pedestalFile = new TFile(TString(pedestalFileName));        
	  if (!pedestalFile || pedestalFile->IsZombie()) {
		std::cerr << "Error opening pedestal file " << pedestalFileName  << std::endl;
		return;
	  }

          pedestalTree = (TTree*) pedestalFile->Get("PedestalTree");
	}

	//define canvas
	c1 = new TCanvas("c0","",0,0,1000,800);

	//load tree and assign variables
        tree = (TTree*)g->Get("T");

	//initialize histograms used in analysis
	initializeHistograms();

	//initialize graphs
	initializeGraphs();

	//process tree
	processTree();

	//define output file name
	std::string outputFileName = "output_analyzeIRS3BCopperTriggerData.root";
	std::cout << " outputFileName " << outputFileName << std::endl;

	TFile f( outputFileName.c_str() , "RECREATE");
	//write output here
	f.Close();
	return;
}

void initializeHistograms(){
	//initialize histograms here
}

void processTree(){
	//define tree variables
	TBranch *branch_scrodId = tree->GetBranch("scrodId");
	branch_scrodId->SetAddress(&scrodId);
	TBranch *branch_windId = tree->GetBranch("winId");
	branch_windId->SetAddress(&winId);
	TBranch *branch_eModule = tree->GetBranch("eModule");
	branch_eModule->SetAddress(&eModule);
	TBranch *branch_eventNum = tree->GetBranch("eventNum");
	branch_eventNum->SetAddress(&eventNum);
	TBranch *branch_asicCol = tree->GetBranch("asicCol");
	branch_asicCol->SetAddress(&asicCol);
	TBranch *branch_asicRow = tree->GetBranch("asicRow");
	branch_asicRow->SetAddress(&asicRow);
	TBranch *branch_asicCh = tree->GetBranch("asicCh");
	branch_asicCh->SetAddress(&asicCh);
	TBranch *branch_window = tree->GetBranch("window");
	branch_window->SetAddress(&window);
	TBranch *branch_samples = tree->GetBranch("samples");
	branch_samples->SetAddress(samples);

        if (subtractPedestals) {
	  pedestalTree->SetBranchAddress("eModule", &pedestalEModule);    
	  pedestalTree->SetBranchAddress("asicRow", &pedestalAsicRow);
	  pedestalTree->SetBranchAddress("asicCol", &pedestalAsicCol);	          
	  pedestalTree->SetBranchAddress("asicCh", &pedestalAsicCh);
	  pedestalTree->SetBranchAddress("window", &pedestalWindow);
	  pedestalTree->SetBranchAddress("window", &pedestalWindow);
	  pedestalTree->SetBranchAddress("sample", &pedestalSample);
	  pedestalTree->SetBranchAddress("mean", &pedestalMean);
	  pedestalTree->SetBranchAddress("RMS", &pedestalRMS);
        }

	//loop through tree, plot each waveform in graph
	UInt_t prevEventNum = -1;
	for (int i = 0; i < tree->GetEntries(); i++){
		//std::cout << "event " << i << std::endl;
		tree->GetEvent(i);
		//detect if new event
		if( prevEventNum != eventNum ){
			//std::cout << "NEW EVENT " << std::endl;
			//do something for new event
			if( prevEventNum >= 0 ){
				//plotGraphs(); //plot all the windows in the previous event
				//reset graphs
				resetGraphs(); //reset the global window graphs each event
			}

			//record the first window in a data acquisition
			firstWindow = window;
		}

		//draw event
		plotSamples();
		//update global window graph
		makeGraph();
		
		//update previous event number
		prevEventNum = eventNum;
	}

	return;
}

void plotSamples(){
	c1->Clear();

  	double num[POINTS_PER_WAVEFORM];
  	double numErr[POINTS_PER_WAVEFORM];
  	double val[POINTS_PER_WAVEFORM]; 
  	double valErr[POINTS_PER_WAVEFORM];
        double pedestalSubtracted[POINTS_PER_WAVEFORM];
	double pedestalSubtractedError[POINTS_PER_WAVEFORM];
  	memset(num,0,sizeof(num[0])*POINTS_PER_WAVEFORM );
  	memset(numErr,0,sizeof(numErr[0])*POINTS_PER_WAVEFORM  );
  	memset(val,0,sizeof(val[0])*POINTS_PER_WAVEFORM  );
  	memset(valErr,0,sizeof(valErr[0])*POINTS_PER_WAVEFORM  );

	for(int i = 0 ; i < POINTS_PER_WAVEFORM ; i++){          
		num[i] = i;
		val[i] = samples[i];
		
		if (subtractPedestals) {
                  pedestalSubtracted[i] = val[i] - GetPedestalValue(eModule, asicRow, asicCol, asicCh, window, i);
		  pedestalSubtractedError[i] = GetPedestalRMS(eModule, asicRow, asicCol, asicCh, window, i);
		}
	}
  
        c1->SetFillColor(kWhite);
        c1->Divide(1, 3);
         
        c1->cd(2);
    
     	TGraphErrors *gr = new TGraphErrors(POINTS_PER_WAVEFORM,num,val,numErr,valErr); 
 	gr->SetName("Efficiency");
 	gr->SetMarkerColor(4);
 	gr->SetMarkerStyle(21);
 	gr->SetMarkerSize(1);

        TString title("Digitised samples - Electronics module ");
	title += eModule;
	title += " ASIC column ";
	title += asicCol;
	title += " ASIC row ";
	title += asicRow;
	title += " ASIC channel ";     
	title += asicCh; 
        title += " window ";
	title += window;

 
        gr->Draw("ALP");
	gr->SetTitle(title);
	gr->GetXaxis()->SetTitle("Sample Number");
	gr->GetXaxis()->CenterTitle();
	gr->GetYaxis()->SetTitle("Value (ADC)"); 

        c1->cd(2);
        gr->DrawClone("ALP");
	
	
	gr->GetYaxis()->SetRangeUser(0,4100); 
        c1->cd(1);
        gr->Draw("ALP");
 	
	TGraphErrors *cgr;
        if (subtractPedestals) {
     	  cgr = new TGraphErrors(POINTS_PER_WAVEFORM, num, pedestalSubtracted, numErr, pedestalSubtractedError); 
 	  cgr->SetName("namae");
 	  cgr->SetMarkerColor(kBlue);
 	  cgr->SetMarkerStyle(21);
 	  cgr->SetMarkerSize(1);
          cgr->SetTitle("Pedestal subtracted samples");

	  cgr->GetYaxis()->SetTitle("Subtracted value (ADC)");
	  cgr->GetXaxis()->SetTitle("Sample Number");


          c1->cd(3);
	  if( cgr )
	  	cgr->Draw("ALP");
        } //if subtract pedestals

	std::cout << std::hex << " eModule " << eModule << std::endl;
	std::cout << std::hex << " eventNum " << eventNum << std::endl;
	std::cout << std::hex << " winId " << winId << std::endl;
	std::cout << std::hex << " asicCol " << asicCol << std::endl;
	std::cout << std::hex << " asicRow " << asicRow << std::endl;
	std::cout << std::hex << " asicCh " << asicCh << std::endl;
	std::cout << std::hex << " window " << window << std::endl;


	c1->Update();
	std::cout << "Enter character to continue" << std::endl;
	char ct;
	std::cin >> ct;

	gr->Delete();
        if (subtractPedestals) {
	  if( cgr )
	  	cgr->Delete();
        }
	return;
}


Float_t GetPedestalValue(Int_t ped_eModule, Int_t ped_asicRow, Int_t ped_asicCol, Int_t ped_asicCh, Int_t ped_window, Int_t ped_sample) {
  //Will need to update to use eModule when we start running with more than 1 electronics module.

  //Try to guess where the entry is based on the structure of the pedestal root file:
  int numberOfElectronicsModules(1);
  int numberOfAsicRows(4);  
  int numberOfAsicColumns(4);
  int numberOfAsicChannels(8);
  int numberOfWindows(64);
  
  pedestalTree->GetEntry(ped_sample + POINTS_PER_WAVEFORM*ped_window + POINTS_PER_WAVEFORM*numberOfWindows*ped_asicCh +  POINTS_PER_WAVEFORM*numberOfWindows*numberOfAsicChannels*ped_asicCol + POINTS_PER_WAVEFORM*numberOfWindows*numberOfAsicChannels*numberOfAsicColumns*ped_asicRow);
  
  
  if (ped_asicRow == pedestalAsicRow && ped_asicCol == pedestalAsicCol && ped_asicCh == pedestalAsicCh && ped_window == pedestalWindow && ped_sample == pedestalSample) {
    //Correct position found, return the mean:
    return pedestalMean;
  } 

  //look for the correct value by looping through all entries: 
  Int_t pedestalTreeEntries(pedestalTree->GetEntries());
 
  for (Int_t p(0); p<pedestalTreeEntries;  ++p) {
    pedestalTree->GetEntry(p);
    if (ped_asicRow == pedestalAsicRow && ped_asicCol == pedestalAsicCol && ped_asicCh == pedestalAsicCh 
	&& ped_window == pedestalWindow && ped_sample == pedestalSample) 
	{break;}
  }
  return pedestalMean;
}


Float_t GetPedestalRMS(Int_t ped_eModule, Int_t ped_asicRow, Int_t ped_asicCol, Int_t ped_asicCh, Int_t ped_window, Int_t ped_sample) {
  //Will need to update to use eModule when we start running with more than 1 electronics module.

  //Try to guess where the entry is based on the structure of the pedestal root file:
  int numberOfAsicRows(4);  
  int numberOfAsicColumns(4);
  int numberOfAsicChannels(8);
  int numberOfWindows(64);
  
  pedestalTree->GetEntry(ped_sample + POINTS_PER_WAVEFORM*ped_window + POINTS_PER_WAVEFORM*numberOfWindows*ped_asicCh +  POINTS_PER_WAVEFORM*numberOfWindows*numberOfAsicChannels*ped_asicCol + POINTS_PER_WAVEFORM*numberOfWindows*numberOfAsicChannels*numberOfAsicColumns*ped_asicRow);
  
  
  if (ped_asicRow == pedestalAsicRow && ped_asicCol == pedestalAsicCol && ped_asicCh == pedestalAsicCh && ped_window == pedestalWindow && ped_sample == pedestalSample) {
    //Correct position found, return the mean:
    return pedestalRMS;
  } 

  //look for the correct value by looping through all entries: 
  Int_t pedestalTreeEntries(pedestalTree->GetEntries());
 
  for (Int_t p(0); p<pedestalTreeEntries;  ++p) {
    pedestalTree->GetEntry(p);
    //this could be done much more efficiently;
    if (ped_asicRow == pedestalAsicRow && ped_asicCol == pedestalAsicCol && ped_asicCh == pedestalAsicCh 
	&& ped_window == pedestalWindow && ped_sample == pedestalSample) 
	{break;}
  } 
  return pedestalRMS;
}

void initializeGraphs(){
	//64 sample window graphs
	double num[POINTS_PER_WAVEFORM];
  	double numErr[POINTS_PER_WAVEFORM];
  	double val[POINTS_PER_WAVEFORM]; 
  	double valErr[POINTS_PER_WAVEFORM];
  	memset(num,0,sizeof(num[0])*POINTS_PER_WAVEFORM );
  	memset(numErr,0,sizeof(numErr[0])*POINTS_PER_WAVEFORM  );
  	memset(val,0,sizeof(val[0])*POINTS_PER_WAVEFORM  );
  	memset(valErr,0,sizeof(valErr[0])*POINTS_PER_WAVEFORM  );

	for(int i = 0 ; i < MEMORY_DEPTH ; i++)
		grWinGlobal[i] = new TGraphErrors(POINTS_PER_WAVEFORM,num,val,numErr,valErr);  
}

void makeGraph(){
  	double num[POINTS_PER_WAVEFORM];
  	double numErr[POINTS_PER_WAVEFORM];
  	double val[POINTS_PER_WAVEFORM]; 
  	double valErr[POINTS_PER_WAVEFORM];
        double pedestalSubtracted[POINTS_PER_WAVEFORM];
	double pedestalSubtractedError[POINTS_PER_WAVEFORM];
  	memset(num,0,sizeof(num[0])*POINTS_PER_WAVEFORM );
  	memset(numErr,0,sizeof(numErr[0])*POINTS_PER_WAVEFORM  );
  	memset(val,0,sizeof(val[0])*POINTS_PER_WAVEFORM  );
  	memset(valErr,0,sizeof(valErr[0])*POINTS_PER_WAVEFORM  );

	for(int i = 0 ; i < POINTS_PER_WAVEFORM ; i++){          
		num[i] = i;
		val[i] = samples[i];
		if (subtractPedestals) {
                  val[i] = val[i] - GetPedestalValue(eModule, asicRow, asicCol, asicCh, window, i);
		  valErr[i] = GetPedestalRMS(eModule, asicRow, asicCol, asicCh, window, i);
		}
	}

	TString title("Digitised samples - Electronics module ");
	title += eModule;
	title += " ASIC column ";
	title += asicCol;
	title += " ASIC row ";
	title += asicRow;
	title += " ASIC channel ";     
	title += asicCh; 
        title += " window ";
	title += window;

	TString name("grWinGlobal_");
    	title += " window ";
	title += window;

	if( !grWinGlobal[window] )
		std::cout << "Window graph object not defined, returning" << std::endl;

	//reset graph - set npoitns to 0
	grWinGlobal[window]->Set(0);
	//add in new points
	for(int i = 0 ; i < POINTS_PER_WAVEFORM ; i++)
		grWinGlobal[window]->SetPoint(i,num[i],val[i]);

	grWinGlobal[window]->SetTitle(title);
 	grWinGlobal[window]->SetName(name);
	if( window == firstWindow )
		grWinGlobal[window]->SetMarkerColor(2);	
	else
	 	grWinGlobal[window]->SetMarkerColor(4);
 	grWinGlobal[window]->SetMarkerStyle(21);
 	grWinGlobal[window]->SetMarkerSize(0.5);
	grWinGlobal[window]->GetYaxis()->SetRangeUser(-200,500);
	return;
}

void plotGraphs(){
	c1->Clear();
	int numGraphCount = 0;

	c1->Divide(8,8);
	for(int i = 0 ; i < MEMORY_DEPTH ; i++){
		c1->cd(i+1);
		if( grWinGlobal[i] ){
			grWinGlobal[i]->Draw("ALP");
		}
		else
			std::cout << "Window " << i << " graph does not exist." << std::endl;
	}

	c1->Update();
	std::cout << "Enter character to continue" << std::endl;
	char ct;
	std::cin >> ct;
}

void resetGraphs(){
	for(int i = 0 ; i < MEMORY_DEPTH ; i++)
		if( grWinGlobal[i] )
			grWinGlobal[i]->Set(0);
}
