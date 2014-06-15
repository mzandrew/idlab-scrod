#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <dirent.h>
#include <sys/stat.h>
#include <iostream>
#include <fstream>
#include <vector>
#include "TFile.h"
#include "TTree.h"

// CRT / Fuji Hall / June 14, 2014, replaced USB CAMAC controller
//#define HEADER 0x00cc0247
#define HEADER 0x00cc0200
#define FOOTER 0xffffffff
#define SLOT_MARKER 0xdddd

using namespace std;

int CAMACevent = 0;
int CAMACtime_sec = 0;
int CAMACtime_msec = 0;
int trigS_tdc[2] = {0};
int trigS_adc[2] = {0};
int trigM_tdc[2] = {0};
int trigM_adc[2] = {0};
int timing_tdc = 0;
int timing_adc = 0;
int ratemon = 0;
short ftsw = 0;
int rf[4] = {0};
int veto[2] = {0};
short c3377nhit = 0;
short c3377tdc[1024] = {0};
short c3377lt[1024] = {0};
short c3377ch[1024] = {0};
short eventtag = 0;

ifstream fin;
TTree *tree;

int Decoder(vector<unsigned int> *buf){

  int iword = 0;
  assert((buf->at(iword++)&0x00ffffff) == HEADER);
  CAMACevent = buf->at(iword++);
  CAMACtime_sec = buf->at(iword++);
  CAMACtime_msec = buf->at(iword++);
  int nbytes = buf->at(iword++);

  int nwords = (buf->at(iword++))>>16;
  int slot;
  unsigned short data;
  c3377nhit = 0;
  while (buf->at(iword) != FOOTER) {
    slot = (buf->at(iword))&0xffff;
    //std::cout << std::hex << ((buf->at(iword))) << std::endl;
    // CRT / Fuji Hall / June 14, 2014, placed LeCroy TDC into station 6
    //    if (1 && slot==21) {
    if (1 && slot==6) {
	//iword++;	
    	ftsw = (((buf->at(iword+2))>>16) & 0x7FF);
	//std::cout << "\t" << std::dec << ftsw << "\t" << std::hex << ftsw << std::endl;
      //ftsw = 0; 
    }
    iword++;
    //assert(buf->at(iword++)>>16 == SLOT_MARKER);
  }

  //std::cout << std::hex << ftsw;
  //  for( int i = 0 ; i < 16 ; i++ )
  //	std::cout << "\t" << std::dec << ((ftsw >> 15 - i) & 0x1);
  //  std::cout <<  std::endl;

  assert(iword == (nwords-1)/2.+6);
  
  tree -> Fill();
  
  return 0;
}

int main(int argc,char *argv[]){
  
  unsigned int data = 0;
  vector<unsigned int> buf;

  if(argc != 3){
    cout << "Usage: ./IndicateRawdata [inputFileName] [outputFileName]" << endl;
    exit(1);
  }

  char inputFileName[1000];
  char outputFileName[1000];
  sprintf(inputFileName,"%s",argv[1]);
  sprintf(outputFileName,"%s",argv[2]);

  fin.open(inputFileName, ios::in | ios::binary);
  if(!fin){
    cout << "Error: " << argv[1] << " does not exist." << endl;
    exit(1);
  }

  cout << "Start conversion" << endl;

  TFile *f = new TFile(outputFileName,"recreate");
  tree = new TTree("camac","camac");
  tree->Branch("time1",&CAMACtime_sec,"TIME1/I");
  tree->Branch("time2",&CAMACtime_msec,"TIME2/I");
  tree->Branch("event",&CAMACevent,"EVENT/I");
  tree->Branch("trigS_tdc",trigS_tdc,"TRIGS_TDC[2]/I");
  tree->Branch("trigS_adc",trigS_adc,"TRIGS_ADC[2]/I");
  tree->Branch("trigM_tdc",trigM_tdc,"TRIGM_TDC[2]/I");
  tree->Branch("trigM_adc",trigM_adc,"TRIGM_ADC[2]/I");
  tree->Branch("timing_tdc",&timing_tdc,"TIMING_TDC/I");
  tree->Branch("timing_adc",&timing_adc,"TIMING_ADC/I");
  tree->Branch("ratemon",&ratemon,"RATEMON/I");
  tree->Branch("ftsw",&ftsw,"FTSW/S");
  tree->Branch("rf",rf,"RF[4]/I");
  tree->Branch("veto",veto,"VETO[2]/I");
  tree->Branch("eventtag",&eventtag,"EVENTTAG/S");
  tree->Branch("c3377nhit",&c3377nhit,"C3377NHIT/S");
  tree->Branch("c3377tdc",c3377tdc,"C3377TDC[C3377NHIT]/S");
  tree->Branch("c3377lt",c3377lt,"C3377LT[C3377NHIT]/S");
  tree->Branch("c3377ch",c3377ch,"C3377CH[C3377NHIT]/S");

  while(fin){
    fin.read((char*)&data,sizeof(int));
    buf.push_back(data);
    if(buf.size() > 2 && buf.back() == FOOTER){
      Decoder(&buf);
      buf.clear();
    }
  }

  tree -> Write();
  f -> Close();
  
  return 0;

}
