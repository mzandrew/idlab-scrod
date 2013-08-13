 #include "STURM2Data.h"
/////////////////////////////////////////////////////////
STURM2Data::STURM2Data(){
}
/////////////////////////////////////////////////////////
STURM2Data::~STURM2Data(void)
{}
/////////////////////////////////////////////////////////
void STURM2Data::unpackData(int fReadoutBuffer[]){  
  for(int i=0;i<NUM_CHANNELS;i++){
    for(int j=0;j<NUM_SMPL;j++){
      fRaw[i][j]  = fReadoutBuffer[1+NUM_SMPL*i+j];
    }
  }
  fPRCO_INT  = fReadoutBuffer[NUM_CHANNELS*NUM_SMPL+1];
  fPROVDD    = fReadoutBuffer[NUM_CHANNELS*NUM_SMPL+2];
  fRCO_INT   = fReadoutBuffer[NUM_CHANNELS*NUM_SMPL+3];
  fROVDD     = fReadoutBuffer[NUM_CHANNELS*NUM_SMPL+4];
  fPED_SCAN  = fReadoutBuffer[NUM_CHANNELS*NUM_SMPL+5];
  fDEBUG     = fReadoutBuffer[NUM_CHANNELS*NUM_SMPL+6];
///////////////////////////////////////////////////////// 
  int ptr;
  for(int i=0;i<NUM_CHANNELS;i++){
    for(int j=0;j<NUM_SMPL;j++){
      ptr = fRaw[i][j];
      // check if pedestal taken
      if(fPED[i][j]!=0) 
	{
	  if(i==0 && j<8) cout << "using ped value = " << fPED[i][j] << " for sample " << j << " and raw sample = " << 1.0*fRaw[i][j] << endl;  
	  fRaw[i][j]-=fPED[i][j];  
	}
        fWaveform[i][j] = fRaw[i][j];
      //              fWaveform[i][j] = fRaw[i][j] - fPED[i][j];
      //fWaveform[i][j] = fVLUT[i][j][ptr] - fPED[i][j];
       //     if(i==0 && j<8)   cout << "channel = " << i << " sample = " << j << " value = " << fRaw[i][j] << " and ped = " << fPED[i][j] << endl;
      // fWaveform[i][j] = fVLUT[i][j][ptr];
    }
  }
}  
/////////////////////////////////////////////////////////
void STURM2Data::LoadPED(){
  TFile *hfile;  
  TTree *tree;
  double data[NUM_CHANNELS][NUM_SMPL]; 
/////////////////////////////////////////////////////////  
  hfile = new TFile("PED.root");
  cout << "file_name: PED.root" << endl;
  tree = (TTree*)(hfile->Get("T"));  
/////////////////////////////////////////////////////////  
  tree->SetBranchAddress("data",data);
/////////////////////////////////////////////////////////
  nEntries = (int)tree->GetEntries();
  cout << "nEntries: " << std::dec<< nEntries << endl;
/////////////////////////////////////////////////////////
  for(int a=0; a<nEntries;a++){
    cout << "LoadPED("<<a+1<<"'"<<nEntries<<")"<<endl;
    tree->GetEntry(a);
    for(int i=0;i<NUM_CHANNELS;i++){
      for(int j=0;j<NUM_SMPL;j++){
        fPED[i][j] = data[i][j];
      }
    }
  }
  delete tree;
  delete hfile;
}
/////////////////////////////////////////////////////////
void STURM2Data::GenPED(){ 
  cout << "Starting GenPED processing...." << endl;
  TString xSTRING("GenPED");
  open_TFile(xSTRING);
/////////////////////////////////////////////////////////  
  double data[NUM_CHANNELS][NUM_SMPL] = {{0}};
  int ptr;
 /////////////////////////////////////////////////////////
  TFile *hfile = new TFile("PED.root","RECREATE","data file",1);
  TTree *tree = new TTree("T","data tree");
  hfile->SetCompressionLevel(0);
   // create new event
  TTree::SetBranchStyle(0); // old branch style
  tree->Branch("data",data,"data[8][64]/D");
 ///////////////////////////////////////////////////////// 
  for(int a=0; a<nEntries;a++){
    T->GetEntry(a);
    for(int i=0;i<NUM_CHANNELS;i++){
      for(int j=0;j<NUM_SMPL;j++){
	//	ptr = Raw[i][j];
	//               data[i][j] += fVLUT[i][j][ptr];
	//	if(i==0 && j==0) cout << "Raw data for Ch. 0, sample 0 = " << 1.0*Raw[i][j] << endl; 
            data[i][j] += Raw[i][j];
      }
    }
  }
 /////////////////////////////////////////////////////////
  for(int i=0;i<NUM_CHANNELS;i++){
    for(int j=0;j<NUM_SMPL;j++){
      data[i][j] /= nEntries;
      fPED[i][j] = data[i][j];
      //      if(i==0 && j==0) cout << "Calculated pedestal for Ch. 0, sample 0 = " << 1.0*fPED[i][j] << endl; 
    }
  }
  tree->Fill();
 ///////////////////////////////////////////////////////// 
  hfile->Write();
  delete tree; 
  delete hfile;
  close_TFile();
  cout << " ....done processing GenPED" << endl;
}
 ///////////////////////////////////////////////////////// 
