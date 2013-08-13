#include <TApplication.h> 
#include <TGClient.h> 
#include "Riostream.h"
#include "USBdisplay.h" 
//////////////////////////////////////
using namespace std;
using std::cout;
using std::cin;
using std::endl;
void guitest(int verbose,int OffLineMode);
 //////////////////////////////////////
int main(int argc, char **argv)
{
  TApplication theApp("App", &argc, argv);
   if (gROOT->IsBatch()) {
      fprintf(stderr, "%s: cannot run in batch mode\n", argv[0]);
      return 1;
   }
   guitest(false,false);
   theApp.Run();
   return 0;
}
//////////////////////////////////////
void guitest(int verbose,int OffLineMode)
{
  bool verbose_check;
  bool OffLineMode_check;
  if(verbose == 1){
    verbose_check = true;
    cout << "verbose is true" << endl;
  }
  else{
    verbose_check = false;    
    cout << "verbose is false" << endl;
  }
  if(OffLineMode == 1){
    OffLineMode_check = true;
    cout << "OffLineMode is true" << endl;
  }
  else{
    OffLineMode_check = false;    
    cout << "OffLineMode is false" << endl;
  }
   new MainFrame(gClient->GetRoot(),verbose_check,OffLineMode_check);
}
//////////////////////////////////////