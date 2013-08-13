#include "IDL_USB.h"
#include "stdUSB.h"
stdUSB fTheUsb;
//////////////////////////////////////
IDL_USB::IDL_USB(bool OffLineMode,bool Verbose){
  fOffLineMode = OffLineMode;
  fVerbose = Verbose;
}
//////////////////////////////////////
IDL_USB::~IDL_USB()
{}
//////////////////////////////////////
void IDL_USB::ShowErrorMessage(TString ErrorText){
  if(fVerbose){
    cout << "Called: IRS_EVAL::ShowErrorMessage();" << endl;
  }
  TRootHelpDialog *hd = new TRootHelpDialog(0, "Error!?!",250, 250);
  hd->SetText(ErrorText.Data());
  hd->Popup();
}
//////////////////////////////////////
TString IDL_USB::BoolToTString(bool value){
  TString xTrue("true");
  TString xFalse("false");
  if(value){
    return xTrue;
  }
  else{
    return xFalse;
  }
}
//////////////////////////////////////
int IDL_USB::ReadUSBBuffer(bool DumpData){
  TString temp;
  if(fOffLineMode){
    if(fVerbose) cout << "Called: IRS_EVAL::ReadUSBBuffer("<< BoolToTString(DumpData)<<");" << endl;
    return 1;
  }
   //////////////////////////////////////
  //This only read the data from the USB thingy and sticks it into fReadoutBuffer
  //////////////////////////////////////
  //Zero fReadoutBuffer
  memset(fReadoutBuffer,0,BUFFERSIZE*sizeof(unsigned short));
  //////////////////////////////////////
  int bytesRead=0;
  if (fTheUsb.createHandles() != stdUSB::SUCCEED) {
    ShowErrorMessage("USB failed to initalize.\n");
  }
  //////////////////////////////////////
  bool retVal=fTheUsb.readData(fReadoutBuffer, BUFFERSIZE, &bytesRead);
  if(retVal!=stdUSB::SUCCEED) { 
    sleep(1);
    retVal=fTheUsb.readData(fReadoutBuffer, BUFFERSIZE, &bytesRead);
  }
  fTheUsb.freeHandles();
  //////////////////////////////////////
  if(bytesRead<BUFFERSIZE){	
    if(fVerbose) cout << "Only read " <<  bytesRead << " of " << BUFFERSIZE << endl;
    return -1;
  }
  //////////////////////////////////////
  if(DumpData) {
    ofstream HexDump("eventHexDump.txt");
    for(int i=0;i<BUFFERSIZE;i++) {
      HexDump << std::dec << i << "\t" << std::hex << "\t" << fReadoutBuffer[i] << "\n";
    }
  }
  return 0;
}
//////////////////////////////////////
bool IDL_USB::SendUSBCMD(unsigned int value){
  TString temp;
  char hex_value[99];
  sprintf(hex_value,"%x",(int)value);
  if(fOffLineMode){
    if(fVerbose) cout << "Called: IRS_EVAL::SendUSBCMD(0x" <<  hex_value << ");" << endl;
    return true;
  }
  if (fTheUsb.createHandles() != stdUSB::SUCCEED) {
    ShowErrorMessage("USB failed to initalize.\n");
  }
  bool retVal=fTheUsb.sendData(value);
  fTheUsb.freeHandles();
  return retVal;
}
//////////////////////////////////////
bool IDL_USB::SendCMDline(TString CMDline)
{
  TString temp = CMDline;
  char *temp2;
  int i;
  unsigned long tempdata;
  unsigned int ManualData = 0;
  temp.ToLower();
  temp2 = (char*)temp.Data();
  //Go through the character array to snoop about for characters other than digits and letters
  //from 'A' to 'F' (upper and lower case). We want to use hexadecimal values.
  for(i=0;i<(int)temp.Length();i++){   
    if(((temp2[i] < '0') || (temp2[i] > '9')) && ((temp2[i] < 'a') || (temp2[i] > 'f'))){
	  ShowErrorMessage("Invalid input\n");
	  return false;
    }
  }
  //Empty textfield will yield a message stating that there's nothing to read.
  if(temp == TString("")){
    ShowErrorMessage("The field is empty.\n");
    return false;
  }
  else{	//Display the data that's to be sent.
    tempdata = strtoul(temp2,NULL,16);//Read the hex value from "temp" string buffer.
    //cout << std::hex << tempdata << endl;
    ManualData = (unsigned int) tempdata;	
    bool retVal=SendUSBCMD(ManualData);
    return retVal;
  }
}  
//////////////////////////////////////