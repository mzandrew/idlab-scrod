#include "STURM2_EVAL.h"
#include "STURM2_EVAL_USB_CMDS.cxx"
//////////////////////////////////////
STURM2_EVAL::STURM2_EVAL(bool Verbose, bool OffLineMode,TGTextEntry *CMDline,TGStatusBar *StatusBar){
  fVerbose     = Verbose;
  fOffLineMode = OffLineMode;
  fCMDline     = CMDline;
  fStatusBar   = StatusBar;
  //////////////////////////////////////
  xIDL_USB = new IDL_USB(OffLineMode,false);
  xIDL_USB->SetVerbose(true);
  //////////////////////////////////////
  xSTURM2Data = new STURM2Data();
  //////////////////////////////////////
  if(!fOffLineMode){
    //LoadVCAL();
    //LoadPED(); 
    SendVCAL(false);
    SendPEDSCAN(0);
    SendEN_PED(false);
    SendDEBUG(4095);
  }
}
//////////////////////////////////////
STURM2_EVAL::~STURM2_EVAL(){
  delete xIDL_USB;
  delete xSTURM2Data;
}
//////////////////////////////////////
void STURM2_EVAL::LoadPED(){
  if(fOffLineMode){
    cout << "Called: STURM2_EVAL::LoadPED()" << endl;
    return;
  }
  xSTURM2Data->LoadPED();
}
//////////////////////////////////////
void STURM2_EVAL::GenPED(){
  if(fOffLineMode){
    cout << "Called: STURM2_EVAL::GenPED()" << endl;
  }
  if(!fOffLineMode){
    SendEN_PED(true);
    TString xSTRING("GenPED");
    Start_TFile(xSTRING);
    for(int event=0;event<NUM_PED_READS;event++){
      xSTRING = xSTRING.Format("Ped: %d of %d",(event+1),NUM_PED_READS);
      fStatusBar->SetText(xSTRING.Data());
      fStatusBar->Draw();
      cout << xSTRING.Data() << endl;
      SendSoftTrig();
      usleep(10);
      int return_value=ReadUSB(false,false);
      if(return_value<0) continue;
      else if (fOffLineMode) continue;
      tree->Fill();  
    }
    End_TFile();
    xSTURM2Data->GenPED(); 
    SendEN_PED(false);
  }
}
//////////////////////////////////////
void STURM2_EVAL::LoadVCAL(){
  if(fOffLineMode){
    cout << "Called: STURM2_EVAL::LoadVCAL()" << endl;
    return;
  }
  xSTURM2Data->LoadVCAL();
}
//////////////////////////////////////
void STURM2_EVAL::GenVCAL(){
  if(fOffLineMode){
    cout << "Called: STURM2_EVAL::GenVCAL()" << endl;
  }
  if(!fOffLineMode){
    TString xSTRING("GenVCAL");
    Start_TFile(xSTRING);
    SendVCAL(true);
    usleep(10);   
    SendEN_PED(true);
    usleep(1e6);
    for(int ADC=0;ADC<4096;ADC+=10){
      int fPedScan = ADC;
      SendPEDSCAN(fPedScan);    
      usleep(1000);
      xSTRING = xSTRING.Format("VCAL: %d of %d",(ADC+1),4096);
      cout << xSTRING.Data() << endl;
      for(int event=0;event<10;event++){
        SendSoftTrig();
        usleep(1000);
        int return_value=ReadUSB(false,false);
        if(return_value<0) continue;
        else if (fOffLineMode) continue;
        tree->Fill();
      }  
    }
    End_TFile();
    SendVCAL(false);
    usleep(10);
    SendPEDSCAN(0); 
    usleep(10);
    SendEN_PED(false);
  }
  xSTURM2Data->GenVCAL();
}
//////////////////////////////////////
void STURM2_EVAL::LOG_DATA(){
  if(fOffLineMode){
    cout << "Called: STURM2_EVAL::LOG_DATA()" << endl;
  }
  if(!fOffLineMode){
    //FILE *dfile = fopen("fWaveform.dat","w");
    TString xSTRING("LOG_DATA");
    Start_TFile(xSTRING);
    for(int event=0;event<1000;event++){
      xSTRING = xSTRING.Format("LOG_DATA: %d of %d",(event+1),1000);
      fStatusBar->SetText(xSTRING.Data());
      fStatusBar->Draw();
      cout << xSTRING.Data() << endl;
      SendSoftTrig();
      //fprintf(dfile, "%d\t%d\t%g\n", i, j, fWaveform[i][j]);
      usleep(100);
      int return_value=ReadUSB(false,false);
      if(return_value<0) continue;
      else if (fOffLineMode) continue;
      tree->Fill();  
    }
    End_TFile();
    //fclose(dfile);
  }
}
//////////////////////////////////////
void STURM2_EVAL::GEN_DUMMY_Waveform(){
  for(int i=0; i<NUM_CHANNELS; i++){
    double temp = (double)NUM_SMPL;
    double peak_loc = gRandom->Uniform((temp/3),((2*temp)/3));
    for(int j=0; j<NUM_SMPL; j++){
      double sample  = (double)j;
      fWaveform[i][j] = TMath::Gaus(sample,peak_loc,5);
      fWaveform[i][j] *= 4096;
    }
  }
  cout << "1234,";
  for(int i=0; i<NUM_CHANNELS; i++){ 
    for(int j=0; j<NUM_SMPL; j++){
      cout << (int)fWaveform[i][j]<<"," << endl;
    }
  }    
  cout << "4321" << endl;
}
//////////////////////////////////////
void STURM2_EVAL::ShowErrorMessage(const char* ErrorText){
  if(fOffLineMode){
    cout << "Called: STURM2_EVAL::ShowErrorMessage()" << endl;
  }
  TRootHelpDialog *hd = new TRootHelpDialog(0, "Error!?!",250, 250);
  hd->SetText(ErrorText);
  hd->Popup();
}
//////////////////////////////////////
void STURM2_EVAL::Start_TFile(TString filename){
  char outputfile_name[99];
  sprintf(outputfile_name,"%s.root",filename.Data());

  hfile = new TFile(outputfile_name,"RECREATE","data file",1);
  tree = new TTree("T","data tree");
  hfile->SetCompressionLevel(1);
   // create new event
  TTree::SetBranchStyle(0); // old branch style
  tree->Branch("fWaveform",fWaveform,"fWaveform[8][64]/D");
  tree->Branch("fRaw",fRaw,"fRaw[8][64]/I");
  tree->Branch("fPRCO_INT",&fPRCO_INT,"fPRCO_INT/I");
  tree->Branch("fPROVDD",&fPROVDD,"fPROVDD/I");
  tree->Branch("fROVDD",&fROVDD,"fROVDD/I");
  tree->Branch("fRCO_INT",&fRCO_INT,"fRCO_INT/I");
  tree->Branch("fPED_SCAN",&fPED_SCAN,"fPED_SCAN/I");
  tree->Branch("fDEBUG",&fDEBUG,"fDEBUG/I");  
}
////////////////////////////////////////////////////////
void STURM2_EVAL::End_TFile(){
  hfile->Write();
  //tree->Print();
  delete tree;
  delete hfile;
}
////////////////////////////////////////////////////////
