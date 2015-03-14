#include <iostream>
#include <cstdlib>

#include "base/KlmSystem.h"

using namespace std;

int main(int argc, char** argv)
{
	if(argc != 4)
	{
		cout << "USAGE: KlmRegisterWrite <board_id> <register_number> <register_value>" << endl;
		return 1;
	}
	
	KlmModule* module;

	// init the system
	KlmSystem::KLM().initialize(std::cout);
	
	// get the module
	module = KlmSystem::KLM()[atoi(argv[1])];
	if(module)
	{
		module->write_register(atoi(argv[2]), atoi(argv[3]), true);
		cout << "Register write done!" << endl;
	}
	else
	{
		cout << "ERROR: Module " << atoi(argv[1]) << " not found!" << endl;
	}
	
	// clear the system
	KlmSystem::Cleanup();
}
