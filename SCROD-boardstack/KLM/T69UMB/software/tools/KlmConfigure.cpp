#include <iostream>
#include <cstdlib>

#include "base/KlmSystem.h"

using namespace std;

int main(int argc, char** argv)
{
	if(argc != 2)
	{
		cout << "USAGE: KlmConfigure <configuration>" << endl;
		return 1;
	}
	
	KlmModule* module;

	// init the system
	KlmSystem::KLM().initialize(std::cout, argv[1]);
	
	// clear the system
	KlmSystem::Cleanup();
	
	return 0;
}
