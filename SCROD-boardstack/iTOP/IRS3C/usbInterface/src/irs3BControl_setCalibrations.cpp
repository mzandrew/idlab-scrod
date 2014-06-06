#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <iostream>
#include <stdlib.h> 
#include "irs3BControlClass.h"

using namespace std;

int triggerThreshold[4][4][8];
int loadTriggerThresholds();

int main(int argc, char* argv[]){
	if (argc != 1){
    		std::cout << "wrong number of arguments: usage ./isr3BControl_setCalibrations" << std::endl;
    		return 0;
  	}

	//create irs3b interface object
	irs3BControlClass *control = new irs3BControlClass();

	//initialize USB interface - Mandatory
	control->initializeUSBInterface();

	//define the SCROD ID for board stack, hardcoded for now
	unsigned int board_id = 0x0;

	//write the register
	int regValReadback;

	//load trigger thresholds
	loadTriggerThresholds();

	for( int row = 0 ; row < 4 ; row++)
	for( int col = 0 ; col < 4 ; col++)
	for( int ch = 0 ; ch < 8 ; ch++){
		//get trigger threshold register 
		int trigThreshReg = 13 + ch + 8*row +8*4*col;

		//program trigger thresholds register
		if( !control->registerWriteReadback(board_id, trigThreshReg, triggerThreshold[row][col][ch] + 5, regValReadback) )
			std::cout << "Register write failed" << std::endl;		
	}
	
	//close USB interface
        control->closeUSBInterface();

	//delete irs3b interface object
	delete control;

	return 1;
}

