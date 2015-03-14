#include <iostream>
#include <cstdlib>


#include "base/KlmSystem.h"

using namespace std;

int main(int argc, char** argv)
{
	if(argc != 3)
	{
		cout << "USAGE: KlmRegisterRead <board_id> <register_number>" << endl;
		return 1;
	}
	
	KlmModule* module;

	// init the system
	KlmSystem::KLM().initialize(std::cout);
	
	// get the module
	module = KlmSystem::KLM()[atoi(argv[1])];
	if(module)
	{
		cout << "Register value is: " << module->read_register(atoi(argv[2])) << endl;
	}
	else
	{
		cout << "ERROR: Module " << atoi(argv[1]) << " not found!" << endl;
	}
	
	// clear the system
	KlmSystem::Cleanup();
	
	return 0;
}
