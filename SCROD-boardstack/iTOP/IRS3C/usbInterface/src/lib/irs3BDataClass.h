#ifndef IRS3BDATACLASS__H
#define IRS3BDATACLASS__H

#include <TGraph.h>
#include <TH2S.h>
#include <TCanvas.h>
#include <vector>

//define global constants
#define MAX_SEGMENTS_PER_EVENT 512
#define POINTS_PER_WAVEFORM    64
#define MEMORY_DEPTH           64
#define NCOLS                  4
#define NROWS                  4
#define NCHS                   8
#define NWORDS_EVENT_HEADER    11
#define NWORDS_WAVE_PACKET     42
#define NELECTRONICSMODULES    4

class irs3BDataClass {
private:
public:

	int firstWindowNum;
	TGraph *grCh;
	TGraph *grChRef;
	TH2S *hPed;
	TCanvas *cData;
	double ped[64*64];
	std::vector<double> pulseTimes;
	std::vector<double> pulseFallTimes;

	irs3BDataClass();
  	~irs3BDataClass();
	int loadDataPacket(unsigned int wavedatabuf[], int wavedataSize);
	int processWaveform(unsigned int *buffer_uint, int bufPos, int sizeInUint32);
	int fillPedestal();
	int getPedestalValues();
	int resetPedestalValues();
	int findPulseTimesFixedThreshold(double threshold, int minSamp, int maxSamp);
};

#endif
