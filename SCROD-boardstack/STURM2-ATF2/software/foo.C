gROOT->Reset();
TFile *file1 = new TFile("data.root");
T->Draw("fWaveform[0]");
T->Draw("fWaveform[0][1]");
T->Draw("fWaveform[0][1]:fWaveform[0][2]");

