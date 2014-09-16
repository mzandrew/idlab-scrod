#include <iostream>
#include <cstdlib>

#include "base/KlmSystem.h"

using namespace std;

int main(int argc, char** argv)
{
	if(argc != 5)
	{
		cout << "USAGE: KlmAsicWrite <board_id> <daughter_board_id> <register_number> <register_value>" << endl;
		return 1;
	}
	
	KlmModule* module;

	// init the system
	KlmSystem::KLM().initialize(std::cout);
	
	// get the module
	module = KlmSystem::KLM()[atoi(argv[1])];
	if(module)
	{
		module->write_register(SCROD_REGISTER_T6_SPEED_1, T6_SPEED_1_DEFAULT, true);
		module->write_register(SCROD_REGISTER_T6_SPEED_2, T6_SPEED_2_DEFAULT, true);
		// write it
		module->write_ASIC_register(atoi(argv[2]), atoi(argv[3]), atoi(argv[4]));
		cout << "Register should be written." << endl;
	}
	else
	{
		cout << "ERROR: Module " << atoi(argv[1]) << " not found!" << endl;
	}
	
	// clear the system
	KlmSystem::Cleanup();
	
	return 0;
}
