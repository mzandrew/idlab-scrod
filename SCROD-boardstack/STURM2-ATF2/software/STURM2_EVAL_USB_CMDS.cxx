//////////////////////////////////////
void STURM2_EVAL::SendCMDline(){
  TString CMDline;
  CMDline = fCMDline-> GetText();
  if(CMDline == "ped"){
    GenPED();
    return;
  }
  else if(CMDline == "vcal"){
    GenVCAL();
    return;
  }
  else{
    if(fOffLineMode){
      cout << "Called: STURM2_EVAL::SendCMDline("<<CMDline.Data()<<")" << endl;
    }
    retVal = xIDL_USB->SendCMDline(CMDline);
    if(fVerbose) cout << "Got "<<BoolToTString(retVal).Data()<<" for Sending USBCMD: 0x"<< CMDline.Data()<<endl;
    if(!retVal)
      fCMDline->Clear();
  }
}
//////////////////////////////////////
void STURM2_EVAL::SendSyncUSB(bool ENABLE){
  if(fOffLineMode){
    cout << "Called: STURM2_EVAL::SendSyncUSB("<<BoolToTString(ENABLE).Data()<<")"<<endl;
  }
  if(ENABLE) {
    retVal = xIDL_USB->SendUSBCMD(ENABLE_SYNC_USB_MASK);
    if(fVerbose) cout << "Got "<<BoolToTString(retVal).Data()<<" for Sending USBCMD: 0x"<< std::hex <<ENABLE_SYNC_USB_MASK<<endl;
  }
  else {
    retVal = xIDL_USB->SendUSBCMD(DISABLE_SYNC_USB_MASK);
    if(fVerbose) cout << "Got "<<BoolToTString(retVal).Data()<<" for Sending USBCMD: 0x"<< std::hex <<DISABLE_SYNC_USB_MASK<<endl;
  }
}
//////////////////////////////////////
void STURM2_EVAL::SendSoftTrig(){
  if(fOffLineMode){
    cout << "Called: STURM2_EVAL::SendSoftTrig()"<<endl;
    GEN_DUMMY_Waveform();
  }
  retVal = xIDL_USB->SendUSBCMD(SOFT_TRIG_MASK);
  if(fVerbose) cout << "Got "<<BoolToTString(retVal).Data()<<" for Sending USBCMD: 0x"<< std::hex<<SOFT_TRIG_MASK<<endl;
}
//////////////////////////////////////
void STURM2_EVAL::SendPEDSCAN(unsigned int DAC){
  if(fOffLineMode){
    cout << "Called: STURM2_EVAL::SendPEDSCAN("<<DAC<<")"<<endl;
  }
  unsigned int USBcmd;
  USBcmd = DAC << 16 | PEDSCAN_MASK;
  retVal = xIDL_USB->SendUSBCMD(USBcmd);
  if(fVerbose) cout << "Got "<<BoolToTString(retVal).Data()<<" for Sending USBCMD: 0x"<< std::hex<<USBcmd<<endl;
}
//////////////////////////////////////
void STURM2_EVAL::SendEN_PED(bool ENABLE){
  if(fOffLineMode){
    cout << "Called: STURM2_EVAL::SendEN_PED("<<BoolToTString(ENABLE).Data()<<")"<<endl;
  }
  if(ENABLE) {
    retVal = xIDL_USB->SendUSBCMD(ENABLE_PED_MASK);
    if(fVerbose) cout << "Got "<<BoolToTString(retVal).Data()<<" for Sending USBCMD: 0x"<< std::hex <<ENABLE_PED_MASK<<endl;
  }
  else {
    retVal = xIDL_USB->SendUSBCMD(DISABLE_PED_MASK);
    if(fVerbose) cout << "Got "<<BoolToTString(retVal).Data()<<" for Sending USBCMD: 0x"<< std::hex <<DISABLE_PED_MASK<<endl;
  }
}
//////////////////////////////////////
void STURM2_EVAL::SendVCAL(bool ENABLE){
  if(fOffLineMode){
    cout << "Called: STURM2_EVAL::SendVCAL("<<BoolToTString(ENABLE).Data()<<")"<<endl;
  }
  if(ENABLE) {
    retVal = xIDL_USB->SendUSBCMD(ENABLE_VCAL_MASK);
    if(fVerbose) cout << "Got "<<BoolToTString(retVal).Data()<<" for Sending USBCMD: 0x"<< std::hex<<ENABLE_VCAL_MASK<<endl;
  }
  else {
    retVal = xIDL_USB->SendUSBCMD(DISABLE_VCAL_MASK);
    if(fVerbose) cout << "Got "<<BoolToTString(retVal).Data()<<" for Sending USBCMD: 0x"<< std::hex<<DISABLE_VCAL_MASK<<endl;
  }
}
//////////////////////////////////////
void STURM2_EVAL::SendDEBUG(unsigned int value){
  TString temp;
  if(fOffLineMode){
    cout << "Called: STURM2_EVAL::SendDEBUG("<<value<<")"<<endl;
  }
  unsigned int USBcmd;
  USBcmd = value << 16 | DEBUG_MASK;
  retVal = xIDL_USB->SendUSBCMD(USBcmd);
  if(fVerbose) cout << "Got "<<BoolToTString(retVal).Data()<<" for Sending USBCMD: 0x"<< std::hex<<USBcmd<<endl;
}
//////////////////////////////////////
TString STURM2_EVAL::BoolToTString(bool value){
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
int STURM2_EVAL::ReadUSB(bool dumpHex, bool display_data){
  int return_value;
  return_value = xIDL_USB->ReadUSBBuffer(dumpHex);
  if(!fOffLineMode){
    for(int i=0;i<BUFFERSIZE;i++){
      fReadoutBuffer[i] = xIDL_USB->GetBuffer(i);
      if(display_data){
        cout<< std::hex<<fReadoutBuffer[i]<<",";
      }
    }
    xSTURM2Data->unpackData(fReadoutBuffer);
    fPRCO_INT = xSTURM2Data->Get_PRCO_INT();
    fPROVDD = xSTURM2Data->Get_PROVDD();
    fRCO_INT = xSTURM2Data->Get_RCO_INT();
    fROVDD = xSTURM2Data->Get_ROVDD();
    fPED_SCAN = xSTURM2Data->Get_PED_SCAN();
    fDEBUG = xSTURM2Data->Get_DEBUG();
    for(int i=0;i<NUM_CHANNELS;i++){
      for(int j=0;j<NUM_SMPL;j++){
        fWaveform[i][j] = xSTURM2Data->Get_fWaveform(i,j);
	fRaw[i][j]  = xSTURM2Data->Get_Raw(i,j);
      }
    } 
  }
  if(display_data) cout<< endl;
  return return_value;
}
//////////////////////////////////////