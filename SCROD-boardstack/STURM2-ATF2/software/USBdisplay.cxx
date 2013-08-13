#include "USBdisplay.h" 
//////////////////////////////////////
MainFrame::MainFrame(const TGWindow *p, bool verbose, bool OffLineMode){
  width = 100;
  height = 100;
  fVerbose = verbose;
  fOffLineMode = OffLineMode;
  //////////////////////////////////////
  // Create test main frame. A TGMainFrame is a top level window.
  //////////////////////////////////////
  fMain = new TGMainFrame(p, 100, 100);
  fMain->SetWindowName("USBtester");
  //////////////////////////////////////
  // use hierarchical cleaning
  //////////////////////////////////////
  fMain->SetCleanup(kDeepCleanup);
  fMain->Connect("CloseWindow()", "MainFrame", this, "CloseWindow()");
  //////////////////////////////////////
  // Create GUI Widgets
  //////////////////////////////////////
  Create_Menu();
  Create_Oscope();
  Create_StatusBar();
  //////////////////////////////////////
  fMain->MapSubwindows();
  fMain->Resize();
  fMain->MapWindow();
  //////////////////////////////////////
  xSTURM2_EVAL = new STURM2_EVAL(fVerbose,fOffLineMode,fCMDline,fStatusBar);
  //////////////////////////////////////  

  Oscope_Draw(); 
}
//////////////////////////////////////
MainFrame::~MainFrame(){
  //////////////////////////////////////
  // Delete all created widgets.
  //////////////////////////////////////
  delete xSTURM2_EVAL;
  delete fMain;
  
  delete fMenuDock;
  delete fMenuBarLayout;
  delete fMenuBarItemLayout;
  delete fMenuBarHelpLayout;
  delete fMenuFile;
  delete fMenuHelp;
  delete fMenuBar;
  
  delete fStatusBar;
  delete fSendButton;
  delete fCMDline;

  delete fCanvasFrame;
  delete fEcanvas;
  
  delete fButtonGroup_CH_EN;
  delete fCH_EN;
  
  delete fEN_DISPLAY;
  delete fButtonSoftTrig;
  delete fButtonExtTrig;
  delete fButtonPED;
  delete fButtonVCAL;
  delete fButtonLOG_DATA;
  
  delete mg;
}
//////////////////////////////////////
void MainFrame::CloseWindow(){
  ////////////////////////////////////// 
  // Got close message for this MainFrame. Terminates the application.
  //////////////////////////////////////
  gApplication->Terminate();
}
//////////////////////////////////////
void MainFrame::Create_Menu(){
  ////////////////////////////////////// 
  // Create menubar and popup menus. The hint objects are used to place
  // and group the different menu widgets with respect to eachother.
  //////////////////////////////////////
  fMenuDock = new TGDockableFrame(fMain);
  fMain->AddFrame(fMenuDock, new TGLayoutHints(kLHintsExpandX, 0, 0, 1, 0));
  fMenuDock->SetWindowName("USBtester");
  //////////////////////////////////////
  fMenuBarLayout = new TGLayoutHints(kLHintsTop | kLHintsExpandX);
  fMenuBarItemLayout = new TGLayoutHints(kLHintsTop | kLHintsLeft, 0, 4, 0, 0);
  fMenuBarHelpLayout = new TGLayoutHints(kLHintsTop | kLHintsRight);
  //////////////////////////////////////
  fMenuFile = new TGPopupMenu(gClient->GetRoot());
  fMenuFile->AddEntry("E&xit", M_FILE_EXIT);
  //////////////////////////////////////
  fMenuHelp = new TGPopupMenu(gClient->GetRoot());
  fMenuHelp->AddEntry("&About", M_HELP_ABOUT);
  //////////////////////////////////////
  // Menu button messages are handled by the main frame (i.e. "this")
  // HandleMenu() method.
  //////////////////////////////////////
  fMenuFile->Connect("Activated(Int_t)", "MainFrame", this,"HandleMenu(Int_t)");
  fMenuHelp->Connect("Activated(Int_t)", "MainFrame", this,"HandleMenu(Int_t)");
  //////////////////////////////////////
  fMenuBar = new TGMenuBar(fMenuDock, 1, 1, kHorizontalFrame);
  fMenuBar->AddPopup("&File", fMenuFile, fMenuBarItemLayout);
  fMenuBar->AddPopup("&Help", fMenuHelp, fMenuBarHelpLayout);
  //////////////////////////////////////
  fMenuDock->AddFrame(fMenuBar, fMenuBarLayout);
  //////////////////////////////////////				  
}
//////////////////////////////////////
void MainFrame::Create_Oscope(){
  Pixel_t white = gVirtualX->GetPixel(0);
  //////////////////////////////////////
  // Create frame containing a canvas widget
  //////////////////////////////////////
  fCanvasFrame = new TGCompositeFrame(fMain, 100, 100, kHorizontalFrame|kSunkenFrame);
  fCanvasFrame->SetBackgroundColor(white);
  fEcanvas = new TRootEmbeddedCanvas("Ecanvas",fCanvasFrame,600,400); 
  fEcanvas->SetBackgroundColor(white);
  fCanvasFrame->AddFrame(fEcanvas, new TGLayoutHints(kLHintsExpandX | kLHintsExpandY,0, 0, 0, 0));
  //////////////////////////////////////
  fEN_DISPLAY = new TGCheckButton(fCanvasFrame, new TGHotString("Enable Display"), IDs.GetUnID());
  fEN_DISPLAY->SetBackgroundColor(white);
  fEN_DISPLAY->SetToolTipText("Enable/Disable Oscope Display");
  fEN_DISPLAY->Connect("Toggled(Bool_t)", "MainFrame", this, "SetGroupEnabled_CH_EN(Bool_t)");
  fEN_DISPLAY->Connect("Toggled(Bool_t)", "MainFrame", this, "Oscope_Draw()");
  fEN_DISPLAY->SetState(kButtonDown);
  fCanvasFrame->AddFrame(fEN_DISPLAY, new TGLayoutHints(kLHintsTop, 0, 10, 10, 0));
  //////////////////////////////////////  
  fButtonGroup_CH_EN = new TGVButtonGroup(fCanvasFrame, "Display CH");
  fButtonGroup_CH_EN->SetBackgroundColor(white);
  char ch_name[99];
  for(int i=0; i<NUM_CHANNELS; i++){
    sprintf(ch_name,"CH %d",i);
    fCH_EN[i] = new TGCheckButton(fButtonGroup_CH_EN, new TGHotString(ch_name), IDs.GetUnID());
    fCH_EN[i]->SetBackgroundColor(white);
    fCH_EN[i]->SetState(kButtonDown);
    Pixel_t text_color = gVirtualX->GetPixel(i+1);
    fCH_EN[i]->SetTextColor(text_color,false);
    fCH_EN[i]->Connect("Clicked()","MainFrame",this,"Oscope_Draw()"); 
  }
  for(int i=2; i<NUM_CHANNELS; i++){
    fCH_EN[i]->SetState(kButtonUp);
  }
  fButtonGroup_CH_EN->Show();
  fCanvasFrame->AddFrame(fButtonGroup_CH_EN, new TGLayoutHints( kLHintsRight, 0, 10, 10, 0));
  //////////////////////////////////////
  fMain->AddFrame(fCanvasFrame, new TGLayoutHints(kLHintsExpandX | kLHintsExpandY,10, 0, 10, 0));
  //////////////////////////////////////
  fBottomButtonsFrame = new TGHorizontalFrame(fMain, 1, 1, kHorizontalFrame|kSunkenFrame);
  //fBottomButtonsFrame->SetBackgroundColor(white);
  fButtonSoftTrig = new TGTextButton(fBottomButtonsFrame,"S&oftTrig"); 
  fButtonSoftTrig->Connect("Clicked()","MainFrame",this,"SoftTrig()"); 
  fBottomButtonsFrame->AddFrame(fButtonSoftTrig, new TGLayoutHints(kLHintsCenterX | kLHintsCenterY,0,0,0,10));
  //////////////////////////////////////
  fButtonExtTrig = new TGTextButton(fBottomButtonsFrame,"&ExtTrig"); 
  fButtonExtTrig->Connect("Clicked()","MainFrame",this,"ExtTrig()"); 
  fBottomButtonsFrame->AddFrame(fButtonExtTrig, new TGLayoutHints(kLHintsCenterX | kLHintsCenterY,0,1,0,10));
  //////////////////////////////////////
  fButtonPED = new TGTextButton(fBottomButtonsFrame,"&Ped"); 
  fButtonPED->Connect("Clicked()","MainFrame",this,"PED()"); 
  fBottomButtonsFrame->AddFrame(fButtonPED, new TGLayoutHints(kLHintsCenterX | kLHintsCenterY,0,2,0,10));
  //////////////////////////////////////
  fButtonVCAL = new TGTextButton(fBottomButtonsFrame,"&VCAL"); 
  fButtonVCAL->Connect("Clicked()","MainFrame",this,"VCAL()"); 
  fBottomButtonsFrame->AddFrame(fButtonVCAL, new TGLayoutHints(kLHintsCenterX | kLHintsCenterY,0,3,0,10));
  //////////////////////////////////////
  fButtonLOG_DATA = new TGTextButton(fBottomButtonsFrame,"&LOG_DATA"); 
  fButtonLOG_DATA->Connect("Clicked()","MainFrame",this,"LOG_DATA()");
  fBottomButtonsFrame->AddFrame(fButtonLOG_DATA, new TGLayoutHints(kLHintsCenterX | kLHintsCenterY,0,4,0,10));
  //////////////////////////////////////
  fMain->AddFrame(fBottomButtonsFrame, new TGLayoutHints(kLHintsCenterX,10, 0, 5, 0));
  //////////////////////////////////////
  // Create status frame containing a button and a text entry widget
  //////////////////////////////////////
  fCMDlineFrame = new TGCompositeFrame(fMain, 10, 10, kHorizontalFrame|kSunkenFrame);
  //////////////////////////////////////
  fSendButton = new TGTextButton(fCMDlineFrame, "&Send", 10);
  fSendButton->Connect("Clicked()", "MainFrame", this, "SendCMD()");
  fSendButton->SetToolTipText("Send HEX CMD");
  fCMDlineFrame->AddFrame(fSendButton, new TGLayoutHints(kLHintsTop|kLHintsLeft, 2, 0, 2, 2));
  //////////////////////////////////////
  fCMDline = new TGTextEntry(fCMDlineFrame, new TGTextBuffer(100));
  fCMDline->Connect("ReturnPressed()", "MainFrame", this, "SendCMD()");
  fCMDline->SetToolTipText("Insert HEX CMD here");
  fCMDline->Resize(300, fCMDline->GetDefaultHeight());
  fCMDlineFrame->AddFrame(fCMDline, new TGLayoutHints(kLHintsTop | kLHintsExpandX,10, 2, 2, 2));   
  //////////////////////////////////////
  fMain->AddFrame(fCMDlineFrame, new TGLayoutHints( kLHintsExpandX,0, 0, 0, 10));  
}
//////////////////////////////////////
void MainFrame::Create_StatusBar(){
  fStatusBar = new TGStatusBar(fMain, 50, 10, kVerticalFrame);
  fStatusBar->Draw3DCorner(kFALSE);
  fMain->AddFrame(fStatusBar, new TGLayoutHints(kLHintsBottom | kLHintsExpandX, 0, 0, 0, 10));
  fStatusBar->SetText("IDLE");
}
//////////////////////////////////////
void MainFrame::HandleMenu(Int_t id){
  //////////////////////////////////////
  // Handle menu items.
  //////////////////////////////////////
  switch(id){
    case M_FILE_EXIT:// terminate theApp no need to use SendCloseMessage()
      CloseWindow();
      break;
    case M_HELP_ABOUT:
      Show_About_POPUP();
      break; 
    default:
      printf("Menu item %d selected\n", id);
      break;
   }
}
//////////////////////////////////////
void MainFrame::Oscope_Draw() { 
  //  if(fEN_DISPLAY->GetState() == kButtonUp) return; 
  delete mg;
  mg = new TMultiGraph();
  mg->SetTitle("Oscope Display");
  
  TGraph *gr[NUM_SMPL];
  const Int_t n = NUM_SMPL;
  double x[NUM_SMPL],y[NUM_SMPL];
  bool Something_Drawn;
  Something_Drawn = false;
  for(int i=0; i<NUM_CHANNELS; i++){ 
    if(fCH_EN[i]->GetState() == kButtonDown){
      Something_Drawn = true;
      for(int j=0; j<NUM_SMPL; j++){
        x[j] = (double)j;
        y[j] = xSTURM2_EVAL->Get_Waveform(i,j);
      }
      gr[i] = new TGraph(n,x,y);
      gr[i]->SetLineColor(i+1);
      gr[i]->SetLineWidth(2);
      gr[i]->SetMarkerColor(i+1);
      gr[i]->SetMarkerStyle(8);
      gr[i]->SetFillColor(0);
      mg->Add(gr[i]);
      
    }
  }
  if(Something_Drawn){
    //   cout << "Something_Drawn" << endl;
    mg->Draw("A");
    mg->GetYaxis()->SetRangeUser(-500,500);
    //    mg->GetXaxis()->SetTitle("time (ns)"); --GSV
    mg->GetXaxis()->SetTitle("Sample number (4x TSA, 8 samples each)");
    mg->GetXaxis()->CenterTitle();
    //    mg->GetYaxis()->SetTitle("voltage (mV)"); --GSV
    mg->GetYaxis()->SetTitle("ADC count value (raw counts)");
    mg->GetYaxis()->CenterTitle(); 
    mg->Draw("ALP");
  }
  //////////////////////////////////////
  
  TCanvas *fCanvas = fEcanvas->GetCanvas(); 
  fCanvas->SetFillColor(0);  
  fCanvas->cd(); 
  fCanvas->Update();
  fCanvas->Modified();   
} 
//////////////////////////////////////
void MainFrame::SetGroupEnabled_CH_EN(Bool_t on)
{
  EN_DISPLAY = on;
  fButtonGroup_CH_EN->SetState(on);
}
//////////////////////////////////////
void MainFrame::Show_About_POPUP(){
  TRootHelpDialog *hd = new TRootHelpDialog(fMain, "About...",250, 50);
  hd->SetText("by Larry Ruckamn, April 2010");
  hd->Popup();
}
//////////////////////////////////////
void MainFrame::SendCMD(){ 
  fStatusBar->SetText("SendCMD()");
  xSTURM2_EVAL->SendCMDline();
  fStatusBar->SetText("IDLE");
} 
/////////////////////////////////////
void MainFrame::SoftTrig(){
  fStatusBar->SetText("SoftTrig()");
  xSTURM2_EVAL->SendSoftTrig();
  xSTURM2_EVAL->ReadUSB(true,true);
  Oscope_Draw();
  fStatusBar->SetText("IDLE");
}
/////////////////////////////////////
void MainFrame::ExtTrig(){
  fStatusBar->SetText("ExtTrig()");
  fStatusBar->SetText("IDLE");
}
/////////////////////////////////////
void MainFrame::PED(){
  fStatusBar->SetText("PED()");
  xSTURM2_EVAL->GenPED();
  fStatusBar->SetText("IDLE");
}
/////////////////////////////////////
void MainFrame::VCAL(){
  fStatusBar->SetText("VCAL()");
  xSTURM2_EVAL->GenVCAL();
  fStatusBar->SetText("IDLE");
}
/////////////////////////////////////
void MainFrame::LOG_DATA(){
  fStatusBar->SetText("LOG_DATA()");
  xSTURM2_EVAL->LOG_DATA();
  fStatusBar->SetText("IDLE");
}
/////////////////////////////////////