void STURM2Data::LoadVCAL(){
  TFile *hfile;  
  TTree *tree;
  int CH,SMPL;
  double DAT[4096]; 
/////////////////////////////////////////////////////////  
  hfile = new TFile("VLUT.root");
  cout << "file_name: VLUT.root" << endl;
  tree = (TTree*)(hfile->Get("T"));  
/////////////////////////////////////////////////////////  
  tree->SetBranchAddress("VLUT",DAT);
  tree->SetBranchAddress("CH",&CH);
  tree->SetBranchAddress("SMPL",&SMPL);
/////////////////////////////////////////////////////////
  nEntries = (int)tree->GetEntries();
/////////////////////////////////////////////////////////
  for(int a=0; a<nEntries;a++){
    //cout << "LoadVCAL("<<a+1<<","<<nEntries<<")"<<endl;
    tree->GetEntry(a);
    for(int i=0;i<4096;i++){
      fVLUT[CH][SMPL][i] = DAT[i];
    }
  }
  delete tree; 
  delete hfile;
}
/////////////////////////////////////////////////////////
void STURM2Data::GenVCAL(){ 
  cout << "Starting GenVCAL processing...." << endl;
  struct stat st;
  if(stat("GenVCAL/",&st) != 0){
    gROOT->ProcessLine(".!mkdir GenVCAL");
  }
/////////////////////////////////////////////////////////   
  TString xSTRING("GenVCAL");
  open_TFile(xSTRING);
/////////////////////////////////////////////////////////  
  int CNT[NUM_DAC];
  int CH,SMPL;
  int a;
  int xDAT[NUM_DAC];
  double spline_data[NUM_DAC];
 /////////////////////////////////////////////////////////   
  c0 = new TCanvas("c0","ADC_counts_vs_Voltage Curves",0,0,1200,600);
  c0->Divide(1,1);
  ///////////////////////////////////////////////////////// 
  TFile *hfile = new TFile("VLUT.root","RECREATE","data file",1);
  TTree *tree  = new TTree("T","data tree");
  hfile->SetCompressionLevel(0);
   // create new event
  TTree::SetBranchStyle(0); // old branch style
  tree->Branch("VLUT",spline_data,"spline_data[4096]/D");
  tree->Branch("CH",&CH,"CH/I");
  tree->Branch("SMPL",&SMPL,"SMPL/I");  
 /////////////////////////////////////////////////////////   
  for(CH=0;CH<NUM_CHANNELS;CH++){
    for(SMPL=0;SMPL<NUM_SMPL;SMPL++){
      cout << "GEN_VCAL: Processing CH("<<CH+1<<":"<<NUM_CHANNELS<<") SMPL("<<SMPL+1<<":"<<NUM_SMPL<<")"<<endl;
      for(a=0; a<NUM_DAC;a++){
        CNT[a] = 0;
        xDAT[a] = 0;
        spline_data[a] = 0;
      }       
      for(a=0; a<nEntries;a++){
        T->GetEntry(a);
        CNT[PED_SCAN]++;
        xDAT[PED_SCAN] += Raw[CH][SMPL];
      }
      for(a=0; a<NUM_DAC;a++){
        if(CNT[a]!=0) xDAT[a] /= CNT[a];
      }
      for(a=0; a<nEntries;a++){
        T->GetEntry(a);
        if(Raw[CH][SMPL]<100) xDAT[PED_SCAN] = 0;
      }
      //GenVCAL_spline(CH,SMPL,xDAT,spline_data);
      GenVCAL_PLOT(CH,SMPL,xDAT,spline_data);
      for(a=0; a<NUM_DAC;a++){
        fVLUT[CH][SMPL][a] = spline_data[a];
      }
      tree->Fill();
    }
  }
  hfile->Write();
  delete tree; 
  delete hfile;
  close_TFile();
  delete c0;
  cout << " ....done processing GenVCAL" << endl;
}
/////////////////////////////////////////////////////////
void STURM2Data::GenVCAL_spline(int CH,int SMPL,int* xDAT,double* spline_data){  
  TSpline3* spline;
  int n1 = 0;
  double a1[NUM_DAC],b1[NUM_DAC];
  double sample;
  int i;
  int smpl;
  bool check[NUM_DAC];
  double upper_cutoff = 1.8*1000;
  double lower_cutoff = 0.6*1000;  
  for(i=0; i<NUM_DAC; i++){
    spline_data[i] = 0;
    check[i] = false;
    if(xDAT[i] > 100){
      sample = (double)i;
      sample *= (2500.0/4096.0);
      a1[n1] = sample;
      b1[n1] = (double)xDAT[i];
      n1++;
    }
  }  
/////////////////////////////////////////////////////////
  spline = new TSpline3("CH1",a1,b1,n1);
/////////////////////////////////////////////////////////
  for(i=0; i<NUM_DAC*10; i++){
    sample  = (double)i;
    sample /= 10.0;
    sample *= (2500.0/4096.0);
    if(sample>lower_cutoff && sample<upper_cutoff){
      //cout << sample << endl;
      smpl = (int)(spline->Eval(sample));
      if(smpl<NUM_DAC){
        if(!check[smpl]){
          spline_data[smpl] = sample;
          check[smpl] = true;
	}
      }
    }
  }
/////////////////////////////////////////////////////////    
  for(i=0; i<NUM_DAC/2; i++){
    if(spline_data[i]<lower_cutoff)
      spline_data[i] = lower_cutoff;
  }
  for(i=NUM_DAC/2; i<NUM_DAC; i++){
    if(spline_data[i]>upper_cutoff)
      spline_data[i] = upper_cutoff;
    if(spline_data[i]<10)
      spline_data[i] = upper_cutoff;
  }
  int start;
  for(i=0; i<NUM_DAC/2; i++){
    if(spline_data[i]>lower_cutoff){
      start = i;
      break;
    }
  }
  delete spline;
  n1 = 0;
  for(i=0; i<start; i++){
    a1[n1] = (double)i;
    b1[n1] = spline_data[i];
    n1++;
  }
  for(i=start; i<NUM_DAC; i++){
    if(spline_data[i]>lower_cutoff){
      a1[n1] = (double)i;
      b1[n1] = spline_data[i];
      n1++;
    }
  }
/////////////////////////////////////////////////////////
  spline = new TSpline3("CH1",a1,b1,n1);
///////////////////////////////////////////////////////// 
  for(i=0; i<NUM_DAC; i++){  
    sample  = (double)i;  
    spline_data[i] = spline->Eval(sample);
  }
  for(i=0; i<200; i++){
    spline_data[i] = upper_cutoff;
  }
  
  delete spline;
  
/////////////////////////////////////////////////////////
}
/////////////////////////////////////////////////////////
void STURM2Data::GenVCAL_PLOT(int CH,int SMPL,int* xDAT,double* spline_data){
  double sample;
/////////////////////////////////////////////////////////
  char file_name[100];
  sprintf(file_name,"IRS_CH=%d_COL=%d",CH,SMPL);
  GenVCAL_PLOT_2D = new TH2D("ADC_Count_vs_Voltage", file_name, 4096, 0, 4096, 4096, 0, 2.5);
  GenVCAL_PLOT_2D_extracted = new TH2D("ADC_Count_vs_Voltage", file_name, 4096, 0, 4096, 4096, 0, 2.5);
/////////////////////////////////////////////////////////
  for(int i=0; i<NUM_DAC; i++){
    sample = (double)i*(2.5/4096);
    GenVCAL_PLOT_2D->Fill((double)xDAT[i],sample);
    sample = (double)i;
    GenVCAL_PLOT_2D_extracted->Fill(sample,spline_data[i]/1000);
  }
/////////////////////////////////////////////////////////
  c0->cd(1); 
  GenVCAL_PLOT_2D->Draw();
  GenVCAL_PLOT_2D->GetYaxis()->SetTitle("voltage (V)");
  GenVCAL_PLOT_2D->GetYaxis()->CenterTitle();
  GenVCAL_PLOT_2D->GetXaxis()->SetTitle("ADC Count");
  GenVCAL_PLOT_2D->GetXaxis()->CenterTitle();
  GenVCAL_PLOT_2D->SetStats(kFALSE);
/////////////////////////////////////////////////////////  
  /*c0->cd(2); 
  GenVCAL_PLOT_2D_extracted->Draw();
  GenVCAL_PLOT_2D_extracted->GetYaxis()->SetTitle("voltage (V)");
  GenVCAL_PLOT_2D_extracted->GetYaxis()->CenterTitle();
  GenVCAL_PLOT_2D_extracted->GetXaxis()->SetTitle("ADC Count");
  GenVCAL_PLOT_2D_extracted->GetXaxis()->CenterTitle();
  GenVCAL_PLOT_2D_extracted->SetStats(kFALSE);*/
/////////////////////////////////////////////////////////
  gStyle->SetFillColor(kWhite);
  gStyle->SetOptFit();
/////////////////////////////////////////////////////////
  sprintf(file_name,"GenVCAL/CURVE_CH=%d_COL=%d.png",CH,SMPL);
  cout << file_name << endl;
  c0->Print(file_name);
/////////////////////////////////////////////////////////  
  delete GenVCAL_PLOT_2D_extracted;
  delete GenVCAL_PLOT_2D;	
}
/////////////////////////////////////////////////////////
void STURM2Data::open_TFile(TString filename)
{
  char file_name[99]; 
  sprintf(file_name,"%s.root",filename.Data());
  f = new TFile(file_name);
  cout << "file_name: " << file_name << endl;
  T = (TTree*)(f->Get("T"));
  
  T->SetBranchAddress("fWaveform",Waveform);
  T->SetBranchAddress("fRaw",Raw);
  T->SetBranchAddress("fPRCO_INT",&PRCO_INT);
  T->SetBranchAddress("fPROVDD",&PROVDD);
  T->SetBranchAddress("fRCO_INT",&RCO_INT);
  T->SetBranchAddress("fROVDD",&ROVDD);
  T->SetBranchAddress("fPED_SCAN",&PED_SCAN);
  T->SetBranchAddress("fDEBUG",&DEBUG);

  nEntries = (int)T->GetEntries();
  cout << "nEntries: " << nEntries << endl;
}
////////////////////////////////////////////////////////
void STURM2Data::close_TFile()
{
  delete f;
}
////////////////////////////////////////////////////////
