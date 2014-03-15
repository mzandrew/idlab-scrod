#ifndef CRTPEDESTALLUT_CC
#define CRTPEDESTALLUT_CC

CRTPedestalLUT::CRTPedestalLUT(TString pedestalFileName, Int_t numberOfElectronicsModules, Int_t numberOfAsicRows, Int_t numberOfAsicColumns, Int_t numberOfAsicChannels, Int_t numberOfWindows, Int_t numberOfSamples, bool check) {
  //constructor

  m_numberOfElectronicsModules = numberOfElectronicsModules;
  m_numberOfAsicRows = numberOfAsicRows;
  m_numberOfAsicColumns = numberOfAsicColumns;
  m_numberOfAsicChannels = numberOfAsicChannels;
  m_numberOfWindows = numberOfWindows;
  m_numberOfSamples = numberOfSamples;

  m_check = check; 
  m_maxWarnings = 10;
  m_numberOfWarnings = 0;
  
  m_pedestalFile = new TFile(pedestalFileName);
  if (!m_pedestalFile || m_pedestalFile->IsZombie()) {
    std::cerr << "Error: Could not open file " << pedestalFileName << std::endl;
  }

  m_pedestalTree = (TTree*) m_pedestalFile->Get("PedestalTree");
  if (!m_pedestalTree) {
    std::cerr << "Error: PedestalTree from file " << pedestalFileName << " does not appear to have loaded properly."  << std::cerr << "This is likely to cause a segmentation violation." << std::endl;
  }
  
  m_pedestalTree->SetBranchAddress("eModule", &m_pedestalEModule);
  m_pedestalTree->SetBranchAddress("asicRow", &m_pedestalAsicRow);
  m_pedestalTree->SetBranchAddress("asicCol", &m_pedestalAsicCol);	          
  m_pedestalTree->SetBranchAddress("asicCh", &m_pedestalAsicCh);
  m_pedestalTree->SetBranchAddress("window", &m_pedestalWindow);
  m_pedestalTree->SetBranchAddress("sample", &m_pedestalSample);
  m_pedestalTree->SetBranchAddress("mean", &m_pedestalMean);
  m_pedestalTree->SetBranchAddress("RMS", &m_pedestalRMS);

  m_pedestalTreeEntries = m_pedestalTree->GetEntries();
  
  if (m_pedestalTreeEntries != m_numberOfElectronicsModules*m_numberOfAsicRows*m_numberOfAsicColumns*m_numberOfAsicChannels*m_numberOfWindows*m_numberOfSamples) {
    std::cerr << "Warning: number of entries in PedestalTree is not equal to product of numbers of elements specified.  This may cause look up calls to become slower." << std::endl;
  }

}


CRTPedestalLUT::~CRTPedestalLUT() {
  //Destructor
  m_pedestalFile->Close();
  delete m_pedestalFile;
}


Float_t CRTPedestalLUT::GetMean(Int_t eModule, Int_t asicRow, Int_t asicCol, Int_t asicCh, Int_t window, Int_t sample) {
  Long64_t entry(this->GetEntry(eModule, asicRow, asicCol, asicCh, window, sample));
  if (entry != -1) {
    m_pedestalTree->GetEntry(entry);
    return m_pedestalMean;
  }
  return -1;
}

Float_t CRTPedestalLUT::GetRMS(Int_t eModule, Int_t asicRow, Int_t asicCol, Int_t asicCh, Int_t window, Int_t sample) {
  Long64_t entry(this->GetEntry(eModule, asicRow, asicCol, asicCh, window, sample));
  if (entry != -1) {
    m_pedestalTree->GetEntry(entry);
    return m_pedestalRMS;
  }
  return -1;
}      


std::pair<Float_t, Float_t> CRTPedestalLUT::GetMeanAndRMS(Int_t eModule, Int_t asicRow, Int_t asicCol, Int_t asicCh, Int_t window, Int_t sample) {
  Long64_t entry(this->GetEntry(eModule, asicRow, asicCol, asicCh, window, sample));
  if (entry != -1) {
    m_pedestalTree->GetEntry(entry);
    return std::pair<Float_t, Float_t>(m_pedestalMean, m_pedestalRMS);
  }
  return std::pair<Float_t, Float_t>(-1, -1);
}



Long64_t CRTPedestalLUT::GetEntry(Int_t eModule, Int_t asicRow, Int_t asicCol, Int_t asicCh, Int_t window, Int_t sample) {

   Long64_t entryToGet(sample + m_numberOfSamples*window + m_numberOfSamples*m_numberOfWindows*asicCh +  m_numberOfSamples*m_numberOfWindows*m_numberOfAsicChannels*asicCol + m_numberOfSamples*m_numberOfWindows*m_numberOfAsicChannels*m_numberOfAsicColumns*asicRow + m_numberOfSamples*m_numberOfWindows*m_numberOfAsicChannels*m_numberOfAsicColumns*m_numberOfAsicRows*eModule);
   if (entryToGet > m_pedestalTreeEntries-1) {return -1;}
   
   if (!m_check) {return entryToGet;}

   m_pedestalTree->GetEntry(entryToGet);
   
   if (eModule == m_pedestalEModule && asicRow == m_pedestalAsicRow && asicCol == m_pedestalAsicCol && asicCh == m_pedestalAsicCh && window == m_pedestalWindow && sample == m_pedestalSample) { 
     return entryToGet;
   } else {
     if (m_numberOfWarnings < m_maxWarnings) {
       std::cerr << "Warning in CRTPedestalLUT::GetEntry:  Fast look up of entries has failed.  Reverting to a slower method.  This warning will appear a maximum of " << m_maxWarnings << " times." << std::endl;
       ++m_numberOfWarnings;
     }
   }

   //Fast lookup failed - Use slow method of looping through every entry:
   Long64_t entryFound(-1);
   for (Int_t p(0); p<m_pedestalTreeEntries;  ++p) {
     m_pedestalTree->GetEntry(p);
     if (eModule == m_pedestalEModule && asicRow == m_pedestalAsicRow && asicCol == m_pedestalAsicCol && asicCh == m_pedestalAsicCh && window == m_pedestalWindow && sample == m_pedestalSample) { 
       entryFound = p;
       break;}
     }
   if (entryFound != -1) {return entryFound;}

   return -1;

} 


#endif
