#include "IRS3Bana.hxx"

using namespace std;

IRS3Bana::IRS3Bana(){
	g = new TGraph();
	f1 = new TF1("f1","gaus");
}

IRS3Bana::~IRS3Bana(){
	delete g;
	delete f1;
}

bool IRS3Bana::MakeWaveform(float PSsamples[NSamples]){
	int i = 0;
	double val_x = 0;
	double val_y = 0;

	g -> Set(0);
  
	for(i = 0;i < NSamples;i++){
		val_x = (double)i;
		val_y = PSsamples[i];
		g -> SetPoint(i,val_x,val_y);
  	}

  	return true;
}

bool IRS3Bana::AlignWaveform(short int firstWindow,short int refWindow,short int camacTDC, int iModule,int iRow,int iCol){

  int i = 0;
  int N = g -> GetN();
  double val_x = 0;
  double val_y = 0;
  double temp_x[NSamples];
  double temp_y[NSamples];
  
  if(refWindow < 0 || refWindow > MEMORY_DEPTH){
    cerr << "Error: the module number must be 0 to " << MEMORY_DEPTH << ". Current value: " << refWindow << endl;
    return false;
  }

  if(firstWindow < 0 || firstWindow > MEMORY_DEPTH){
    cerr << "Error: the module number must be 0 to " << MEMORY_DEPTH << ". Current value: " << firstWindow << endl;
    return false;
  }

  for(i = 0;i < N;i++){
    g -> GetPoint(i,val_x,val_y);
    temp_x[i] = val_x;
    temp_y[i] = val_y;
  }

  g -> Set(0);

  //get sampling rate
  double samplePeriod = 1000./2.715;
  double FTSW_TDC_SCALE = 45.056; //ps per TDC count, ELOG 551
  double phase_ns = double(camacTDC) * FTSW_TDC_SCALE; //ps, sampling clock phase correcction
  
  for(i = 0;i < N;i++){
    val_x = ( temp_x[i] + ((firstWindow - refWindow + 64) % 64) * 64)*samplePeriod + phase_ns; //ps, new implementation
    val_y = temp_y[i];
    g -> SetPoint(i,val_x,val_y);
  }
  
  return true;
}

void IRS3Bana::SearchPeakSampleNumber(int &MaxSampleNum, double &MaxSampleValue){

  int i = 0;
  int N = g -> GetN();
  double val1 = 0;
  double val2 = 0;
  double max = -4100;
  MaxSampleNum = 9999;

  if(NSamples < N){
    cerr << "Error: the number of points (" << N << ") is larger than " << NSamples << endl;
    return;
  }else if(NSamples > N){
    cerr << "Warning: the number of points (" << N << ") is smaller than expected (" << NSamples << ")." << endl;
    return;
  }
  
  for(i = 0;i < N;i++){
    g -> GetPoint(i,val1,val2);
    if(max < val2){
      max = val2;
      MaxSampleNum = i;
    }
  }
  MaxSampleValue = max;
 
  return;
}

int IRS3Bana::FindThresholdSampleAndTime(int start_sample, double target_value, double &threshold_sample, double &threshold_time) {
  if( start_sample >= g->GetN() || start_sample < 0 ){
    cerr << "Error: the start sample is out of bounds" << endl;    
    return 0;
  }
  threshold_time = 0;
  threshold_sample = 0;
  int foundThreshold = 0;
  for(int i = start_sample; i > 0; i--) {
    double valT, prevValT, valY, prevValY;
    g -> GetPoint(i,valT,valY);
    g -> GetPoint(i-1,prevValT,prevValY);

    if ( (valY-target_value)*(prevValY-target_value) < 0 ) {
      double dy = (valY-prevValY);
      double dx = (valT-prevValT);
      double slope = dy/dx;
      threshold_time = prevValT + (target_value-prevValY)/slope;
      //threshold_sample = double(i-1) + (target_value-prevValY)/dy;
      threshold_sample = double(i-1);
      foundThreshold = 1;
      break;
    }
  }
  return foundThreshold;
}

int IRS3Bana::FindThresholdSampleAndTimeFalling(int start_sample, double target_value, double &threshold_sample, double &threshold_time) {
  if( start_sample >= g->GetN() || start_sample < 0 ){
    cerr << "Error: the start sample is out of bounds" << endl;    
    return 0;
  }
  threshold_time = 0;
  threshold_sample = 0;
  int foundThreshold = 0;
  for(int i = start_sample+1; i < g->GetN() ; i++) {
    double valT, prevValT, valY, prevValY;
    g -> GetPoint(i,valT,valY);
    g -> GetPoint(i-1,prevValT,prevValY);

    if ( (valY-target_value)*(prevValY-target_value) < 0 ) {
      double dy = (valY-prevValY);
      double dx = (valT-prevValT);
      double slope = dy/dx;
      threshold_time = prevValT + (target_value-prevValY)/slope;
      //threshold_sample = double(i-1) + (target_value-prevValY)/dy;
      threshold_sample = double(i-1);
      foundThreshold = 1;
      break;
    }
  }
  return foundThreshold;
}

//calculate 5-point truncated mean about input sample
double IRS3Bana::GetTruncatedMean(int sample){
  if( sample < 0 || sample > g->GetN() ){
    std::cerr << "Error: Sample number out of graph bounds" << std::endl;
  }
  int low = sample - 2;
  int high = sample + 2;
  if( low < 0 ) low = 0;
  if( high >= g->GetN() ) high = g->GetN()-1;

  //get input sample value for initial value of mean
  double xVal, yVal;
  g -> GetPoint(sample,xVal,yVal);
  double mean = yVal;

  //find min and max samples in point window
  double min = yVal;
  double max = yVal;
  for( int i = low ; i < high ; i++ ){
    g -> GetPoint(i,xVal,yVal);
    if( yVal < min )
      min = yVal;
    if( yVal > max )
      max = yVal;
  }

  //calculate the mean after discarding min and max samples
  int count = 0;
  double sum = 0;
  for( int i = low ; i < high ; i++ ){
    g -> GetPoint(i,xVal,yVal);
    if( yVal > min && yVal < max ){
      sum += yVal;
      count++;
    }
  }
  //calculate the truncated mean
  if( count > 0 )
    mean = sum/double(count);

  return mean;
}

//generic method to plot a graph
void IRS3Bana::plotGraph(TGraph *grIn,TCanvas *c0){
	if( !grIn)
		return;
	if( grIn->GetN() == 0 )
		return;
    
	grIn->SetMarkerStyle(21);
 	grIn->SetMarkerSize(0.5);

	c0->Clear();
	grIn->Draw("ALP");
	c0->Update();
	std::cout << "Press a key to continue" << std::endl;		

	return;
}

//plot the roi graph object
void IRS3Bana::plotRoi(TCanvas *c0, int mod, int row, int col, int ch){
	//add ROI info
	char title[200];
	memset(title,0,sizeof(char)*200 );
	sprintf(title,"Module %.2i Row %.2i Col %.2i Ch %.2i",mod,row,col,ch);

	g->SetTitle(title);
	plotGraph(g,c0);
	
	return;
}