int loadTriggerThresholds(){
triggerThreshold[0][0][0] = 0;
triggerThreshold[0][0][1] = 1890;
triggerThreshold[0][0][2] = 1881;
triggerThreshold[0][0][3] = 1860;
triggerThreshold[0][0][4] = 1839;
triggerThreshold[0][0][5] = 1893;
triggerThreshold[0][0][6] = 1851;
triggerThreshold[0][0][7] = 1884;
triggerThreshold[0][1][0] = 1908;
triggerThreshold[0][1][1] = 1896;
triggerThreshold[0][1][2] = 1884;
triggerThreshold[0][1][3] = 1911;
triggerThreshold[0][1][4] = 1899;
triggerThreshold[0][1][5] = 1878;
triggerThreshold[0][1][6] = 1878;
triggerThreshold[0][1][7] = 1884;
triggerThreshold[0][2][0] = 1893;
triggerThreshold[0][2][1] = 1881;
triggerThreshold[0][2][2] = 1884;
triggerThreshold[0][2][3] = 1887;
triggerThreshold[0][2][4] = 1866;
triggerThreshold[0][2][5] = 1869;
triggerThreshold[0][2][6] = 1878;
triggerThreshold[0][2][7] = 1878;
triggerThreshold[0][3][0] = 1875;
triggerThreshold[0][3][1] = 1863;
triggerThreshold[0][3][2] = 1890;
triggerThreshold[0][3][3] = 1872;
triggerThreshold[0][3][4] = 1884;
triggerThreshold[0][3][5] = 1890;
triggerThreshold[0][3][6] = 1866;
triggerThreshold[0][3][7] = 1881;
triggerThreshold[1][0][0] = 1875;
triggerThreshold[1][0][1] = 1890;
triggerThreshold[1][0][2] = 1893;
triggerThreshold[1][0][3] = 1872;
triggerThreshold[1][0][4] = 1890;
triggerThreshold[1][0][5] = 1887;
triggerThreshold[1][0][6] = 1887;
triggerThreshold[1][0][7] = 1899;
triggerThreshold[1][1][0] = 1893;
triggerThreshold[1][1][1] = 1863;
triggerThreshold[1][1][2] = 1869;
triggerThreshold[1][1][3] = 1884;
triggerThreshold[1][1][4] = 1905;
triggerThreshold[1][1][5] = 1884;
triggerThreshold[1][1][6] = 1881;
triggerThreshold[1][1][7] = 1878;
triggerThreshold[1][2][0] = 1881;
triggerThreshold[1][2][1] = 1872;
triggerThreshold[1][2][2] = 1899;
triggerThreshold[1][2][3] = 1899;
triggerThreshold[1][2][4] = 1872;
triggerThreshold[1][2][5] = 1887;
triggerThreshold[1][2][6] = 1863;
triggerThreshold[1][2][7] = 1896;
triggerThreshold[1][3][0] = 1905;
triggerThreshold[1][3][1] = 1920;
triggerThreshold[1][3][2] = 1911;
triggerThreshold[1][3][3] = 1914;
triggerThreshold[1][3][4] = 1887;
triggerThreshold[1][3][5] = 1875;
triggerThreshold[1][3][6] = 1896;
triggerThreshold[1][3][7] = 1899;
triggerThreshold[2][0][0] = 1887;
triggerThreshold[2][0][1] = 1857;
triggerThreshold[2][0][2] = 1857;
triggerThreshold[2][0][3] = 1890;
triggerThreshold[2][0][4] = 1896;
triggerThreshold[2][0][5] = 1881;
triggerThreshold[2][0][6] = 1839;
triggerThreshold[2][0][7] = 1857;
triggerThreshold[2][1][0] = 1899;
triggerThreshold[2][1][1] = 1878;
triggerThreshold[2][1][2] = 1875;
triggerThreshold[2][1][3] = 1911;
triggerThreshold[2][1][4] = 1875;
triggerThreshold[2][1][5] = 1872;
triggerThreshold[2][1][6] = 1866;
triggerThreshold[2][1][7] = 1887;
triggerThreshold[2][2][0] = 1899;
triggerThreshold[2][2][1] = 1884;
triggerThreshold[2][2][2] = 1905;
triggerThreshold[2][2][3] = 1908;
triggerThreshold[2][2][4] = 1890;
triggerThreshold[2][2][5] = 1902;
triggerThreshold[2][2][6] = 1887;
triggerThreshold[2][2][7] = 1887;
triggerThreshold[2][3][0] = 1890;
triggerThreshold[2][3][1] = 1902;
triggerThreshold[2][3][2] = 0;
triggerThreshold[2][3][3] = 1893;
triggerThreshold[2][3][4] = 1878;
triggerThreshold[2][3][5] = 1884;
triggerThreshold[2][3][6] = 1869;
triggerThreshold[2][3][7] = 1878;
triggerThreshold[3][0][0] = 1893;
triggerThreshold[3][0][1] = 1887;
triggerThreshold[3][0][2] = 1893;
triggerThreshold[3][0][3] = 1884;
triggerThreshold[3][0][4] = 1866;
triggerThreshold[3][0][5] = 1875;
triggerThreshold[3][0][6] = 1893;
triggerThreshold[3][0][7] = 1872;
triggerThreshold[3][1][0] = 1866;
triggerThreshold[3][1][1] = 1863;
triggerThreshold[3][1][2] = 1884;
triggerThreshold[3][1][3] = 1893;
triggerThreshold[3][1][4] = 1866;
triggerThreshold[3][1][5] = 1851;
triggerThreshold[3][1][6] = 1875;
triggerThreshold[3][1][7] = 1902;
triggerThreshold[3][2][0] = 1884;
triggerThreshold[3][2][1] = 1899;
triggerThreshold[3][2][2] = 1884;
triggerThreshold[3][2][3] = 1899;
triggerThreshold[3][2][4] = 1866;
triggerThreshold[3][2][5] = 1878;
triggerThreshold[3][2][6] = 1875;
triggerThreshold[3][2][7] = 1872;
triggerThreshold[3][3][0] = 1851;
triggerThreshold[3][3][1] = 1857;
triggerThreshold[3][3][2] = 1842;
triggerThreshold[3][3][3] = 1866;
triggerThreshold[3][3][4] = 1866;
triggerThreshold[3][3][5] = 1842;
triggerThreshold[3][3][6] = 1848;
triggerThreshold[3][3][7] = 1863;	
return 0;
}
