#ifndef USBdisplay_H
#define USBdisplay_H
//ROOT includes
#include <TROOT.h>
#include <TApplication.h>
#include <TVirtualX.h>
#include <TVirtualPadEditor.h>
#include <TGClient.h>
#include <TGFrame.h>
#include <RQ_OBJECT.h>

#include <TGButton.h>
#include <TGButtonGroup.h>

#include <TGTextEntry.h>
#include <TGTextView.h>
#include <TGMsgBox.h>
#include <TGMenu.h>
#include <TGStatusBar.h>
#include <TGDockableFrame.h>
#include <TGTextEdit.h>

#include <TRootEmbeddedCanvas.h>
#include <TGCanvas.h>
#include <TCanvas.h>
#include <TMultiGraph.h>
#include <TGraph.h>
#include <TF1.h>
#include <TH1F.h>
#include <TRandom.h>
#include <TMath.h>

#include <TRootHelpDialog.h>
#include <TString.h>
#include <TGText.h>
//user includes
#include <stdlib.h>
#include "Riostream.h"
#include "Defs.h"
#include "STURM2_EVAL.h"
//////////////////////////////////////
enum ETestCommandIdentifiers {
   M_FILE_EXIT,
   M_HELP_ABOUT,
};
//////////////////////////////////////
class IDList {
private:
   Int_t nID;   // creates unique widget's IDs
public:
   IDList() : nID(0) {}
   ~IDList() {}
   Int_t GetUnID(void) { return ++nID; }
};
//////////////////////////////////////
class MainFrame {
  RQ_OBJECT("MainFrame")
  //////////////////////////////////////
 private:
  TGMainFrame        *fMain;
  TGDockableFrame    *fMenuDock;
  TGCompositeFrame   *fCMDlineFrame;
  TGCompositeFrame   *fCanvasFrame;
  TGHorizontalFrame  *fBottomButtonsFrame;
  /////////////////////////////////////
  TGCanvas           *fCanvasWindow;
  TGTextEntry        *fCMDline;
  TGButton           *fSendButton;
  TGStatusBar        *fStatusBar;
  TRootEmbeddedCanvas *fEcanvas;
  /////////////////////////////////////
  TGMenuBar          *fMenuBar;
  TGLayoutHints      *fMenuBarLayout, *fMenuBarItemLayout, *fMenuBarHelpLayout;
  TGPopupMenu        *fMenuFile, *fMenuHelp;
  /////////////////////////////////////
  TGVButtonGroup     *fButtonGroup_CH_EN;  // Button group
  TGCheckButton      *fCH_EN[8], *fEN_DISPLAY;    // Check buttons
  /////////////////////////////////////
  TGTextButton       *fButtonSoftTrig,*fButtonExtTrig,
                     *fButtonPED,*fButtonVCAL,*fButtonLOG_DATA;
  /////////////////////////////////////
  IDList             IDs;// Widget IDs generator 
  UInt_t width, height;
  TMultiGraph *mg;
  /////////////////////////////////////
  STURM2_EVAL *xSTURM2_EVAL;
  bool fVerbose;
  bool fOffLineMode;
  //////////////////////////////////////
 public:
  MainFrame(const TGWindow *p, bool verbose, bool OffLineMode);
  virtual ~MainFrame();
  void CloseWindow();
  /////////////////////////////////////
  void HandleMenu(Int_t id);
  void Created() { Emit("Created()"); } //*SIGNAL*
  void Welcome() { printf("MainFrame has been created. Welcome!\n"); }
  void Show_About_POPUP();
  //////////////////////////////////////
  void Create_Menu();
  void Create_StatusBar();
  void Create_Oscope();
  //////////////////////////////////////
  void Oscope_Draw();
  void SetGroupEnabled_CH_EN(Bool_t on);
  bool EN_DISPLAY;
  //////////////////////////////////////
  void SendCMD();
  void SoftTrig();
  void ExtTrig();
  void PED();
  void VCAL();
  void LOG_DATA();
  //////////////////////////////////////
};
#endif //USBdisplay_H

